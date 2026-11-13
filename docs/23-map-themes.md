# Step 23 — Map themes: Blocky World and Volcano

Date: 2026-11-13 · Status: **in progress** (code written, waiting for your play test)

## Idea (from the user)
"What if we have multiple maps and go into them at random? Start with two. The first should have a
Minecraft theme."

## Important: our own style, not a copy
We **don't** use Minecraft's name, textures, characters or exact look. That's someone else's property, and
Roblox removes games that copy it. A **blocky / voxel style** (cubes, grass, dirt, stone, wood, a sunny sky) is
a common style that anyone may use. So map 1 is our own **"Blocky World"**.

## The two maps
| | Blocky World | Volcano |
|---|---|---|
| Platforms | thick **cubes** (4 studs), 8 or 12 wide, on a **4-stud grid** | thin slabs (1 stud), any size 6–12, free placement |
| Look by height | cobblestone → dirt → grass → wood planks → sand | green → purple |
| Arena floor | grass | basalt |
| Walls | light blue glass | orange glass |
| Sky | bright noon | orange evening, warm fog |

- Each round picks one at random (50/50, `weight` in the theme list).
- The banner at the top shows the map, e.g. `Map: Blocky World  ·  ⚡ LOW GRAVITY! Jump higher and float`.
- After the round the sky goes back to the lobby look.
- Output shows it too: `... (map: BlockyWorld, event: Normal)`.
- The rules don't change: crumbling platforms, lava, golden summit, coins all work the same on every map.

## How it works
| File | Job |
|---|---|
| [`src/shared/Themes.luau`](../src/shared/Themes.luau) | **new**: the list of themes (platform thickness, grid, sizes, materials by height, floor, walls, sky) |
| [`src/server/ThemeService.luau`](../src/server/ThemeService.luau) | **new**: picks the theme before each round, changes floor, walls and sky; writes `RoundState.Theme` |
| [`PlatformService.luau`](../src/server/PlatformService.luau) | builds platforms in the theme's style; snaps to the grid; re-checks that every route step is still jumpable after snapping; head room adapts to the platform thickness |
| `RoundHud.client` | shows the map name in the banner |

## Add a third map later
Copy a block in `Themes.luau`, give it a new `id` and `title`, change the look. Ideas: Candy Land, Ice Cave,
Space Station, Jungle Temple.

## What to try (just play)
1. Play a few rounds: you should get both maps (banner and Output say which).
2. Blocky World: cube blocks, materials change as you climb, bright sky. Can you still climb comfortably?
   (Blocks are thicker, so they look closer together.)
3. Tell Claude: do you like the blocky look? What would make it better? Which third map would you like?
