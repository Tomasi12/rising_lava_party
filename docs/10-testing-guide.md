# Step 10 — Testing guide (all steps)

Date: 2026-11-12 · Status: **waiting for you to test in Studio**

Steps 4–9 are written and build correctly (`rojo build`), but **none of them has run in Studio yet**.
Follow this guide from top to bottom. Each test says what you should see. If something is different,
copy the red/orange lines from the **Output** window and send them to Claude.

Time needed: about **20–30 minutes**.

---

## A. Prepare (once)

1. **Start Rojo** — in a terminal, in `C:\AI_Claude\Roblox\rising_lava_party`:
   ```bash
   rojo serve
   ```
   (Skip if it is already running.)
2. **Open Studio** and open `RisingLavaParty.rbxl` (the place from step 3).
3. **Connect Rojo:** **Plugins → Rojo → Connect**. If it asks to accept changes, accept.
4. **Open the windows you need:** **View → Output** and **View → Explorer**.
5. **Delete the template spawn** (optional since the review fix, but cleaner):
   Explorer → **Workspace → SpawnLocation** → Delete. Keep `Baseplate`.
6. **For step 9 (saving coins)** — do it now so all tests work:
   - **File → Publish to Roblox** → new experience, name `Rising Lava Party` (stays private).
   - **Home → Game Settings → Security** → **Enable Studio Access to API Services** → on → **Save**.
7. **Ctrl+S** to save.

To make tests faster you can temporarily lower the timers in
[`src/shared/Config.luau`](../src/shared/Config.luau) (Rojo syncs it right away), for example
`INTERMISSION_TIME = 5`, `ROUND_TIME = 40`. **Tell Claude to put them back** after testing.

---

## B. Tests — one player (press Play / F5)

| # | Step | What to do | What you should see | ✓ |
|---|------|------------|---------------------|---|
| 1 | 3 | Press **Play**, look at Output | `Rising Lava Party server started` and `Rising Lava Party client started for <name>` | ☐ |
| 2 | 4 | Look around after spawning | You stand on the **yellow pad** in a green, floating lobby with low glass walls | ☐ |
| 3 | 4 | Walk to the edge | The glass walls stop you from falling off | ☐ |
| 4 | 5 | Look at the top of the screen | `Round starts in 15` counting down | ☐ |
| 5 | 7 | Wait for 0, look at Output | `Platforms built: routes A, B, C + D extras` — all three route numbers ideally **20 or more** | ☐ |
| 6 | 5 | — | You are teleported into the arena (tall glass walls); message `Survive! 90s · 1 alive` | ☐ |
| 7 | 7 | Look around | Lots of square platforms, **green low → purple high** | ☐ |
| 8 | 6 | Stand still on the floor | Thin orange lava on the floor; you are **not** hurt for the first 5 s | ☐ |
| 9 | 6 | Keep standing on the floor | Lava starts rising; you **die** within ~1–2 s, respawn in the lobby; message `Nobody survived!`, then a new countdown | ☐ |
| 10 | 6, 7 | Next round | Lava starts again from the floor; **the platforms are different** | ☐ |
| 11 | 7 | Climb a route | Every jump is possible with normal jumps; you don't bump your head often | ☐ |
| 12 | 8 | Stay above the lava until the time runs out | `<name> survived! +10 coins`; teleported back to the lobby | ☐ |
| 13 | 8 | Open the player list (top right) | Column **Coins** shows `10` | ☐ |
| 14 | 9 | Stop the test (**Shift+F5**), wait 5 s, **Play** again | Coins shows `10` right after joining; no DataStore warnings in Output | ☐ |
| 15 | 9 | Survive once more, stop, Play | Coins `20` and still `20` after restarting | ☐ |

## C. Tests — two players

**Test tab → Clients and Servers → Players: 2 → Start.** Two player windows and a server window open.

| # | Step | What to do | What you should see | ✓ |
|---|------|------------|---------------------|---|
| 16 | 5 | Wait for the countdown | Both players are teleported to **different** spawn points; `Survive! … · 2 alive` | ☐ |
| 17 | 5, 8 | Let player 1 fall into the lava | Round ends right away: `<player 2> wins! +25 coins`; player 2 gets 25 coins | ☐ |
| 18 | 5 | Both die | `Nobody survived!`, nobody gets coins | ☐ |
| 19 | 5 | Close one player window during a round | The round continues/ends normally for the other player, no errors | ☐ |

Close everything with **Cleanup** (Test tab) when done.

## D. Things to look out for
- **Red lines in Output** (errors) — send them to Claude with the step number.
- **Orange warnings:**
  - `Disabled extra SpawnLocation "Workspace.SpawnLocation"` → harmless; delete that spawn to remove the warning.
  - `Loading data for … failed` / `DataStores are not available` → step A6 (publish + API access) is missing.
- **Script Analysis** window (**View → Script Analysis**): shows type warnings in the scripts. Send them to
  Claude too — the code was written in `--!strict` mode but has never been type-checked.
- **Fun check:** Is it too easy/hard? Is the lava too slow/fast? All numbers are in `Config.luau`.

## After testing
Tell Claude which test numbers passed and which failed. Claude will fix the failures,
mark each step **done** in [`docs/README.md`](README.md), commit and push.
