# What to do now

Updated: 2026-11-13 (plan 2 · steps 11–20)

**Where we are:** the first version works (steps 1–10, tested). Claude added steps 11–18:
sounds, round events, spectate, wins, daily reward, badges, shop with trails, Robux items and a global
leaderboard. **None of it has run in Studio yet.**

Your job now: test it, then create the Robux items. Tick each box ☐ → ☑.

---

## Part 1 — Get the new code into Studio (2 min)

### ☐ 1. Rojo
- Is Rojo still **connected** in Studio (Rojo panel says *Connected*)? → go to 2.
- If not: in a terminal
  ```
  cd C:\AI_Claude\Roblox\rising_lava_party
  rojo serve
  ```
  then in Studio **Plugins → Rojo → Connect**.

### ☐ 2. Check that the new scripts arrived
In **Explorer**:
- `ServerScriptService → Server` has new scripts like `ShopService`, `EventService`, `ProductService`.
- `Workspace → Lobby` has a new part `Leaderboard`.

---

## Part 2 — Test (30–40 min)

Open **[20-testing-guide-2.md](20-testing-guide-2.md)** and do tests 1–19 (one player and several players).
- Tests 20–23 need the Robux items (Part 3). Skip them for now.
- Test 24 is the phone check.

💡 **Tip:** give yourself coins to test the shop. While playing, in the Output window's command bar
(set to **Server**):
```
game.Players:GetPlayers()[1].leaderstats.Coins.Value = 2000
```

---

## Part 3 — Create Robux items and badges (20 min, on the website)

Create these on **create.roblox.com → Creations → Rising Lava Party → Monetization**.
Each doc has the exact clicks:

| ☐ | What | How many | Doc |
|---|---|---|---|
| ☐ | Game passes: **2x Coins**, **VIP** | 2 | [16-game-passes.md](16-game-passes.md) |
| ☐ | Developer products: **Revive**, **500 Coins**, **2000 Coins** | 3 | [17-developer-products.md](17-developer-products.md) |
| ☐ | Badges: Welcome, First win, 10 wins, 100 wins | up to 4 | [14-wins-daily-badges.md](14-wins-daily-badges.md) |

**Send Claude the IDs** (just the numbers, with the name of each item). Claude puts them into `Config.luau`.
Then do tests 20–23.

---

## Part 4 — Send Claude the results

```
Passed: 1 2 3 ...
Failed: 7 — never saw an event banner
Errors: (red/orange lines from Output, or a photo)
IDs: 2x Coins = ..., VIP = ..., Revive = ..., 500 Coins = ..., 2000 Coins = ..., badges = ...
Fun: ...
```

Claude fixes the problems, marks the steps done, commits and pushes.

---

## Later: launch
When everything works: the checklist in [19-mobile-and-launch.md](19-mobile-and-launch.md)
(icon, thumbnails, description, make it public, ads).
