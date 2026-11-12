# Step 1 — Install Rojo

Date: 2026-11-12 · Status: **done**

## Why
Rojo syncs the code from this repository (normal `.luau` files on disk) into Roblox Studio live.
That way the code is edited in files, versioned in Git, and Studio always runs the latest version.

## What we installed

| Tool | Version | What it is | Where |
|---|---|---|---|
| **Rokit** | 1.2.0 | Tool manager for Roblox tools. Installs the exact tool versions a project needs. | `%USERPROFILE%\.rokit\bin` (added to the user PATH) |
| **Rojo** | 7.7.1 | Syncs files on disk ↔ Roblox Studio | Managed by Rokit, pinned in `rokit.toml` |
| **Rojo Studio plugin** | matches Rojo 7.7.1 | The "Rojo" button inside Studio that connects to `rojo serve` | `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` |

Sources: https://github.com/rojo-rbx/rokit and https://github.com/rojo-rbx/rojo

## How it was done
1. Downloaded `rokit-1.2.0-windows-x86_64.zip` from the Rokit GitHub releases, unzipped it, and ran:
   ```bash
   rokit.exe self-install
   ```
   This installs Rokit into `%USERPROFILE%\.rokit\bin` and adds it to PATH.
2. In the repository folder, created the tool list and added Rojo:
   ```bash
   rokit init
   rokit trust rojo-rbx/rojo
   rokit add rojo-rbx/rojo@7.7.1
   ```
   This created [`rokit.toml`](../rokit.toml), which pins Rojo to 7.7.1.
3. Installed the Studio plugin (must run inside the repository folder):
   ```bash
   rojo plugin install
   ```

## Check that it works
Open a **new** terminal (so PATH is refreshed), go to the repository folder and run:
```bash
rojo --version
```
Expected: `Rojo 7.7.1`.

In Roblox Studio (restart it if it was open), open any place → **Plugins** tab → a **Rojo** button is there.

## Setting up on another PC
1. Install Rokit (step 1 above).
2. In the repository folder: `rokit install` (installs the tools listed in `rokit.toml`).
3. `rojo plugin install`.

## Notes
- `rojo` only works **inside the repository folder**, because Rokit reads the version from `rokit.toml`.
  Outside it you get: `Failed to find tool 'rojo' in any project manifest file`.
- `rokit add` asks to trust a new tool. In a non-interactive terminal, run `rokit trust <tool>` first.
