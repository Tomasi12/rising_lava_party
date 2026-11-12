# Step 5 — Round system

Date: 2026-11-12 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
The server runs a loop forever:

```
 Waiting ──(enough players)──► Intermission ──(countdown 15 s)──► Round ──► Ended ──(5 s)──┐
    ▲                              │ (players left)                                       │
    └──────────────────────────────┘◄─────────────────────────────────────────────────────┘
```

| Phase | What happens | Message on screen |
|---|---|---|
| **Waiting** | Fewer than `MIN_PLAYERS` players in the server | `Waiting for players...` |
| **Intermission** | Countdown in the lobby | `Round starts in 15` … `1` |
| **Round** | All living players are teleported to the arena spawn points (shuffled). The round ends when the time runs out, or when only one player is left (with 2+ players), or when the only player dies (alone). | `Survive! 45s · 3 alive` |
| **Ended** | Shows the result, then survivors are teleported back to the lobby. Dead players have already respawned in the lobby. | `Alex wins!` / `3 players survived!` / `Nobody survived!` |

A player is **out** when their character dies or they leave the game.
Players who join during a round wait in the lobby for the next one.

## Settings — [`src/shared/Config.luau`](../src/shared/Config.luau)
| Setting | Value | Meaning |
|---|---|---|
| `MIN_PLAYERS` | 1 | players needed to start (1 so you can test alone; raise it to 2 for the real game) |
| `INTERMISSION_TIME` | 15 | seconds of countdown in the lobby |
| `ROUND_TIME` | 90 | maximum seconds per round |
| `END_TIME` | 5 | seconds the result is shown |

## Files
| File | Type | Job |
|---|---|---|
| [`src/server/RoundManager.luau`](../src/server/RoundManager.luau) | ModuleScript (server) | The loop above: countdown, teleports, who is alive, result |
| [`src/server/Signal.luau`](../src/server/Signal.luau) | ModuleScript (server) | Tiny event helper so other modules can react to rounds |
| [`src/server/Main.server.luau`](../src/server/Main.server.luau) | Script | Calls `RoundManager.start()` |
| [`src/shared/RoundState.luau`](../src/shared/RoundState.luau) | ModuleScript (shared) | Names of the phases and attributes, used by server and client |
| [`src/client/RoundHud.client.luau`](../src/client/RoundHud.client.luau) | LocalScript | Shows the message at the top of the screen |

## How server and client talk
The server creates a Folder `ReplicatedStorage.RoundState` and sets three **attributes** on it:
`Phase`, `TimeLeft`, `Message`. Roblox copies attributes of objects in `ReplicatedStorage` to every
client automatically, so the client only listens for changes. No RemoteEvents are needed, and the client
can't change the round (the server is the only one who writes).

## How later steps plug in
`RoundManager` has three signals (`RoundPreparing` was added in [step 7](07-random-platforms.md)):
```lua
RoundManager.RoundPreparing:Connect(function() ... end)                        -- step 7: build platforms (before the teleport, must not yield)
RoundManager.RoundStarted:Connect(function(participants: { Player }) ... end) -- step 6: start lava
RoundManager.RoundEnded:Connect(function(survivors: { Player }) ... end)      -- step 6: reset lava, step 8: give coins
```
So the lava, platforms and coins are separate modules and the round code doesn't change.

## Check that it works (to do in Studio)
1. Rojo connected, press **Play**.
2. Top of the screen: `Round starts in 15` counting down.
3. At 0 you are teleported into the arena; the message changes to `Survive! 90s · 1 alive`.
4. Reset your character (**Esc → Reset Character**): you respawn in the lobby, the message shows
   `Nobody survived!`, then the countdown starts again.
5. Play again and wait 90 s: `<your name> wins!`, and you are teleported back to the lobby.
6. Optional, 2 players: **Test** tab → **Clients and Servers** → 2 players → **Start**.
   When one resets, the other wins.

## Verified so far
- `rojo build` succeeds and the place contains all scripts in the right services (2026-11-12).
- Not yet run in Studio.
