# Step 21 — Crumbling platforms

Date: 2026-11-13 · Status: **in progress** (code written, waiting for your play test)

## Why
Playtest feedback (2026-11-13): "I reach the top in 20 seconds and then wait." The round had a safe place
and nothing to do. This is the first gameplay change of "v2": **you can't stand still anymore.**
We do one change at a time and play it before the next one.

## What it does
- You land on a platform → it **shakes** and slowly turns **red**.
- After **2 seconds** it **falls away** and fades out. If you're still on it, you fall.
- It **comes back 4 seconds later** (fades in) and can crumble again. So there is always somewhere to
  jump, but you can never stand still.
  (First version: platforms never came back, so at the top you were forced into the lava.
  Play test 2026-11-13: "annoying". Falling should be your own mistake, not unavoidable.)
- Only real landings count (your body above the platform), not brushing its side while jumping past.

## Settings ([`Config.luau`](../src/shared/Config.luau))
| Setting | Default | Meaning |
|---|---|---|
| `CRUMBLE_ENABLED` | `true` | switch the feature off |
| `CRUMBLE_DELAY` | `2` | seconds from landing until it falls (lower = harder) |
| `CRUMBLE_FALL_TIME` | `0.6` | length of the fall animation |
| `CRUMBLE_RESPAWN_TIME` | `4` | seconds until a fallen platform comes back |

## Files
| File | Job |
|---|---|
| [`src/server/PlatformCrumble.luau`](../src/server/PlatformCrumble.luau) | Detects the landing (`Touched`), shakes, turns red, drops the platform |
| [`src/server/PlatformService.luau`](../src/server/PlatformService.luau) | Calls `PlatformCrumble.attach(part)` for every new platform |

## What to try (10 minutes, just play)
1. Climb normally: each platform shakes and falls ~2 s after you land.
2. Stand still on one: you fall.
3. Questions for you:
   - Is 2 seconds fun, too hard, or too easy? (try `CRUMBLE_DELAY = 1.5` or `3`)
   - Can you still reach the top? Do you still end up waiting there?
