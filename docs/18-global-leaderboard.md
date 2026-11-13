# Step 18 — Global leaderboard in the lobby

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
A dark board on the north wall of the lobby shows **TOP 10 · MOST WINS** of all players, in all servers,
of all time:

```
TOP 10 · MOST WINS
1.  Alex  ·  152
2.  Maria ·  97
...
```

It updates every 60 seconds. Why: players want to see their name on it, which makes them play more
(and players who see big numbers understand the game is alive).

## How it works
- **Board:** new part `Leaderboard` in [`Lobby.model.json`](../src/workspace/Lobby.model.json)
  (18 × 11 studs, at the north wall, facing into the lobby). The server puts a `SurfaceGui` on it.
- **Data:** [`LeaderboardService.luau`](../src/server/LeaderboardService.luau) uses an
  **OrderedDataStore** `GlobalWins_v1` (key = UserId, value = wins). Ordered DataStores can return the
  entries sorted, which a normal DataStore can't.
- Every 60 s: writes the wins of players whose wins changed, then reads the top 10. Also writes when a
  player leaves.
- Only players whose saved data loaded correctly are written.
- Needs DataStores (published place + API access on), like saving coins.
- To start a new leaderboard (e.g. a new season, or to remove test entries before the launch): change
  `STORE_NAME` to `GlobalWins_v2`.

## Check that it works
1. Play: the board is visible on the north side of the lobby with `1.  -` ... `10.  -`.
2. Survive a round (Wins 1), wait up to 60 s in the lobby: your name appears with `1`.
3. If Output says `Leaderboard: DataStores are not available`: publish + API access (see step 9).
