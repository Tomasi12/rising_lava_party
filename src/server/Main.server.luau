--!strict
-- Server entry point. Runs once when the server starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BadgeService = require(script.Parent.BadgeService)
local CoinService = require(script.Parent.CoinService)
local DailyRewardService = require(script.Parent.DailyRewardService)
local DataService = require(script.Parent.DataService)
local EventService = require(script.Parent.EventService)
local GamePassService = require(script.Parent.GamePassService)
local LavaService = require(script.Parent.LavaService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local PlatformService = require(script.Parent.PlatformService)
local ProductService = require(script.Parent.ProductService)
local RoundManager = require(script.Parent.RoundManager)
local ShopService = require(script.Parent.ShopService)
local SummitService = require(script.Parent.SummitService)

print(`{Config.GAME_NAME} server started`)

-- Modules that react to events connect first, then data loading and the round loop start.
CoinService.init()
BadgeService.init()
DailyRewardService.init() -- before DataService: listens to DataService.Loaded
ShopService.init() -- before DataService: listens to DataService.Loaded
GamePassService.init() -- after ShopService: unlocks the VIP trail
ProductService.init() -- Robux developer products (the only ProcessReceipt in the game)
LeaderboardService.init() -- before DataService: listens to DataService.Loaded
DataService.init() -- after CoinService and every DataService.Loaded listener
EventService.init() -- before PlatformService: the platforms read the round event
PlatformService.init()
LavaService.init()
SummitService.init()
RoundManager.start()
