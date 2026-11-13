--!strict
-- Revive button (step 17). Shown when you died in a round that is still running and you
-- haven't been revived yet this round. Opens Roblox's purchase window for the Revive product;
-- the server (ProductService) puts you back into the round.
-- Hidden when Config.PRODUCTS.REVIVE is 0 (product not created yet).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local SoundPlayer = require(script.Parent.SoundPlayer)

local productId = Config.PRODUCTS.REVIVE
if productId == 0 then
	return
end

local player = Players.LocalPlayer
local stateFolder = ReplicatedStorage:WaitForChild(RoundState.FOLDER_NAME)

local gui = Instance.new("ScreenGui")
gui.Name = "RevivePrompt"
gui.ResetOnSpawn = false

local button = Instance.new("TextButton")
button.Name = "Revive"
button.AnchorPoint = Vector2.new(0.5, 1)
button.Position = UDim2.new(0.5, 0, 1, -84) -- above the spectate bar
button.Size = UDim2.new(0, 220, 0, 50)
button.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.Text = "REVIVE"
button.Visible = false
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = button

gui.Parent = player:WaitForChild("PlayerGui")

local function refresh()
	button.Visible = stateFolder:GetAttribute(RoundState.ATTR_PHASE) == RoundState.Phase.Round
		and player:GetAttribute(PlayerAttributes.WAS_IN_ROUND) == true
		and player:GetAttribute(PlayerAttributes.IN_ROUND) ~= true
		and player:GetAttribute(PlayerAttributes.REVIVED) ~= true
end

button.Activated:Connect(function()
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	MarketplaceService:PromptProductPurchase(player, productId)
end)

stateFolder:GetAttributeChangedSignal(RoundState.ATTR_PHASE):Connect(refresh)
player:GetAttributeChangedSignal(PlayerAttributes.IN_ROUND):Connect(refresh)
player:GetAttributeChangedSignal(PlayerAttributes.WAS_IN_ROUND):Connect(refresh)
player:GetAttributeChangedSignal(PlayerAttributes.REVIVED):Connect(refresh)
refresh()
