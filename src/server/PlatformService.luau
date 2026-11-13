--!strict
-- Builds a new random set of platforms in the arena before every round.
--
-- 1. Summit: a big golden platform at the top (step 22). Reaching it finishes the round
--    for that player. It never crumbles and the lava never reaches it.
-- 2. Routes: many climbing paths, each a "random walk" upward. Every next platform is a
--    bit higher (STEP_UP) and a small jump away (GAP). Near the top a route turns toward
--    the summit and ends one jump away from it. If a route gets stuck, it tries again from
--    one of its earlier platforms (backtracking), so most routes reach the summit.
-- 3. Extras: more platforms at random places and heights, for variety and shortcuts.
-- The look (thickness, grid, sizes, materials) comes from the round's map theme (step 23).
--
-- Rules that keep it playable:
-- - Platforms stay inside the arena walls (with a margin).
-- - No platform is placed directly above another one with less than headClearance
--   between them, so players never bump their head when jumping.
-- - The area above the arena spawn points is kept free near the floor.
--
-- Called through RoundManager.RoundPreparing, so it must not yield.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local EventService = require(script.Parent.EventService)
local PlatformCrumble = require(script.Parent.PlatformCrumble)
local RoundManager = require(script.Parent.RoundManager)
local ThemeService = require(script.Parent.ThemeService)

local EDGE_MARGIN = 4 -- keep platforms this far from the walls
local HEAD_ROOM = 12 -- min free space between a platform's top and the bottom of one above it (character ~5 + jump ~7)
local SIDE_CLEARANCE = 2 -- extra horizontal room around a platform for that check (shoulders, jump arc)
local MAX_TRIES = 30 -- attempts to find a valid spot for the next platform
local MAX_BACKTRACKS = 8 -- when stuck, retry from an earlier platform of the route this often
local SPAWN_KEEP_FREE = 6 -- size of the free area above each spawn point
local SUMMIT_ABOVE_TOP = 4 -- the summit's top is this much above PLATFORM_TOP_HEIGHT

local SUMMIT_COLOR = Color3.fromRGB(255, 200, 40)

-- A placed (or reserved) square area, used for the overlap checks.
-- y is the top surface (where players stand); half is half the width.
type Box = { x: number, y: number, z: number, half: number }

-- Placed boxes, sorted into height bands of headClearance studs. A box can only block
-- boxes in its own band or the bands next to it, so we only check those (fast).
type Placed = { [number]: { Box } }

local PlatformService = {}

local summitPart: BasePart? = nil

-- Set at the start of build() from the round's theme.
local thickness = 1 -- platform thickness in studs
local headClearance = HEAD_ROOM + thickness -- min vertical distance between the tops of overlapping platforms

local function getArena(): (BasePart, Folder, Folder)
	local arena = Workspace:FindFirstChild("Arena")
	assert(arena, "Workspace.Arena is missing")
	local floor = arena:FindFirstChild("Floor")
	local platforms = arena:FindFirstChild("Platforms")
	local spawnPoints = arena:FindFirstChild("SpawnPoints")
	assert(floor and floor:IsA("BasePart"), "Arena.Floor is missing")
	assert(platforms and platforms:IsA("Folder"), "Arena.Platforms is missing")
	assert(spawnPoints and spawnPoints:IsA("Folder"), "Arena.SpawnPoints is missing")
	return floor, platforms, spawnPoints
end

local function bandOf(y: number): number
	return math.floor(y / headClearance)
end

local function addPlaced(placed: Placed, box: Box)
	local band = bandOf(box.y)
	local list = placed[band]
	if not list then
		list = {}
		placed[band] = list
	end
	table.insert(list, box)
end

local function overlapsHorizontally(a: Box, b: Box): boolean
	local reach = a.half + b.half + SIDE_CLEARANCE
	return math.abs(a.x - b.x) < reach and math.abs(a.z - b.z) < reach
end

-- True if the box would sit too close above or below an existing one.
local function isBlocked(candidate: Box, placed: Placed): boolean
	local band = bandOf(candidate.y)
	for b = band - 1, band + 1 do
		local list = placed[b]
		if list then
			for _, other in list do
				if math.abs(candidate.y - other.y) < headClearance and overlapsHorizontally(candidate, other) then
					return true
				end
			end
		end
	end
	return false
