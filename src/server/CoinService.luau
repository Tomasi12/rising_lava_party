--!strict
-- Coins and Wins, shown on the player list (leaderstats).
-- - Coins: the game's currency. Survivors of a round get coins; the last player standing a bonus.
-- - Wins: +1 every time you are still alive at the end of a round (step 14).
-- - Other modules use CoinService.get / add / set / spend and getWins / setWins
--   (DataService loads and saves them, the shop spends coins).
--
-- Only the server changes these values. The client just sees the leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local RoundManager = require(script.Parent.RoundManager)
local Signal = require(script.Parent.Signal)

local CoinService = {}

-- Fires (player, wins) when a player's wins go up by winning a round (used by badges).
CoinService.WinAdded = Signal.new()

-- Returns the multiplier for round coins (2 with the 2x Coins pass). Set by GamePassService (step 16).
local rewardMultiplier: (Player) -> number = function()
	return 1
end

function CoinService.setRewardMultiplier(fn: (Player) -> number)
	rewardMultiplier = fn
end

local function ensureValue(leaderstats: Instance, name: string): IntValue
	local value = leaderstats:FindFirstChild(name)
	if not value then
		local newValue = Instance.new("IntValue")
		newValue.Name = name
		newValue.Value = 0
		newValue.Parent = leaderstats
		return newValue
	end
	return value :: IntValue
end

-- Creates leaderstats with Coins and Wins (in that order on the player list) if they don't exist yet.
-- Safe to call many times.
function CoinService.ensureLeaderstats(player: Player): Instance
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		local folder = Instance.new("Folder")
		folder.Name = "leaderstats" -- this exact name makes Roblox show it on the player list
		folder.Parent = player
		leaderstats = folder
	end
	local stats = leaderstats :: Instance
	ensureValue(stats, "Coins")
	ensureValue(stats, "Wins")
	return stats
end

local function coinsValue(player: Player): IntValue
	return ensureValue(CoinService.ensureLeaderstats(player), "Coins")
end

local function winsValue(player: Player): IntValue
	return ensureValue(CoinService.ensureLeaderstats(player), "Wins")
end

function CoinService.get(player: Player): number
	return coinsValue(player).Value
end

function CoinService.set(player: Player, amount: number)
	coinsValue(player).Value = math.max(0, math.floor(amount))
end

function CoinService.add(player: Player, amount: number)
	local coins = coinsValue(player)
	coins.Value = math.max(0, coins.Value + math.floor(amount))
end

-- Removes `amount` coins if the player has enough. Returns true if they were spent.
function CoinService.spend(player: Player, amount: number): boolean
	local coins = coinsValue(player)
	if coins.Value < amount then
		return false
	end
	coins.Value -= amount
	return true
end

function CoinService.getWins(player: Player): number
	return winsValue(player).Value
end

function CoinService.setWins(player: Player, wins: number)
	winsValue(player).Value = math.max(0, math.floor(wins))
end

local function rewardSurvivors(survivors: { Player }, participants: { Player })
	local lastStanding = #survivors == 1 and #participants > 1
	for _, player in survivors do
		if player.Parent then -- still in the game
			local reward = Config.COINS_SURVIVE
			if lastStanding then
				reward += Config.COINS_WIN_BONUS
			end
			local multiplier = rewardMultiplier(player)
			reward = math.floor(reward * multiplier)
			CoinService.add(player, reward)
			Net.notify(player, if multiplier > 1 then `+{reward} coins (x{multiplier})` else `+{reward} coins`, "coins")

			local wins = winsValue(player)
			wins.Value += 1
			CoinService.WinAdded:Fire(player, wins.Value)
		end
	end
end

-- Call once from the server entry point, before RoundManager.start().
function CoinService.init()
	Players.PlayerAdded:Connect(CoinService.ensureLeaderstats)
	for _, player in Players:GetPlayers() do -- players who joined before this ran (Studio)
		CoinService.ensureLeaderstats(player)
	end
	RoundManager.RoundEnded:Connect(rewardSurvivors)
end

return CoinService
