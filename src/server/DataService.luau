--!strict
-- Saves and loads each player's data (for now: coins) with Roblox DataStores.
--
-- - Load when a player joins (with retries).
-- - Save when they leave, every AUTOSAVE_INTERVAL seconds, and when the server shuts down.
-- - If loading fails, that player's data is NOT saved this session, so a temporary
--   Roblox outage can never overwrite real saved coins with 0.
--
-- Requirements (see docs/09-save-coins.md):
-- - The place must be published to Roblox.
-- - In Studio: Game Settings → Security → "Enable Studio Access to API Services" = on.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local CoinService = require(script.Parent.CoinService)

local STORE_NAME = "PlayerData_v1" -- change the version to start everyone from zero
local AUTOSAVE_INTERVAL = 60 -- seconds
local MAX_ATTEMPTS = 3
local RETRY_DELAY = 2 -- seconds, doubled after each failed attempt

-- What is stored per player. Add new fields here with a default in `defaultData`.
type PlayerData = {
	coins: number,
}

local function defaultData(): PlayerData
	return { coins = 0 }
end

local DataService = {}

local store: DataStore? = nil
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

-- Turns whatever is in the DataStore into valid PlayerData (missing or wrong fields get defaults).
local function sanitize(raw: unknown): PlayerData
	local data = defaultData()
	if typeof(raw) == "table" then
		local coins = (raw :: any).coins
		if typeof(coins) == "number" and coins >= 0 then
			data.coins = math.floor(coins)
		end
	end
	return data
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
	-- Keep coins earned while loading (e.g. a round ended during the request).
	CoinService.set(player, data.coins + CoinService.get(player))
	loaded[player] = true
end

-- Writes the player's current data. Callers make sure the data was loaded first
-- (autosave only goes over `loaded`; onPlayerRemoving checks it).
local function save(player: Player)
	local dataStore = store
	if not dataStore then
		return
	end
	local data: PlayerData = { coins = CoinService.get(player) }
	withRetries(`Saving data for {player.Name}`, function()
		-- UpdateAsync instead of SetAsync: the recommended way to write, safer with several servers.
		dataStore:UpdateAsync(keyFor(player), function()
			return data
		end)
		return true
	end)
end

-- Final save for a player. Clears `loaded` first, so a second call
-- (PlayerRemoving and BindToClose both happen on shutdown) does nothing.
local function onPlayerRemoving(player: Player)
	if not loaded[player] then
		return
	end
	loaded[player] = nil
	save(player)
end

-- Call once from the server entry point, after CoinService.init().
function DataService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		-- Typical in Studio when the place isn't published or API access is off.
		warn(`DataStores are not available, coins will not be saved: {result}`)
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
