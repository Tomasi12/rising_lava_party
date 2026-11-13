--!strict
-- Shop window (step 15 + Robux section from steps 16/17).
-- A "SHOP" button on the left opens it. Trails are bought with coins through the ShopRequest
-- RemoteFunction; the server checks everything and answers with a pop-up.
-- The Robux section opens Roblox's own purchase window (game passes / developer products).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ShopItems = require(ReplicatedStorage.Shared.ShopItems)
local SoundPlayer = require(script.Parent.SoundPlayer)

type ShopItem = ShopItems.ShopItem

local player = Players.LocalPlayer
local shopRequest = ReplicatedStorage:WaitForChild(Remotes.FOLDER):WaitForChild(Remotes.SHOP_REQUEST) :: RemoteFunction

local COLOR_PANEL = Color3.fromRGB(30, 26, 32)
local COLOR_ROW = Color3.fromRGB(48, 42, 52)
local COLOR_BUY = Color3.fromRGB(215, 160, 20)
local COLOR_EQUIP = Color3.fromRGB(50, 110, 220)
local COLOR_EQUIPPED = Color3.fromRGB(40, 150, 70)
local COLOR_DISABLED = Color3.fromRGB(90, 90, 90)
local COLOR_ROBUX = Color3.fromRGB(0, 170, 90)

-- Small UI helpers ----------------------------------------------------------

local function corner(parent: GuiObject, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function textLabel(parent: Instance, text: string, size: UDim2, position: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Size = size
	label.Position = position
	label.Parent = parent
	return label
end

local function button(parent: Instance, text: string, size: UDim2, position: UDim2, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Text = text
	b.Size = size
	b.Position = position
	b.AutoButtonColor = true
	corner(b, 8)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 6)
	padding.PaddingBottom = UDim.new(0, 6)
	padding.PaddingLeft = UDim.new(0, 6)
	padding.PaddingRight = UDim.new(0, 6)
	padding.Parent = b
	b.Parent = parent
	return b
end

-- Window ---------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "ShopUi"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5

local openButton = button(gui, "SHOP", UDim2.new(0, 90, 0, 44), UDim2.new(0, 12, 0.5, -22), COLOR_BUY)
openButton.Name = "OpenShop"

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0.9, 0, 0.8, 0)
panel.BackgroundColor3 = COLOR_PANEL
panel.Visible = false
panel.Parent = gui
corner(panel, 12)

local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MaxSize = Vector2.new(540, 480)
sizeLimit.Parent = panel

textLabel(panel, "SHOP", UDim2.new(0.3, 0, 0, 36), UDim2.new(0, 16, 0, 10))
local coinsLabel = textLabel(panel, "", UDim2.new(0.35, 0, 0, 30), UDim2.new(0.35, 0, 0, 13))
coinsLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
local closeButton = button(panel, "X", UDim2.new(0, 40, 0, 40), UDim2.new(1, -50, 0, 8), Color3.fromRGB(150, 45, 45))

local list = Instance.new("ScrollingFrame")
list.Name = "List"
list.Position = UDim2.new(0, 12, 0, 58)
list.Size = UDim2.new(1, -24, 1, -70)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local order = 0
local function nextOrder(): number
	order += 1
	return order
end

local function sectionTitle(text: string)
	local label = textLabel(list, text, UDim2.new(1, 0, 0, 28), UDim2.new())
	label.LayoutOrder = nextOrder()
	label.TextColor3 = Color3.fromRGB(255, 190, 120)
end

local function row(): Frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -8, 0, 56)
	frame.BackgroundColor3 = COLOR_ROW
	frame.LayoutOrder = nextOrder()
	corner(frame, 8)
	frame.Parent = list
	return frame
end

-- Trails (coins) -------------------------------------------------------------

local busy = false

local function request(action: string, itemId: string)
	if busy then
		return
	end
	busy = true
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	-- The server answers with a pop-up (Notifications), so the result isn't needed here.
	local ok, err = pcall(function()
		return shopRequest:InvokeServer(action, itemId)
	end)
	if not ok then
		warn(`Shop request failed: {err}`)
	end
	busy = false
end

type TrailRow = { item: ShopItem, action: TextButton }
local trailRows: { TrailRow } = {}

local function refreshTrailRow(trailRow: TrailRow)
	local item = trailRow.item
	local owned = player:GetAttribute(PlayerAttributes.OWNED_PREFIX .. item.id) == true
	local equipped = player:GetAttribute(PlayerAttributes.EQUIPPED_TRAIL) == item.id
	local action = trailRow.action
	if item.vipOnly and not owned then
		action.Text = "VIP only"
		action.BackgroundColor3 = COLOR_DISABLED
	elseif not owned then
		action.Text = `{item.price} coins`
		action.BackgroundColor3 = COLOR_BUY
	elseif equipped then
		action.Text = "Equipped"
		action.BackgroundColor3 = COLOR_EQUIPPED
	else
		action.Text = "Equip"
		action.BackgroundColor3 = COLOR_EQUIP
	end
end

local function onTrailPressed(trailRow: TrailRow)
	local item = trailRow.item
	local owned = player:GetAttribute(PlayerAttributes.OWNED_PREFIX .. item.id) == true
	local equipped = player:GetAttribute(PlayerAttributes.EQUIPPED_TRAIL) == item.id
	if item.vipOnly and not owned then
		SoundPlayer.play(Config.SOUNDS.ERROR)
	elseif not owned then
		request("buy", item.id)
	elseif equipped then
		request("unequip", "")
	else
		request("equip", item.id)
	end
