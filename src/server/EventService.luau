--!strict
-- Picks a random event for every round (step 12) and applies its gravity.
-- Lava speed and platform size are read from EventService.current() by LavaService and
-- PlatformService.
--
-- init() must run BEFORE PlatformService.init(): RoundPreparing handlers run in the order
-- they were connected, and the platforms need to know the event.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local RoundEvents = require(ReplicatedStorage.Shared.RoundEvents)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local RoundManager = require(script.Parent.RoundManager)

type RoundEvent = RoundEvents.RoundEvent

local EventService = {}

local normalGravity = Workspace.Gravity
local current: RoundEvent = RoundEvents.byId[RoundEvents.NORMAL]
local rng = Random.new()

local function pickRandom(): RoundEvent
	if not Config.EVENTS_ENABLED then
		return RoundEvents.byId[RoundEvents.NORMAL]
	end
	local total = 0
	for _, event in RoundEvents.list do
		total += event.weight
	end
	local roll = rng:NextNumber(0, total)
	for _, event in RoundEvents.list do
		roll -= event.weight
		if roll <= 0 then
			return event
		end
	end
	return RoundEvents.list[1]
end

-- The event of the current (or next) round.
function EventService.current(): RoundEvent
	return current
end

local function apply(event: RoundEvent)
	current = event
	Workspace.Gravity = normalGravity * event.gravity
	RoundManager.setStateAttribute(RoundState.ATTR_EVENT, event.id)
end

-- Call once from the server entry point, BEFORE PlatformService.init().
function EventService.init()
	RoundManager.RoundPreparing:Connect(function()
		apply(pickRandom())
	end)
	RoundManager.RoundEnded:Connect(function()
		apply(RoundEvents.byId[RoundEvents.NORMAL])
	end)
end

return EventService
