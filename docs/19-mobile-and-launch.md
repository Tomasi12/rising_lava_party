# Step 19 — Mobile check and launch checklist

Date: 2026-11-13 · Status: **to do by you** (no code; a checklist)

## A. Mobile check (most Roblox players are on phones)
In Studio: **Test** tab → **Device** (emulator) → choose a phone (e.g. *iPhone 14* or *Galaxy S*) → Play.
- [ ] The round message and event banner fit on the screen and are readable.
- [ ] The **SHOP** button can be tapped and doesn't cover the jump button (bottom right).
- [ ] The shop window fits; you can scroll the list; the **X** closes it.
- [ ] Spectate bar (◀ ▶ ✕) and **REVIVE** button can be tapped.
- [ ] Pop-ups (`+10 coins`) don't cover anything important.
- [ ] Try a tablet and a small phone too.
Send Claude a screenshot of anything that looks wrong.

## B. Before making the game public
### Robux items and badges (steps 14, 16, 17)
- [ ] Create the 2 game passes, 3 developer products and up to 4 badges; paste the IDs into `Config.luau`.
- [ ] Test each purchase once in Studio (test purchases are free).

### Store page (create.roblox.com → your experience)
- [ ] **Icon** 512 × 512: a character jumping above glowing lava, big and simple. Readable when tiny.
- [ ] **Thumbnails** 1920 × 1080 (at least 3): a round from above with lava + platforms; players with trails;
      the leaderboard. Bright colors, little text.
- [ ] **Name:** `Rising Lava Party` (later you can test names like `Lava Rising 🌋 Party`).
- [ ] **Description** (draft):
      > The lava is rising! Climb the platforms, jump from block to block and be the last one standing.
      > 🌋 New platforms every round · ⚡ Random events: Fast Lava, Low Gravity, Tiny Platforms
      > 🏆 Win coins, buy trails, climb the global leaderboard · 🎁 Daily rewards
- [ ] **Genre:** Obby & Platformer (or Party & Casual).
- [ ] **Maturity / content questionnaire** (required before public): answer honestly (no violence beyond
      "falling into lava", no chat-specific content) → usually "Minimal" / all ages.
- [ ] **Max players per server:** 12–16 (Places → Rising Lava Party → Configure / Settings).
- [ ] **Devices:** Computer, Phone, Tablet (VR off).

### Clean data before launch
- [ ] Remove test progress: change `STORE_NAME` in `DataService.luau` to `PlayerData_v2` and in
      `LeaderboardService.luau` to `GlobalWins_v2` (ask Claude), so the public starts from zero.
- [ ] Timers back to normal in `Config.luau` (if you changed them for testing).
- [ ] Push everything to GitHub; Rojo connected; **File → Publish to Roblox**.

### Go public
- [ ] Experience settings → **Privacy / Access** → **Public**.
- [ ] Play it yourself once on a phone from the Roblox app.
- [ ] Invite friends for the first rounds (a game with 0 players doesn't get recommended).

## C. After launch: getting players
- **Sponsored ads / Ads Manager** (create.roblox.com → Ads): start small (e.g. a few hundred Robux per day)
  and watch the analytics.
- **Analytics** (create.roblox.com → Analytics): watch **D1 retention** (players who come back the next day),
  **average session time**, **paying users %**. Improve the weakest number first.
- Short videos (TikTok / YouTube Shorts) of funny lava moments help a lot.
- Update often (new trails, new events): Roblox shows "updated" games more.
