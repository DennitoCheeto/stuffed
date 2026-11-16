# 07 — Night siege

Status: **DRAFT** (waiting for the product owner).
Milestone: **M4 — Night siege** (after M3.7 Building tricks, before M4.5 Equipment).
Based on: vision §5 ("Night siege", "Rhythm"), §6.5 ("the siege is where the town really counts"), the siege roles
in spec 03 §6, and the PO direction of 2026-10-27: **features first, polish later** (good-enough looks, no option
boards).

## 1. Goal

One question: **does building my town now feel like getting ready for something?**

After this spec:

- the town warns you **"The horde arrives in 2 nights"**, so every expedition has a "get ready" reason,
- the **night siege** is a short wave defence (about 3 minutes) **in the town itself**, with the same controls as a
  run,
- every built building **fights along** in its own way (turret, bait, healing spot, trap),
- a won siege gives a big bonus; a lost one **damages** buildings, which you repair (never deleted, never lose a
  level).

Not in this spec: equipment (M4.5), playable plushies (M5), new buildings, walls you place yourself, a full dark
night look, idle production.

## 2. What the player experiences

1. After a few runs, a felt **moon calendar** appears next to the fort door: **"The horde arrives in 2 nights."**
   Each expedition (one "night" away) ticks it down. The end screen says it too ("1 night until the horde!").
2. You come home from the run that ends the countdown. The town turns to **dusk** (warm evening light, fairy lights
   on, not dark). A banner: **"The horde is coming!"**
3. You can still build, repair and buy tricks first. The fort door now says **"E: Defend the fort"** instead of
   "Go to the Bedroom" (no expedition until the siege is played).
4. E starts the siege. The camera stays in the town. Zombies come from the edges of the room in **3 waves**
   (~60 s each, a short breather between, banner "Wave 2 of 3"). The last wave brings a big boss.
5. You fight with your starting weapon and level up fast (XP and cards as in a run, but quicker), so you get
   strong within 3 minutes.
6. Your buildings fight along (§4). Zombies try to reach the **pillow fort** and knock it down; they attack heroes
   and buildings that are in their way.
7. If your hero falls, you stand back up at the fort after a few seconds. **The siege is lost only if the fort
   falls.**
8. **Won:** a "Night defended!" moment, a bonus haul of coins, stuffing and thread, a sticker on the end screen.
   **Lost:** the horde leaves at dawn; buildings that were knocked down are **damaged**. You still get a small
   consolation haul (no run is wasted, vision §6.4).
9. Back in town: damaged buildings look patched-up and broken and show **"Repair"** with a cheap price. A damaged
   building keeps its level but its bonuses and tricks are **off until repaired**.
10. The calendar starts again: **"The horde arrives in 3 nights."** Each siege is a bit bigger than the last.

## 3. Rhythm (vision §5 "Rhythm", §6.9 reveal)

- The first warning appears once **2 buildings are built** (so there is something to defend), with **2 nights** to
  go.
- After every siege (won or lost) the next one comes in **3 nights**.
- A "night" = one expedition that ends (any ending: goal, Way Home, died, gave up).
- All numbers in data (`data/siege/siege_rules.tres`): first trigger, nights between sieges, wave length, breather,
  scaling per siege (more zombies, more health), rewards, repair share.

## 4. Buildings in the siege

Only **built** buildings fight. Ruins and damaged buildings stand still and zombies ignore them. Each building has
**health** (more per level) and a small health bar that shows only while it is hurt.

| Building | Siege role | Lv 1 → Lv 3 (first guess, in data) |
|----------|-----------|--------------------------------------|
| **Pillow fort** | The heart. Siege is lost if it falls. Always there, gets sturdier with every built level in town. | health grows with the fort pieces |
| **Toy Box Armory** | **Turret:** fires your hero's starting weapon at nearby zombies. | weapon at Lv 1 / 3 / 5 |
| **Lucky Jar** | **Bait:** zombies near it go for the jar first. Extra sturdy. | bait radius 250 / 350 / 450 px |
| **Watchtower** | **Long-range turret:** slow, strong pin shots at the toughest zombie in range. | 1 shot / 2 s → 1 / 1 s |
| **Snack Bar** | **Healing spot:** heroes standing in its ring heal over time. | 3 / 5 / 8 health per s |
| **Party Shop** | **Confetti trap:** every few seconds a confetti pop hurts zombies around it. | every 8 / 6 / 4 s |
| **Plush Hospital** | **Revives plushies:** knocked-out plushies stand back up after a few seconds. | 12 / 8 / 5 s |

