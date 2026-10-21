# 01 — Core run: Banane's first run (M1)

Status: **DRAFT**, waiting for product owner approval.
Milestone: **M1 — Core run** (vision §10).
Based on: [`00-product-vision.md`](00-product-vision.md) §5 (Combat, Enemies, Heroes → Banane), §6, §8.1.

## 1. Goal

One question for this milestone: **is a 5-minute run fun?**

The player starts the game, is dropped straight into a run as Banane, moves and dashes through a horde of zombie
plushies, collects XP buttons, picks upgrades, and either dies or reaches the goal: survive 5 minutes. Then they
can stop with a win, or **keep going endlessly** to see how far their build carries them. Afterwards they press
"Try again" and want to go once more.

5 minutes is the length of this *first* run. Later areas get harder and longer (vision: 8–12 min), and their goal
becomes a boss; the "keep going" choice stays.

No town, no materials, no saving yet: those come in M3. Everything here is the foundation the rest of the game
stands on, so it has to *feel* good, not just work.

## 2. What the player experiences

1. Start `Stuffed.exe` → a simple title screen ("Stuffed", **Start run**, **Quit**).
2. **Start run** → Banane stands in the middle of a felt bedroom floor. The Peel Boomerang starts throwing by itself.
3. Shamblers shuffle in from the edges of the screen. Later, runners join. Every minute there is a surge,
   then a short breather.
4. Killed zombies pop into stuffing and drop **XP buttons**. Buttons fly into Banane when he gets close.
5. A full XP bar → the game pauses, Banane quacks deadpan with sunglasses on, and **3 upgrade cards** appear.
   Pick one, the game continues.
6. Banane survives 5:00 → **goal reached**: the remaining zombies pop, the game pauses and asks:
   **"You survived! End run"** or **"Keep going (endless)"**.
7. **Endless:** the timer keeps running and the horde keeps getting tougher, until Banane falls.
8. The run ends (death, or "End run") → end screen with run stats and **Try again**: **"You survived!"** if the
   goal was reached (plus how long Banane lasted in endless), **"Banane got stuffed"** if he died before 5:00.

## 3. Controls

| Action | Key (player 1) | Notes |
|--------|----------------|-------|
| Move | W A S D | 8 directions, diagonal not faster than straight |
| Dash | Space | Short burst in the move direction (or facing direction when standing still) |
| Aim | Mouse cursor | Only used by aimed weapons; cursor is shown as a small crosshair |
| Pick upgrade | Keys 1 / 2 / 3 (mouse click also works) | |

**Weapons always fire on their own.** Some are aimed with the cursor, but playing never needs a mouse button.
Mouse clicks are only used in menus, and every menu also works with the keyboard.
| Pause | Esc | Resume, toggle damage numbers, volume, Quit to title |
| Fullscreen | F11 / Alt+Enter | Toggles windowed ↔ fullscreen |
| Developer menu | F1 | See §9 |

Rebinding keys and controller support are not in M1 (vision §6.11 and §9; planned for M6 / M7).

## 4. Banane

- **Looks:** the felt Banane from [`docs/art/felt-style-concept.html`](../art/felt-style-concept.html) in a simple
  form: separate pieces (feet, body, peel hood + 3 flaps, beak, eyes) with puppet animation (§8.1):
  waddle + bob when walking, feet stepping, flaps swinging a moment late, stretch on dash, squish on hit.
- **Hitbox:** smaller than the drawing, and visible as a small soft dot at his centre (vision §6.1).
- **Health:** shown as a small bar under Banane and in the HUD. No regeneration; healing only via upgrades.
- **Getting hit:** touching a zombie hurts. After a hit Banane is invulnerable for a moment (blinks), so a crowd
  can't delete him in one frame.
- **Dash:** a quick burst forward with a short cooldown. During the dash Banane can pass through zombies without
  being hurt. The cooldown is visible (a small ring around the hitbox dot fills up).
- **Passive: Slippery.** Every dash drops a banana peel where the dash started. The first zombie(s) to step on it
  slip and are stunned for a moment (they spin, little stars). The peel disappears after it was used or after a few
  seconds. Max a few peels on the floor at once.

## 5. Weapons

Banane starts with the Peel Boomerang. The Sewing-Pin Sniper is offered as an upgrade card from the first level-up.
Both weapons have **5 levels**; each level-up card says exactly what the next level adds.

### 5.1 Peel Boomerang (auto)

- Every couple of seconds Banane throws a banana peel at the **nearest zombie**. It flies out to a set range,
  turns, and flies back to Banane (following him if he moved).
- It damages each zombie it touches **once on the way out and once on the way back**.
- Levels add: a second boomerang, more damage, more range, faster throws.

### 5.2 Sewing-Pin Sniper (aimed)

