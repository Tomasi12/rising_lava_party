--!strict
-- Shows the round message ("Round starts in 10", "Survive! 45s · 3 alive", ...)
-- at the top of the screen. The server writes the message; this script only displays it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundState = require(ReplicatedStorage.Shared.RoundState)

local player = Players.LocalPlayer
local stateFolder = ReplicatedStorage:WaitForChild(RoundState.FOLDER_NAME)

local gui = Instance.new("ScreenGui")
gui.Name = "RoundHud"
gui.ResetOnSpawn = false -- keep the HUD when the player dies and respawns

local label = Instance.new("TextLabel")
label.Name = "Message"
label.AnchorPoint = Vector2.new(0.5, 0)
label.Position = UDim2.new(0.5, 0, 0, 12)
label.Size = UDim2.new(0.6, 0, 0, 44)
label.BackgroundColor3 = Color3.fromRGB(25, 20, 20)
label.BackgroundTransparency = 0.25
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.Text = ""
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = label

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(520, 44)
sizeLimit.Parent = label

gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	local message = stateFolder:GetAttribute(RoundState.ATTR_MESSAGE)
	label.Text = if typeof(message) == "string" then message else ""
end

stateFolder:GetAttributeChangedSignal(RoundState.ATTR_MESSAGE):Connect(refresh)
refresh()
