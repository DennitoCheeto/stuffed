# 03 — The Pillow Fort: town, materials, saving (M3)

Status: **DRAFT**, waiting for the product owner's approval (first round of answers worked in, 2026-10-22).
Milestone: **M3 — Town** (vision §10).
Based on: [`00-product-vision.md`](00-product-vision.md) §2, §4, §5 (The loop, Town, Rescued plushies, Collection
book), §6 (principles 2, 3, 4, 5, 6, 9); builds on [`01-core-run.md`](01-core-run.md) and
[`02-build-variety.md`](02-build-variety.md). The M2 acceptance playtest is postponed (product owner, 2026-10-22):
it will be played together with M3.

## 1. Goal

One question for this milestone: **after a run, do I want to go home, build something, and go out again?**

That's the product test (vision §4): *"I had a cool run, my town got visibly better, and I already know what I want to
build next."* M1 and M2 made the run fun. M3 adds the second half: runs bring home **materials**, the materials
**rebuild the wrecked town** you can see and walk around in, and every building changes your next run a little.
Progress is **saved**.

Still no night siege (M4), no equipment (M4.5) and no other heroes (M5). Buildings already get their siege role
written down (§5), but it only does something in M4.

## 2. What the player experiences

1. **Start the game** → title screen → **Continue** goes straight to the town (first time: **New game**).
2. **The Pillow Fort** is a small, cozy town built from pillows and blankets in a quiet corner of the house, but the
   zombie horde got there first: **every building is a wrecked ruin** (torn pillows, knocked-over blocks, yarn
   everywhere). Only the fort in the middle still stands. Banane walks around with WASD, like in a run (no zombies,
   no weapons).
3. The fort has the **Bedroom door**: walk up to it and press **E** → an expedition starts (the Bedroom run from M2).
4. During the run, every kill earns **coins** automatically (no extra pickups on the floor; XP buttons stay XP only).
   Bigger zombies and bosses also give **stuffing** and **thread** (§3).
5. After beating Big Ted, a **Way Home** portal opens: step in to go home early and keep everything, or stay and
   fight the King for the big rewards (§4).
6. At the end of the run a **"Brought home"** screen counts the haul into your jars.
7. Back in town, walk up to a ruin → press **E** → if you can pay, it's **rebuilt** with a felt puff and a sound.
   Rebuilt buildings can be **upgraded** the same way (3 levels), and they look bigger and fancier per level.
   Step by step the wrecked town turns into a cozy one.
8. Sometimes a run has a **plushie to rescue** (§7). Rescued plushies move into town and walk around.
9. The **Scrapbook** (the collection book, §8) shows everything you've found, with blank spots for what's missing.
10. Everything is **saved automatically**. Closing the game never loses buildings or materials.

## 3. Materials

Three materials in M3. **None of them lie on the floor**: they go straight into your jars, so the floor only has XP
buttons, gift boxes and floor pickups like before (product owner: collecting two kinds of buttons would be confusing).

| Material | Look | Where it comes from | Used for |
|----------|------|---------------------|----------|
| **Coins** | gold-foil chocolate coins (felt) | **Every kill**: a few per normal zombie, more for tanks and bloaters, a handful for elites, lots for Big Ted and the King | everything (the common currency) |
| **Stuffing** | a white fluffy tuft | Tanks and bloaters now and then, every elite, Big Ted and the King | level 2 upgrades, the Plush Hospital |
| **Thread** | a small coloured spool | Big Ted, the Sock Puppet King, and gift boxes | level 3 upgrades |

- **On the HUD:** small jar icons in a corner show the run's haul (quieter than the health bar). Normal kills just
  tick the counters up. Elites and bosses send a short burst of coins/tufts/spools **flying to the HUD jar** (never
  to the floor), so the big moments feel rewarding.
- **End of run:**

  | How the run ends | You keep |
  |------------------|----------|
  | **Beat the King** | **100%**, plus a **victory bonus** (coins + thread). Endless time after it is also kept at 100%. |
  | **Way Home portal** (after Big Ted, §4) | **100%**, but no victory bonus and no King rewards |
  | **Stuffed** (died) or **Give up** (pause menu) | **50%** (rounded up). Vision §6.4: no run is wasted. |

- **Fast first building** (vision §6.2): the cheapest rebuild costs about what a **5-minute first run that dies**
  brings home, so the first building comes in the first 10 minutes of play.
- All amounts, chances, the keep share and the victory bonus live in `data/town/material_rules.tres` (hard rule 8).

## 4. Going home early: the Way Home portal

