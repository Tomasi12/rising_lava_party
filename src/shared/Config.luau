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
}

return table.freeze(Config)