**Plushies help:** every plushie living in town stands near the fort and throws a small stuffing ball at a nearby
zombie every ~2 s (weak, a bit of help, mostly charm). Zombies can knock a plushie out (it sits down, dizzy stars);
without the Hospital it stays out until the siege ends. Plushies can never be lost.

**Tricks in the siege:** tricks that make sense work (Shiny Card, Four of a Kind, Second Helping, Spare Stuffing,
Confetti Rush, Pocket Pickup, Magnet Whistle, Head Start, Second Toy, ...). Bedroom-only tricks don't (Treasure Map,
Picnic, rescue tricks). Floor pickups don't drop in the siege.

## 5. Enemies and waves

- Same zombie types as the Bedroom (shamblers, runners, spitters, bloaters, tanks, elites).
- **Wave 1:** shamblers and runners. **Wave 2:** + spitters and bloaters, one elite. **Wave 3:** + tanks and the
  boss **Big Ted** (the Bedroom mini-boss, as the night's boss).
- Zombies walk towards the fort. On the way they turn to attack a hero, a plushie or a building that is close
  (Lucky Jar: from further away). They hit by touching, like they hit heroes today.
- They spawn just outside the town room's edges, from all four sides, so every building can be in danger.
- Each siege after the first: more zombies and more health (numbers in data). Endless sieges are not planned.

## 6. After the siege

- **Won:** reward haul (first guess: 400 coins + 20 stuffing + 4 thread for siege 1, +25% per siege), counted into
  the jars like a run. No damage, even for buildings that were knocked down during the fight (they pop back up
  with a puff).
- **Lost:** every building knocked down in the fight becomes **damaged**. Consolation haul = 30% of the reward.
- **Damaged building:** broken look (tilted, patches, a few loose stitches; reuses the ruin colours), the card
  says "Damaged: repair to turn its bonuses back on". **Repair** with E costs **25% of the coins of its current
  level** (Snack Bar Lv 3 → 375 coins). A short stitch-up moment, saves at once.
- The pillow fort is never damaged (it is the heart, and losing the fort would feel unfair). Plushies are never
  hurt for good.
- The end screen shows the siege result: waves held, zombies popped, best weapon (reuses the run end screen with a
  siege title, "Night defended!" / "The horde got in").

## 7. Look and readability (vision §6.1, hard rule 9)

- **Dusk, not night:** the town keeps its sunny patchwork colours with a warm evening tint and fairy lights on the
  buildings. The PO found the dark look "too dark": we stay bright enough to read.
- Zombies keep the strongest contrast. Building shots, the confetti trap and the healing ring are **quieter than
  enemy danger** (no danger colours, `UiColors.is_danger`), like your own shots.
- Siege HUD: the fort's health bar at the top middle (felt, player-side colour, it turns into a warning only when
  low), the wave counter, the hero's usual bar. A fort under attack off-screen gets an edge arrow.
- Every new siege visual goes into a readability test (same idea as AC-73).

## 8. Saving (hard rule 10, vision §6.6)

- `TownSave` v5: nights until the next siege, sieges played / won, damaged building ids. Old saves load with no
  warning yet (the countdown appears as in §3).
- The game saves when the siege starts and when it ends. Closing the game during a siege: next time the siege is
  still due (it starts over). Nothing is lost.
- A test saves, reloads and compares all new fields.

## 9. Co-op (hard rule 11)

- Every hero fights in the siege and stands back up at the fort when fallen. Snack Bar heals every hero in its ring.
- Buildings and zombies look players up (nearest hero), never "the player".

## 10. Developer menu and run log

- Town dev menu: **"Siege now"** (sets the countdown to 0), **"Damage a building"**, **"Repair all"**.
- Siege dev menu (the run one): **"Next wave"**, **"Win siege"**, **"Hurt the fort"**.
- Log: one line per siege in the run log (`kind: "siege"`, number, won, waves held, fort health left, buildings
  knocked down, damaged ids, reward).