- Fires a long sewing pin **towards the mouse cursor** on its own rhythm (no clicking: you aim, it shoots).
- Fast, hits hard, **pierces** through a few zombies in a line. A reward for lining shots up.
- Levels add: more damage, more pierce, faster firing, two pins in a narrow spread.

## 6. Enemies

Zombie plushies in felt style: torn seams, a missing button eye, a mismatched patch. Creepy-cute, never gory.
Enemies always have the **strongest contrast** on screen; Banane's own effects are softer (vision §6.1).

| Enemy | Behaviour | Feel |
|-------|-----------|------|
| **Shambler** (zombie teddy) | Slow, walks straight at the nearest player, comes in big swarms | The basic horde you mow down |
| **Runner** (zombie sock bunny) | Fast and fragile, slightly slower than Banane | Forces you to keep moving; appears from about minute 1 |

- Zombies push each other apart a little so they form a crowd, not a single blob.
- When hit: white flash, small knockback, squish. When killed: the zombie **bursts into pieces plus a stuffing
  cloud**, the button eye pops off, and it drops an XP button.
- Enemies spawn **just outside the visible screen**, never on top of Banane.

## 7. The run

- **Arena:** one bedroom floor (felt carpet with a simple pattern so movement is readable), about 4 × 4 screens,
  bounded by toy-block walls. The camera follows Banane smoothly and stops at the walls.
- **Goal:** survive 5:00. A timer is shown at the top, with the goal marked ("3:12 / 5:00").
- **Pacing (waves with breathers, vision §5 Enemies):** spawning ramps up over the run. About every minute there is
  a **surge** (many more zombies for ~20 s), followed by a **breather** (~10 s, few spawns) to collect buttons.
  The last 30 seconds before the goal are the biggest surge.
- **Goal reached at 5:00:** spawning stops, all zombies pop at once (a satisfying chain of pops), a short
  celebration, then the choice **End run** / **Keep going (endless)**. In M2 this moment becomes the boss fight.
- **Endless (after the goal):** the run continues with no time limit. The surge/breather rhythm goes on, and every
  minute the horde gets tougher: more zombies per surge (up to the maximum alive) and more zombie health and damage,
  so even a great build eventually falls. The timer now counts the endless time ("Endless +2:41"). Level-ups,
  weapons and the developer menu work as before. Dying in endless still counts as a win (the goal was reached).
- **Randomness is seedable:** each run has a seed (shown on the end screen), so a run can be replayed for tuning and
  tests are deterministic.

## 8. XP, level-up and upgrades

- **XP buttons** come in 3 sizes / colours (small, medium, big) by enemy type. They are drawn as felt buttons.
- When Banane is within the **pickup range**, a button accelerates and flies into him. Picking up several in a row
  plays rising "plip" sounds.
- The **XP needed per level** grows with each level (a curve in a data file, see §11).
- **Level-up:** the game pauses, a short big moment (deadpan quack, sunglasses, a burst of felt confetti), then
  **3 cards** to pick 1 from. Several level-ups at once are shown one after another.
- **The upgrade pool in M1:**
  - Peel Boomerang levels 2–5
  - Sewing-Pin Sniper (new) and its levels 2–5
  - Four simple boosts, each up to 5 levels: **Quick Feet** (move speed), **Extra Stuffing** (max health, also
    heals that amount), **Magnet Pocket** (pickup range), **Quick Hands** (all weapons fire faster).
    The real passive items with their own effects come in M2.
- **Card rules:** 3 different cards; maxed-out upgrades are no longer offered; if fewer than 3 upgrades are left,
  the empty slots become **Banana Snack** (heal 30%). Each card shows icon, name, level ("New!" or "Lv 2 → 3")
  and one line of what it does.
- Reroll, skip and banish are **M2**.

## 9. Developer menu (F1)

Available in every build for now (we only have test builds). Shows as a small panel; the game keeps running
unless "pause" is ticked.

- Give XP / level up now
- Spawn 10 / 100 / 500 shamblers or runners
- Kill all zombies
- Skip time +30 s / jump to 4:30
- Invincible on/off
- Time speed 0.5× / 1× / 2×
- Show FPS, enemy count, hitboxes
- Restart run (same seed / new seed)

**Run log:** at the end of every run, one line is appended to a local file
(`%APPDATA%\Godot\app_userdata\Stuffed\run_log.jsonl`): date, seed, time survived, goal reached yes/no, endless
time, level, kills, what killed Banane, and which upgrades were picked in which order. This is for tuning, not
shown in the game.

## 10. Game feel and sound (from day one, vision §5 Combat)

**Feel:** hit flash, small knockback, short hit-stop on big hits (e.g. a pin piercing 3+ zombies), small screen
shake on taking damage, zombies popping into stuffing, buttons flying into Banane, a big level-up moment,
small damage numbers (can be turned off in the pause menu).