end

sectionTitle("Trails (buy with coins)")
for _, item in ShopItems.list do
	local frame = row()
	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.new(0, 60, 0, 36)
	swatch.Position = UDim2.new(0, 10, 0.5, -18)
	swatch.BackgroundColor3 = Color3.new(1, 1, 1)
	corner(swatch, 6)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ShopItems.colorSequence(item)
	gradient.Parent = swatch
	swatch.Parent = frame

	textLabel(frame, item.name, UDim2.new(0.4, -80, 0, 28), UDim2.new(0, 82, 0.5, -14))
	local action = button(frame, "", UDim2.new(0.38, 0, 0, 40), UDim2.new(0.62, -10, 0.5, -20), COLOR_BUY)
	local trailRow: TrailRow = { item = item, action = action }
	table.insert(trailRows, trailRow)
	action.Activated:Connect(function()
		onTrailPressed(trailRow)
	end)
	refreshTrailRow(trailRow)
end

local function refreshAllTrails()
	for _, trailRow in trailRows do
		refreshTrailRow(trailRow)
	end
end

player.AttributeChanged:Connect(function(name)
	if name == PlayerAttributes.EQUIPPED_TRAIL or string.sub(name, 1, #PlayerAttributes.OWNED_PREFIX) == PlayerAttributes.OWNED_PREFIX then
		refreshAllTrails()
	end
end)

-- Robux (steps 16 and 17) ------------------------------------------------------
-- IDs come from Config. An item whose ID is 0 isn't set up yet and is not shown.

-- passKey: the key in Config.GAME_PASSES; the server sets the attribute "Pass_<passKey>" when owned.
type RobuxOffer = { title: string, description: string, kind: "pass" | "product", id: number, passKey: string }

local robuxOffers: { RobuxOffer } = {
	{ title = "2x Coins", description = "Double coins from every round, forever", kind = "pass", id = Config.GAME_PASSES.DOUBLE_COINS, passKey = "DOUBLE_COINS" },
	{ title = "VIP", description = "Gold trail, VIP tag, +50% coins", kind = "pass", id = Config.GAME_PASSES.VIP, passKey = "VIP" },
	{ title = "500 Coins", description = "Coin pack", kind = "product", id = Config.PRODUCTS.COINS_500, passKey = "" },
	{ title = "2000 Coins", description = "Big coin pack", kind = "product", id = Config.PRODUCTS.COINS_2000, passKey = "" },
}

local shownOffers = 0
for _, offer in robuxOffers do
	if offer.id ~= 0 then
		shownOffers += 1
	end
end

if shownOffers > 0 then
	sectionTitle("Robux")
	for _, offer in robuxOffers do
		if offer.id == 0 then
			continue
		end
		local frame = row()
		textLabel(frame, offer.title, UDim2.new(0.55, -16, 0, 24), UDim2.new(0, 12, 0, 6))
		local description = textLabel(frame, offer.description, UDim2.new(0.55, -16, 0, 18), UDim2.new(0, 12, 0, 32))
		description.Font = Enum.Font.Gotham
		description.TextColor3 = Color3.fromRGB(200, 200, 200)
		local buyButton = button(frame, "Buy", UDim2.new(0.38, 0, 0, 40), UDim2.new(0.62, -10, 0.5, -20), COLOR_ROBUX)

		local function refreshPass()
			if offer.kind == "pass" then
				-- The server sets Pass_<id> when the player owns it.
				local owned = player:GetAttribute(PlayerAttributes.PASS_PREFIX .. offer.passKey) == true
				buyButton.Text = if owned then "Owned" else "Buy"
				buyButton.BackgroundColor3 = if owned then COLOR_EQUIPPED else COLOR_ROBUX
			end
		end
		refreshPass()
		player:GetAttributeChangedSignal(PlayerAttributes.PASS_PREFIX .. offer.passKey):Connect(refreshPass)

		buyButton.Activated:Connect(function()
			SoundPlayer.play(Config.SOUNDS.BUTTON)
			if offer.kind == "pass" then
				if player:GetAttribute(PlayerAttributes.PASS_PREFIX .. offer.passKey) ~= true then
					MarketplaceService:PromptGamePassPurchase(player, offer.id)
				end
			else
				MarketplaceService:PromptProductPurchase(player, offer.id)
			end
		end)
	end
end

-- Open / close -----------------------------------------------------------------

local function refreshCoins()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = if leaderstats then leaderstats:FindFirstChild("Coins") else nil
	coinsLabel.Text = if coins and coins:IsA("IntValue") then `{coins.Value} coins` else ""
end

local function setOpen(open: boolean)
	panel.Visible = open
	if open then
		refreshCoins()
		refreshAllTrails()
	end
end

openButton.Activated:Connect(function()
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	setOpen(not panel.Visible)
end)
closeButton.Activated:Connect(function()
	SoundPlayer.play(Config.SOUNDS.BUTTON)
	setOpen(false)
end)

-- Keep the coin display up to date while the shop is open.
task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats")
	local coins = leaderstats:WaitForChild("Coins") :: IntValue
	coins.Changed:Connect(refreshCoins)
	refreshCoins()
end)

gui.Parent = player:WaitForChild("PlayerGui")
