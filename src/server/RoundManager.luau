--!strict
-- Runs the game loop:  Waiting → Intermission → Round → Ended → (repeat)
--
-- Other server modules plug in through the signals:
--   RoundManager.RoundPreparing:Connect(function() ... end)  -- before players are teleported
--   RoundManager.RoundStarted:Connect(function(participants: {Player}) ... end)
--   RoundManager.RoundEnded:Connect(function(survivors: {Player}, participants: {Player}) ... end)
-- (Step 7 builds the platforms on RoundPreparing, step 6 starts the lava on RoundStarted,
--  step 8 gives coins on RoundEnded.)
--
-- RoundPreparing handlers must NOT yield (no task.wait / WaitForChild on missing objects):
-- Signal:Fire runs each handler immediately until it yields, so a handler that doesn't
-- yield is guaranteed to finish before the teleport. Handlers run in the order they
-- were connected (the order of the init() calls in Main.server.luau).
--
-- Each player gets attributes (see shared/PlayerAttributes) so clients know who is
-- still in the round: InRound, WasInRound, RevivedThisRound.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local Signal = require(script.Parent.Signal)

local Phase = RoundState.Phase

local RoundManager = {}

RoundManager.RoundPreparing = Signal.new() -- ()
RoundManager.RoundStarted = Signal.new() -- (participants: {Player})
RoundManager.RoundEnded = Signal.new() -- (survivors: {Player}, participants: {Player})

-- The round being played right now (nil between rounds).
type Round = {
	participants: { Player },
	alive: { [Player]: boolean },
	aliveCount: number,
	connections: { RBXScriptConnection },
}

local stateFolder: Folder? = nil
local currentRound: Round? = nil

-- Writes the current state where every client can read it.
local function setState(phase: string, timeLeft: number, message: string)
	local folder = stateFolder :: Folder
	folder:SetAttribute(RoundState.ATTR_PHASE, phase)
	folder:SetAttribute(RoundState.ATTR_TIME_LEFT, timeLeft)
	folder:SetAttribute(RoundState.ATTR_MESSAGE, message)
end

-- Returns the player's living humanoid, or nil if they have no character or are dead.
local function getLivingHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return humanoid
end

local function teleport(player: Player, target: CFrame)
	local character = player.Character
	if character then
		character:PivotTo(target)
	end
end

local function shuffled<T>(list: { T }): { T }
	local copy = table.clone(list)
	for i = #copy, 2, -1 do
		local j = math.random(i)
		copy[i], copy[j] = copy[j], copy[i]
	end
	return copy
end

local function getArenaSpawnPoints(): { BasePart }
	local folder = Workspace:WaitForChild("Arena"):WaitForChild("SpawnPoints")
	local points: { BasePart } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(points, child)
		end
	end
	return points
end

local function getLobbySpawn(): BasePart
	return Workspace:WaitForChild("Lobby"):WaitForChild("LobbySpawn") :: BasePart
end

local function sendToLobby(player: Player)
	local offset = Vector3.new(math.random(-6, 6), 4, math.random(-6, 6))
	teleport(player, getLobbySpawn().CFrame + offset)
end

local function knockOut(round: Round, player: Player)
	if round.alive[player] then
		round.alive[player] = nil
		round.aliveCount -= 1
		player:SetAttribute(PlayerAttributes.IN_ROUND, false)
	end
end

-- Marks the player as alive in the round and watches their humanoid.
local function track(round: Round, player: Player, humanoid: Humanoid)
	if round.alive[player] then
		return
	end
	round.alive[player] = true
	round.aliveCount += 1
	player:SetAttribute(PlayerAttributes.IN_ROUND, true)
	player:SetAttribute(PlayerAttributes.WAS_IN_ROUND, true)
	table.insert(round.connections, humanoid.Died:Connect(function()
		knockOut(round, player)
	end))
end

local function clearRoundAttributes()
	for _, player in Players:GetPlayers() do
		player:SetAttribute(PlayerAttributes.IN_ROUND, false)
		player:SetAttribute(PlayerAttributes.WAS_IN_ROUND, false)
		player:SetAttribute(PlayerAttributes.REVIVED, false)
	end
end

-- Counts down in the lobby. Returns when a round should start.
-- If players leave and there are too few, it goes back to waiting.
local function runIntermission()
	while true do
		if #Players:GetPlayers() < Config.MIN_PLAYERS then
			setState(Phase.Waiting, 0, "Waiting for players...")
			task.wait(1)
			continue
		end

		local enoughPlayers = true
		for timeLeft = Config.INTERMISSION_TIME, 1, -1 do
			if #Players:GetPlayers() < Config.MIN_PLAYERS then
				enoughPlayers = false
				break
			end
			setState(Phase.Intermission, timeLeft, `Round starts in {timeLeft}`)
			task.wait(1)
		end

		if enoughPlayers then
			return
		end
	end
end

