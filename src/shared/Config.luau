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

	-- Random platforms (built new for every round). Heights and distances in studs.
	PLATFORM_PATHS = 3, -- number of climbing routes from the floor to the top
	PLATFORM_EXTRAS = 20, -- extra platforms placed anywhere, for variety and shortcuts
	PLATFORM_TOP_HEIGHT = 130, -- routes climb up to this height above the arena floor
	PLATFORM_MIN_SIZE = 6, -- platforms are squares between MIN and MAX size
	PLATFORM_MAX_SIZE = 12,
	PLATFORM_STEP_UP_MIN = 3.5, -- each next platform on a route is this much higher...
	PLATFORM_STEP_UP_MAX = 5.5,
	PLATFORM_GAP_MIN = 1, -- ...with an edge-to-edge horizontal gap in this range
	PLATFORM_GAP_MAX = 5,

	-- Coins
	COINS_SURVIVE = 10, -- every player alive at the end of a round
	COINS_WIN_BONUS = 15, -- extra for the last player standing (only when 2+ players took part)

	-- Sounds (step 11). "rbxasset://sounds/..." are sounds built into Roblox.
	-- To use a sound from the Creator Store, paste its id like "rbxassetid://1234567890".
	-- An empty string "" means no sound.
	SOUNDS = table.freeze({
		COUNTDOWN_TICK = "rbxasset://sounds/clickfast.wav", -- last 5 seconds before a round
		ROUND_START = "rbxasset://sounds/electronicpingshort.wav",
		VICTORY = "rbxasset://sounds/victory.wav", -- you survived the round
		COINS = "rbxasset://sounds/electronicpingshort.wav", -- coins received
		BUTTON = "rbxasset://sounds/button.wav", -- UI clicks
		ERROR = "rbxasset://sounds/uuhhh.mp3", -- e.g. not enough coins
		LAVA_LOOP = "", -- looping lava sound while it rises (find one in the Creator Store)
	}),
}

return table.freeze(Config)
