--!strict
-- Shop (step 15): buy trails with coins, equip / unequip them.
--
-- The client asks through the ShopRequest RemoteFunction:
--   ShopRequest:InvokeServer("buy", itemId)    → (ok: boolean, message: string)
--   ShopRequest:InvokeServer("equip", itemId)
--   ShopRequest:InvokeServer("unequip", "")
-- The server checks everything (price, ownership); the client only shows buttons.
-- Owned items and the equipped trail are mirrored as Player attributes for the shop UI.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local ShopItems = require(ReplicatedStorage.Shared.ShopItems)
local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Net)

type ShopItem = ShopItems.ShopItem

local TRAIL_NAME = "ShopTrail"

local ShopService = {}

-- Returns true if the player may use VIP-only items. Set by GamePassService (step 16).
local hasVip: (Player) -> boolean = function()
	return false
end

function ShopService.setVipCheck(fn: (Player) -> boolean)
	hasVip = fn
end

local function canUse(player: Player, item: ShopItem): boolean
	if item.vipOnly then
		return hasVip(player)
	end
	return DataService.get(player).owned[item.id] == true
end

-- Copies owned items and the equipped trail into attributes the client can read.
local function syncAttributes(player: Player)
	local session = DataService.get(player)
	for _, item in ShopItems.list do
		player:SetAttribute(PlayerAttributes.OWNED_PREFIX .. item.id, canUse(player, item))
	end
	player:SetAttribute(PlayerAttributes.EQUIPPED_TRAIL, session.equippedTrail)
end

local function removeTrail(root: Instance)
	for _, name in { TRAIL_NAME, "TrailTop", "TrailBottom" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
end

-- Puts the equipped trail on the player's current character (or removes it).
function ShopService.applyTrail(player: Player)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not root then
		return
	end
	removeTrail(root)
	local item = ShopItems.byId[DataService.get(player).equippedTrail]
	if not item or not canUse(player, item) then
		return
	end

	local top = Instance.new("Attachment")
	top.Name = "TrailTop"
	top.Position = Vector3.new(0, 0.9, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "TrailBottom"
	bottom.Position = Vector3.new(0, -0.9, 0)
	bottom.Parent = root

	local trail = Instance.new("Trail")
	trail.Name = TRAIL_NAME
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Color = ShopItems.colorSequence(item)
	trail.Lifetime = 0.6
	trail.LightEmission = 0.5
	trail.FaceCamera = true
	trail.Transparency = NumberSequence.new(0.1, 1)
	trail.Parent = root
end

local function buy(player: Player, item: ShopItem): (boolean, string)
	if item.vipOnly then
		return false, "This trail comes with the VIP pass"
	end
	local session = DataService.get(player)
	if session.owned[item.id] then
		return false, "You already own this"
	end
	if not DataService.isLoaded(player) then
		-- Without loaded data the purchase could not be saved.
		return false, "Your data is not loaded yet, try again in a moment"
	end
	if not CoinService.spend(player, item.price) then
		return false, `Not enough coins (need {item.price})`
	end
	session.owned[item.id] = true
	session.equippedTrail = item.id -- wear it right away
	syncAttributes(player)
	ShopService.applyTrail(player)
	return true, `Bought {item.name}!`
end

local function equip(player: Player, item: ShopItem): (boolean, string)
	if not canUse(player, item) then
		return false, "You do not own this"
	end
	DataService.get(player).equippedTrail = item.id
	syncAttributes(player)
	ShopService.applyTrail(player)
	return true, `Equipped {item.name}`
end

local function unequip(player: Player): (boolean, string)
	DataService.get(player).equippedTrail = ""
	syncAttributes(player)
	ShopService.applyTrail(player)
	return true, "Trail removed"
end

local function onRequest(player: Player, action: unknown, itemId: unknown): (boolean, string)
	if action == "unequip" then
		return unequip(player)
	end
	local item = if typeof(itemId) == "string" then ShopItems.byId[itemId] else nil
	if not item then
		return false, "Unknown item"
	end
	if action == "buy" then
		return buy(player, item)
	elseif action == "equip" then
		return equip(player, item)
	end
	return false, "Unknown action"
end

-- Re-reads ownership (e.g. after the VIP pass was bought) and updates attributes and trail.
function ShopService.refresh(player: Player)
	syncAttributes(player)
	ShopService.applyTrail(player)
end

-- Call once from the server entry point, BEFORE DataService.init().
function ShopService.init()
	Net.ShopRequest.OnServerInvoke = function(player: Player, action: unknown, itemId: unknown)
		local ok, message = onRequest(player, action, itemId)
		Net.notify(player, message, if ok then "success" else "error")
		return ok, message
	end

	local function onPlayerAdded(player: Player)
		syncAttributes(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 5) -- the parts may arrive a moment later
			ShopService.applyTrail(player)
		end)
		if player.Character then
			ShopService.applyTrail(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	DataService.Loaded:Connect(function(player: Player)
		ShopService.refresh(player)
	end)
end

return ShopService