- When **Big Ted** (mini-boss, 4:00) is beaten, a **Way Home** portal opens near the player: a glowing felt pillow
  door with soft swirls, a short banner ("The way home is open!") and a sound. An edge arrow points to it when it's
  off screen.
- **Stand in it for 2 seconds** (a ring fills; moving out pauses it) → the run ends and you go home with **100%** of
  your haul.
- The portal stays open until the King is beaten (after that, "End run" from M2 does the same job).
- The point: a real choice every run. **"Do I play it safe and take everything home, or risk it all for the King's
  thread and victory bonus?"** Dying to the King costs half.
- Portal colours are soft (blue/white), never the red/orange of enemy danger (hard rule 9).

## 5. The town

- **One screen-and-a-bit big.** The camera follows Banane, like in a run. Soft felt floor (a big blanket), the fort
  in the middle, the 6 ruins in a ring around it, a few cozy props (cushions, a lamp, building blocks).
- **Ruins show what they will become:** each ruin is a messy pile in the shape of its building, with a little sign
  showing the building's name, price and what it does. That way the whole town is a visible to-do list from the start.
- **Not everything can be rebuilt right away** (vision §6.9: reveal systems when they're needed): at the start only
  the **Toy Box Armory** and the **Lucky Jar** can be rebuilt. The others are tangled in zombie yarn with a hint:
  "Rebuild 1 building first", "Rebuild 3 buildings first", "Bring home a rescued plushie". When one becomes
  available, the yarn falls away with a short "New building!" moment.
- **The fort grows with the town:** after every 3 rebuilds/upgrades the fort gets a new piece (a flag, a second
  tower, string lights). The town should look clearly cozier after each session.
- **Short visits** (vision §6.5): rebuilding is "walk up, press E". No menus, no timers, no waiting.
- **Readable prices:** a sign shows the cost with jar icons; what you can't afford yet is grey with the missing
  amount ("needs 40 more stuffing").
- **Info:** standing next to a building shows a small card: name, level, what it does now, and what the next level
  adds.

## 6. Buildings (6)

Each building starts as a **ruin**. **Rebuilding it = level 1** (costs coins), **level 2** adds stuffing, **level 3**
adds thread. All costs and effects live in `data/town/buildings/*.tres`.

| Building | Can be rebuilt | What it does in town / in your runs | Siege role (M4, not in M3) |
|----------|----------------|-------------------------------------|----------------------------|
| **Toy Box Armory** | from the start | Lv 1: unlocks 2 more weapons for the level-up cards. Lv 2: 2 more. Lv 3: choose Banane's **starting weapon** before a run. | turret that fires one of your weapons |
| **Lucky Jar** | from the start | Each level: **+1 reroll, +1 skip, +1 banish** per run. | bait: zombies go for it |
| **Watchtower** | after 1 rebuild | Each level: + pickup range (+10% / +20% / +30%). | long-range turret |
| **Snack Bar** | after 1 rebuild | Each level: + max health (+10 / +20 / +30). | healing spot |
| **Party Shop** | after 3 rebuilds | Floor pickups (spec 02b) drop more often (−15% / −30% / −45% gap). Lv 3: the first one drops after 15 s. | confetti trap |
| **Plush Hospital** | after the 1st rescue (§7) | Stitches up rescued plushies so they move in. Lv 1: room for 2 plushies, Lv 2: 4, Lv 3: 6. | revives fallen plushies |

**Weapon unlocks (Toy Box Armory):** a new save starts with **6 weapons** in the level-up pool: Peel Boomerang,
Sewing-Pin Sniper, Orbiting Needles, Button Shotgun, Stuffing Cloud, Yarn Cannon (every evolution of M2 is still
possible). Lv 1 adds **Bouncy Yarn Ball + Thimble Mortar**, Lv 2 adds **Thread Whip + Zipper Ray**. Fewer cards at
the start makes the first runs easier to learn; unlocking new weapons is a "sideways" unlock (vision §6.3). All
items stay unlocked from the start.

**Stat bonuses are small and capped** (vision §6.3): Watchtower and Snack Bar are the only plain number bonuses,
3 levels each.

**Fits M4:** in the night siege, buildings can be damaged back towards a ruin and repaired (vision §5), so "ruin →
rebuilt" is the same look and idea the siege will use.

## 7. Rescued plushies

- **Who:** the rescued plushies are **the girlfriend's real stuffed animals**. The product owner sends a photo and a
  name for each when this ticket starts; until then the code uses simple placeholder looks. M3 has room for **4**.
- **In the run:** from the second run on, about **one run in two** has a rescue (between 2:00 and 6:00). A plushie
  that isn't fully zombified yet sits **tangled in a ball of yarn** somewhere in the Bedroom. An edge arrow points to
  it (like floor pickups) and a soft "help!" squeak plays once.
- **Freeing it:** stand next to it for **3 seconds** (a ring fills up). Zombies keep coming, so it's a small risk.
  Moving away pauses the ring; it doesn't reset. When the ring is full, the plushie hops into Banane's backpack
  (it's safe now: dying later still brings it home).
- **At home:** the first rescue makes the **Plush Hospital** ruin rebuildable. Rescued plushies wait in a little tent
  until there's a bed in the Hospital, then they're stitched up (a short moment) and **move into town**: they walk
  around, sit on cushions, wave at Banane, and have a name tag.
- **What they give in M3:** each plushie living in town gives **+5% coins** brought home (4 plushies = +20%).
  In M4 they also help in the siege.
- Each plushie can only be rescued once; after all of them are home, no more rescues appear.

## 8. The Scrapbook (collection book)

- A **stand with a big open book** next to the fort; walk up and press **E** (also reachable from the title screen).
- **Pages:** Weapons (and evolutions), Items, Enemies (incl. elites and bosses), Floor pickups, Plushies.
- Every entry you've seen shows its felt picture, name and a one- or two-line explanation (weapons also show their
  evolution partner, vision: "no wiki needed"). **Unseen entries are blank silhouettes with "?"**.
- Each page shows a count ("Weapons 7 / 14").
- It is saved: once seen, always in the book. The pause-menu **Recipes** page from M2 now also remembers what you've
  seen across sessions.

## 9. Saving (hard rule 10, vision §6.6)

- **One save** (one town) in M3. Saved automatically after every run, after every rebuild/upgrade, after a rescue
  moves in, and when you quit the game.
- **Mid-run:** while a run is going, the haul and rescue collected so far are saved every few seconds as a
  "run in progress". If the game closes mid-run, the next start counts that run as **given up** (50% kept, rescue
  kept). Resuming a run right where it stopped comes later (M6).
- The save file is versioned, so later milestones can add things without breaking old saves.
- **Settings → "Start over"** deletes the town after a double confirmation ("Really? Your whole town will be gone.").
- If the save file is damaged, the game keeps a backup of the last good save and loads that instead.

## 10. Co-op, developer menu, run log

- **Co-op (hard rule 11):** the town and its materials are **shared** (vision §7: shared town in M7). Every player
  walks around in town; anyone can rebuild. Kills by any player go into the shared jars. The Way Home portal takes
  everybody home once one player has filled it.
- **Developer menu** (also in town): give materials, rebuild/upgrade any building, reset the town, open the Way Home
  portal, start a rescue now, add a plushie, fill/clear the Scrapbook.
- **Run log:** `materials_collected`, `materials_kept`, `run_end` (`king`, `way_home`, `died`, `gave_up`),
  `rescue` (plushie, time, freed or not), `unlocked_weapons` at the start of the run.

## 11. Feel and readability

- Rebuilding: the ruin shakes, a felt puff, stitches run around it, and the building pops up with a satisfying
  "fwump" sound; upgrading adds the new piece with a smaller puff.
- Coin/tuft bursts flying to the HUD are **quieter than XP and much quieter than enemy danger** (hard rule 9).
  Nothing in the town is red/orange.
- The "Brought home" screen counts up with a rising "plip" (like the XP chain) and ends on "Back to the fort".
- The town has its own calm music loop (generated, like the run's).

## 12. Acceptance criteria

**Automated (scenario or unit tests)**
- **AC-37** New game → the town opens with the fort, the Bedroom door, the Scrapbook and 6 ruins, of which exactly
  2 can be rebuilt; Banane can walk around and is blocked by buildings and ruins. *(scenario)*
- **AC-38** Pressing E at the Bedroom door starts a run; after the run (King, Way Home, death or give up) the
  "Brought home" screen shows the right amounts and "Back to the fort" returns to the town. *(scenario)*
- **AC-39** In a run, kills add coins (and stuffing/thread from the sources in §3) straight to the run's haul with
  the numbers from data; nothing new drops on the floor; XP buttons give only XP; the HUD shows the haul.
  *(unit on the rules + scenario)*
- **AC-40** The keep share is applied: 100% + victory bonus after beating the King (and everything after it), 100%
  without bonus through the Way Home portal, 50% rounded up after death or give up. *(unit)*
- **AC-41** Beating Big Ted opens the Way Home portal with a banner and an edge arrow; standing in it for 2 s
  (moving out pauses the ring) ends the run and goes home; it is not there before Big Ted is beaten. *(scenario)*
- **AC-42** At a ruin, E rebuilds the building if the jars hold enough (the cost is taken), and does nothing but show
  the missing amount if not; upgrading works the same up to level 3; locked ruins become rebuildable after 1 and 3
  rebuilds and after the first rescue. *(scenario)*
- **AC-43** Each building's effect reaches the next run with the numbers from data: Armory weapon unlocks and
  starting weapon choice, Lucky Jar uses, Watchtower range, Snack Bar health, Party Shop drop gap. *(scenario per
  building)*
- **AC-44** A rescue appears in about every second run (from run 2), with an edge arrow; standing next to it fills
  the ring in 3 s (moving away pauses it); a freed plushie is brought home even if Banane dies later. *(scenario)*
- **AC-45** Plushies wait until there's a bed in the Hospital, then move in and walk around; each adds +5% coins to
  runs. *(scenario)*
- **AC-46** The Scrapbook shows seen entries with picture and text, unseen ones as "?", and the right counts; what you
  see in a run appears in the book afterwards. *(scenario)*
- **AC-47** Save → quit → load gives the same town: materials, building levels, plushies, Scrapbook, unlocks, run
  count. Closing mid-run counts the run as given up on the next start. A damaged save falls back to the backup.
  "Start over" resets everything. *(unit: save, reload, compare — hard rule 10)*
- **AC-48** Two players: both walk in town, both can rebuild, kills by both go into the shared jars, the portal takes
  both home. *(scenario)*

**Playtest (product owner)**
- **P-12** After a run you want to go home and build something, and you already know what you want next.
- **P-13** Rebuilding the wrecked town feels good, and it looks clearly cozier after a session.
- **P-14** The Way Home portal is a real choice ("go home or fight the King?").
- **P-15** Rescuing a plushie feels worth the risk, and seeing it walk around town is nice.
- **P-16** The first building comes quickly (within the first 10 minutes of play).
- **P-17** Fewer weapons at the start doesn't feel like a loss, and unlocking them feels good.

## 13. Decisions (product owner, 2026-10-22)

1. **Materials:** XP buttons stay XP only. The currency is **coins, earned straight from kills** (more from
   elites/bosses), never picked up from the floor. Stuffing and thread work the same way.
2. **Keep share:** 100% on a win, 50% on death or give up, plus a **way to go home early** with everything
   (Way Home portal after Big Ted, §4).
3. **The 6 buildings** in §6, and they **start as ruins** you rebuild (§5).
4. **Weapon unlocks:** a new save starts with 6 of the 10 weapons; the Armory unlocks the other 4.
5. **Rescued plushies are the girlfriend's real plushies**; photos and names come from the product owner when that
   ticket starts.
6. **Mid-run quit** counts as giving up (50% kept); true resume comes later (M6).
7. **Town name:** the Pillow Fort.

Still open (my proposal in bold; approving the spec means "yes"):
- Way Home opens **after Big Ted** (not earlier), and you have to **stand in it for 2 s**?
- Coins for **every kill**, with a burst flying to the HUD only for elites and bosses?

## 14. Not in this spec

- Night siege, invasion warning, repairing buildings after a siege (M4).
- Sewing Workshop, equipment, sewing patterns, blueprints (M4.5).
- New heroes and unlocking them (M5), new areas (M8+), idle production (M8+).
- A **skill tree / progress tree** (product owner idea, 2026-10-22): later, its own spec.
- Several save slots, cloud saves, resuming a run mid-way (later).
- Moving buildings around or free placement: building spots are fixed in M3.

## 15. Proposed tickets (after approval)

1. Save system: versioned save file, backup, autosave points, "Start over", mid-run checkpoint — AC-47
2. Title → town → run → "Brought home" → town flow, with the town scene (walkable, fort, Bedroom door) — AC-37, 38
3. Materials in the run: coins/stuffing/thread from kills and bosses, HUD jars and bursts, keep share, run log —
   AC-39, 40
4. Way Home portal after Big Ted — AC-41
5. Ruins and rebuilding: rebuild/upgrade with E, costs, info card, rebuild moment, level looks, unlock hints, fort
   growth — AC-42
6. Toy Box Armory: weapon unlocks + starting weapon choice — AC-43
7. Lucky Jar + Watchtower + Snack Bar — AC-43
8. Party Shop — AC-43
9. Rescue in the run: yarn ball, edge arrow, 3 s freeing ring, backpack (placeholder looks) — AC-44
10. Plush Hospital + plushies living in town (the girlfriend's plushies from photos, walking, +5% coins) — AC-45
11. Scrapbook: pages, entries, silhouettes, saved "seen" state (Recipes too) — AC-46
12. Co-op in town, developer menu, town music and sounds pass — AC-48, §10, §11
