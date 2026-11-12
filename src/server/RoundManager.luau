--!strict
-- Runs the game loop:  Waiting → Intermission → Round → Ended → (repeat)
--
-- Other server modules plug in through the signals:
--   RoundManager.RoundStarted:Connect(function(participants: {Player}) ... end)
--   RoundManager.RoundEnded:Connect(function(survivors: {Player}) ... end)
-- (Step 6 starts the lava on RoundStarted, step 8 gives coins on RoundEnded.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local Signal = require(script.Parent.Signal)

local Phase = RoundState.Phase

local RoundManager = {}

RoundManager.RoundStarted = Signal.new() -- (participants: {Player})
RoundManager.RoundEnded = Signal.new() -- (survivors: {Player})

local stateFolder: Folder? = nil

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

-- Teleports everyone into the arena, waits until the round is over and returns the survivors.
local function runRound(): { Player }
	-- Everyone who is alive in the lobby right now takes part.
	local participants: { Player } = {}
	for _, player in Players:GetPlayers() do
		if getLivingHumanoid(player) then
			table.insert(participants, player)
		end
	end
	if #participants == 0 then
		return {}
	end

	-- Teleport to the arena, spread over the spawn points.
	local spawnPoints = shuffled(getArenaSpawnPoints())
	for index, player in participants do
		local point = spawnPoints[(index - 1) % #spawnPoints + 1]
		teleport(player, point.CFrame + Vector3.new(0, 3, 0))
	end

	-- Track who is still alive. A player is out when they die or leave the game.
	local alive: { [Player]: boolean } = {}
	local aliveCount = 0
	local connections: { RBXScriptConnection } = {}

	local function knockOut(player: Player)
		if alive[player] then
			alive[player] = nil
			aliveCount -= 1
		end
	end

	for _, player in participants do
		local humanoid = getLivingHumanoid(player)
		if humanoid then
			alive[player] = true
			aliveCount += 1
			table.insert(connections, humanoid.Died:Connect(function()
				knockOut(player)
			end))
		end
	end
	table.insert(connections, Players.PlayerRemoving:Connect(knockOut))

	RoundManager.RoundStarted:Fire(participants)

	-- With several players the round ends when one is left (the winner).
	-- Alone (testing), it ends when you die or the time runs out.
	local playersNeededToContinue = if #participants > 1 then 2 else 1

	for timeLeft = Config.ROUND_TIME, 1, -1 do
		if aliveCount < playersNeededToContinue then
			break
		end
		setState(Phase.Round, timeLeft, `Survive! {timeLeft}s · {aliveCount} alive`)
		task.wait(1)
	end

	for _, connection in connections do
		connection:Disconnect()
	end

	local survivors: { Player } = {}
	for player in alive do
		table.insert(survivors, player)
	end
	return survivors
end

local function showResult(survivors: { Player })
	local message
	if #survivors == 0 then
		message = "Nobody survived!"
	elseif #survivors == 1 then
		message = `{survivors[1].DisplayName} wins!`
	else
		message = `{#survivors} players survived!`
	end
	setState(Phase.Ended, Config.END_TIME, message)
	task.wait(Config.END_TIME)
end

local function gameLoop()
	while true do
		runIntermission()
		local survivors = runRound()
		RoundManager.RoundEnded:Fire(survivors)
		showResult(survivors)
		-- Dead players already respawn in the lobby; bring the survivors back too.
		for _, player in survivors do
			if player.Parent then
				sendToLobby(player)
			end
		end
	end
end

-- Call once from the server entry point.
function RoundManager.start()
	assert(stateFolder == nil, "RoundManager.start() was called twice")

	local folder = Instance.new("Folder")
	folder.Name = RoundState.FOLDER_NAME
	folder.Parent = ReplicatedStorage
	stateFolder = folder
	setState(Phase.Waiting, 0, "Waiting for players...")

	task.spawn(gameLoop)
end

return RoundManager
