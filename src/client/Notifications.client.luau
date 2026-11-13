--!strict
-- Small pop-up messages ("toasts") at the bottom of the screen, sent by the server:
-- "+10 coins", "Daily reward: +30 coins", "Not enough coins", ... (Step 11.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(script.Parent.SoundPlayer)

local SHOW_TIME = 3 -- seconds

local COLORS: { [string]: Color3 } = {
	info = Color3.fromRGB(40, 40, 50),
	coins = Color3.fromRGB(190, 140, 20),
	success = Color3.fromRGB(40, 140, 70),
	error = Color3.fromRGB(170, 40, 40),
}

local player = Players.LocalPlayer
local notify = ReplicatedStorage:WaitForChild(Remotes.FOLDER):WaitForChild(Remotes.NOTIFY) :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "Notifications"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10

local list = Instance.new("Frame")
list.Name = "List"
list.AnchorPoint = Vector2.new(0.5, 1)
list.Position = UDim2.new(0.5, 0, 1, -120)
list.Size = UDim2.new(0, 360, 0, 200)
list.BackgroundTransparency = 1
list.Parent = gui

local layout = Instance.new("UIListLayout")
layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

gui.Parent = player:WaitForChild("PlayerGui")

local counter = 0

local function show(text: string, kind: string)
	counter += 1
	local label = Instance.new("TextLabel")
	label.LayoutOrder = counter
	label.Size = UDim2.new(1, 0, 0, 36)
	label.BackgroundColor3 = COLORS[kind] or COLORS.info
	label.BackgroundTransparency = 0.1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = label
	label.Parent = list

	if kind == "coins" then
		SoundPlayer.play(Config.SOUNDS.COINS)
	elseif kind == "error" then
		SoundPlayer.play(Config.SOUNDS.ERROR)
	end

	task.delay(SHOW_TIME, function()
		local fade = TweenInfo.new(0.4)
		TweenService:Create(label, fade, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.4)
		label:Destroy()
	end)
end

notify.OnClientEvent:Connect(function(text: unknown, kind: unknown)
	if typeof(text) == "string" then
		show(text, if typeof(kind) == "string" then kind else "info")
	end
end)
