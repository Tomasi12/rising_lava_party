# Step 9 — Save coins (DataStore)

Date: 2026-11-12 · Status: **done** (tested in Studio 2026-11-13)

## What it does
Coins are kept between sessions: leave the game, come back tomorrow, your coins are still there.

| When | What happens |
|---|---|
| Player joins | Saved data is loaded (up to 3 tries) and put into `leaderstats/Coins` |
| Every 60 s | Everyone's data is saved (protects against server crashes) |
| Player leaves | Their data is saved |
| Server shuts down / Studio test stopped | Everyone still in the server is saved (Roblox waits up to 30 s) |

**Safety rule:** if loading fails for a player (Roblox DataStore outage, no API access), that player's
data is **not saved** this session. Otherwise a failed load would show 0 coins and then overwrite the real
saved coins with 0. A warning is printed in Output instead.

## ⚠ Required one-time setup in Studio (you)
DataStores only work for places that are **published to Roblox**, and Studio needs permission to use them.

1. **Publish the place:** **File → Publish to Roblox** → create a new experience, name it
   `Rising Lava Party`. It stays **private** until you make it public (you choose that later).
2. **Allow API access in Studio:** **Home → Game Settings → Security** →
   turn on **Enable Studio Access to API Services** → **Save**.

Without these, the game still runs, but Output shows a warning like
`Loading data for <name> failed ... ` / `DataStores are not available` and coins are not saved.

## Data format
- DataStore name: `PlayerData_v1`
- Key per player: `player_<UserId>` (e.g. `player_123456789`)
- Value:
  ```json
  { "coins": 125 }
  ```
- When loading, anything invalid (missing, negative, not a number) becomes the default (`coins = 0`).
- To add new saved fields later (e.g. owned trails), add them to `PlayerData` and `defaultData()`
  in [`DataService.luau`](../src/server/DataService.luau). Old saves get the default automatically.
- To reset everyone to zero (e.g. before the public launch), change `STORE_NAME` to `PlayerData_v2`.

## Files
| File | Job |
|---|---|
| [`src/server/DataService.luau`](../src/server/DataService.luau) | Load / autosave / save on leave / save on shutdown |
| [`src/server/Main.server.luau`](../src/server/Main.server.luau) | Calls `DataService.init()` right after `CoinService.init()` |

## Design details
- Uses `CoinService.get/set` (step 8); DataService doesn't create leaderstats itself.
- Coins earned **while** the data is loading are kept (they are added to the loaded amount).
- Saves use `UpdateAsync` (Roblox's recommended write call).
- Failed requests are retried 3 times, waiting 2 s, then 4 s.
- A player is saved **once** on leave even though both `PlayerRemoving` and `BindToClose` run when a
  server shuts down: the `loaded` flag is cleared before the final save.
- Not done yet (fine for now, needed later with real money items): **session locking** (protects against
  the same player being in two servers at once). A library like ProfileStore does this; we can switch later.

## Check that it works (to do in Studio, after the setup above)
1. Press **Play**. No DataStore warnings in Output.
2. Survive a round → Coins `10`.
3. **Stop** the test (Shift+F5). Wait a few seconds.
4. Press **Play** again → Coins shows `10` right after joining.
5. Survive again → `20`. Stop, Play → still `20`.

## Verified so far
- `rojo build` succeeds and `DataService` is included (2026-11-12).
- Tested in Studio by the user on 2026-11-13: works.
