--!strict
-- Round sounds: a tick in the last 5 seconds of the countdown, a sound when the round starts,
-- and a victory sound if you survived. (Step 11.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerAttributes = require(ReplicatedStorage.Shared.PlayerAttributes)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local SoundPlayer = require(script.Parent.SoundPlayer)

local player = Players.LocalPlayer
local stateFolder = ReplicatedStorage:WaitForChild(RoundState.FOLDER_NAME)

local lastPhase = stateFolder:GetAttribute(RoundState.ATTR_PHASE)

stateFolder:GetAttributeChangedSignal(RoundState.ATTR_TIME_LEFT):Connect(function()
	local phase = stateFolder:GetAttribute(RoundState.ATTR_PHASE)
	local timeLeft = stateFolder:GetAttribute(RoundState.ATTR_TIME_LEFT)
	if phase == RoundState.Phase.Intermission and typeof(timeLeft) == "number" and timeLeft <= 5 then
		SoundPlayer.play(Config.SOUNDS.COUNTDOWN_TICK)
	end
end)

stateFolder:GetAttributeChangedSignal(RoundState.ATTR_PHASE):Connect(function()
	local phase = stateFolder:GetAttribute(RoundState.ATTR_PHASE)
	if phase == lastPhase then
		return
	end
	lastPhase = phase
	if phase == RoundState.Phase.Round then
		SoundPlayer.play(Config.SOUNDS.ROUND_START)
	elseif phase == RoundState.Phase.Ended and player:GetAttribute(PlayerAttributes.IN_ROUND) == true then
		SoundPlayer.play(Config.SOUNDS.VICTORY)
	end
end)