end

local function isInsideArena(box: Box, floor: BasePart): boolean
	local limitX = floor.Size.X / 2 - EDGE_MARGIN
	local limitZ = floor.Size.Z / 2 - EDGE_MARGIN
	return math.abs(box.x - floor.Position.X) + box.half <= limitX
		and math.abs(box.z - floor.Position.Z) + box.half <= limitZ
end

local function isValid(box: Box, floor: BasePart, placed: Placed): boolean
	return isInsideArena(box, floor) and not isBlocked(box, placed)
end

local function randomSize(rng: Random): number
	local scale = EventService.current().platformSize -- smaller in the Tiny Platforms event
	local sizes = ThemeService.current().platformSizes
	if sizes then
		return sizes[rng:NextInteger(1, #sizes)] * scale
	end
	return rng:NextNumber(Config.PLATFORM_MIN_SIZE, Config.PLATFORM_MAX_SIZE) * scale
end

-- Blocky themes: put the platform on the theme's grid (x and z only; heights stay free,
-- because a 4-stud grid in height would make some steps too high to jump).
local function snapped(box: Box): Box
	local grid = ThemeService.current().gridSnap
	if grid <= 0 then
		return box
	end
	return {
		x = math.round(box.x / grid) * grid,
		y = box.y,
		z = math.round(box.z / grid) * grid,
		half = box.half,
	}
end

local function randomStepUp(rng: Random): number
	return rng:NextNumber(Config.PLATFORM_STEP_UP_MIN, Config.PLATFORM_STEP_UP_MAX)
end

-- Horizontal edge-to-edge distance between two squares (negative if they overlap).
local function edgeGap(a: Box, b: Box): number
	local gapX = math.abs(a.x - b.x) - (a.half + b.half)
	local gapZ = math.abs(a.z - b.z) - (a.half + b.half)
	return math.max(gapX, gapZ)
end

-- True if a player can jump from `from` onto `to` (not too far, not too high).
local function isJumpable(from: Box, to: Box): boolean
	local gap = edgeGap(from, to)
	return gap <= Config.PLATFORM_GAP_MAX + 0.01 and to.y - from.y <= Config.PLATFORM_STEP_UP_MAX + 0.01
end

-- True if a player can jump from `box` onto the summit.
local function canReachSummit(box: Box, summit: Box): boolean
	local gap = edgeGap(box, summit)
	local up = summit.y - box.y
	return gap >= 0 and gap <= Config.PLATFORM_GAP_MAX and up <= Config.PLATFORM_STEP_UP_MAX
end

local function createPart(box: Box, floorTop: number, folder: Folder)
	local part = Instance.new("Part")
	part.Name = "Platform"
	part.Anchored = true
	part.Size = Vector3.new(box.half * 2, thickness, box.half * 2)
	part.CFrame = CFrame.new(box.x, box.y - thickness / 2, box.z)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local progress = math.clamp((box.y - floorTop) / Config.PLATFORM_TOP_HEIGHT, 0, 1)
	local look = ThemeService.current().styleAt(progress)
	part.Material = look.material
	part.Color = look.color
	part.Parent = folder
	PlatformCrumble.attach(part) -- falls away shortly after a player lands on it (step 21)
end

local function createSummit(box: Box, folder: Folder): BasePart
	local part = Instance.new("Part")
	part.Name = "Summit"
	part.Anchored = true
	part.Size = Vector3.new(box.half * 2, 2, box.half * 2)
	part.CFrame = CFrame.new(box.x, box.y - 1, box.z)
	part.Material = Enum.Material.Neon
	part.Color = SUMMIT_COLOR
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	local light = Instance.new("PointLight")
	light.Color = SUMMIT_COLOR
	light.Range = 40
	light.Brightness = 3
	light.Parent = part

	-- A big "FINISH" sign above it, visible from far below.
	local sign = Instance.new("BillboardGui")
	sign.Name = "FinishSign"
	sign.Size = UDim2.new(0, 260, 0, 70)
	sign.StudsOffset = Vector3.new(0, 12, 0)
	sign.MaxDistance = 1000
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "FINISH"
	label.TextColor3 = SUMMIT_COLOR
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = sign
	sign.Parent = part

	part.Parent = folder
	return part
end

-- A random spot on the floor area, `height` above the floor.
local function randomBox(rng: Random, floor: BasePart, height: number): Box
	local half = randomSize(rng) / 2
	local limitX = floor.Size.X / 2 - EDGE_MARGIN - half
	local limitZ = floor.Size.Z / 2 - EDGE_MARGIN - half
	return snapped({
		x = floor.Position.X + rng:NextNumber(-limitX, limitX),
		y = height,
		z = floor.Position.Z + rng:NextNumber(-limitZ, limitZ),
		half = half,
	})
end

-- The next platform on a route: higher, and a jumpable gap away in a random direction.
local function nextBox(rng: Random, from: Box): Box
	local half = randomSize(rng) / 2
	local angle = rng:NextNumber(0, 2 * math.pi)
	local distance = from.half + half + rng:NextNumber(Config.PLATFORM_GAP_MIN, Config.PLATFORM_GAP_MAX)
	return snapped({
		x = from.x + math.cos(angle) * distance,
		y = from.y + randomStepUp(rng),
		z = from.z + math.sin(angle) * distance,
		half = half,
	})
end

-- Near the top: the next platform goes toward the summit, staying about level just below it.
-- `spread` (0..1) widens the direction on later tries, to get around obstacles.
local function approachBox(rng: Random, from: Box, summit: Box, spread: number): Box
	local half = randomSize(rng) / 2
	local toSummit = math.atan2(summit.z - from.z, summit.x - from.x)
	local angle = toSummit + rng:NextNumber(-1, 1) * (0.4 + spread * math.pi)
	local distance = from.half + half + rng:NextNumber(math.max(Config.PLATFORM_GAP_MIN, 2.5), Config.PLATFORM_GAP_MAX)
	local y = math.clamp(from.y + rng:NextNumber(-0.5, 1.5), summit.y - 4.5, summit.y - 0.5)
	return snapped({
		x = from.x + math.cos(angle) * distance,
		y = y,
		z = from.z + math.sin(angle) * distance,
		half = half,
	})
end

-- Builds one route. Returns the number of platforms and whether it reaches the summit.
local function buildRoute(
	rng: Random,
	floor: BasePart,
	floorTop: number,
	summit: Box,
	placed: Placed,
	folder: Folder
): (number, boolean)
	local topY = summit.y - SUMMIT_ABOVE_TOP

	-- First platform: one jump up from the floor.
	local first: Box? = nil
	for _ = 1, MAX_TRIES do
		local candidate = randomBox(rng, floor, floorTop + randomStepUp(rng))
		if isValid(candidate, floor, placed) then
			first = candidate
			break
		end
	end
	if not first then
		return 0, false
	end

	local route: { Box } = {}
	local current: Box? = first
	local backtracks = 0
	while current do
		local box: Box = current
		addPlaced(placed, box)
		createPart(box, floorTop, folder)
		table.insert(route, box)
		if canReachSummit(box, summit) and box.y >= topY - Config.PLATFORM_STEP_UP_MAX then
			return #route, true
		end

		-- Find the next platform, from the newest one or (when stuck) from an earlier one.
		current = nil
		local from = box
		while not current do
			for try = 1, MAX_TRIES do
				local candidate = if from.y >= topY
					then approachBox(rng, from, summit, try / MAX_TRIES)
					else nextBox(rng, from)
				-- (the summit is in `placed`, so isValid also keeps platforms from touching it;
				-- isJumpable re-checks the distance, which grid snapping can change)
				if isJumpable(from, candidate) and isValid(candidate, floor, placed) then
					current = candidate
					break
				end
			end
			if current then
				break
			end
			backtracks += 1
			if backtracks > MAX_BACKTRACKS then
				return #route, false
			end
			-- Retry from one of the last few platforms of this route (all of them are reachable).
			local back = math.min(#route, rng:NextInteger(2, 6))
			from = route[#route - back + 1]
		end
	end
	return #route, false
end

local function buildExtras(rng: Random, floor: BasePart, floorTop: number, placed: Placed, folder: Folder): number
	local count = 0
	local topY = floorTop + Config.PLATFORM_TOP_HEIGHT
	for _ = 1, Config.PLATFORM_EXTRAS do
		for _ = 1, MAX_TRIES do
			local height = floorTop + rng:NextNumber(Config.PLATFORM_STEP_UP_MIN, topY - floorTop)
			local candidate = randomBox(rng, floor, height)
			if isValid(candidate, floor, placed) then
				addPlaced(placed, candidate)
				createPart(candidate, floorTop, folder)
				count += 1
				break
			end
		end
	end
	return count
end

-- Removes the old platforms and builds a new random set.
function PlatformService.build()
	local floor, folder, spawnPoints = getArena()
	folder:ClearAllChildren()

	local rng = Random.new()
	local floorTop = floor.Position.Y + floor.Size.Y / 2
	local placed: Placed = {}
	thickness = ThemeService.current().platformThickness
	headClearance = HEAD_ROOM + thickness

	-- The summit, in the middle at the top. Routes are not allowed under it (head clearance).
	local summit: Box = {
		x = floor.Position.X,
		y = floorTop + Config.PLATFORM_TOP_HEIGHT + SUMMIT_ABOVE_TOP,
		z = floor.Position.Z,
		half = Config.SUMMIT_SIZE / 2,
	}
	addPlaced(placed, summit)
	summitPart = createSummit(summit, folder)

	-- Reserve the space above each spawn point so nobody is teleported into a platform.
	for _, point in spawnPoints:GetChildren() do
		if point:IsA("BasePart") then
			addPlaced(placed, { x = point.Position.X, y = floorTop, z = point.Position.Z, half = SPAWN_KEEP_FREE / 2 })
		end
	end

	local routeCounts = {}
	local reached = 0
	for _ = 1, Config.PLATFORM_PATHS do
		local count, reachesSummit = buildRoute(rng, floor, floorTop, summit, placed, folder)
		table.insert(routeCounts, count)
		if reachesSummit then
			reached += 1
		end
	end
	local extras = buildExtras(rng, floor, floorTop, placed, folder)

	print(
		`Platforms built: routes {table.concat(routeCounts, ", ")} + {extras} extras; `
			.. `{reached}/{Config.PLATFORM_PATHS} routes reach the summit (map: {ThemeService.current().id}, event: {EventService.current().id})`
	)
	if reached == 0 then
		warn("No route reaches the summit this round! Try more PLATFORM_PATHS or a lower PLATFORM_TOP_HEIGHT.")
	end
end

-- The summit part of the current round (nil before the first round).
function PlatformService.getSummit(): BasePart?
	local part = summitPart
	if part and part.Parent then
		return part
	end
	return nil
end

-- True if `position` (e.g. a HumanoidRootPart) is standing on top of the summit.
function PlatformService.isOnSummit(position: Vector3): boolean
	local part = PlatformService.getSummit()
	if not part then
		return false
	end
	local half = part.Size / 2
	local top = part.Position.Y + half.Y
	return math.abs(position.X - part.Position.X) <= half.X
		and math.abs(position.Z - part.Position.Z) <= half.Z
		and position.Y >= top
		and position.Y <= top + 12
end

-- A place to put a revived player (step 17): on the lowest platform whose top is at least
-- `minY`, so they have time before the lava reaches them. If no platform is that high,
-- the highest platform. Never the summit. Returns nil if there are no platforms.
function PlatformService.findSafeSpot(minY: number): CFrame?
	local _, folder = getArena()
	local best: BasePart? = nil
	local highest: BasePart? = nil
	for _, child in folder:GetChildren() do
		if not child:IsA("BasePart") or child.Name ~= "Platform" then
			continue
		end
		local top = child.Position.Y + child.Size.Y / 2
		if not highest or top > highest.Position.Y + highest.Size.Y / 2 then
			highest = child
		end
		if top >= minY and (not best or top < best.Position.Y + best.Size.Y / 2) then
			best = child
		end
	end
	local chosen = best or highest
	if not chosen then
		return nil
	end
	return CFrame.new(chosen.Position + Vector3.new(0, chosen.Size.Y / 2 + 3, 0))
end

-- Call once from the server entry point, before RoundManager.start().
function PlatformService.init()
	RoundManager.RoundPreparing:Connect(function()
		PlatformService.build()
	end)
end

return PlatformService
