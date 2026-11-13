--!strict
-- Names shared by the server (writes the round state) and the client (shows it).
-- The server creates ReplicatedStorage.RoundState (a Folder) and sets these attributes on it.
-- Attributes on objects in ReplicatedStorage are copied to every client automatically.

local Phase = table.freeze({
	Waiting = "Waiting", -- not enough players
	Intermission = "Intermission", -- countdown in the lobby
	Round = "Round", -- players are in the arena
	Ended = "Ended", -- showing the result
})

local RoundState = {
	FOLDER_NAME = "RoundState",

	ATTR_PHASE = "Phase", -- string, one of Phase
	ATTR_TIME_LEFT = "TimeLeft", -- number, seconds
	ATTR_MESSAGE = "Message", -- string, text shown at the top of the screen
	ATTR_EVENT = "Event", -- string, id of the round event (shared/RoundEvents), step 12
	ATTR_THEME = "Theme", -- string, id of the round's map theme (shared/Themes), step 23

	Phase = Phase,
}

return table.freeze(RoundState)
