--!strict
-- Items in the shop (step 15). For now: trails, a colored streak that follows you.
-- To add a trail: copy a block, give it a new unique `id` (never change an id after release:
-- it is saved in the players' data), a name, a price in coins and 2+ colors.
-- `vipOnly` items can't be bought with coins: they come with the VIP game pass (step 16).

export type ShopItem = {
	id: string,
	name: string,
	price: number,
	colors: { Color3 },
	vipOnly: boolean,
}

local list: { ShopItem } = {
	{
		id = "trail_ember",
		name = "Ember",
		price = 100,
		colors = { Color3.fromRGB(255, 170, 40), Color3.fromRGB(220, 30, 20) },
		vipOnly = false,
	},
	{
		id = "trail_ocean",
		name = "Ocean",
		price = 150,
		colors = { Color3.fromRGB(90, 230, 255), Color3.fromRGB(20, 70, 220) },
		vipOnly = false,
	},
	{
		id = "trail_toxic",
		name = "Toxic",
		price = 250,
		colors = { Color3.fromRGB(200, 255, 60), Color3.fromRGB(30, 160, 40) },
		vipOnly = false,
	},
	{
		id = "trail_galaxy",
		name = "Galaxy",
		price = 400,
		colors = { Color3.fromRGB(120, 60, 255), Color3.fromRGB(255, 80, 200), Color3.fromRGB(40, 20, 120) },
		vipOnly = false,
	},
	{
		id = "trail_rainbow",
		name = "Rainbow",
		price = 800,
		colors = {
			Color3.fromRGB(255, 60, 60),
			Color3.fromRGB(255, 200, 40),
			Color3.fromRGB(60, 220, 80),
			Color3.fromRGB(60, 140, 255),
			Color3.fromRGB(190, 70, 255),
		},
		vipOnly = false,
	},
	{
		id = "trail_vip_gold",
		name = "VIP Gold",
		price = 0,
		colors = { Color3.fromRGB(255, 240, 150), Color3.fromRGB(230, 170, 20) },
		vipOnly = true,
	},
}

local byId: { [string]: ShopItem } = {}
for _, item in list do
	table.freeze(item.colors)
	table.freeze(item)
	byId[item.id] = item
end

-- Turns the item's colors into an evenly spread ColorSequence (for Trails and UIGradients).
local function colorSequence(item: ShopItem): ColorSequence
	local colors = item.colors
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local keypoints: { ColorSequenceKeypoint } = {}
	for index, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / (#colors - 1), color))
	end
	return ColorSequence.new(keypoints)
end

return table.freeze({
	list = table.freeze(list),
	byId = table.freeze(byId),
	colorSequence = colorSequence,
})
