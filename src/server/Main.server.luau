--!strict
-- Server entry point. Runs once when the server starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)
local LavaService = require(script.Parent.LavaService)
local PlatformService = require(script.Parent.PlatformService)
local RoundManager = require(script.Parent.RoundManager)

print(`{Config.GAME_NAME} server started`)

-- Modules that react to round events connect first, then the round loop starts.
CoinService.init()
DataService.init() -- after CoinService: loads saved coins into leaderstats
PlatformService.init()
LavaService.init()
RoundManager.start()
