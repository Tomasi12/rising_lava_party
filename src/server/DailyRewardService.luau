--!strict
-- Daily reward (step 14): the first time a player joins on a new day (UTC), they get coins.
-- Coming back every day builds a streak: day 1 = 10 coins, day 2 = 20, ... up to day 7 = 70.
-- Missing a day starts the streak again at day 1.
--
-- Runs only after the player's data was loaded (DataService.Loaded), so it can't be given twice
-- and isn't given when saving doesn't work.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Net)

local SECONDS_PER_DAY = 86400
local NOTIFY_DELAY = 3 -- seconds, so the player's screen is ready

local DailyRewardService = {}

local function today(): number
	return math.floor(os.time() / SECONDS_PER_DAY)
end

local function onLoaded(player: Player, session: DataService.Session)
	local day = today()
	if session.dailyDay == day then
		return -- already got today's reward
	end
	if session.dailyDay == day - 1 then
		session.dailyStreak += 1
	else
		session.dailyStreak = 1
	end
	session.dailyDay = day

	local streakDay = math.min(session.dailyStreak, Config.DAILY_REWARD_MAX_STREAK)
	local reward = Config.DAILY_REWARD_BASE * streakDay
	CoinService.add(player, reward)
	task.delay(NOTIFY_DELAY, function()
		if player.Parent then
			Net.notify(player, `Daily reward, day {session.dailyStreak}: +{reward} coins`, "coins")
		end
	end)
end

-- Call once from the server entry point, BEFORE DataService.init().
function DailyRewardService.init()
	DataService.Loaded:Connect(onLoaded)
end

return DailyRewardService
