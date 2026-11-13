# Step 14 — Wins, daily reward, badges

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

Goal: give players reasons to **come back** (retention). Roblox recommends games with good retention
more often, and returning players are the ones who spend.

## Wins
- New column **Wins** on the player list, next to Coins.
- +1 every time you are alive at the end of a round (alone or with others).
- Saved like coins. Used by the badges and by the global leaderboard (step 18).

## Daily reward
- The first time you join on a new day (UTC), you get coins and a pop-up `Daily reward, day 3: +30 coins`.
- Streak: day 1 = 10, day 2 = 20, … day 7 and later = 70. Missing a day starts at day 1 again.
- Only given after your saved data loaded, so it can't be given twice.
- Numbers: `DAILY_REWARD_BASE` and `DAILY_REWARD_MAX_STREAK` in [`Config.luau`](../src/shared/Config.luau).

## Badges
| Badge | When |
|---|---|
| Welcome | first time in the game |
| First win | 1 win |
| 10 wins | 10 wins |
| 100 wins | 100 wins |

### ⚠ You must create the badges (on the website)
Badges can't be created from code.
1. Go to **create.roblox.com → Creations → Rising Lava Party → Monetization/Engagement → Badges**
   (menu names change sometimes: look for **Badges**).
2. **Create a Badge**: name, description, a square image (512×512). Roblox lets you create a few badges per
   day for free.
3. Copy the **badge ID** (number in the badge URL or in the badge's menu → *Copy Asset ID*).
4. Paste it in [`Config.luau`](../src/shared/Config.luau) under `BADGES`, e.g. `WELCOME = 1234567890,`.

A badge with ID `0` is skipped, so the game works before you create them.
Badges are only awarded in a **published** game (also works in Studio tests of the published place).

## What changed in the code
| File | Change |
|---|---|
| [`DataService.luau`](../src/server/DataService.luau) | Saves more: `wins`, `owned`, `equippedTrail`, `dailyDay`, `dailyStreak`, `receipts`. New: `DataService.get(player)` (session data), `Loaded` signal, `saveNow`. Old saves (only coins) load fine. |
| [`CoinService.luau`](../src/server/CoinService.luau) | Wins column, `spend`, `getWins/setWins`, `WinAdded` signal, coin multiplier hook for 2x Coins |
| [`DailyRewardService.luau`](../src/server/DailyRewardService.luau) | Daily reward |
| [`BadgeService.luau`](../src/server/BadgeService.luau) | Awards badges |
| [`Main.server.luau`](../src/server/Main.server.luau) | Init order: Coin → Badge → DailyReward → Data → Event → Platform → Lava → Round |

## Check that it works
1. Play: pop-up `Daily reward, day 1: +10 coins` after ~3 s (once per day; to test again, see below).
2. Survive a round: Wins 1.
3. Stop, Play: Coins and Wins are still there; no daily reward again today.
4. To test the daily reward again: change `STORE_NAME` in DataService to `PlayerData_test` for a moment
   (fresh data), **then change it back**.
