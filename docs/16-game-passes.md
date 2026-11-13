# Step 16 — Game passes: 2x Coins and VIP

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
Game passes are **one-time Robux purchases**, owned forever. They appear in the shop's **Robux** section.

| Pass | Suggested price | What the player gets |
|---|---|---|
| **2x Coins** | 99–149 Robux | 2× coins from every round |
| **VIP** | 199–299 Robux | VIP Gold trail, a gold **VIP** tag above the head, 1.5× coins |

Both together: 3× coins. The pop-up shows it: `+30 coins (x3)`.

You receive about **70 %** of the price as Robux (Roblox keeps the rest), which you can later cash out via
DevEx (see the second brain note on monetization).

## ⚠ You must create the passes (on the website)
1. **create.roblox.com → Creations → Rising Lava Party → Monetization → Passes → Create a Pass**.
2. Name (`2x Coins`), description, image (512×512, e.g. a big "2x" coin) → **Create Pass**.
3. Open the pass → **Sales** → **Item for sale** on → set the **price** → Save.
4. Copy the pass **ID** (number in the URL, or ⋯ → *Copy Asset ID*).
5. Paste it into [`Config.luau`](../src/shared/Config.luau):
   ```lua
   GAME_PASSES = table.freeze({
       DOUBLE_COINS = 1234567890,
       VIP = 1234567891,
   }),
   ```
6. Same for **VIP**.

While an ID is `0`, that pass is hidden in the shop and switched off.

## How it works
- [`src/server/GamePassService.luau`](../src/server/GamePassService.luau):
  - On join: asks Roblox (`UserOwnsGamePassAsync`) which passes the player owns → attribute `Pass_DOUBLE_COINS` / `Pass_VIP`.
  - After a purchase in the game (`PromptGamePassPurchaseFinished`) the pass works immediately.
  - Gives `CoinService` the coin multiplier, gives `ShopService` the VIP check, adds the VIP tag.
- The shop (client) opens Roblox's purchase window with `PromptGamePassPurchase`; the button shows **Owned** after buying.
- Nothing extra is saved in our DataStore: Roblox keeps track of who owns a pass.

## Check that it works (after creating the passes)
In Studio, purchases are **test purchases**: no real Robux are spent.
1. Open the shop → Robux section shows **2x Coins** and **VIP**.
2. Buy 2x Coins → Roblox window says it's a test purchase → confirm → pop-up `Thank you! Your pass is active.`, button **Owned**.
3. Survive a round → `+20 coins (x2)`.
4. Buy VIP → gold tag above your head, VIP Gold trail can be equipped, survive → `+30 coins (x3)`.
5. Note: in Studio, test-purchased passes are **not remembered** after you stop the test. That's normal.
