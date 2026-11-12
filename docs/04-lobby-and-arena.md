# Step 4 — Lobby and arena

Date: 2026-11-12 · Status: **in progress** (waiting for the check in Studio)

## Decision: the base map is in files, not hand-built
The plan said "build the lobby and arena in Studio by hand". We changed that:
the **base geometry** (floors, walls, spawn points) is defined in Rojo model files, so that
- sizes and positions are exact, and the round scripts (steps 5–7) can rely on them,
- the map is versioned in Git together with the code,
- the same map is rebuilt on any PC.

**Decorations** (trees, signs, lights, effects) are still added by hand in Studio — see "Rules" below.

## Files
| File | Becomes | Contents |
|---|---|---|
| [`src/workspace/Lobby.model.json`](../src/workspace/Lobby.model.json) | `Workspace.Lobby` | Floor, `LobbySpawn`, 4 low glass walls |
| [`src/workspace/Arena.model.json`](../src/workspace/Arena.model.json) | `Workspace.Arena` | Floor, 4 tall glass walls, `SpawnPoints` folder, empty `Platforms` folder |

Both are mapped in [`default.project.json`](../default.project.json) under `Workspace`.

## Layout (studs)

```
            side view (not to scale)

  y=200  ┌──── Lobby (60 x 60) ────┐          players wait here
         └─────────────────────────┘

  y=152               ┌─ walls top ─┐
                      │             │
                      │    Arena    │        lava will rise from the floor
  y=2                 └─ floor ─────┘
         x=0                      x=300
```

### Lobby — centered at (0, 200, 0), floating in the sky
| Part | Size | Position (center) | Notes |
|---|---|---|---|
| `Floor` | 60 × 2 × 60 | (0, 199, 0) | top surface at y = 200, grass |
| `LobbySpawn` | 8 × 1 × 8 | (0, 200.5, 0) | SpawnLocation, `Neutral`, no force field (`Duration` 0) |
| `WallNorth` / `WallSouth` | 62 × 10 × 2 | (0, 205, ∓31) | glass-like, stops players falling off |
| `WallEast` / `WallWest` | 2 × 10 × 60 | (±31, 205, 0) | |

### Arena — centered at (300, 0, 0), on the ground
| Part | Size | Position (center) | Notes |
|---|---|---|---|
| `Floor` | 100 × 2 × 100 | (300, 1, 0) | top surface at y = 2, basalt |
| `WallNorth` / `WallSouth` | 104 × 150 × 2 | (300, 77, ∓51) | from y = 2 to y = 152, 70 % transparent |
| `WallEast` / `WallWest` | 2 × 150 × 100 | (300 ± 51, 77, 0) | |
| `SpawnPoints/Spawn1..8` | 4 × 1 × 4 | ring of radius ~35 at y = 5 | invisible, no collision; players are teleported here when a round starts |
| `Platforms` | folder | — | empty; step 7 fills it with random platforms each round |

The playable area inside the walls is 100 × 100 studs, from x = 250 to 350 and z = −50 to 50.

## One manual change in Studio
The **Baseplate** template comes with its own `SpawnLocation` in `Workspace` (at the center, on the ground).
Players could spawn there instead of in the lobby.
→ In Explorer, select **Workspace → SpawnLocation** and **delete** it. Keep the `Baseplate`.
Then **Ctrl+S** to save the place.

## Rules
- **Don't move or resize** the parts inside `Lobby` and `Arena` in Studio: Rojo overwrites them from the files.
  To change them, change the `.model.json` files (ask Claude).
- **Decorations**: put them in a separate model/folder in `Workspace`, for example `Workspace.Decor`.
  Rojo doesn't manage it, so it is never overwritten. It is saved in the place file (`RisingLavaParty.rbxl`), not in Git.

## Check that it works
1. `rojo serve` is running; in Studio, Rojo is **connected** (reconnect if it was disconnected).
2. Explorer shows `Workspace → Lobby` and `Workspace → Arena`.
3. Delete the default `Workspace → SpawnLocation` (see above).
4. Press **Play**: you spawn on the yellow pad in the floating lobby.
5. In the editor (not playing), you can see the arena on the ground to the east (x = 300).

## Notes for property formats (Rojo `.model.json`)
- `CFrame` uses the explicit form `{ "CFrame": { "position": [...], "orientation": [[...],[...],[...]] } }`.
- Enums use the explicit numeric form `{ "Enum": <number> }`. Values used: Material Grass = 1280,
  Basalt = 788; SurfaceType Smooth = 0.
- `Size` and `Color` use plain arrays: `[x, y, z]` and `[r, g, b]` with values 0–1.
