--!strict
-- Shows the round message ("Round starts in 10", "Survive! 45s · 3 alive", ...)
-- at the top of the screen. The server writes the message; this script only displays it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundEvents = require(ReplicatedStorage.Shared.RoundEvents)
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

-- Round event banner (step 12), under the message, only during a special round.
local eventLabel = Instance.new("TextLabel")
eventLabel.Name = "Event"
eventLabel.AnchorPoint = Vector2.new(0.5, 0)
eventLabel.Position = UDim2.new(0.5, 0, 0, 62)
eventLabel.Size = UDim2.new(0.5, 0, 0, 30)
eventLabel.BackgroundColor3 = Color3.fromRGB(200, 70, 20)
eventLabel.BackgroundTransparency = 0.15
eventLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
eventLabel.Font = Enum.Font.GothamBold
eventLabel.TextScaled = true
eventLabel.Visible = false
eventLabel.Parent = gui

local eventCorner = Instance.new("UICorner")
eventCorner.CornerRadius = UDim.new(0, 8)
eventCorner.Parent = eventLabel

local eventSizeLimit = Instance.new("UISizeConstraint")
eventSizeLimit.MaxSize = Vector2.new(420, 30)
eventSizeLimit.Parent = eventLabel

gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	local message = stateFolder:GetAttribute(RoundState.ATTR_MESSAGE)
	label.Text = if typeof(message) == "string" then message else ""
end

local function refreshEvent()
	local phase = stateFolder:GetAttribute(RoundState.ATTR_PHASE)
	local eventId = stateFolder:GetAttribute(RoundState.ATTR_EVENT)
	local event = if typeof(eventId) == "string" then RoundEvents.byId[eventId] else nil
	if phase == RoundState.Phase.Round and event and event.title ~= "" then
		eventLabel.Text = `⚡ {event.title} {event.description}`
		eventLabel.Visible = true
	else
		eventLabel.Visible = false
	end
end

stateFolder:GetAttributeChangedSignal(RoundState.ATTR_MESSAGE):Connect(refresh)
stateFolder:GetAttributeChangedSignal(RoundState.ATTR_PHASE):Connect(refreshEvent)
stateFolder:GetAttributeChangedSignal(RoundState.ATTR_EVENT):Connect(refreshEvent)
refresh()
refreshEvent()
