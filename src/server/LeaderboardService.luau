--!strict
-- Global leaderboard (step 18): the top 10 players by Wins of ALL servers, ever,
-- shown on the board in the lobby (Workspace.Lobby.Leaderboard).
--
-- Uses an OrderedDataStore (a DataStore that can return entries sorted by value):
--   key = UserId, value = wins.
-- Every UPDATE_INTERVAL seconds: write the wins of players whose wins changed, then read the top 10.
-- Only players whose data loaded correctly are written (so a failed load never writes 0 wins).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CoinService = require(script.Parent.CoinService)
local DataService = require(script.Parent.DataService)

local STORE_NAME = "GlobalWins_v1"
local UPDATE_INTERVAL = 60 -- seconds (DataStore limits: don't go much lower)
local TOP_COUNT = 10

local LeaderboardService = {}

local store: OrderedDataStore? = nil
local lastWritten: { [Player]: number } = {}
-- Players whose saved data loaded (set from DataService.Loaded). Only they are written.
local eligible: { [Player]: boolean } = {}
local nameCache: { [number]: string } = {}
local rows: { TextLabel } = {}

local function nameFor(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local result = if ok and typeof(name) == "string" then name else `Player {userId}`
	nameCache[userId] = result
	return result
end

local function buildBoard(): boolean
	local lobby = Workspace:FindFirstChild("Lobby")
	local part = if lobby then lobby:FindFirstChild("Leaderboard") else nil
	if not part or not part:IsA("BasePart") then
		warn("Workspace.Lobby.Leaderboard is missing, the global leaderboard is not shown")
		return false
	end

	local surface = Instance.new("SurfaceGui")
	surface.Name = "Board"
	surface.Face = Enum.NormalId.Back -- the side facing into the lobby
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.LightInfluence = 0

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = surface

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = surface

	local title = Instance.new("TextLabel")
	title.LayoutOrder = 0
	title.Size = UDim2.new(1, 0, 0, 56)
	title.BackgroundTransparency = 1
	title.Text = "TOP 10 · MOST WINS"
	title.TextColor3 = Color3.fromRGB(255, 190, 60)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = surface

	for rank = 1, TOP_COUNT do
		local row = Instance.new("TextLabel")
		row.LayoutOrder = rank
		row.Size = UDim2.new(1, 0, 0, 34)
		row.BackgroundTransparency = 1
		row.Text = `{rank}.  -`
		row.TextColor3 = Color3.new(1, 1, 1)
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Parent = surface
		rows[rank] = row
	end

	surface.Parent = part
	return true
end

local function writeWins(player: Player)
	local dataStore = store
	if not dataStore or not eligible[player] then
		return
	end
	local wins = CoinService.getWins(player)
	if wins > 0 and lastWritten[player] ~= wins then
		local ok, err = pcall(dataStore.SetAsync, dataStore, tostring(player.UserId), wins)
		if ok then
			lastWritten[player] = wins
		else
			warn(`Leaderboard: could not save wins of {player.Name}: {err}`)
		end
	end
end

local function writeChangedWins()
	for _, player in Players:GetPlayers() do
		writeWins(player)
	end
end

local function refreshBoard()
	local dataStore = store
	if not dataStore or #rows == 0 then
		return
	end
	local ok, pages = pcall(dataStore.GetSortedAsync, dataStore, false, TOP_COUNT)
	if not ok then
		warn(`Leaderboard: could not read the top {TOP_COUNT}: {pages}`)
		return
	end
	local entries = (pages :: DataStorePages):GetCurrentPage()
	for rank = 1, TOP_COUNT do
		local entry = entries[rank]
		if entry then
			local userId = tonumber(entry.key)
			local name = if userId then nameFor(userId) else tostring(entry.key)
			rows[rank].Text = `{rank}.  {name}  ·  {entry.value}`
		else
			rows[rank].Text = `{rank}.  -`
		end
	end
end

-- Call once from the server entry point.
function LeaderboardService.init()
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, STORE_NAME)
	if ok then
		store = result
	else
		warn(`Leaderboard: DataStores are not available: {result}`)
		return
	end
	if not buildBoard() then
		return
	end

	-- Must be connected before DataService.init() so no Loaded event is missed.
	DataService.Loaded:Connect(function(player: Player)
		eligible[player] = true
	end)
	Players.PlayerRemoving:Connect(function(player)
		writeWins(player) -- last wins of this session
		eligible[player] = nil
		lastWritten[player] = nil
	end)

	task.spawn(function()
		while true do
			writeChangedWins()
			refreshBoard()
			task.wait(UPDATE_INTERVAL)
		end
	end)
end

return LeaderboardService
