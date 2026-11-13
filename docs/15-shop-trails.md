# Step 15 — Shop: trails bought with coins

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
- A yellow **SHOP** button on the left side of the screen opens the shop.
- **Trails**: a colored streak that follows you when you move. Bought with coins, saved forever.

| Trail | Price |
|---|---|
| Ember | 100 coins |
| Ocean | 150 |
| Toxic | 250 |
| Galaxy | 400 |
| Rainbow | 800 |
| VIP Gold | only with the VIP pass (step 16) |

Buttons: `100 coins` = buy (and wear it right away) → `Equip` → `Equipped` (press again to take it off).
Pop-ups tell you the result: `Bought Ember!`, `Not enough coins (need 250)`, ...

Why: coins need a use, or players stop caring about them. Trails are seen by everyone in the round,
which makes others want them too. This prepares the Robux shop (steps 16–17) in the same window.

## Safety
- The **server** checks price and ownership. The client only shows buttons, so cheaters can't get free items.
- You can't buy while your saved data isn't loaded (otherwise the item could be lost).
- Item `id`s are saved in the player's data: **never rename an id** after the game is public.

## Add or change trails
Edit [`src/shared/ShopItems.luau`](../src/shared/ShopItems.luau): copy a block, new unique `id`, `name`,
`price`, `colors` (2 or more). The shop window builds itself from this list.

## Files
| File | Job |
|---|---|
| [`src/shared/ShopItems.luau`](../src/shared/ShopItems.luau) | The item list |
| [`src/server/ShopService.luau`](../src/server/ShopService.luau) | Buy / equip / unequip (RemoteFunction `ShopRequest`), puts the Trail on the character |
| [`src/client/ShopUi.client.luau`](../src/client/ShopUi.client.luau) | The shop window (works on phone too: big buttons, scrolls) |

## Check that it works
1. Click **SHOP**: the window opens with the trails and your coins at the top.
2. With less than 100 coins: click `100 coins` on Ember → red pop-up `Not enough coins`.
3. Get coins (survive rounds or use the daily reward), buy Ember → yellow → `Equipped`, a trail follows you.
4. Die / respawn: the trail is still there. Stop and Play: still owned and equipped.
5. Click `Equipped` → trail removed, button shows `Equip`.

💡 To test faster you can give yourself coins: in Studio while playing, in the **server** Command Bar:
`game.Players:GetPlayers()[1].leaderstats.Coins.Value = 1000`
