# 03 — The Pillow Fort: town, materials, saving (M3)

Status: **DRAFT**, waiting for the product owner's approval.
Milestone: **M3 — Town** (vision §10).
Based on: [`00-product-vision.md`](00-product-vision.md) §2, §4, §5 (The loop, Town, Rescued plushies, Collection
book), §6 (principles 2, 3, 4, 5, 6, 9); builds on [`01-core-run.md`](01-core-run.md) and
[`02-build-variety.md`](02-build-variety.md). The M2 acceptance playtest is postponed (product owner, 2026-10-22):
it will be played together with M3.

## 1. Goal

One question for this milestone: **after a run, do I want to go home, build something, and go out again?**

That's the product test (vision §4): *"I had a cool run, my town got visibly better, and I already know what I want to
build next."* M1 and M2 made the run fun. M3 adds the second half: runs bring home **materials**, the materials become
**buildings** you can see and walk around, and every building changes your next run a little. Progress is **saved**.

Still no night siege (M4), no equipment (M4.5) and no other heroes (M5). Buildings already get their siege role
written down (§5), but it only does something in M4.

## 2. What the player experiences

1. **Start the game** → title screen → **Continue** goes straight to the town (first time: **New game**).
2. **The Pillow Fort** is a small, cozy town built from pillows and blankets in a quiet corner of the house. Banane
   walks around it with WASD, like in a run (no zombies, no weapons).
3. In the middle stands the **fort**, with the **Bedroom door**: walk up to it and press **E** → an expedition starts
   (the Bedroom run from M2).
4. Around the fort are **building plots**: an empty patch of felt with a dashed stitch outline and a little sign with
   the building's name and price. Walk up → press **E** → if you can pay, the building **pops up** with a felt puff
   and a sound. Built buildings can be **upgraded** the same way (3 levels), and they look bigger and fancier per level.
5. During a run, zombies drop **buttons, stuffing and thread** (§3). At the end of the run a **"Brought home"**
   screen counts them into your jars. Winning brings home everything; getting stuffed brings home half.
6. Sometimes a run has a **plushie to rescue** (§6). Rescued plushies move into town and walk around.
7. The **Scrapbook** (the collection book, §7) shows everything you've found, with blank spots for what's missing.
8. Everything is **saved automatically**. Closing the game never loses buildings or materials.

## 3. Materials

Three materials in M3. The amounts per run are counted on the HUD (small jar icons in a corner, quieter than the
health bar) so you see your haul grow.

| Material | Look | Where it comes from | Used for |
|----------|------|---------------------|----------|
| **Buttons** | the XP buttons you already collect | Every XP button you pick up also goes into your button jar (1 button per XP point). No new floor clutter. | everything (the common currency) |
| **Stuffing** | a white fluffy tuft | Dropped now and then by bigger zombies (tanks, bloaters), always by elites; flies to you like XP | level 2 upgrades, the Plush Hospital |
| **Thread** | a small coloured spool | Big Ted, the Sock Puppet King, and the gift boxes | level 3 upgrades |

- **End of run:**
  - **Beat the King** → keep **100%**, plus a small bonus jar of buttons ("Victory bonus").
  - **Stuffed (died) or quit** → keep **50%** (rounded up). Vision §6.4: no run is wasted.
  - Endless time after the goal counts too: everything you collect after beating the King is kept at 100%.
- **Fast first building** (vision §6.2): the cheapest building costs about what a **5-minute first run that dies**
  brings home, so the first building comes in the first 10 minutes of play.
- All drop chances, amounts and the keep share live in `data/town/material_rules.tres` (hard rule 8).

## 4. The town

- **One screen-and-a-bit big.** The camera follows Banane, like in a run. Soft felt floor (a big blanket), the fort
  in the middle, plots in a ring around it, a few cozy props (cushions, a lamp, building blocks).
