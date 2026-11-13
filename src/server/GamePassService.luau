--!strict
-- Game passes (step 16): one-time Robux purchases, owned forever.
--   DOUBLE_COINS → 2x coins from rounds
--   VIP          → VIP Gold trail, a "VIP" tag above the head, 1.5x coins from rounds
-- Both together: 3x coins.
--
-- Pass IDs are in Config.GAME_PASSES (0 = not created yet → that pass is off).
-- Ownership is checked when the player joins and updated right after a purchase in the game.
-- Roblox remembers who owns a pass, so nothing needs to be saved in our DataStore.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local CoinService = require(script.Parent.CoinService)
local Net = require(script.Parent.Net)
local ShopService = require(script.Parent.ShopService)

local DOUBLE_COINS_MULTIPLIER = 2
local VIP_MULTIPLIER = 1.5
local TAG_NAME = "VipTag"

local GamePassService = {}

-- owned[player][key] = true, key from Config.GAME_PASSES
local owned: { [Player]: { [string]: boolean } } = {}

function GamePassService.has(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

local function keyForId(passId: number): string?
	for key, id in Config.GAME_PASSES do
		if id ~= 0 and id == passId then
			return key
		end
	end
	return nil
end

local function addVipTag(player: Player)
	local character = player.Character
	if not character or not GamePassService.has(player, "VIP") then
		return
	end
	local head = character:WaitForChild("Head", 5)
	if not head or not head:IsA("BasePart") or head:FindFirstChild(TAG_NAME) then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Name = TAG_NAME
	tag.Size = UDim2.new(0, 80, 0, 26)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.AlwaysOnTop = false
	tag.MaxDistance = 80
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "VIP"
	label.TextColor3 = Color3.fromRGB(255, 215, 60)
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = tag
	tag.Parent = head
end

local function setOwned(player: Player, key: string)
	local passes = owned[player]
	if not passes then
		passes = {}
		owned[player] = passes
	end
	passes[key] = true
	player:SetAttribute(PlayerAttributes.PASS_PREFIX .. key, true)
	if key == "VIP" then
		ShopService.refresh(player) -- unlocks the VIP Gold trail
		task.spawn(addVipTag, player)
	end
end

local function checkPasses(player: Player)
	owned[player] = owned[player] or {}
	for key, id in Config.GAME_PASSES do
		if id == 0 then
			continue
		end
		local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
		if ok and result == true and player.Parent then
			setOwned(player, key)
		elseif not ok then
			warn(`Could not check game pass {key} for {player.Name}: {result}`)
		end
	end
end

local function coinMultiplier(player: Player): number
	local multiplier = 1
	if GamePassService.has(player, "DOUBLE_COINS") then
		multiplier *= DOUBLE_COINS_MULTIPLIER
	end
	if GamePassService.has(player, "VIP") then
		multiplier *= VIP_MULTIPLIER
	end
	return multiplier
end

-- Call once from the server entry point (after ShopService.init()).
function GamePassService.init()
	CoinService.setRewardMultiplier(coinMultiplier)
	ShopService.setVipCheck(function(player: Player)
		return GamePassService.has(player, "VIP")
	end)

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function()
			addVipTag(player)
		end)
		checkPasses(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)

	-- A pass bought inside the game works right away (no rejoin needed).
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		if not purchased then
			return
		end
		local key = keyForId(passId)
		if key then
			setOwned(player, key)
			Net.notify(player, "Thank you! Your pass is active.", "success")
		end
	end)
end

return GamePassService
