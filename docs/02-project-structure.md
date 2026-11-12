# Step 2 — Rojo project structure

Date: 2026-11-12 · Status: **done**

## Why
Rojo needs a project file that says which folder on disk goes where in the Roblox game.
We keep **code in files** (this repo) and **the map / 3D parts in Studio**.

## Folder layout

```
rising_lava_party/
├── default.project.json   ← Rojo project: maps folders → Roblox services
├── rokit.toml             ← tool versions (Rojo 7.7.1)
├── src/
│   ├── server/            → ServerScriptService.Server            (runs on the server only)
│   │   └── Main.server.luau
│   ├── client/            → StarterPlayer.StarterPlayerScripts.Client (runs on each player's device)
│   │   └── Main.client.luau
│   └── shared/            → ReplicatedStorage.Shared              (modules used by both)
│       └── Config.luau
└── docs/                  ← this documentation
```

## File name rules (Rojo)
| File name | Becomes in Roblox | Runs where |
|---|---|---|
| `Name.server.luau` | `Script` | Server |
| `Name.client.luau` | `LocalScript` | Player's device |
| `Name.luau` | `ModuleScript` | Wherever it is `require`d |

## The files
- [`default.project.json`](../default.project.json) — the mapping above. Each service has
  `"$ignoreUnknownInstances": true`, so things you build in Studio (lobby, arena parts) are **not deleted**
  by Rojo. `Workspace` started with no `$path`. Since step 4 it also holds the base map (`Lobby`, `Arena`) from
  `src/workspace/`; see [step 4](04-lobby-and-arena.md).
- [`src/shared/Config.luau`](../src/shared/Config.luau) — one place for all game settings (names, timers,
  rewards). Frozen with `table.freeze` so scripts can't change it by accident.
- [`src/server/Main.server.luau`](../src/server/Main.server.luau) — server entry point. For now it prints
  `Rising Lava Party server started`.
- [`src/client/Main.client.luau`](../src/client/Main.client.luau) — client entry point. Prints
  `Rising Lava Party client started for <player name>`.
- [`.gitignore`](../.gitignore) — keeps built place files (`*.rbxl`, `*.rbxlx`), Studio lock files and
  generated files out of Git.

All scripts start with `--!strict` so Luau's type checker checks them fully.

## Check that it works
In the repository folder:
```bash
rojo build -o test.rbxlx
```
Expected: `Built project to test.rbxlx` (the file is ignored by Git; you can delete it).

```bash
rojo serve
```
Expected: `Rojo server listening: Address: localhost Port: 34872`. Stop it with `Ctrl+C`.

Both were run on 2026-11-12 and worked.
