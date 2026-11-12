--!strict
-- Game settings shared by server and client.
-- Change numbers here instead of inside the game scripts.

local Config = {
	GAME_NAME = "Rising Lava Party",

	-- Rounds (seconds)
	MIN_PLAYERS = 1, -- players needed to start a round (1 = you can test alone)
	INTERMISSION_TIME = 15, -- wait in the lobby before a round
	ROUND_TIME = 90, -- maximum length of a round
	END_TIME = 5, -- show the result before going back to the lobby

	-- Lava
	LAVA_START_DELAY = 5, -- seconds after the round starts before the lava begins to rise
	LAVA_RISE_SPEED = 1.2, -- studs per second (after 85 s the lava is ~100 studs high)
	LAVA_MAX_HEIGHT = 140, -- the lava stops rising at this height above the arena floor
}

return table.freeze(Config)
