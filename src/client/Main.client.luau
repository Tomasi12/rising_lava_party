--!strict
-- Client entry point. Runs on each player's device when they join.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

print(`{Config.GAME_NAME} client started for {Players.LocalPlayer.Name}`)
