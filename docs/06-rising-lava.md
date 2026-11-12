# Step 6 — Rising lava

Date: 2026-11-12 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
1. **Round starts** → a thin layer of lava (0.2 studs) appears on the whole arena floor. Standing on it is safe.
2. After **5 seconds** the lava starts rising at **1.2 studs per second**, up to **140 studs** above the floor.
3. Any player whose **feet are 0.5 studs or more inside the lava dies**.
   With the round code from step 5, that player is out and respawns in the lobby.
4. **Round ends** → the lava is removed.

How high the lava is over time (with the default settings):

| Time in round | Lava height above floor |
|---|---|
| 0–5 s | 0.2 (waiting) |
| 15 s | ~12 |
| 45 s | ~48 |
| 90 s (round end) | ~102 |

Step 7 adds platforms up to ~130 studs high, so players can survive until the end by climbing.

## Settings — [`src/shared/Config.luau`](../src/shared/Config.luau)
| Setting | Value | Meaning |
|---|---|---|
| `LAVA_START_DELAY` | 5 | seconds before the lava starts rising |
| `LAVA_RISE_SPEED` | 1.2 | studs per second |
| `LAVA_MAX_HEIGHT` | 140 | the lava stops at this height above the arena floor |

Constants inside [`LavaService.luau`](../src/server/LavaService.luau) (rarely changed):
`START_THICKNESS` 0.2, `KILL_DEPTH` 0.5, `CHECK_INTERVAL` 0.1 s.

## Files
| File | Job |
|---|---|
| [`src/server/LavaService.luau`](../src/server/LavaService.luau) | Creates, raises and removes the lava; kills players in it |
| [`src/server/Main.server.luau`](../src/server/Main.server.luau) | Calls `LavaService.init()` before `RoundManager.start()` |

## How it works
- The lava is one `Part` named `Lava` in `Workspace`: neon orange, anchored, **no collision** (players sink in).
  It is the size of the arena floor; its size and position are read from `Workspace.Arena.Floor`, so if the
  arena changes size, the lava follows.
- Rising uses **TweenService** (linear) on the part's `Size` and `CFrame`. The bottom stays on the floor;
  the top goes up.
- **Kill check (server, every 0.1 s):** for each player, feet height =
  `HumanoidRootPart.Position.Y − HumanoidRootPart.Size.Y / 2 − Humanoid.HipHeight`.
  If the feet are below `lava top − 0.5` **and** the player is above the arena floor area, `Health = 0`.
  - Why not the `Touched` event: it doesn't fire reliably for anchored parts moved by code.
  - Why on the server: the client can't fake it.
- **Round-safe:** a `generation` counter goes up every time the lava starts or stops.
  The kill loop and the delayed "start rising" task check it and quit if the round already ended,
  so nothing from an old round affects the next one.
- Plugs into the round system through the signals from step 5:
  `RoundStarted → LavaService.start()`, `RoundEnded → LavaService.stop()`.

## Check that it works (to do in Studio)
1. Press **Play** and wait for the round to start.
2. A thin orange layer covers the arena floor. You don't die for the first 5 seconds.
3. The lava rises. Standing on the floor, you die after about 1 second of rising,
   respawn in the lobby, and the message shows `Nobody survived!`.
4. Next round: the lava starts from the floor again (it doesn't continue from the old height).
5. Before step 7 there is nothing to climb, so you can't survive a round yet. That's expected.

## Verified so far
- `rojo build` succeeds and `LavaService` is included in `ServerScriptService.Server` (2026-11-12).
- Not yet run in Studio.
