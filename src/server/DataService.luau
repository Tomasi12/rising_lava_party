--!strict
-- Saves and loads each player's data with Roblox DataStores.
--
-- What is saved (PlayerData):
--   coins, wins               → live in leaderstats while playing (CoinService)
--   owned, equippedTrail      → shop (step 15)
--   dailyDay, dailyStreak     → daily reward (step 14)
--   receipts                  → Robux purchases already handled (step 17)
-- Everything except coins/wins lives in a "session" table per player: DataService.get(player).
--
-- - Load when a player joins (with retries). DataService.Loaded fires when it worked.
-- - Save when they leave, every AUTOSAVE_INTERVAL seconds, and when the server shuts down.
-- - If loading fails, that player's data is NOT saved this session, so a temporary
--   Roblox outage can never overwrite real saved data with empty data.
--
-- Requirements (see docs/09-save-coins.md):
-- - The place must be published to Roblox.
-- - In Studio: Experience Settings → Security → "Enable Studio Access to API Services" = on.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CoinService = require(script.Parent.CoinService)
local Signal = require(script.Parent.Signal)

local STORE_NAME = "PlayerData_v1" -- change the version to start everyone from zero
local AUTOSAVE_INTERVAL = 60 -- seconds
local MAX_ATTEMPTS = 3
local RETRY_DELAY = 2 -- seconds, doubled after each failed attempt
local MAX_RECEIPTS = 50 -- remember this many handled purchase ids

-- What is stored per player. Add new fields here and in `defaultSession` / `sanitize`.
type PlayerData = {
	coins: number,
	wins: number,
	owned: { string },
	equippedTrail: string,
	dailyDay: number,
	dailyStreak: number,
	receipts: { string },
}

-- The part of the data other modules read and change while the player is in the game.
export type Session = {
	owned: { [string]: boolean },
	equippedTrail: string,
	dailyDay: number,
	dailyStreak: number,
	receipts: { string },
}

local function defaultSession(): Session
	return { owned = {}, equippedTrail = "", dailyDay = 0, dailyStreak = 0, receipts = {} }
end

local DataService = {}

-- Fires (player, session) after the player's saved data was loaded successfully.
DataService.Loaded = Signal.new()

local store: DataStore? = nil
local sessions: { [Player]: Session } = {}
-- Players whose data loaded successfully. Only these are saved.
local loaded: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return `player_{player.UserId}`
end

-- Calls `fn` up to MAX_ATTEMPTS times until it doesn't error. Returns ok, result.
local function withRetries<T>(description: string, fn: () -> T): (boolean, T?)
	local delay = RETRY_DELAY
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(`{description} failed (attempt {attempt}/{MAX_ATTEMPTS}): {result}`)
		if attempt < MAX_ATTEMPTS then
			task.wait(delay)
			delay *= 2
		end
	end
	return false, nil
end

local function nonNegativeInteger(value: unknown): number
	if typeof(value) == "number" and value >= 0 and value == value then -- value == value: not NaN
		return math.floor(value)
	end
	return 0
end

local function stringList(value: unknown): { string }
	local result: { string } = {}
	if typeof(value) == "table" then
		for _, item in value :: { any } do
			if typeof(item) == "string" then
				table.insert(result, item)
			end
		end
	end
	return result
end

-- Turns whatever is in the DataStore into valid PlayerData (missing or wrong fields get defaults).
local function sanitize(raw: unknown): PlayerData
	local source: { [string]: any } = if typeof(raw) == "table" then raw :: any else {}
	return {
		coins = nonNegativeInteger(source.coins),
		wins = nonNegativeInteger(source.wins),
		owned = stringList(source.owned),
		equippedTrail = if typeof(source.equippedTrail) == "string" then source.equippedTrail else "",
		dailyDay = nonNegativeInteger(source.dailyDay),
		dailyStreak = nonNegativeInteger(source.dailyStreak),
		receipts = stringList(source.receipts),
	}
end

-- The player's session data (created with defaults if needed). Never nil while the player is in the game.
function DataService.get(player: Player): Session
	local session = sessions[player]
	if not session then
		local newSession = defaultSession()
		sessions[player] = newSession
		return newSession
	end
	return session
end

function DataService.isLoaded(player: Player): boolean
	return loaded[player] == true
end

local function load(player: Player)
	local dataStore = store
	if not dataStore then
		return
	end
	local ok, raw = withRetries(`Loading data for {player.Name}`, function()
		return dataStore:GetAsync(keyFor(player))
	end)
	if not player.Parent then
		return -- left while loading
	end
	if not ok then
		warn(`Could not load data for {player.Name}; their progress will not be saved this session.`)
		return
	end
	local data = sanitize(raw)

	-- Merge with anything earned while loading (e.g. a round ended during the request).
	CoinService.set(player, data.coins + CoinService.get(player))
	CoinService.setWins(player, data.wins + CoinService.getWins(player))
	local session = DataService.get(player)
	for _, itemId in data.owned do
		session.owned[itemId] = true
	end
	if session.equippedTrail == "" then
		session.equippedTrail = data.equippedTrail
	end
	session.dailyDay = data.dailyDay
	session.dailyStreak = data.dailyStreak
	session.receipts = data.receipts

	loaded[player] = true
	DataService.Loaded:Fire(player, session)
end

local function snapshot(player: Player): PlayerData
	local session = DataService.get(player)
	local owned: { string } = {}
	for itemId in session.owned do
		table.insert(owned, itemId)
	end
	local receipts = session.receipts
	while #receipts > MAX_RECEIPTS do
		table.remove(receipts, 1)
	end
	return {
		coins = CoinService.get(player),
		wins = CoinService.getWins(player),
		owned = owned,
		equippedTrail = session.equippedTrail,
		dailyDay = session.dailyDay,
		dailyStreak = session.dailyStreak,
		receipts = table.clone(receipts),
	}
end

-- Writes the player's current data. Returns true if it was saved.
-- Callers make sure the data was loaded first.
local function save(player: Player): boolean
	local dataStore = store
	if not dataStore then
		return false
	end
	local data = snapshot(player)
	local ok = withRetries(`Saving data for {player.Name}`, function()
		-- UpdateAsync instead of SetAsync: the recommended way to write, safer with several servers.
		dataStore:UpdateAsync(keyFor(player), function()
			return data
		end)
		return true
	end)
	return ok
end

-- Saves right now (used after Robux purchases). Returns false if the data isn't loaded or saving failed.
function DataService.saveNow(player: Player): boolean
	if not loaded[player] then
		return false
	end
	return save(player)
end

-- Final save for a player. Clears `loaded` first, so a second call
-- (PlayerRemoving and BindToClose both happen on shutdown) does nothing.
local function onPlayerRemoving(player: Player)
	if loaded[player] then
		loaded[player] = nil
		save(player)
	end
	sessions[player] = nil
end

-- Call once from the server entry point, after CoinService.init() and after every module
-- that connects to DataService.Loaded (so nobody misses the first load).
function DataService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		-- Typical in Studio when the place isn't published or API access is off.
		warn(`DataStores are not available, progress will not be saved: {result}`)
	end

	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Autosave, in case the server crashes.
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in loaded do
				task.spawn(save, player)
			end
		end
	end)

	-- Server shutting down (or Studio test stopped): save everyone before it closes.
	-- Roblox waits up to 30 s for this function. A player saved here and again in
	-- PlayerRemoving is only written once (see onPlayerRemoving).
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			pending += 1
			task.spawn(function()
				onPlayerRemoving(player)
				pending -= 1
			end)
		end
		while pending > 0 do
			task.wait(0.5)
		end
	end)
end

return DataService
