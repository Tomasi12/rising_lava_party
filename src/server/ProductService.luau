--!strict
-- Developer products (step 17): Robux items that can be bought again and again.
--   REVIVE      → back into the current round once, on a platform high above the lava
--   COINS_500   → +500 coins
--   COINS_2000  → +2000 coins
-- Product IDs are in Config.PRODUCTS (0 = not created yet).
--
-- Roblox calls MarketplaceService.ProcessReceipt for every purchase (and again later if we
-- don't confirm it). Rules that make it safe:
-- - Only confirm (PurchaseGranted) after the item was given AND the player's data was saved.
-- - Remember each PurchaseId in the saved data, so a purchase is never given twice.
-- - If the player's data isn't loaded (or they left), answer NotProcessedYet: Roblox tries again later.
-- There must be only ONE ProcessReceipt in the whole game: this one.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)
local LavaService = require(script.Parent.LavaService)
local Net = require(script.Parent.Net)
local PlatformService = require(script.Parent.PlatformService)
local RoundManager = require(script.Parent.RoundManager)

local ProductService = {}

local function revive(player: Player)
	if not RoundManager.canRevive(player) then
		-- The round ended (or they were already revived) while buying: give coins instead.
		CoinService.add(player, Config.REVIVE_REFUND_COINS)
		Net.notify(player, `The round is over, you got {Config.REVIVE_REFUND_COINS} coins instead`, "coins")
		return
	end

	player:LoadCharacter() -- new character (spawns in the lobby, then we move it)
	local character = player.Character
	if not character then
		return
	end
	character:WaitForChild("HumanoidRootPart", 5)

	local lavaY = LavaService.surfaceY() or 0
	local spot = PlatformService.findSafeSpot(lavaY + Config.REVIVE_HEIGHT_ABOVE_LAVA)
	if spot then
		character:PivotTo(spot)
	end

	if RoundManager.readmit(player) then
		Net.notify(player, "Revived! Climb!", "success")
	else
		-- The round ended during the respawn.
		CoinService.add(player, Config.REVIVE_REFUND_COINS)
		Net.notify(player, `The round is over, you got {Config.REVIVE_REFUND_COINS} coins instead`, "coins")
	end
end

local function coinPack(amount: number): (Player) -> ()
	return function(player: Player)
		CoinService.add(player, amount)
		Net.notify(player, `+{amount} coins. Thank you!`, "coins")
	end
end

-- product id → function that gives the item
local handlers: { [number]: (Player) -> () } = {}

local function register(productId: number, handler: (Player) -> ())
	if productId ~= 0 then
		handlers[productId] = handler
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or not DataService.isLoaded(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receipt.PurchaseId)
	local session = DataService.get(player)
	if table.find(session.receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already given earlier
	end

	local handler = handlers[receipt.ProductId]
	if not handler then
		warn(`No handler for product {receipt.ProductId}; check Config.PRODUCTS`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err = pcall(handler, player)
	if not ok then
		warn(`Giving product {receipt.ProductId} to {player.Name} failed: {err}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	table.insert(session.receipts, purchaseId)
	if not DataService.saveNow(player) then
		-- Given in this session but not saved: Roblox will ask again; the receipt list
		-- (still in memory) prevents giving it twice in this session.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Call once from the server entry point.
function ProductService.init()
	register(Config.PRODUCTS.REVIVE, revive)
	register(Config.PRODUCTS.COINS_500, coinPack(500))
	register(Config.PRODUCTS.COINS_2000, coinPack(2000))
	MarketplaceService.ProcessReceipt = processReceipt
end

return ProductService
