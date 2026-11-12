# Step 7 — Random platforms

Date: 2026-11-12 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
Before every round, the old platforms are removed and a **new random set** is built in the arena,
so no two rounds look the same. Players climb the platforms to escape the lava.

- **3 climbing routes** go from the floor up to **130 studs**. Each route is a "random walk" upward:
  every next platform is **3.5–5.5 studs higher** and **1–5 studs away** (edge to edge), in a random direction.
  So every route can be climbed with normal jumps.
- **20 extra platforms** at random places and heights add variety and shortcuts between routes.
- Platforms are squares of **6–12 studs**, 1 stud thick.
- **Color shows height:** green near the floor → purple at the top.

The lava (step 6) is ~102 studs high when the round ends at 90 s, so players who keep climbing survive.

## Rules that keep it playable
| Rule | Why |
|---|---|
| Platforms stay 4 studs away from the walls | no getting stuck against the glass |
| No platform less than **8 studs** above or below another one it overlaps | players never bump their head when jumping |
| The space above the 8 arena spawn points is kept free near the floor | nobody is teleported into a platform |
| Each placement tries 12 random spots; if none fits, that route ends there | building never loops forever |

## When it runs
The round system (step 5) got a new signal, **`RoundPreparing`**, fired **before** players are teleported:
```
Intermission ends → RoundPreparing (build platforms) → teleport → RoundStarted (lava) → ... → RoundEnded
```
Platforms stay during the result screen (survivors are still standing on them) and are replaced
before the next round.

`RoundPreparing` handlers must not yield (`task.wait`, `WaitForChild` on missing objects):
`Signal:Fire` runs each handler right away until it yields, so a non-yielding handler is guaranteed
to finish before the teleport. `PlatformService` uses `FindFirstChild` + `assert` instead of
`WaitForChild` for this reason.

## Settings — [`src/shared/Config.luau`](../src/shared/Config.luau)
| Setting | Value | Meaning |
|---|---|---|
| `PLATFORM_PATHS` | 3 | number of climbing routes |
| `PLATFORM_EXTRAS` | 20 | extra random platforms |
| `PLATFORM_TOP_HEIGHT` | 130 | routes climb up to this height above the floor |
| `PLATFORM_MIN_SIZE` / `MAX_SIZE` | 6 / 12 | platform size range (square) |
| `PLATFORM_STEP_UP_MIN` / `MAX` | 3.5 / 5.5 | height step between route platforms |
| `PLATFORM_GAP_MIN` / `MAX` | 1 / 5 | horizontal edge-to-edge gap between route platforms |

Default Roblox characters jump about 7 studs high, so 5.5 up with a 5 stud gap is a real but fair jump.
Make the game easier with smaller steps and gaps, harder with bigger ones.

## Files
| File | Job |
|---|---|
| [`src/server/PlatformService.luau`](../src/server/PlatformService.luau) | Builds the platforms into `Workspace.Arena.Platforms` |
| [`src/server/RoundManager.luau`](../src/server/RoundManager.luau) | New `RoundPreparing` signal, fired before the teleport |
| [`src/server/Main.server.luau`](../src/server/Main.server.luau) | Calls `PlatformService.init()` |

## Check that it works (to do in Studio)
1. Press **Play** and wait for the round to start.
2. The arena is full of green-to-purple platforms. Output shows a line like
   `Platforms built: routes 28, 25, 30 + 18 extras`.
   If a route number is small (under ~20), that route stopped early: tell Claude, the rules may be too strict.
3. Climb: every route can be done with normal jumps; you don't bump your head.
4. Stay above the lava until the end → `<your name> wins!`.
5. Next round: the platforms are different.

## Verified so far
- `rojo build` succeeds and `PlatformService` is included (2026-11-12).
- Not yet run in Studio.
