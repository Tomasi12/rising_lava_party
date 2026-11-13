--!strict
-- Spectate (step 13): when you are out of the round (dead, or joined late), the camera follows
-- a player who is still alive. Buttons: ◀ ▶ switch player, ✕ stop watching (until the next round).
--
-- Who is alive comes from the InRound attribute the server sets on every player.
-- The Revive button (step 17) sits just above this bar (RevivePrompt.client).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local SoundPlayer = require(script.Parent.SoundPlayer)

local REFRESH_INTERVAL = 0.25 -- seconds

local player = Players.LocalPlayer
local stateFolder = ReplicatedStorage:WaitForChild(RoundState.FOLDER_NAME)

-- UI -----------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "SpectateGui"
gui.ResetOnSpawn = false

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -20)
bar.Size = UDim2.new(0, 360, 0, 50)
bar.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
bar.BackgroundTransparency = 0.2
bar.Visible = false
bar.Parent = gui

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 10)
barCorner.Parent = bar

local function makeButton(name: string, text: string, xScale: number, xOffset: number, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.new(xScale, xOffset, 0.5, 0)
	button.Size = UDim2.new(0, width, 0, 40)
	button.BackgroundColor3 = Color3.fromRGB(70, 60, 60)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Parent = bar
	return button
end

local previousButton = makeButton("Previous", "◀", 0, 30, 44)
local nextButton = makeButton("Next", "▶", 1, -80, 44)
local closeButton = makeButton("Close", "✕", 1, -28, 40)
closeButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "Watching"
nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
nameLabel.Position = UDim2.new(0.5, -25, 0.5, 0)
nameLabel.Size = UDim2.new(0, 190, 0, 34)
nameLabel.BackgroundTransparency = 1
nameLabel.TextColor3 = Color3.new(1, 1, 1)
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextScaled = true
nameLabel.Parent = bar

gui.Parent = player:WaitForChild("PlayerGui")

-- Logic --------------------------------------------------------------------

local target: Player? = nil
local stoppedThisRound = false -- the player pressed ✕

local function isAlive(other: Player): boolean
	return other:GetAttribute(PlayerAttributes.IN_ROUND) == true
end

local function alivePlayers(): { Player }
	local result: { Player } = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and isAlive(other) then
			table.insert(result, other)
		end
	end
	return result
end

local function humanoidOf(other: Player): Humanoid?
	local character = other.Character
	return if character then character:FindFirstChildOfClass("Humanoid") else nil
end

local function shouldSpectate(): boolean
	return stateFolder:GetAttribute(RoundState.ATTR_PHASE) == RoundState.Phase.Round
		and not isAlive(player)
		and not stoppedThisRound
end

local function setCameraSubject(humanoid: Humanoid?)
	local camera = Workspace.CurrentCamera
	if camera and humanoid and camera.CameraSubject ~= humanoid then
		camera.CameraSubject = humanoid
	end
end

local function stopSpectating()
	if target then
		target = nil
		setCameraSubject(humanoidOf(player))
	end
	bar.Visible = false
end

-- Moves to the next (+1) or previous (-1) alive player.
local function cycle(direction: number)
	local candidates = alivePlayers()
	if #candidates == 0 then
		return
	end
	local index = if target then table.find(candidates, target) else nil
	if index then
		index = (index - 1 + direction) % #candidates + 1
	else
		index = 1
	end
	target = candidates[index]
end

local function refresh()
	if not shouldSpectate() then
		stopSpectating()
		return
	end
	if not target or not target.Parent or not isAlive(target) then
		target = nil
		cycle(1)
	end
	local current = target
	if not current then
		stopSpectating()
		return
	end
	bar.Visible = true
	nameLabel.Text = `Watching: {current.DisplayName}`
	setCameraSubject(humanoidOf(current))
end

previousButton.Activated:Connect(function()
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	cycle(-1)
	refresh()
end)
nextButton.Activated:Connect(function()
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	cycle(1)
	refresh()
end)
closeButton.Activated:Connect(function()
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	stoppedThisRound = true
	stopSpectating()
end)

stateFolder:GetAttributeChangedSignal(RoundState.ATTR_PHASE):Connect(function()
	if stateFolder:GetAttribute(RoundState.ATTR_PHASE) ~= RoundState.Phase.Round then
		stoppedThisRound = false -- next round: spectate again automatically
	end
	refresh()
end)

-- Respawning resets the camera to your own character; refresh() points it back.
player.CharacterAdded:Connect(function()
	task.defer(refresh)
end)

while true do
	refresh()
	task.wait(REFRESH_INTERVAL)
end
