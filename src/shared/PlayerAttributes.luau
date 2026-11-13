--!strict
-- Names of the attributes the server sets on each Player object.
-- Attributes on a Player are copied to every client, so clients (HUD, sounds, spectate,
-- shop) can read them. Only the server writes them.

local PlayerAttributes = {
	-- Round
	IN_ROUND = "InRound", -- boolean: alive in the arena in the current round
	WAS_IN_ROUND = "WasInRound", -- boolean: took part in the current round (alive or out)
	REVIVED = "RevivedThisRound", -- boolean: already used a Revive this round
	FINISHED = "FinishedRound", -- boolean: reached the summit this round (step 22)

	-- Shop (step 15)
	OWNED_PREFIX = "Owned_", -- boolean per item, e.g. "Owned_trail_fire"
	EQUIPPED_TRAIL = "EquippedTrail", -- string: item id, or "" for none

	-- Game passes (step 16)
	PASS_PREFIX = "Pass_", -- boolean per pass, key from Config.GAME_PASSES, e.g. "Pass_VIP"
}

return table.freeze(PlayerAttributes)