## 11. Performance (vision §6.7)

- The siege must stay smooth with ~300 zombies in the town plus every building firing. Benchmark the siege like
  the Bedroom (`tools/benchmark.gd`): no worse than the Bedroom run on draw calls.

## 12. Acceptance criteria

- **AC-74** The moon calendar shows the nights until the horde; it appears once 2 buildings are built, counts down
  by one per finished expedition and resets to the data value after a siege.
- **AC-75** When the siege is due, the town turns to dusk, the door offers "Defend the fort" and no expedition can
  start until the siege is played.
- **AC-76** The siege plays in the town with the run's controls: 3 waves from the room edges, XP and level-ups,
  a boss in the last wave, a fallen hero stands back up at the fort, the siege is lost only when the fort falls.
- **AC-77** Zombies walk to the fort and attack heroes, plushies and built buildings in their way; the Lucky Jar
  pulls zombies from further away.
- **AC-78** Every built building does its siege role from §4 (one scenario test per building), ruins and damaged
  buildings do nothing.
- **AC-79** Plushies throw stuffing balls; a knocked-out plushie stands up again only with the Plush Hospital.
- **AC-80** Won: reward haul, no damage. Lost: knocked-down buildings are damaged, consolation haul. A damaged
  building's bonuses and tricks are off in runs until it is repaired; repair costs 25% of its level's coins.
- **AC-81** Siege state (countdown, damage, sieges won) is saved and comes back after closing and reopening the
  game (save, reload, compare); a siege interrupted by closing the game is still due.
- **AC-82** In co-op every hero fights, stands back up and heals at the Snack Bar.
- **AC-83** No siege visual of ours (building shots, traps, healing ring, fort bar, dusk tint) uses a danger colour;
  zombies stay the strongest contrast on the dusk town.
- **AC-84** Siege screens (HUD, end screen, repair card, calendar) fit every window size of the fit check.
- **P-29** (playtest) The countdown makes you want to build or repair before the siege.
- **P-30** In the siege you can see your buildings helping, and it feels like *your* town fighting.
- **P-31** Losing a siege stings a little but never feels like losing progress.

## 13. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Rhythm: **first warning once 2 buildings are built (2 nights), then every 3 nights** — or every 2?
2. Siege length: **3 waves of ~60 s** (about 3 to 3.5 minutes in total).
3. Who fights: **your hero with the starting weapon, levelling up fast inside the siege** — or bring your last
   run's build along?
4. Losing: **only when the fort falls**; fallen heroes stand back up after a few seconds.
5. Damage: **damaged buildings keep their level but their bonuses/tricks are off until a cheap repair** (25% of the
   level's coins).
6. Look: **dusk (warm evening tint + fairy lights)**, not the dark night look.
7. Night boss: **Big Ted** for now; a siege-only boss can come later.

## 14. Not in this spec

Equipment and the Sewing Workshop (M4.5), playable plushies (M5), placing walls or traps yourself, new buildings,
building interiors, a dark night look, endless sieges, siege-only enemies.

## 15. Proposed tickets (after approval)

1. Siege data + `TownSave` v5 (countdown, damage, repair) + moon calendar + town dev menu — AC-74, AC-81
2. Siege flow: dusk town, "Defend the fort" door, siege scene in the town (waves from the edges, fort health,
   hero stands back up, win/lose) — AC-75, AC-76
3. Zombie targeting in the siege: fort, heroes, plushies, buildings; building health + knocked-down look; Lucky
   Jar bait — AC-77, AC-78 (jar)
4. Turrets: Toy Box Armory + Watchtower — AC-78
5. Snack Bar healing ring + Party Shop confetti trap — AC-78, AC-82
6. Plushies help + Plush Hospital revive — AC-79
7. After the siege: reward / consolation, damaged look, repair, bonuses off while damaged, end screen — AC-80
8. Siege HUD (fort bar, waves, edge arrow), tricks in the siege, co-op, run log — AC-82, AC-84
9. Readability + performance check (dusk tint, all siege visuals, benchmark) — AC-83
