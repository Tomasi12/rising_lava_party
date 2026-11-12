--!strict
-- Server entry point. Runs once when the server starts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local LavaService = require(script.Parent.LavaService)
local RoundManager = require(script.Parent.RoundManager)

print(`{Config.GAME_NAME} server started`)

-- Modules that react to round events connect first, then the round loop starts.
LavaService.init()
RoundManager.start()
