--!strict
-- The special events a round can have (step 12). One is picked at random before each round.
-- `weight` = how often it is picked compared to the others (Normal 4 vs FastLava 2 → Normal twice as often).
-- The effects are applied on the server (server/EventService, LavaService, PlatformService);
-- `title` and `description` are shown to the players.

export type RoundEvent = {
	id: string,
	title: string,
	description: string,
	weight: number,
	lavaSpeed: number, -- multiplier for Config.LAVA_RISE_SPEED
	gravity: number, -- multiplier for the normal gravity
	platformSize: number, -- multiplier for the platform sizes
}

local list: { RoundEvent } = {
	{ id = "Normal", title = "", description = "", weight = 4, lavaSpeed = 1, gravity = 1, platformSize = 1 },
	{
		id = "FastLava",
		title = "FAST LAVA!",
		description = "The lava rises faster",
		weight = 2,
		lavaSpeed = 1.25,
		gravity = 1,
		platformSize = 1,
	},
	{
		id = "LowGravity",
		title = "LOW GRAVITY!",
		description = "Jump higher and float",
		weight = 2,
		lavaSpeed = 1.15,
		gravity = 0.55,
		platformSize = 1,
	},
	{
		id = "TinyPlatforms",
		title = "TINY PLATFORMS!",
		description = "Watch your step",
		weight = 2,
		lavaSpeed = 0.9,
		gravity = 1,
		platformSize = 0.65,
	},
}

local byId: { [string]: RoundEvent } = {}
for _, event in list do
	table.freeze(event)
	byId[event.id] = event
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	NORMAL = "Normal",
})
