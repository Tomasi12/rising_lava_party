# Step 12 — Round events

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
Before each round one event is picked at random. Players see a red-orange banner under the message.

| Event | Chance | Effect |
|---|---|---|
| Normal | 40 % | nothing special (no banner) |
| ⚡ FAST LAVA! | 20 % | lava rises 1.6× faster |
| ⚡ LOW GRAVITY! | 20 % | gravity 55 % (jump higher, float), lava 1.2× faster to keep it exciting |
| ⚡ TINY PLATFORMS! | 20 % | platforms 65 % of the normal size, lava 0.9× (a bit slower) |

Why: the same round again and again gets boring. Events make every round a little different, which keeps
players for "one more round".

## Change or add events
- All events are in [`src/shared/RoundEvents.luau`](../src/shared/RoundEvents.luau): title, description,
  `weight` (how often), `lavaSpeed`, `gravity`, `platformSize`.
- Switch all events off: `EVENTS_ENABLED = false` in [`Config.luau`](../src/shared/Config.luau).

## How it works
| File | Job |
|---|---|
| [`src/server/EventService.luau`](../src/server/EventService.luau) | Picks the event on `RoundPreparing`, sets the gravity, writes the event id into `RoundState.Event`; back to Normal on `RoundEnded` |
| `LavaService` | Lava speed × `lavaSpeed` |
| `PlatformService` | Platform size × `platformSize`; Output line now ends with `(event: FastLava)` etc. |
| `RoundHud.client` | Shows the banner while the round runs |

`EventService.init()` runs before `PlatformService.init()` in `Main.server.luau`, so the platforms are built
for the right event (round-preparing handlers run in the order they were connected).

## Check that it works
1. Play several rounds. Output shows `Platforms built: ... (event: <name>)`.
2. When the event isn't `Normal`, the banner appears under the message.
3. Low Gravity: you jump much higher. Tiny Platforms: small platforms. Fast Lava: lava clearly faster.
4. After a Low Gravity round, jumping in the lobby is normal again.