-- Teleports everyone into the arena, waits until the round is over.
-- Returns the survivors and everyone who took part (both empty if nobody could play).
local function runRound(): ({ Player }, { Player })
	-- Everyone who is alive in the lobby right now takes part.
	local participants: { Player } = {}
	for _, player in Players:GetPlayers() do
		if getLivingHumanoid(player) then
			table.insert(participants, player)
		end
	end
	if #participants == 0 then
		return {}, {}
	end

	-- Let other modules set up the arena (new platforms) before anyone arrives.
	RoundManager.RoundPreparing:Fire()

	-- Teleport to the arena, spread over the spawn points.
	local spawnPoints = shuffled(getArenaSpawnPoints())
	for index, player in participants do
		local point = spawnPoints[(index - 1) % #spawnPoints + 1]
		teleport(player, point.CFrame + Vector3.new(0, 3, 0))
	end

	-- Track who is still alive. A player is out when they die or leave the game.
	local round: Round = { participants = participants, alive = {}, aliveCount = 0, connections = {} }
	for _, player in participants do
		local humanoid = getLivingHumanoid(player)
		if humanoid then
			track(round, player, humanoid)
		end
	end
	table.insert(round.connections, Players.PlayerRemoving:Connect(function(player)
		knockOut(round, player)
	end))
	currentRound = round

	RoundManager.RoundStarted:Fire(participants)

	-- With several players the round ends when one is left (the winner).
	-- Alone (testing), it ends when you die or the time runs out.
	local playersNeededToContinue = if #participants > 1 then 2 else 1

	for timeLeft = Config.ROUND_TIME, 1, -1 do
		if round.aliveCount < playersNeededToContinue then
			break
		end
		setState(Phase.Round, timeLeft, `Survive! {timeLeft}s · {round.aliveCount} alive`)
		task.wait(1)
	end

	currentRound = nil
	for _, connection in round.connections do
		connection:Disconnect()
	end

	local survivors: { Player } = {}
	for player in round.alive do
		table.insert(survivors, player)
	end
	return survivors, participants
end

local function showResult(survivors: { Player }, participants: { Player })
	local message
	if #survivors == 0 then
		message = "Nobody survived!"
	elseif #survivors == 1 and #participants > 1 then
		message = `{survivors[1].DisplayName} wins!`
	elseif #survivors == 1 then
		message = `{survivors[1].DisplayName} survived!`
	else
		message = `{#survivors} players survived!`
	end
	setState(Phase.Ended, Config.END_TIME, message)
	task.wait(Config.END_TIME)
end

local function gameLoop()
	while true do
		runIntermission()
		local survivors, participants = runRound()
		if #participants == 0 then
			continue -- nobody was alive in the lobby (e.g. everyone respawning): just count down again
		end
		RoundManager.RoundEnded:Fire(survivors, participants)
		showResult(survivors, participants)
		clearRoundAttributes()
		-- Dead players already respawn in the lobby; bring the survivors back too.
		for _, player in survivors do
			if player.Parent then
				sendToLobby(player)
			end
		end
	end
end

-- Players must only (re)spawn in the lobby. The Baseplate template comes with its own
-- SpawnLocation on the ground; switch off every spawn except the lobby's (for this server
-- only, the saved place is not changed).
local function disableOtherSpawns()
	local lobbySpawn = getLobbySpawn()
	for _, instance in Workspace:GetDescendants() do
		if instance:IsA("SpawnLocation") and instance ~= lobbySpawn and instance.Enabled then
			instance.Enabled = false
			warn(`Disabled extra SpawnLocation "{instance:GetFullName()}" (players spawn in the lobby only)`)
		end
	end
end

-- True while a round is being played.
function RoundManager.isRoundActive(): boolean
	return currentRound ~= nil
end

-- True if the player is still alive in the current round.
function RoundManager.isAlive(player: Player): boolean
	local round = currentRound
	return round ~= nil and round.alive[player] == true
end

-- True if the player took part in the current round, is out, and hasn't been revived yet.
function RoundManager.canRevive(player: Player): boolean
	local round = currentRound
	return round ~= nil
		and table.find(round.participants, player) ~= nil
		and not round.alive[player]
		and player:GetAttribute(PlayerAttributes.REVIVED) ~= true
end

-- Puts a revived player (with a new, living character already placed in the arena)
-- back into the current round. Returns false if that is no longer possible.
function RoundManager.readmit(player: Player): boolean
	local round = currentRound
	local humanoid = getLivingHumanoid(player)
	if not round or not humanoid or not RoundManager.canRevive(player) then
		return false
	end
	player:SetAttribute(PlayerAttributes.REVIVED, true)
	track(round, player, humanoid)
	return true
end

-- Call once from the server entry point.
function RoundManager.start()
	assert(stateFolder == nil, "RoundManager.start() was called twice")
	disableOtherSpawns()

	local folder = Instance.new("Folder")
	folder.Name = RoundState.FOLDER_NAME
	folder.Parent = ReplicatedStorage
	stateFolder = folder
	setState(Phase.Waiting, 0, "Waiting for players...")

	task.spawn(gameLoop)
end

-- Sets an extra attribute on the RoundState folder (e.g. the round event, step 12).
function RoundManager.setStateAttribute(name: string, value: any)
	local folder = stateFolder
	if folder then
		folder:SetAttribute(name, value)
	end
end

return RoundManager
