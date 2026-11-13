--!strict
-- Badges (step 14): Welcome, First win, 10 wins, 100 wins.
-- Badge IDs are in Config.BADGES; a badge with id 0 is skipped (not created yet).

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CoinService = require(script.Parent.CoinService)

local Badges = {}

-- Wins needed → badge id
local WIN_BADGES: { { wins: number, id: number } } = {
	{ wins = 1, id = Config.BADGES.FIRST_WIN },
	{ wins = 10, id = Config.BADGES.WINS_10 },
	{ wins = 100, id = Config.BADGES.WINS_100 },
}

-- Badges already checked this session, so we don't ask Roblox again every round.
local checked: { [Player]: { [number]: boolean } } = {}

local function award(player: Player, badgeId: number)
	if badgeId == 0 then
		return
	end
	local done = checked[player]
	if not done then
		done = {}
		checked[player] = done
	end
	if done[badgeId] then
		return
	end
	done[badgeId] = true
	task.spawn(function()
		local ok, hasBadge = pcall(BadgeService.UserHasBadgeAsync, BadgeService, player.UserId, badgeId)
		if ok and hasBadge then
			return
		end
		local awarded, err = pcall(BadgeService.AwardBadge, BadgeService, player.UserId, badgeId)
		if not awarded then
			warn(`Could not award badge {badgeId} to {player.Name}: {err}`)
			done[badgeId] = nil -- try again next time
		end
	end)
end

local function checkWins(player: Player, wins: number)
	for _, badge in WIN_BADGES do
		if wins >= badge.wins then
			award(player, badge.id)
		end
	end
end

-- Call once from the server entry point.
function Badges.init()
	local function onPlayerAdded(player: Player)
		award(player, Config.BADGES.WELCOME)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		checked[player] = nil
	end)
	CoinService.WinAdded:Connect(checkWins)
	-- Players who already had wins before badges existed get them when they win next time.
end

return Badges
