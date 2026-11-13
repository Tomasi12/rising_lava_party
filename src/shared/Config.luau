--!strict
-- Game settings shared by server and client.
-- Change numbers here instead of inside the game scripts.

local Config = {
	GAME_NAME = "Rising Lava Party",

	-- Rounds (seconds)
	MIN_PLAYERS = 1, -- players needed to start a round (1 = you can test alone)
	INTERMISSION_TIME = 15, -- wait in the lobby before a round
	ROUND_TIME = 240, -- maximum length of a round (the climb to the summit takes ~2-3 minutes)
	END_TIME = 5, -- show the result before going back to the lobby

	-- Lava
	LAVA_START_DELAY = 8, -- seconds after the round starts before the lava begins to rise
	LAVA_RISE_SPEED = 2.3, -- studs per second. A good climber goes ~3 studs/s, so the lava catches slow or stuck players
	LAVA_MAX_HEIGHT = 510, -- the lava stops here; must stay BELOW the summit (PLATFORM_TOP_HEIGHT + 4)

	-- Round events (step 12): Fast Lava, Low Gravity, Tiny Platforms. See shared/RoundEvents.luau.
	EVENTS_ENABLED = true,

	-- Random platforms (built new for every round). Heights and distances in studs.
	PLATFORM_PATHS = 8, -- number of climbing routes from the floor to the summit
	PLATFORM_EXTRAS = 150, -- extra platforms placed anywhere, for variety and shortcuts
	PLATFORM_TOP_HEIGHT = 520, -- routes climb up to this height above the arena floor (step 22: 4x higher)
	SUMMIT_SIZE = 24, -- the golden finish platform at the top is SUMMIT_SIZE x SUMMIT_SIZE studs
	PLATFORM_MIN_SIZE = 6, -- platforms are squares between MIN and MAX size
	PLATFORM_MAX_SIZE = 12,
	PLATFORM_STEP_UP_MIN = 3.5, -- each next platform on a route is this much higher...
	PLATFORM_STEP_UP_MAX = 5.5,
	PLATFORM_GAP_MIN = 1, -- ...with an edge-to-edge horizontal gap in this range
	PLATFORM_GAP_MAX = 5,

	-- Crumbling platforms (step 21): a platform shakes, turns red and falls away after a player lands on it.
	CRUMBLE_ENABLED = true,
	CRUMBLE_DELAY = 2, -- seconds from landing until it falls
	CRUMBLE_FALL_TIME = 0.6, -- seconds the falling animation takes
	CRUMBLE_RESPAWN_TIME = 4, -- seconds until a fallen platform comes back

	-- Coins
	COINS_SURVIVE = 10, -- every player who reaches the summit
	COINS_WIN_BONUS = 15, -- extra for the first one at the summit (only when 2+ players took part)

	-- Daily reward (step 14): DAILY_REWARD_BASE × day of the streak, up to MAX_STREAK days.
	-- Day 1: 10, day 2: 20, ... day 7 and later: 70. Missing a day starts again at day 1.
	DAILY_REWARD_BASE = 10,
	DAILY_REWARD_MAX_STREAK = 7,

	-- Robux items. Create them on create.roblox.com (see docs/16 and docs/17) and paste the IDs here.
	-- 0 = not created yet: the item is hidden in the shop and the feature is off.
	GAME_PASSES = table.freeze({
		DOUBLE_COINS = 0, -- step 16: 2x coins from rounds
		VIP = 0, -- step 16: gold trail, VIP tag, 1.5x coins
	}),
	PRODUCTS = table.freeze({
		REVIVE = 0, -- step 17: back into the round once (suggested 25 Robux)
		COINS_500 = 0, -- step 17
		COINS_2000 = 0, -- step 17
	}),

	-- Revive (step 17): put the revived player at least this many studs above the lava.
	REVIVE_HEIGHT_ABOVE_LAVA = 15,
	-- If a Revive is bought but the round already ended, the player gets these coins instead.
	REVIVE_REFUND_COINS = 100,

	-- Badges (step 14). Create them on create.roblox.com and paste the badge IDs here.
	-- 0 = badge not created yet (it is simply not awarded).
	BADGES = table.freeze({
		WELCOME = 0, -- joined the game for the first time
		FIRST_WIN = 0, -- 1 win
		WINS_10 = 0, -- 10 wins
		WINS_100 = 0, -- 100 wins
	}),

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
