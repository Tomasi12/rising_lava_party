--!strict
-- Builds a new random set of platforms in the arena before every round.
--
-- 1. Routes: a few climbing paths, each a "random walk" upward. Every next platform is a
--    bit higher (STEP_UP) and a small jump away (GAP), so every route can be climbed
--    from the floor to the top.
-- 2. Extras: more platforms at random places and heights, for variety and shortcuts.
--
-- Rules that keep it playable:
-- - Platforms stay inside the arena walls (with a margin).
-- - No platform is placed directly above another one with less than HEAD_CLEARANCE
--   between them, so players never bump their head when jumping.
-- - The area above the arena spawn points is kept free near the floor.
--
-- Called through RoundManager.RoundPreparing, so it must not yield.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local EventService = require(script.Parent.EventService)
local RoundManager = require(script.Parent.RoundManager)

local THICKNESS = 1 -- platform height in studs
local EDGE_MARGIN = 4 -- keep platforms this far from the walls
local HEAD_CLEARANCE = 13 -- min vertical space between overlapping platforms (character ~5 + jump ~7 + margin)
local SIDE_CLEARANCE = 2 -- extra horizontal room around a platform for that check (shoulders, jump arc)
local MAX_TRIES = 30 -- attempts to find a valid spot before giving up on a platform
local SPAWN_KEEP_FREE = 6 -- size of the free area above each spawn point

local LOW_COLOR = Color3.fromRGB(80, 200, 120) -- green near the floor
local HIGH_COLOR = Color3.fromRGB(170, 90, 255) -- purple at the top

-- A placed (or reserved) square area, used for the overlap checks.
type Box = { x: number, y: number, z: number, half: number }

local PlatformService = {}

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

local function overlapsHorizontally(a: Box, b: Box): boolean
	local reach = a.half + b.half + SIDE_CLEARANCE
	return math.abs(a.x - b.x) < reach and math.abs(a.z - b.z) < reach
end

-- True if the box would sit too close above or below an existing one.
local function isBlocked(candidate: Box, placed: { Box }): boolean
	for _, other in placed do
		if math.abs(candidate.y - other.y) < HEAD_CLEARANCE and overlapsHorizontally(candidate, other) then
			return true
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

local function isValid(box: Box, floor: BasePart, placed: { Box }): boolean
	return isInsideArena(box, floor) and not isBlocked(box, placed)
end

local function randomSize(rng: Random): number
	local scale = EventService.current().platformSize -- smaller in the Tiny Platforms event
	return rng:NextNumber(Config.PLATFORM_MIN_SIZE, Config.PLATFORM_MAX_SIZE) * scale
end

local function randomStepUp(rng: Random): number
	return rng:NextNumber(Config.PLATFORM_STEP_UP_MIN, Config.PLATFORM_STEP_UP_MAX)
end

local function createPart(box: Box, floorTop: number, folder: Folder)
	local part = Instance.new("Part")
	part.Name = "Platform"
	part.Anchored = true
	part.Size = Vector3.new(box.half * 2, THICKNESS, box.half * 2)
	-- box.y is the top surface (where players stand)
	part.CFrame = CFrame.new(box.x, box.y - THICKNESS / 2, box.z)
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local progress = math.clamp((box.y - floorTop) / Config.PLATFORM_TOP_HEIGHT, 0, 1)
	part.Color = LOW_COLOR:Lerp(HIGH_COLOR, progress)
	part.Parent = folder
end

-- A random spot on the floor area, `height` above the floor.
local function randomBox(rng: Random, floor: BasePart, height: number): Box
	local half = randomSize(rng) / 2
	local limitX = floor.Size.X / 2 - EDGE_MARGIN - half
	local limitZ = floor.Size.Z / 2 - EDGE_MARGIN - half
	return {
		x = floor.Position.X + rng:NextNumber(-limitX, limitX),
		y = height,
		z = floor.Position.Z + rng:NextNumber(-limitZ, limitZ),
		half = half,
	}
end

-- The next platform on a route: higher, and a jumpable gap away in a random direction.
local function nextBox(rng: Random, from: Box): Box
	local half = randomSize(rng) / 2
	local angle = rng:NextNumber(0, 2 * math.pi)
	local distance = from.half + half + rng:NextNumber(Config.PLATFORM_GAP_MIN, Config.PLATFORM_GAP_MAX)
	return {
		x = from.x + math.cos(angle) * distance,
		y = from.y + randomStepUp(rng),
		z = from.z + math.sin(angle) * distance,
		half = half,
	}
end

local function buildRoute(rng: Random, floor: BasePart, floorTop: number, placed: { Box }, folder: Folder): number
	local topY = floorTop + Config.PLATFORM_TOP_HEIGHT

	-- First platform: one jump up from the floor.
	local current: Box? = nil
	for _ = 1, MAX_TRIES do
		local candidate = randomBox(rng, floor, floorTop + randomStepUp(rng))
		if isValid(candidate, floor, placed) then
			current = candidate
			break
		end
	end

	local count = 0
	while current do
		local box: Box = current
		table.insert(placed, box)
		createPart(box, floorTop, folder)
		count += 1
		if box.y >= topY then
			break
		end

		current = nil
		for _ = 1, MAX_TRIES do
			local candidate = nextBox(rng, box)
			if isValid(candidate, floor, placed) then
				current = candidate
				break
			end
		end
	end
	return count
end

local function buildExtras(rng: Random, floor: BasePart, floorTop: number, placed: { Box }, folder: Folder): number
	local count = 0
	for _ = 1, Config.PLATFORM_EXTRAS do
		for _ = 1, MAX_TRIES do
			local height = floorTop + rng:NextNumber(Config.PLATFORM_STEP_UP_MIN, Config.PLATFORM_TOP_HEIGHT)
			local candidate = randomBox(rng, floor, height)
			if isValid(candidate, floor, placed) then
				table.insert(placed, candidate)
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
	local placed: { Box } = {}

	-- Reserve the space above each spawn point so nobody is teleported into a platform.
	for _, point in spawnPoints:GetChildren() do
		if point:IsA("BasePart") then
			table.insert(placed, { x = point.Position.X, y = floorTop, z = point.Position.Z, half = SPAWN_KEEP_FREE / 2 })
		end
	end

	local routeCounts = {}
	for _ = 1, Config.PLATFORM_PATHS do
		table.insert(routeCounts, buildRoute(rng, floor, floorTop, placed, folder))
	end
	local extras = buildExtras(rng, floor, floorTop, placed, folder)

	print(`Platforms built: routes {table.concat(routeCounts, ", ")} + {extras} extras (event: {EventService.current().id})`)
end

-- A place to put a revived player (step 17): on the lowest platform whose top is at least
-- `minY`, so they have time before the lava reaches them. If no platform is that high,
-- the highest platform. Returns nil if there are no platforms.
function PlatformService.findSafeSpot(minY: number): CFrame?
	local _, folder = getArena()
	local best: BasePart? = nil
	local highest: BasePart? = nil
	for _, child in folder:GetChildren() do
		if not child:IsA("BasePart") then
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
