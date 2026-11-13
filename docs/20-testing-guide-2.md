# Step 20 — Testing guide for steps 11–18

Date: 2026-11-13 · Status: **waiting for you to test in Studio**

None of steps 11–18 has run in Studio yet. Do the tests in order. If something is different,
send Claude the test number and the red/orange lines from **Output** (or a screenshot).

Before you start: Rojo connected, Output open (Window → Output).

💡 Coins for testing: while playing, switch Output's command bar to the **server** and run
`game.Players:GetPlayers()[1].leaderstats.Coins.Value = 2000`

## One player (F5)
| # | Step | What to do | What you should see | ✓ |
|---|---|---|---|---|
| 1 | — | Press Play, look at Output | `server started`, no red lines | ☐ |
| 2 | 14 | Wait ~3 s | Pop-up `Daily reward, day 1: +10 coins` (only the first time today) | ☐ |
| 3 | 14 | Player list (top right) | Columns **Coins** and **Wins** | ☐ |
| 4 | 18 | Look at the north side of the lobby | Dark board `TOP 10 · MOST WINS` | ☐ |
| 5 | 11 | Countdown 5…1 | A tick sound each second | ☐ |
| 6 | 11 | Round starts | "Ping" sound; lava with cracks, sparks and orange light | ☐ |
| 7 | 12 | Play 4–5 rounds | Sometimes a banner `⚡ FAST LAVA!` / `LOW GRAVITY!` / `TINY PLATFORMS!`; Output shows `(event: …)` | ☐ |
| 8 | 12 | Low Gravity round | You jump much higher; after the round, normal jumps in the lobby | ☐ |
| 9 | 11, 14 | Survive a round | Victory sound, pop-up `+10 coins`, Wins +1 | ☐ |
| 10 | 15 | Click **SHOP** | Window with 6 trails and your coins; VIP Gold says `VIP only` | ☐ |
| 11 | 15 | Buy a trail with too few coins | Red pop-up `Not enough coins (need …)` | ☐ |
| 12 | 15 | Give yourself coins, buy Ember | `Bought Ember!`, button `Equipped`, a trail follows you | ☐ |
| 13 | 15 | Die and respawn | Trail still there | ☐ |
| 14 | 15 | Click `Equipped` | Trail gone, button `Equip` | ☐ |
| 15 | 9, 14, 15 | Stop, wait 5 s, Play | Coins, Wins, owned trails still there; no second daily reward | ☐ |
| 16 | 18 | Stay ~60 s in the lobby after a win | Your name on the board | ☐ |

## Several players (Test tab → Clients and Servers)
| # | Step | What to do | What you should see | ✓ |
|---|---|---|---|---|
| 17 | 13 | **3 players**, let player 1 die | Player 1's camera follows another player; bar `◀ Watching: … ▶ ✕` | ☐ |
| 18 | 13 | ◀ / ▶ / ✕ | Switches player / camera back to you | ☐ |
| 19 | 15 | Player 1 with a trail | The other windows see the trail too | ☐ |

## Robux (only after creating the items, steps 16–17; test purchases are free)
| # | Step | What to do | What you should see | ✓ |
|---|---|---|---|---|
| 20 | 16 | Shop → Robux → 2x Coins → buy | `Thank you! Your pass is active.`, button `Owned`; next win `+20 coins (x2)` | ☐ |
| 21 | 16 | Buy VIP | Gold `VIP` above your head; VIP Gold trail can be equipped | ☐ |
| 22 | 17 | Buy 500 Coins | `+500 coins. Thank you!` | ☐ |
| 23 | 17 | 3 players, player 1 dies | Green **REVIVE** button; buy → back on a high platform, counted alive again | ☐ |

## Phone (step 19 A)
| # | What to do | What you should see | ✓ |
|---|---|---|---|
| 24 | Test → Device → a phone → Play | Everything readable and tappable (see the list in step 19) | ☐ |

## Also send
- **Script Analysis** window (Window → Script Analysis): any warnings in our scripts.
- **Fun check:** which event is the most fun? Are trails too cheap / too expensive?
