--!strict
-- Coins: the game's currency.
-- - Every player gets a `leaderstats` folder with a `Coins` value, so Roblox shows it
--   on the player list (top right).
-- - Survivors of a round get coins; the last player standing gets a bonus.
-- - Other modules use CoinService.get / CoinService.add / CoinService.set
--   (DataService in step 9 loads and saves the value; a shop will spend it later).
--
-- Only the server changes coins. The client just sees the leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(script.Parent.Net)
local RoundManager = require(script.Parent.RoundManager)

local CoinService = {}

-- Creates leaderstats/Coins for the player if it doesn't exist yet, and returns the value.
-- Safe to call many times (CoinService and DataService both call it).
function CoinService.ensureLeaderstats(player: Player): IntValue
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats" -- this exact name makes Roblox show it on the player list
		leaderstats.Parent = player
	end
	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		local value = Instance.new("IntValue")
		value.Name = "Coins"
		value.Value = 0
		value.Parent = leaderstats
		coins = value
	end
	return coins :: IntValue
end

function CoinService.get(player: Player): number
	return CoinService.ensureLeaderstats(player).Value
end

function CoinService.set(player: Player, amount: number)
	CoinService.ensureLeaderstats(player).Value = math.max(0, math.floor(amount))
end

function CoinService.add(player: Player, amount: number)
	local coins = CoinService.ensureLeaderstats(player)
	coins.Value = math.max(0, coins.Value + math.floor(amount))
end

local function rewardSurvivors(survivors: { Player }, participants: { Player })
	local lastStanding = #survivors == 1 and #participants > 1
	for _, player in survivors do
		if player.Parent then -- still in the game
			local reward = Config.COINS_SURVIVE
			if lastStanding then
				reward += Config.COINS_WIN_BONUS
			end
			CoinService.add(player, reward)
			Net.notify(player, `+{reward} coins`, "coins")
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
