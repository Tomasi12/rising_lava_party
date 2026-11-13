--!strict
-- Picks a random map theme for every round (step 23) and applies its look to the arena
-- (floor, walls) and the sky (Lighting). PlatformService reads ThemeService.current()
-- to build the platforms in the theme's style.
--
-- init() must run BEFORE EventService.init() and PlatformService.init(): RoundPreparing handlers
-- run in the order they were connected. After the round the sky goes back to the lobby look.
-- The map's gravity is applied by EventService (together with the event's gravity).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RoundState = require(ReplicatedStorage.Shared.RoundState)
local Themes = require(ReplicatedStorage.Shared.Themes)
local RoundManager = require(script.Parent.RoundManager)

type Theme = Themes.Theme

local ThemeService = {}

local current: Theme = Themes.list[1]
local rng = Random.new()

-- The lobby's sky, saved when the server starts.
local lobbyLighting = {
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	FogColor = Lighting.FogColor,
	FogEnd = Lighting.FogEnd,
}

local function pickRandom(): Theme
	local total = 0
	for _, theme in Themes.list do
		total += theme.weight
	end
	local roll = rng:NextNumber(0, total)
	for _, theme in Themes.list do
		roll -= theme.weight
		if roll <= 0 then
			return theme
		end
	end
	return Themes.list[1]
end

-- The theme of the current (or next) round.
function ThemeService.current(): Theme
	return current
end

local function applyArena(theme: Theme)
	local arena = Workspace:FindFirstChild("Arena")
	if not arena then
		return
	end
	local floor = arena:FindFirstChild("Floor")
	if floor and floor:IsA("BasePart") then
		floor.Material = theme.floor.material
		floor.Color = theme.floor.color
	end
	for _, name in { "WallNorth", "WallSouth", "WallEast", "WallWest" } do
		local wall = arena:FindFirstChild(name)
		if wall and wall:IsA("BasePart") then
			wall.Color = theme.wallColor
			wall.Transparency = theme.wallTransparency
		end
	end
end

local function applySky(theme: Theme)
	Lighting.ClockTime = theme.clockTime
	Lighting.Brightness = theme.brightness
	Lighting.Ambient = theme.ambient
	Lighting.OutdoorAmbient = theme.outdoorAmbient
	Lighting.FogColor = theme.fogColor
	Lighting.FogEnd = theme.fogEnd
end

local function restoreLobbySky()
	Lighting.ClockTime = lobbyLighting.ClockTime
	Lighting.Brightness = lobbyLighting.Brightness
	Lighting.Ambient = lobbyLighting.Ambient
	Lighting.OutdoorAmbient = lobbyLighting.OutdoorAmbient
	Lighting.FogColor = lobbyLighting.FogColor
	Lighting.FogEnd = lobbyLighting.FogEnd
end

-- Call once from the server entry point, BEFORE PlatformService.init().
function ThemeService.init()
	RoundManager.RoundPreparing:Connect(function()
		current = pickRandom()
		applyArena(current)
		applySky(current)
		RoundManager.setStateAttribute(RoundState.ATTR_THEME, current.id)
	end)
	RoundManager.RoundEnded:Connect(restoreLobbySky)
end

return ThemeService
