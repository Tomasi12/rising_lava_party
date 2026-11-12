# Step 8 — Coins and leaderboard

Date: 2026-11-12 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
- Every player has **Coins**, shown on the Roblox player list (top right of the screen).
- At the end of a round:
  - every **survivor** gets **+10 coins**,
  - the **last player standing** gets **+15 extra** (only when 2 or more players took part, so you can't farm it alone).
- The result message shows the reward: `Alex wins! +25 coins`, `Alex survived! +10 coins`,
  `3 players survived! +10 coins`.
- Coins are not saved yet when you leave: that's step 9.

## Settings — [`src/shared/Config.luau`](../src/shared/Config.luau)
| Setting | Value | Meaning |
|---|---|---|
| `COINS_SURVIVE` | 10 | coins for every survivor |
| `COINS_WIN_BONUS` | 15 | extra for the last player standing (2+ players) |

## Files
| File | Job |
|---|---|
| [`src/server/CoinService.luau`](../src/server/CoinService.luau) | Creates `leaderstats/Coins`, gives rewards, `get` / `set` / `add` for other modules |
| [`src/server/RoundManager.luau`](../src/server/RoundManager.luau) | `RoundEnded` now also passes the participants; result message shows coins |
| [`src/server/Main.server.luau`](../src/server/Main.server.luau) | Calls `CoinService.init()` |

## How it works
- **Leaderboard:** Roblox shows any `IntValue` inside a folder named exactly `leaderstats` under the
  `Player` object. `CoinService.ensureLeaderstats(player)` creates it (safe to call many times).
- **Rewards:** `CoinService` listens to `RoundManager.RoundEnded(survivors, participants)`.
- **Server only:** coins are changed only by server code, through `CoinService.add/set`. Values never go below 0
  and are whole numbers.
- Players who are already in the server when the script starts (normal in Studio) also get their leaderstats.

## Changes to the round system (step 5)
- `RoundEnded` now fires with **two** lists: `(survivors, participants)`.
- If nobody could take part (everyone was respawning), the round is skipped: no `RoundEnded`, no result,
  just a new countdown. Before, it showed `Nobody survived!` for an empty round.

## Check that it works (to do in Studio)
1. Press **Play**. The player list (top right) shows a **Coins** column with `0`.
2. Survive a round (climb above the lava until the time runs out).
   Result: `<your name> survived! +10 coins`, and Coins shows `10`.
3. Die in a round: Coins doesn't change.
4. With 2 players (**Test → Clients and Servers → 2 players → Start**): when one dies and the other is
   the last one standing, the winner gets `+25`.

## Verified so far
- `rojo build` succeeds and `CoinService` is included (2026-11-12).
- Not yet run in Studio.