**Sounds** (generated in code or sfxr-style, no purchased files, vision §8.1):

| Event | Sound |
|-------|-------|
| Boomerang throw / return | soft "whff" |
| Pin shot | short "tsing" |
| Zombie hit | soft felt "thup" |
| Zombie pop | "plop" + fabric rip |
| XP button pickup | "plip", pitch rises in a chain |
| Dash | quick "fwip" |
| Peel slip | cartoon slip "zwiip" |
| Banane hurt | squeaky "honk" |
| Level-up | deadpan "quack" |
| Death | sad deflating squeak |
| Goal reached | short happy jingle |

Many identical sounds at once (100 pops) are limited and slightly varied in pitch so it doesn't become noise.

**Music:** one looping track during the run and a calm one on the title screen. Free CC0 (public domain) music,
or a simple track generated in code; the licence is recorded in `docs/art/credits.md`. The music is a little
quieter than the effects, and it keeps playing (muffled) while paused. Replaced or refined in M6.

The pause menu has three volume sliders: **Master**, **Effects**, **Music**.

## 11. Balance lives in data (hard rule 8)

All numbers below live in `.tres` resources (one per hero, weapon, enemy, plus spawn schedule, XP curve and
upgrade pool), not in code. They are **first guesses** to be tuned in the playtest. A tester can change a number,
restart the run, and see the effect in under a minute.

| Thing | Starting value |
|-------|----------------|
| Banane: health / move speed | 100 HP / 150 px/s |
| Dash: distance / cooldown / invulnerable | 120 px / 1.5 s / during the dash |
| After-hit invulnerability | 0.5 s |
| Slippery: peel lifetime / stun / max peels | 4 s / 1.0 s / 3 |
| Peel Boomerang L1: damage / every / range | 8 / 1.4 s / 250 px |
| Sewing-Pin Sniper L1: damage / every / pierce | 15 / 1.2 s / 2 |
| Shambler: HP / speed / contact damage / XP | 10 / 45 px/s / 5 / small |
| Runner: HP / speed / contact damage / XP | 5 / 125 px/s / 4 / medium |
| Run goal | 5:00 |
| Endless: growth per minute | +15% zombie health and damage, +10% spawns |
| XP to level 2, growth per level | 5, +40% per level (rounded) |
| Pickup range | 60 px |
| Max zombies alive | 500 |

## 12. Ready for local co-op (hard rule 11)

M1 has one player, but the code must not assume that:

- Input is read **per player** (player index → device and action set). Player 1 = keyboard + mouse.
- Systems find players through a list/group, never a single global "the player": zombies chase the **nearest**
  player, weapons belong to their player, XP buttons fly to the nearest player.
