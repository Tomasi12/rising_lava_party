# What to do now

Updated: 2026-11-13 · **Done:** all tests passed on 2026-11-13. The next to-do list comes with the next plan.

**Where we are:** the game code is written, but it has **never run in Studio**.
Your job now: test it once (about 30 min, on the PC) and send Claude the results.

You don't need to understand the code. Do the steps below in order.
Tick each box ☐ → ☑ as you go.

---

## Part 1 — Get ready (10 min, only once)

### ☐ 1. Start Rojo
Rojo sends the code from the PC folder into Studio.
- Open a terminal (PowerShell).
- Type:
  ```
  cd C:\AI_Claude\Roblox\rising_lava_party
  rojo serve
  ```
- ✅ OK if you see: `Rojo server listening on port 34872`
- Leave this window **open** the whole time.
- ⚠ If you see "address already in use": Rojo is already running. That's fine, go on.

### ☐ 2. Open the game in Studio
- Open **Roblox Studio**.
- **If the file already exists:** open `C:\AI_Claude\Roblox\rising_lava_party\RisingLavaParty.rbxl`.
- **If not (first time):**
  1. Click **New → Baseplate**.
  2. **File → Save to File As…**
  3. Go to `C:\AI_Claude\Roblox\rising_lava_party`, name it `RisingLavaParty.rbxl` → **Save**.
  - Git ignores `.rbxl` files, so the file stays only on your PC.
  - Nothing is lost by starting new: Rojo puts all code, the lobby and the arena into it at step 3.

### ☐ 3. Connect Studio to Rojo
- Top menu: **Plugins → Rojo → Connect**.
- If it asks to accept changes → **Accept**.
- ✅ OK if the Rojo window says **Connected**.

### ☐ 4. Open the 2 windows you need
- **Window → Output** (shows messages and errors)
- **Window → Explorer** (shows everything in the game)
- Older Studio versions: these are under the **View** tab instead.

### ☐ 5. Delete the extra spawn pad
- In **Explorer**: open **Workspace**, click **SpawnLocation**, press **Delete**.
- Don't delete `Baseplate`, `Lobby` or `Arena`.

### ☐ 6. Publish the game (needed to save coins)
- **File → Publish to Roblox**
- Choose **new experience**, name: `Rising Lava Party` → **Create**.
- It stays **private**; nobody can see it.

### ☐ 7. Allow saving in Studio
- **Home → Game Settings → Security**
- Turn on **Enable Studio Access to API Services** → **Save**.

### ☐ 8. Save
- Press **Ctrl+S**.

---

## Part 2 — Test alone (15 min)

Press **Play** (F5). Watch the screen and the **Output** window.

| ☐ | What you do | What should happen |
|---|---|---|
| ☐ A | Press Play | You stand on a **yellow pad** in a green lobby in the sky |
| ☐ B | Walk to the edge | Glass walls stop you |
| ☐ C | Look at the top of the screen | `Round starts in 15` counts down |
| ☐ D | Wait for 0 | You are teleported into the arena; lots of **colored platforms** |
| ☐ E | Stand still on the floor | Orange lava rises after 5 s and **kills you**; you are back in the lobby |
| ☐ F | Next round: climb the platforms | You can reach every platform with normal jumps |
| ☐ G | Stay above the lava until the time is 0 | `<your name> survived! +10 coins` |
| ☐ H | Look at the player list (top right) | **Coins: 10** |
| ☐ I | Stop (**Shift+F5**), wait 5 s, Play again | Still **Coins: 10** |

💡 **Rounds take long?** Tell Claude "make the timers short for testing".
Claude changes them, and you change nothing in Studio.

---

## Part 3 — Test with 2 players (5 min)

- **Test** tab → **Clients and Servers** → Players: **2** → **Start**.
- Two game windows open.

| ☐ | What you do | What should happen |
|---|---|---|
| ☐ J | Wait for the countdown | Both go to the arena, at **different** places |
| ☐ K | Let player 1 die in the lava | Round ends: `<player 2> wins! +25 coins` |
| ☐ L | Close one window during a round | The other player keeps playing; no errors |

- Close everything: **Test** tab → **Cleanup**.

---

## Part 4 — Send Claude the results

Write a message like this (from the phone is fine):

```
Passed: A B C D E F G H
Failed: I — coins were 0 after restart
Errors: (paste red/orange lines from Output, or a photo)
Fun: lava too slow / too fast / OK
```

- **Red lines** in Output = errors. These are the most important to send.
- **Orange lines** = warnings. Send them too.
- A **photo of the screen** is OK if copying is hard.

Then Claude fixes the problems, marks the steps done, commits and pushes.

---

## Need more detail?
The full guide with all 19 tests: [10-testing-guide.md](10-testing-guide.md).
