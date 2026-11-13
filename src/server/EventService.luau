--!strict
-- Picks a random event for every round (step 12) and applies the gravity
-- (event gravity × map gravity, e.g. the Moon map, step 24).
-- Lava speed and platform size are read from EventService.current() by LavaService and
-- PlatformService.
--
-- init() must run AFTER ThemeService.init() (the map is picked first, so we know its gravity)
-- and BEFORE PlatformService.init() (the platforms need to know the event):
-- RoundPreparing handlers run in the order they were connected.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local RoundEvents = require(ReplicatedStorage.Shared.RoundEvents)
local RoundState = require(ReplicatedStorage.Shared.RoundState)
local RoundManager = require(script.Parent.RoundManager)
local ThemeService = require(script.Parent.ThemeService)

type RoundEvent = RoundEvents.RoundEvent

local EventService = {}

local normalGravity = Workspace.Gravity
local current: RoundEvent = RoundEvents.byId[RoundEvents.NORMAL]
local rng = Random.new()

local function pickRandom(): RoundEvent
	if not Config.EVENTS_ENABLED then
		return RoundEvents.byId[RoundEvents.NORMAL]
	end
	-- On a low-gravity map (Moon), skip events that change gravity again.
	local lowGravityMap = ThemeService.current().gravity < 1
	local choices: { RoundEvent } = {}
	local total = 0
	for _, event in RoundEvents.list do
		if not (lowGravityMap and event.gravity ~= 1) then
			table.insert(choices, event)
			total += event.weight
		end
	end
	local roll = rng:NextNumber(0, total)
	for _, event in choices do
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

local function apply(event: RoundEvent, gravity: number)
	current = event
	Workspace.Gravity = gravity
	RoundManager.setStateAttribute(RoundState.ATTR_EVENT, event.id)
end

-- Call once from the server entry point, AFTER ThemeService.init() and BEFORE PlatformService.init().
function EventService.init()
	RoundManager.RoundPreparing:Connect(function()
		local event = pickRandom()
		apply(event, normalGravity * event.gravity * ThemeService.current().gravity)
	end)
	RoundManager.RoundEnded:Connect(function()
		-- Back in the lobby: normal gravity, whatever the map was.
		apply(RoundEvents.byId[RoundEvents.NORMAL], normalGravity)
	end)
end

return EventService
