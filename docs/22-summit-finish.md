# Step 22 — Summit finish and a 4x higher tower

Date: 2026-11-13 · Status: **in progress** (code written, waiting for your play test)

## Why
Play test feedback (2026-11-13):
- "I reach the top in 20 seconds and wait." → the round had no goal at the top.
- With crumbling platforms: "after 4 seconds the platforms are eaten by lava" → staying alive at the top
  became impossible, which is frustrating.
- "I want more platforms, the cube 4x higher, more routes to reach the top."

So the goal of a round changes from **"survive 90 seconds"** to **"reach the top before the lava gets you"**.

## What changed

### New goal: the golden SUMMIT
- A big golden, glowing platform (24 × 24) in the middle at the top, with a **FINISH** sign visible from below.
- Stand on it → you **finish**: pop-up `You reached the top FIRST!` (or `2nd`, `3rd`, ...) and the victory sound.
- It never crumbles, and the lava stops **below** it. On the summit you are safe.
- When you finish, the camera can watch the players still climbing (spectate).

### Round rules
| | Before | Now |
|---|---|---|
| Goal | stay alive | reach the summit |
| Round ends | time up / one player left | **everyone finished or out**, or time up (240 s) |
| Coins | +10 for alive players, +15 for last standing | **+10** for everyone who reaches the summit, **+15** extra for the **first** (with 2+ players) |
| Wins | +1 for alive at the end | **+1 for reaching the summit** |
| Message | `Survive! 45s · 3 alive` | `Reach the top! 120s · 2 at the top` |
| Result | `Alex wins!` | `Alex wins! 3 reached the top` / `Nobody reached the top!` |

Climbers who are still on the way when the time runs out get nothing and go back to the lobby.

### Bigger arena (4x higher, wider)
| | Before | Now |
|---|---|---|
| Floor | 100 × 100 | **160 × 160** |
| Walls | 150 high | **600 high** |
| Platforms up to | 130 | **520** (summit at 524) |
| Routes | 3 | **8** |
| Extra platforms | 20 | **150** |
| Lava | 1.2 studs/s, max 140 | **2.3 studs/s** after 8 s, max **510** |

A route that gets stuck now **backtracks** (tries again from an earlier platform of the same route), and
near the top it turns toward the summit and ends one jump away from it. Output shows for each round, e.g.:
`Platforms built: routes 131, 118, ... + 150 extras; 7/8 routes reach the summit (event: Normal)`.

Round events were softened for the long climb: Fast Lava 1.25× (was 1.6×), Low Gravity lava 1.15×.

## Files
| File | Change |
|---|---|
| [`Arena.model.json`](../src/workspace/Arena.model.json) | 160 × 160 floor, 600-high walls |
| [`PlatformService.luau`](../src/server/PlatformService.luau) | Summit, routes to the summit, backtracking, faster overlap check (height bands), `isOnSummit` |
| [`SummitService.luau`](../src/server/SummitService.luau) | **new**: checks 5×/s who stands on the summit → `RoundManager.finish` |
| [`RoundManager.luau`](../src/server/RoundManager.luau) | New round rules, `finish`, `getClimbers`; everyone alive goes back to the lobby |
| [`CoinService.luau`](../src/server/CoinService.luau) | Bonus for the first at the summit |
| `Sounds.client`, `RevivePrompt.client` | Victory sound on finishing; no Revive button after finishing |
| [`Config.luau`](../src/shared/Config.luau), [`RoundEvents.luau`](../src/shared/RoundEvents.luau) | New numbers |

## What to try (just play)
1. Look up from the arena floor: a very tall tower of platforms, the golden FINISH sign at the top.
2. Climb. Platforms crumble behind you, the lava follows.
3. Reach the summit: pop-up, victory sound, round ends (alone) → `+10 coins`.
4. Tell Claude:
   - Is the climb too long / too short? (`PLATFORM_TOP_HEIGHT`)
   - Is the lava too fast / too slow? (`LAVA_RISE_SPEED`)
   - Are there enough routes? What does the Output line say (`x/8 routes reach the summit`)?

## Known for later
- The arena floor is lava from the start ("not nice to run on lava and then burn") → next step: the ground.