- **Starting state:** the fort with the Bedroom door, the Scrapbook stand and **2 plots** (Toy Box Armory and Lucky
  Jar). More plots appear as the town grows (§5), with a short "New plot!" moment, so there's always one more thing
  to want (vision §6.9: reveal systems when they're needed).
- **The fort grows with the town:** after every 3 buildings/upgrades the fort gets a new piece (a flag, a second
  tower, string lights). The town should look clearly fuller after each session.
- **Short visits** (vision §6.5): building is "walk up, press E". No menus, no timers, no waiting.
- **Readable prices:** a plot sign shows the cost with jar icons; what you can't afford yet is shown in grey with the
  missing amount ("needs 40 more stuffing").
- **Info:** standing next to a building shows a small card: name, level, what it does now, and what the next level
  adds.

## 5. Buildings (6)

Each building has **3 levels**. Level 1 costs only buttons, level 2 adds stuffing, level 3 adds thread. All costs
and effects live in `data/town/buildings/*.tres`.

| Building | Appears | What it does in town / in your runs | Siege role (M4, not in M3) |
|----------|---------|-------------------------------------|----------------------------|
| **Toy Box Armory** | from the start | Lv 1: unlocks 2 more weapons for the level-up cards. Lv 2: 2 more. Lv 3: choose Banane's **starting weapon** before a run. | turret that fires one of your weapons |
| **Lucky Jar** | from the start | Each level: **+1 reroll, +1 skip, +1 banish** per run. | — (bait: zombies go for it) |
| **Watchtower** | after the 1st building | Each level: + pickup range (+10% / +20% / +30%). | long-range turret |
| **Snack Bar** | after the 1st building | Each level: + max health (+10 / +20 / +30). | healing spot |
| **Party Shop** | after the 3rd building | Floor pickups (spec 02b) drop more often (−15% / −30% / −45% gap). Lv 3: the first one drops after 15 s. | confetti trap |
| **Plush Hospital** | after the 1st rescue (§6) | Stitches up rescued plushies so they move in. Lv 1: room for 2 plushies, Lv 2: 4, Lv 3: 6. | revives fallen plushies |

**Weapon unlocks (Toy Box Armory):** a new save starts with **6 weapons** in the level-up pool: Peel Boomerang,
Sewing-Pin Sniper, Orbiting Needles, Button Shotgun, Stuffing Cloud, Yarn Cannon (every evolution of M2 is still
possible). Lv 1 adds **Bouncy Yarn Ball + Thimble Mortar**, Lv 2 adds **Thread Whip + Zipper Ray**. Fewer cards at
the start makes the first runs easier to learn; unlocking new weapons is a "sideways" unlock (vision §6.3). All
items stay unlocked from the start.

**Stat bonuses are small and capped** (vision §6.3): Watchtower and Snack Bar are the only plain number bonuses,
3 levels each.

## 6. Rescued plushies

- **In the run:** from the second run on, about **one run in two** has a rescue (between 2:00 and 6:00). A plushie
  that isn't fully zombified yet sits **tangled in a ball of yarn** somewhere in the Bedroom. An edge arrow points to
  it (like floor pickups) and a soft "help!" squeak plays once.
- **Freeing it:** stand next to it for **3 seconds** (a ring fills up). Zombies keep coming, so it's a small risk.
  Moving away pauses the ring; it doesn't reset. When the ring is full, the plushie hops into Banane's backpack
  (it's safe now: dying later still brings it home).
- **At home:** the first rescue makes the **Plush Hospital** plot appear. Rescued plushies wait in a little tent until
  there's a bed in the Hospital, then they're stitched up (a short moment) and **move into town**: they walk around,
  sit on cushions, wave at Banane.
- **What they give in M3:** each plushie living in town gives **+5% buttons** brought home (up to 6 plushies = +30%).
  In M4 they also help in the siege.
- **M3 has 4 plushies**, un-zombified versions of the Bedroom zombies (fixed seams, both button eyes, bright
  colours): **Bunny, Frog, Piglet, Elephant**. Each has a name tag in town ("Pip the Bunny"). Each can only be
  rescued once; after all 4, no more rescues appear.

## 7. The Scrapbook (collection book)

- A **stand with a big open book** next to the fort; walk up and press **E** (also reachable from the title screen).
- **Pages:** Weapons (and evolutions), Items, Enemies (incl. elites and bosses), Floor pickups, Plushies.
- Every entry you've seen shows its felt picture, name and a one- or two-line explanation (weapons also show their
  evolution partner, vision: "no wiki needed"). **Unseen entries are blank silhouettes with "?"**.
- Each page shows a count ("Weapons 7 / 14").
- It is saved: once seen, always in the book. The pause-menu **Recipes** page from M2 now also remembers what you've
  seen across sessions.

## 8. Saving (hard rule 10, vision §6.6)

- **One save** (one town) in M3. Saved automatically after every run, after every build/upgrade, after a rescue
  moves in, and when you quit the game.
- **Mid-run:** while a run is going, the materials and rescue collected so far are saved every few seconds as a
  "run in progress". If the game closes mid-run, the next start counts that run as **quit** (50% kept, rescue kept).
  Resuming a run right where it stopped comes later (M6).
- The save file is versioned, so later milestones can add things without breaking old saves.
- **Settings → "Start over"** deletes the town after a double confirmation ("Really? Your whole town will be gone.").
- If the save file is damaged, the game keeps a backup of the last good save and loads that instead.

## 9. Co-op, developer menu, run log

- **Co-op (hard rule 11):** the town and its materials are **shared** (vision §7: shared town in M7). Every player
  walks around in town; anyone can build. Materials collected by any player go into the shared jars.
- **Developer menu** (also in town): give materials, build/upgrade any building, reset the town, start a rescue now,
  add a plushie, fill/clear the Scrapbook.
- **Run log:** `materials_collected`, `materials_kept`, `keep_share`, `rescue` (plushie, time, freed or not),
  `unlocked_weapons` at the start of the run.

## 10. Feel and readability

- Building pops in with a felt puff, a few stitches running around it, and a satisfying "fwump" sound; upgrading
  adds the new piece with a smaller puff.
- Material pickups in the run are **quieter than XP and much quieter than enemy danger** (hard rule 9): stuffing is
  soft white, thread spools are small. Nothing in the town is red/orange.
- The "Brought home" screen counts up with a rising "plip" (like the XP chain) and ends on "Back to the fort".
- The town has its own calm music loop (generated, like the run's).

## 11. Acceptance criteria

**Automated (scenario or unit tests)**
- **AC-37** New game → the town opens with the fort, the Bedroom door, the Scrapbook and exactly 2 plots; Banane can
  walk around and is blocked by buildings. *(scenario)*
- **AC-38** Pressing E at the Bedroom door starts a run; after the run (win, death or quit) the "Brought home" screen
  shows the right amounts and "Back to the fort" returns to the town. *(scenario)*
- **AC-39** In a run, XP buttons also count as buttons; stuffing and thread drop from the sources in §3 with the
  numbers from data; the HUD shows the run's haul. *(unit on the rules + scenario)*
- **AC-40** The keep share is applied: 100% + victory bonus after beating the King (and everything after it), 50%
  rounded up after death or quit. *(unit)*
- **AC-41** At a plot, E builds the building if the jars hold enough (the cost is taken), and does nothing but show
  the missing amount if not; upgrading works the same up to level 3; new plots appear after the 1st and 3rd
  building. *(scenario)*
- **AC-42** Each building's effect reaches the next run with the numbers from data: Armory weapon unlocks and
  starting weapon choice, Lucky Jar uses, Watchtower range, Snack Bar health, Party Shop drop gap. *(scenario per
  building)*
- **AC-43** A rescue appears in about every second run (from run 2), with an edge arrow; standing next to it fills
  the ring in 3 s (moving away pauses it); a freed plushie is brought home even if Banane dies later. *(scenario)*
- **AC-44** The first rescue reveals the Hospital plot; plushies wait until there's a bed, then move in and walk
  around; each adds +5% buttons to runs. *(scenario)*
- **AC-45** The Scrapbook shows seen entries with picture and text, unseen ones as "?", and the right counts; what you
  see in a run appears in the book afterwards. *(scenario)*
- **AC-46** Save → quit → load gives the same town: materials, building levels, plushies, Scrapbook, unlocks, run
  count. Closing mid-run counts the run as quit on the next start. A damaged save falls back to the backup.
  "Start over" resets everything. *(unit: save, reload, compare — hard rule 10)*
- **AC-47** Two players: both walk in town, both can build, materials from both go into the shared jars. *(scenario)*

**Playtest (product owner)**
- **P-12** After a run you want to go home and build something, and you already know what you want next.
- **P-13** The town looks clearly fuller after a session.
- **P-14** Rescuing a plushie feels worth the risk, and seeing it walk around town is nice.
- **P-15** The first building comes quickly (within the first 10 minutes of play).
- **P-16** Fewer weapons at the start doesn't feel like a loss, and unlocking them feels good.

## 12. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. **Materials:** XP buttons **double as the button currency**, plus stuffing and thread? (Alternative: a separate
   coin-like drop for the currency.)
2. **Keep share:** **100% on a win, 50% on death or quit**?
3. **The 6 buildings in §5** (Armory, Lucky Jar, Watchtower, Snack Bar, Party Shop, Plush Hospital)? Swap any you
   don't like; ideas for others are welcome (e.g. a *Cookie Oven*: start each run at level 2).
4. **Weapon unlocks:** start a new save with **6 of the 10 weapons**, the Armory unlocks the other 4? (Alternative:
   all 10 from the start, the Armory unlocks something else.)
5. **Rescues:** about **one run in two**, **4 plushies** (bunny, frog, piglet, elephant)? If your girlfriend's real
   plushies should appear here instead, tell me which.
6. **Mid-run quit** counts as a **quit run (50% kept)**; true resume comes later (M6)?
7. **Town name:** "**the Pillow Fort**"? (Alternatives: *Fluffington*, *Stitchville*, *Cushion Corner*.)

## 13. Not in this spec

- Night siege, invasion warning, repairing buildings (M4).
- Sewing Workshop, equipment, sewing patterns, blueprints (M4.5).
- New heroes and unlocking them (M5), new areas (M8+), idle production (M8+).
- Several save slots, cloud saves, resuming a run mid-way (later).
- Moving buildings around or free placement: plots are fixed in M3.

## 14. Proposed tickets (after approval)

1. Save system: versioned save file, backup, autosave points, "Start over", mid-run checkpoint — AC-46
2. Title → town → run → "Brought home" → town flow, with the town scene (walkable, fort, Bedroom door) — AC-37, 38
3. Materials in the run: buttons from XP, stuffing/thread drops, HUD jars, keep share, run log — AC-39, 40
4. Building plots: build/upgrade with E, costs, info card, pop-in, level looks, plot reveals, fort growth — AC-41
5. Toy Box Armory: weapon unlocks + starting weapon choice — AC-42
6. Lucky Jar + Watchtower + Snack Bar — AC-42
7. Party Shop — AC-42
8. Rescue in the run: yarn ball, edge arrow, 3 s freeing ring, backpack — AC-43
9. Plush Hospital + plushies living in town (4 looks, walking, +5% buttons) — AC-44
10. Scrapbook: pages, entries, silhouettes, saved "seen" state (Recipes too) — AC-45
11. Co-op in town, developer menu, town music and sounds pass — AC-47, §9, §10
