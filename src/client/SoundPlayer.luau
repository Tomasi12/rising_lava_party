--!strict
-- Plays short UI / game sounds on this client only.
--   SoundPlayer.play(Config.SOUNDS.BUTTON)

local SoundService = game:GetService("SoundService")

local SoundPlayer = {}

local cache: { [string]: Sound } = {}

function SoundPlayer.play(soundId: string, volume: number?)
	if soundId == "" then
		return
	end
	local sound = cache[soundId]
	if not sound then
		local newSound = Instance.new("Sound")
		newSound.SoundId = soundId
		newSound.Parent = SoundService
		cache[soundId] = newSound
		sound = newSound
	end
	sound.Volume = volume or 0.6
	SoundService:PlayLocalSound(sound)
end

return SoundPlayer
