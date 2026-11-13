# Step 11 — Sounds and lava effects

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
| What | When |
|---|---|
| Tick sound | Each of the last 5 seconds of the countdown |
| "Ping" sound | The round starts |
| Victory sound | The round ends and you are still alive |
| Coin sound + pop-up `+10 coins` | You get coins |
| Lava looks like lava | `CrackedLava` material, glowing embers flying up, orange light |
| Lava sound (optional) | Loops while the lava rises, if `SOUNDS.LAVA_LOOP` is set |

The result message no longer shows the coins (`Alex wins!` instead of `Alex wins! +25 coins`):
since the 2x Coins pass (step 16) not everyone gets the same amount. Each player sees their own
coins in a pop-up instead.

## Change the sounds
All sounds are in [`src/shared/Config.luau`](../src/shared/Config.luau) under `SOUNDS`.
- `rbxasset://sounds/...` are sounds built into Roblox (always available, free).
- To use a sound from the **Creator Store** (Toolbox → Audio): copy its ID and write
  `"rbxassetid://<id>"`. Good to add: a lava bubbling loop for `LAVA_LOOP`.
- `""` = no sound.

## New shared pieces (used by later steps)
| File | Job |
|---|---|
| [`src/shared/PlayerAttributes.luau`](../src/shared/PlayerAttributes.luau) | Names of attributes on each Player: `InRound`, `WasInRound`, `RevivedThisRound`, owned items, passes |
| [`src/shared/Remotes.luau`](../src/shared/Remotes.luau) | Names of the RemoteEvents/Functions |
| [`src/server/Net.luau`](../src/server/Net.luau) | Creates the remotes; `Net.notify(player, text, kind)` shows a pop-up |
| [`src/client/SoundPlayer.luau`](../src/client/SoundPlayer.luau) | `SoundPlayer.play(id)` on this client |
| [`src/client/Sounds.client.luau`](../src/client/Sounds.client.luau) | Round sounds |
| [`src/client/Notifications.client.luau`](../src/client/Notifications.client.luau) | Pop-ups at the bottom of the screen |

`RoundManager` now keeps the current round in a module variable and sets the player attributes, so the
client knows who is alive (used by sounds, spectate in step 13 and Revive in step 17).

## Check that it works
1. Countdown: you hear a tick at 5, 4, 3, 2, 1.
2. Round start: a "ping".
3. The lava has a cracked, glowing look with sparks flying up.
4. Survive: victory sound and a yellow pop-up `+10 coins`.
