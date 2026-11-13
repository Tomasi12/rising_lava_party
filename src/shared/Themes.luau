--!strict
-- Maps / themes (step 23). Before each round one theme is picked at random. It decides how the
-- platforms, the arena floor and walls, and the sky look. The game rules stay the same.
--
-- To add a theme: copy one block, give it a new id and title, change the look.
-- Note: our own designs only. Don't copy another game's name, textures or characters.

export type Style = { material: Enum.Material, color: Color3 }

export type Theme = {
	id: string,
	title: string, -- shown to players
	weight: number, -- how often it is picked compared to the others

	-- Platforms
	platformThickness: number, -- studs
	gridSnap: number, -- 0 = free placement; 4 = platforms snap to a 4-stud grid (blocky look)
	platformSizes: { number }?, -- fixed sizes to choose from; nil = any size between Config MIN and MAX
	styleAt: (progress: number) -> Style, -- look of a platform at height progress 0 (floor) .. 1 (top)

	-- Arena
	floor: Style,
	wallColor: Color3,
	wallTransparency: number,

	-- Sky / light (Lighting properties)
	clockTime: number, -- 0..24, time of day
	brightness: number,
	ambient: Color3,
	outdoorAmbient: Color3,
	fogColor: Color3,
	fogEnd: number,
}

local function style(material: Enum.Material, r: number, g: number, b: number): Style
	return { material = material, color = Color3.fromRGB(r, g, b) }
end

local VOLCANO_LOW = Color3.fromRGB(80, 200, 120)
local VOLCANO_HIGH = Color3.fromRGB(170, 90, 255)

local list: { Theme } = {
	{
		id = "BlockyWorld",
		title = "Blocky World",
		weight = 1,
		platformThickness = 4,
		gridSnap = 4,
		platformSizes = { 8, 8, 12 }, -- 8 twice: more often than 12
		styleAt = function(progress: number): Style
			if progress < 0.2 then
				return style(Enum.Material.Cobblestone, 120, 120, 125)
			elseif progress < 0.45 then
				return style(Enum.Material.Ground, 125, 85, 55) -- dirt
			elseif progress < 0.7 then
				return style(Enum.Material.Grass, 95, 170, 70)
			elseif progress < 0.9 then
				return style(Enum.Material.WoodPlanks, 170, 125, 75)
			end
			return style(Enum.Material.Sand, 225, 205, 140)
		end,
		floor = style(Enum.Material.Grass, 95, 170, 70),
		wallColor = Color3.fromRGB(170, 215, 255),
		wallTransparency = 0.8,
		clockTime = 12,
		brightness = 3,
		ambient = Color3.fromRGB(120, 120, 130),
		outdoorAmbient = Color3.fromRGB(150, 150, 160),
		fogColor = Color3.fromRGB(190, 220, 255),
		fogEnd = 2000,
	},
	{
		id = "Volcano",
		title = "Volcano",
		weight = 1,
		platformThickness = 1,
		gridSnap = 0,
		platformSizes = nil,
		styleAt = function(progress: number): Style
			return { material = Enum.Material.SmoothPlastic, color = VOLCANO_LOW:Lerp(VOLCANO_HIGH, progress) }
		end,
		floor = style(Enum.Material.Basalt, 64, 56, 56),
		wallColor = Color3.fromRGB(255, 190, 150),
		wallTransparency = 0.75,
		clockTime = 17.6,
		brightness = 2,
		ambient = Color3.fromRGB(110, 70, 60),
		outdoorAmbient = Color3.fromRGB(150, 100, 80),
		fogColor = Color3.fromRGB(120, 60, 40),
		fogEnd = 1500,
	},
}

local byId: { [string]: Theme } = {}
for _, theme in list do
	table.freeze(theme)
	byId[theme.id] = theme
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
})