- The camera follows the group of players (with one player, that's just Banane).
- The run ends when **all** players are down.

A test proves this by spawning a second player in code (no real second input device needed).

## 13. Acceptance criteria

Each criterion gets a scenario test in `tests/scenarios/test_01_core_run.gd` (real scenes, simulated input and
time) unless marked *(unit)*. "Playtest" items can only be judged by playing.

**Start and movement**
- **AC-1** From the title screen, **Start run** loads the run with Banane in the arena centre and the timer at 0:00.
- **AC-2** Holding D moves Banane right; holding W+D moves him diagonally at the same speed as straight movement.
- **AC-3** Banane cannot leave the arena through the walls.
- **AC-4** Space dashes Banane about the dash distance; pressing Space again during the cooldown does nothing.
- **AC-5** During a dash Banane takes no contact damage.
- **AC-6** A dash drops a banana peel; a zombie walking onto it is stunned for the stun time, then moves again.
  At most 3 peels exist at once.

**Weapons**
- **AC-7** The Peel Boomerang fires automatically at the nearest zombie, returns to Banane, and can damage the same
  zombie once on the way out and once on the way back.
- **AC-8** The Sewing-Pin Sniper (once picked) fires on its own, without any mouse button, towards the mouse
  cursor, and passes through up to its pierce count of zombies in a line.
- **AC-9** Weapon levels change the weapon as their card describes (e.g. Boomerang L2 throws two). *(unit for the
  numbers, scenario for one visible change)*

**Enemies and the run**
- **AC-10** Zombies spawn outside the visible screen and walk towards the nearest player.
- **AC-11** Runners appear only after about the first minute; both types appear in a full run.
- **AC-12** Spawning follows the schedule: surges spawn clearly more than breathers. *(unit on the schedule, scenario
  on a short simulated run)*
- **AC-13** Touching a zombie damages Banane; he can't be damaged again during after-hit invulnerability.
- **AC-14** A killed zombie disappears and drops an XP button.
- **AC-15** The number of zombies alive never goes above the maximum.

**XP and level-up**
- **AC-16** An XP button within pickup range flies to Banane and adds XP; one outside the range stays put.
- **AC-17** A full XP bar pauses the game and shows 3 different upgrade cards; the run doesn't continue until one is
  picked (by click or by keys 1/2/3).
- **AC-18** Picking a card applies it (e.g. Quick Feet makes Banane faster; Sewing-Pin Sniper adds the weapon).
- **AC-19** Maxed-out upgrades are not offered; with fewer than 3 options, Banana Snack fills the slots. *(unit)*
- **AC-20** XP needed per level follows the curve from the data file. *(unit)*
- **AC-21** Two level-ups from one big pickup show two card screens one after another.

**End of run**
- **AC-22** At 0 HP before the goal, the run stops and the "Banane got stuffed" screen shows time survived, level,
  kills, what killed Banane, the upgrades picked, and the seed.
- **AC-23** Surviving to 5:00 stops spawning, pops all remaining zombies, pauses, and offers **End run** and
  **Keep going (endless)** (keys and mouse).
- **AC-24** **End run** shows the "You survived!" screen with the same stats.
- **AC-25** **Keep going** continues the run: zombies spawn again, the timer shows endless time, and each endless
  minute makes zombies tougher as set in the data file. *(unit for the scaling, scenario for continuing)*
- **AC-26** Dying in endless shows "You survived!" with the endless time added to the stats.
- **AC-27** **Try again** starts a fresh run (full health, level 1, timer 0:00, only the Peel Boomerang).
- **AC-28** Each finished run appends one line to the run log with the fields from §9.

**Pause, menu, developer menu**
- **AC-29** Esc pauses the run (zombies and timer stop) and Esc / Resume continues it; Quit returns to the title.
- **AC-30** The damage-number toggle and the Master / Effects / Music sliders in the pause menu take effect
  immediately.
- **AC-31** Music plays on the title screen and during the run.
- **AC-32** F1 opens the developer menu; "Spawn 100 shamblers", "Level up now", "Kill all" and "Jump to 4:30" do
  what they say.

**Data, randomness and co-op readiness**
- **AC-33** Changing a value in a balance `.tres` (e.g. Banane's speed) changes the game without code changes.
  *(unit: systems read their numbers from the resources)*
- **AC-34** The same seed gives the same spawn sequence and the same upgrade cards. *(unit)*
- **AC-35** With a second player spawned in code, zombies chase whichever player is nearer, XP flies to the nearer
  player, and the run only ends when both are down.

**Playtest (product owner, not automatable)**
- **P-1** The 5-minute run is fun and you want "one more".
- **P-2** Movement and dash feel responsive; Banane looks like a soft plushie when he moves.
- **P-3** You can always see where the danger is, and you always know why you died.
- **P-4** Hits, pops, pickups and level-ups feel and sound satisfying, not noisy.
- **P-5** With "Spawn 500" in the developer menu and FPS shown, the game stays smooth (target 60 fps) on your PC.
- **P-6** Reaching the goal feels like a win, and with a good build, endless is tempting and gets hard in a fair way.

## 14. Not in this spec

- Town, materials, saving / resuming, meta-progression (M3).
- More weapons, evolutions (Banana Split), passive items, gift box, reroll / skip / banish, spitters, bloaters,
  tanks, elites, bosses (M2).
- Other heroes (M5), equipment (M4.5), siege (M4).
- Key rebinding, controller support, readability options beyond damage numbers, final art polish (M6 / M7).

## 15. Proposed tickets (after approval)

Each becomes a GitHub issue and one PR, roughly in this order:

1. Arena, camera and Banane movement + dash (per-player input) — AC-1–5
2. Banane felt puppet drawing and animation (walk, dash stretch, hit squish)
3. Zombie base: shambler, spawning outside the screen, chase nearest player, contact damage, health — AC-10, 13, 15
4. Peel Boomerang — AC-7
5. XP buttons, pickup, XP curve — AC-14, 16, 20
6. Level-up screen, upgrade pool, boosts — AC-17–19, 21
7. Sewing-Pin Sniper + weapon levels — AC-8, 9
8. Runners, spawn schedule with surges and breathers, goal at 5:00 — AC-11, 12, 23
9. Endless mode after the goal — AC-24–26
10. Slippery passive — AC-6
11. Title, pause, end screens, Try again, run log — AC-22, 27–30
12. Game feel pass + generated sounds + music — AC-31
13. Developer menu, seeds, data checks, co-op readiness test — AC-32–35

## 16. Decisions (product owner, 2026-10-21)

1. **Weapons always fire on their own.** Some can be aimed with the cursor; gameplay never uses mouse buttons.
2. **Every run has a goal, then the player chooses** to end with a win or keep going endlessly. The first run's
   goal is 5:00; later areas are harder and longer, and their goal is a boss.
3. **Music in M1:** one simple track for the title and one for the run.
