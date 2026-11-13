# Step 24 — Map 3: Moon Base (low gravity)

Date: 2026-11-13 · Status: **in progress** (code written, waiting for your play test)

## Idea (from the user)
"A new map with low gravity like on the moon, so you don't have very good control. Then we have 3 maps."

## What it does
| | Moon Base |
|---|---|
| Gravity | **40 %** of normal: you float and jump ~2.5× higher |
| Control | platforms are **slippery** (low friction): you slide a little when you land |
| Platforms | 2 studs thick, any size; **farther apart and higher** (steps up to ~9 studs, gaps up to ~8.5) so you need the big moon jumps |
| Head room | 20 studs (instead of 12), because you jump much higher |
| Look | grey moon rock (Slate) low, light concrete in the middle, blue-grey metal near the top |
| Arena | slate floor, dark blue glass walls |
| Sky | night, dark sky with stars |

- The banner says `Map: Moon Base (low gravity!)`.
- On the Moon map, events that change gravity (**Low Gravity**) are skipped: the map is already low gravity.
  Fast Lava and Tiny Platforms can still happen.
- When the round ends, gravity goes back to normal in the lobby.
- All 3 maps (Blocky World, Volcano, Moon Base) are picked with the same chance.

## How it works
| File | Change |
|---|---|
| [`Themes.luau`](../src/shared/Themes.luau) | New theme `MoonBase`. Every theme now also has `gravity`, `jumpScale`, `headRoom`, `slippery`. |
| [`PlatformService.luau`](../src/server/PlatformService.luau) | Step-up heights and gaps × `jumpScale`; head room from the theme; slippery platforms get low friction (`CustomPhysicalProperties`) |
| [`EventService.luau`](../src/server/EventService.luau) | Gravity = normal × event × map; skips gravity events on low-gravity maps; normal gravity after the round |
| [`Main.server.luau`](../src/server/Main.server.luau) | `ThemeService.init()` now runs **before** `EventService.init()` (the map is picked first) |

## Tuning (in `Themes.luau`, MoonBase block)
- Less / more floaty: `gravity` (0.3 = very floaty, 0.6 = a bit floaty).
- Platforms closer / farther: `jumpScale`.
- Less slippery: set `slippery = false`.

## What to try (just play)
1. Play rounds until you get `Map: Moon Base` (1 in 3).
2. Jump: very high and slow. Land: you slide a bit.
3. Tell Claude: fun or too hard? More or less floaty? Too slippery?
