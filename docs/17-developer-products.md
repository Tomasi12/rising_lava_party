# Step 17 — Developer products: Revive and coin packs

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
Developer products are Robux items that can be bought **again and again**.

| Product | Suggested price | Effect |
|---|---|---|
| **Revive** | 25 Robux | You died but the round is still running: a green **REVIVE** button appears. You come back on a platform at least 15 studs above the lava. Once per round. |
| **500 Coins** | 49 Robux | +500 coins (shown in the shop's Robux section) |
| **2000 Coins** | 149 Robux | +2000 coins |

Revive is usually the best seller in round games: it is cheap and bought in an emotional moment.

### When is the REVIVE button shown?
Only while the round continues after you die. With **2 players**, the round ends as soon as one dies, so
Revive is useful from **3 players** up. If the round ends while the purchase window is open, the player
gets **100 coins** instead (`REVIVE_REFUND_COINS`), so nobody pays for nothing.

## ⚠ You must create the products (on the website)
1. **create.roblox.com → Creations → Rising Lava Party → Monetization → Developer Products → Create**.
2. Name, description, image, **price** → Save.
3. Copy the product **ID**.
4. Paste into [`Config.luau`](../src/shared/Config.luau):
   ```lua
   PRODUCTS = table.freeze({
       REVIVE = 1234567890,
       COINS_500 = 1234567891,
       COINS_2000 = 1234567892,
   }),
   ```
While an ID is `0`, that product is hidden.

## Safety (how purchases are handled)
[`src/server/ProductService.luau`](../src/server/ProductService.luau) is the game's only `ProcessReceipt`:
- It confirms a purchase to Roblox **only after** the item was given **and** the data was saved.
- Every `PurchaseId` is saved in the player's data (`receipts`, last 50), so a purchase is never given twice.
- If the player's data isn't loaded, it answers "not processed yet" and Roblox retries later
  (e.g. next time the player joins). The player never loses a purchase.

## Files
| File | Job |
|---|---|
| [`ProductService.luau`](../src/server/ProductService.luau) | `ProcessReceipt`, Revive, coin packs |
| [`RevivePrompt.client.luau`](../src/client/RevivePrompt.client.luau) | The REVIVE button |
| `LavaService.surfaceY()`, `PlatformService.findSafeSpot()` | Where to put a revived player |
| `RoundManager.canRevive()`, `readmit()` | Put the player back into the round |

## Check that it works (after creating the products)
Purchases in Studio are test purchases (no real Robux). **Data must be loaded** (published place +
API access on), otherwise purchases are not processed.
1. Shop → Robux → **500 Coins** → confirm → `+500 coins. Thank you!`.
2. Revive: Test tab → **3 players** → in a round let player 1 die → **REVIVE** button → buy →
   player 1 appears on a high platform, the message counts them as alive again, the button disappears.
