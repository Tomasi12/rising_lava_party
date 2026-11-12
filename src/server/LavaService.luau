--!strict
-- The lava. When a round starts it appears on the arena floor, waits a few seconds,
-- then rises at a steady speed. Any player whose feet are in the lava dies.
-- When the round ends the lava is removed.
--
-- The kill check runs on the server every 0.1 s by comparing each player's feet with the
-- lava surface. We don't use the Touched event: it is unreliable for anchored parts that
-- are moved by code, and a server-side check can't be cheated by the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local RoundManager = require(script.Parent.RoundManager)

local START_THICKNESS = 0.2 -- studs; the thin layer visible before the lava starts rising
local KILL_DEPTH = 0.5 -- feet must be this deep in the lava to die (so standing on the floor at the start is safe)
local CHECK_INTERVAL = 0.1 -- seconds between kill checks

local LavaService = {}

-- Increases every time the lava is started or stopped. Loops and delayed tasks
-- from an older round see a different number and stop by themselves.
local generation = 0
local lavaPart: BasePart? = nil
local riseTween: Tween? = nil

local function getArenaFloor(): BasePart
	return Workspace:WaitForChild("Arena"):WaitForChild("Floor") :: BasePart
end

local function floorTopY(floor: BasePart): number
	return floor.Position.Y + floor.Size.Y / 2
end

-- Lava surface height (world Y).
local function lavaTopY(part: BasePart): number
	return part.Position.Y + part.Size.Y / 2
end

local function isAboveFloor(position: Vector3, floor: BasePart): boolean
	local half = floor.Size / 2
	return math.abs(position.X - floor.Position.X) <= half.X and math.abs(position.Z - floor.Position.Z) <= half.Z
end

-- A slab of lava covering the whole floor, `height` studs thick, sitting on the floor.
local function lavaCFrame(floor: BasePart, height: number): CFrame
	return CFrame.new(floor.Position.X, floorTopY(floor) + height / 2, floor.Position.Z)
end

local function createLava(floor: BasePart): BasePart
	local part = Instance.new("Part")
	part.Name = "Lava"
	part.Anchored = true
	part.CanCollide = false -- players sink into it
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 90, 20)
	part.Transparency = 0.15
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(floor.Size.X, START_THICKNESS, floor.Size.Z)
	part.CFrame = lavaCFrame(floor, START_THICKNESS)
	part.Parent = Workspace
	return part
end

local function killPlayersInLava(part: BasePart, floor: BasePart)
	local deadlyY = lavaTopY(part) - KILL_DEPTH
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
			continue
		end
		local feetY = root.Position.Y - root.Size.Y / 2 - humanoid.HipHeight
		if feetY < deadlyY and isAboveFloor(root.Position, floor) then
			humanoid.Health = 0
		end
	end
end

function LavaService.stop()
	generation += 1
	if riseTween then
		riseTween:Cancel()
		riseTween = nil
	end
	if lavaPart then
		lavaPart:Destroy()
		lavaPart = nil
	end
end

function LavaService.start()
	LavaService.stop()
	local myGeneration = generation

	local floor = getArenaFloor()
	local part = createLava(floor)
	lavaPart = part

	-- Kill check loop for this round.
	task.spawn(function()
		while generation == myGeneration do
			killPlayersInLava(part, floor)
			task.wait(CHECK_INTERVAL)
		end
	end)

	-- After a short delay, rise steadily up to the maximum height.
	task.delay(Config.LAVA_START_DELAY, function()
		if generation ~= myGeneration then
			return -- the round already ended
		end
		local height = Config.LAVA_MAX_HEIGHT
		local duration = (height - START_THICKNESS) / Config.LAVA_RISE_SPEED
		local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = Vector3.new(floor.Size.X, height, floor.Size.Z),
			CFrame = lavaCFrame(floor, height),
		})
		riseTween = tween
		tween:Play()
	end)
end

-- Call once from the server entry point, before RoundManager.start().
function LavaService.init()
	RoundManager.RoundStarted:Connect(function()
		LavaService.start()
	end)
	RoundManager.RoundEnded:Connect(function()
		LavaService.stop()
	end)
end

return LavaService
