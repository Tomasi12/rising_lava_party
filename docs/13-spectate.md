# Step 13 — Spectate after you die

Date: 2026-11-13 · Status: **in progress** (code written, not yet tested in Studio)

## What it does
When you are out of the round (you died, or you joined while a round was running), the camera
follows a player who is still alive. A bar at the bottom shows:

`◀   Watching: Alex   ▶   ✕`

| Button | Effect |
|---|---|
| ◀ / ▶ | watch the previous / next player who is still alive |
| ✕ | stop watching; you can walk around the lobby. Spectate starts again automatically next round. |

When the player you watch dies, it switches to another one. When the round ends, the camera goes back to you.

Why: without it, dead players wait 1–2 minutes with nothing to do and may leave the game.
Watching the others also makes them want to play the next round.

## How it works
- Only the client: [`src/client/Spectate.client.luau`](../src/client/Spectate.client.luau).
- It reads the `InRound` attribute on every player (set by `RoundManager`, step 11) and sets
  `Workspace.CurrentCamera.CameraSubject` to the watched player's Humanoid.
- It checks 4 times per second, so it reacts to deaths, respawns and players leaving.
- Alone (1 player) there is nobody to watch, so the bar never appears.

## Check that it works (needs 2 players)
1. Test tab → Clients and Servers → 2 players → Start.
2. Let player 1 die in the lava → player 1's camera follows player 2, bar shows `Watching: Player2`.
   (With 2 players the round ends right away when one dies, so use **3 players** to see it longer.)
3. ✕ → camera back on yourself in the lobby.
