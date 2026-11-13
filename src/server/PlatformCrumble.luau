--!strict
-- Crumbling platforms (step 21): when a player lands on a platform, it starts shaking and
-- turns red, and after Config.CRUMBLE_DELAY seconds it falls away. It comes back after
-- Config.CRUMBLE_RESPAWN_TIME seconds, so there is always somewhere to jump. Players can't stand still:
-- they must keep moving, which is what makes a round exciting.
--
-- PlatformService calls PlatformCrumble.attach(part) for every platform it creates.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local SHAKE_STEP = 0.05 -- seconds between shake moves
local SHAKE_DISTANCE = 0.12 -- studs; small, so players standing on it aren't thrown off
local WARNING_COLOR = Color3.fromRGB(230, 60, 40)
local FALL_DISTANCE = 10 -- studs the platform drops while fading out
local RESPAWN_FADE_TIME = 0.5 -- seconds a returning platform takes to fade in

local PlatformCrumble = {}

-- True if `hit` belongs to a living player whose body is above the platform's top
-- (landing on it, not just brushing the side while jumping past).
local function isPlayerStandingOn(hit: BasePart, platform: BasePart): boolean
	local character = hit.Parent
	if not character or not character:IsA("Model") then
		return false
	end
	if not Players:GetPlayerFromCharacter(character) then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	local top = platform.Position.Y + platform.Size.Y / 2
	return root.Position.Y > top
end

local function crumble(platform: BasePart)
	local home = platform.CFrame
	local startColor = platform.Color

	-- Shake and slowly turn red.
	local elapsed = 0
	while elapsed < Config.CRUMBLE_DELAY do
		if not platform.Parent then
			return -- removed (new round)
		end
		local progress = elapsed / Config.CRUMBLE_DELAY
		platform.Color = startColor:Lerp(WARNING_COLOR, progress)
		local offset = Vector3.new(
			(math.random() - 0.5) * 2 * SHAKE_DISTANCE,
			0,
			(math.random() - 0.5) * 2 * SHAKE_DISTANCE
		)
		platform.CFrame = home + offset
		elapsed += task.wait(SHAKE_STEP)
	end
	if not platform.Parent then
		return
	end

	-- Fall: players drop through it right away, the part sinks and fades out.
	platform.CFrame = home
	platform.CanCollide = false
	local tween = TweenService:Create(platform, TweenInfo.new(Config.CRUMBLE_FALL_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = home - Vector3.new(0, FALL_DISTANCE, 0),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Wait()

	-- Come back after a while, so there is always somewhere to jump.
	task.wait(Config.CRUMBLE_RESPAWN_TIME)
	if not platform.Parent then
		return
	end
	platform.CFrame = home
	platform.Color = startColor
	local appear = TweenService:Create(platform, TweenInfo.new(RESPAWN_FADE_TIME), { Transparency = 0 })
	appear:Play()
	appear.Completed:Wait()
	platform.CanCollide = true
end

-- Makes the platform crumble every time a player lands on it (once it has come back).
function PlatformCrumble.attach(platform: BasePart)
	if not Config.CRUMBLE_ENABLED then
		return
	end
	local busy = false -- shaking, fallen or coming back
	platform.Touched:Connect(function(hit: BasePart)
		if busy or not isPlayerStandingOn(hit, platform) then
			return
		end
		busy = true
		task.spawn(function()
			crumble(platform)
			busy = false
		end)
	end)
end

return PlatformCrumble
