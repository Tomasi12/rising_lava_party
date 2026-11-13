--!strict
-- Summit finish (step 22): while a round runs, checks 5 times per second whether a climber
-- is standing on the golden summit. If yes, they finish the round (RoundManager.finish):
-- they are safe, get coins at the end of the round, and the first one wins.
--
-- A server-side position check (not Touched), like the lava, so it can't be faked by the client.

local Net = require(script.Parent.Net)
local PlatformService = require(script.Parent.PlatformService)
local RoundManager = require(script.Parent.RoundManager)

local CHECK_INTERVAL = 0.2 -- seconds

local SummitService = {}

local generation = 0

local function ordinal(place: number): string
	if place == 1 then
		return "1st"
	elseif place == 2 then
		return "2nd"
	elseif place == 3 then
		return "3rd"
	end
	return `{place}th`
end

local function checkClimbers()
	for _, player in RoundManager.getClimbers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") and PlatformService.isOnSummit(root.Position) then
			local place = RoundManager.finish(player)
			if place then
				local text = if place == 1 then "You reached the top FIRST!" else `You reached the top, {ordinal(place)}!`
				Net.notify(player, text, "success")
			end
		end
	end
end

-- Call once from the server entry point.
function SummitService.init()
	RoundManager.RoundStarted:Connect(function()
		generation += 1
		local myGeneration = generation
		while generation == myGeneration do
			checkClimbers()
			task.wait(CHECK_INTERVAL)
		end
	end)
	RoundManager.RoundEnded:Connect(function()
		generation += 1 -- stops the loop
	end)
end

return SummitService
