# Step 3 — Connect Roblox Studio to Rojo

Date: 2026-11-12 · Status: **in progress** (waiting for the test in Studio)

## Why
Once Studio is connected, every change to the files in `src/` shows up in Studio within a second.
No copy-paste of code into Studio.

## Every time you work on the game
1. **Start the Rojo server** in the repository folder and leave it running:
   ```bash
   rojo serve
   ```
   Expected: `Rojo server listening ... Port: 34872`.
2. **Open the place in Studio.**
   - First time: **New** → **Baseplate**, then **File → Save to File As…** →
     save it as `RisingLavaParty.rbxl` (anywhere outside this repo, or inside: `*.rbxl` is ignored by Git).
     Later we will publish it to Roblox and use **Save to Roblox** instead.
   - Next times: open that same place.
3. **Connect:** **Plugins** tab → **Rojo** → in the Rojo window click **Connect**
   (address `localhost`, port `34872`, the defaults).
   The window shows `Connected` and the project name `RisingLavaParty`.
4. If Rojo asks to accept changes, accept them: the scripts from `src/` are added to the place.

## Check that it works
1. Open the **Output** window: **View** tab → **Output**.
2. Press **Play** (F5).
3. Expected in Output:
   ```
   Rising Lava Party server started
   Rising Lava Party client started for <your Roblox name>
   ```
4. Stop the playtest (Shift+F5).

In the **Explorer** window you should see:
- `ServerScriptService → Server → Main`
- `StarterPlayer → StarterPlayerScripts → Client → Main`
- `ReplicatedStorage → Shared → Config`

## Rules while connected
- **Edit code only in the files** (`src/`), not inside Studio. Rojo overwrites script changes made in Studio.
- **Build the map in Studio** (parts, models, lighting). Rojo does not touch those
  (`$ignoreUnknownInstances` in `default.project.json`).
- Save the place in Studio regularly (**Ctrl+S**). The map lives in the place file, not in Git.

## Problems
| Problem | Fix |
|---|---|
| Rojo button missing | Restart Studio. Check `%LOCALAPPDATA%\Roblox\Plugins\RojoManagedPlugin.rbxm` exists, else run `rojo plugin install` in the repo folder. |
| "Couldn't connect" | `rojo serve` is not running, or another program uses port 34872. |
| Version mismatch warning | Run `rojo plugin install` again so the plugin matches Rojo 7.7.1. |
| Script errors about `Shared.Config` | Rojo is not connected, so `ReplicatedStorage.Shared` doesn't exist yet. |
