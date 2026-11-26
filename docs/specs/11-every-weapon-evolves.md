# 11 — Every weapon evolves (6 more evolutions)

Status: **DRAFT**, waiting for the product owner's approval (spec PR).
Milestone: **Playtest fixes (Nov 2026)**, issue #333.
Based on: the big playtest (2026-11-21): *"all weapons need an evolved state"*; research
[`docs/research/05-evolution-research.md`](../research/05-evolution-research.md). Builds on
[`02-build-variety.md`](02-build-variety.md) §4-5 (items, evolution rule) and
[`10-look-and-feel.md`](10-look-and-feel.md) §3 (the evolution "wow" pass and the evolution moment).

## 1. Goal

One question: **is every weapon worth maxing?**

Today 6 of 12 weapons evolve. The other six (Bouncy Yarn Ball, Button Shotgun, Stuffing Cloud, Thimble Mortar,
Thread Whip, Zipper Ray) are a dead end at level 5, so players learn to skip them. After this spec **all 12 weapons
evolve**, each into something that plays differently, with the same big moment the M6 evolutions have.

## 2. What the player experiences

1. A run with the Button Shotgun at level 5 and Quick Hands. The shotgun's card already showed the Quick Hands icon
   (as today). The loadout page says "Ready". The next gift box plays the sewing reveal: shotgun + hands →
   **Bowling Buttons**, "EVOLVED!".
2. Back in the run: slow motion, a ring pulse, a huge first blast. Zombies the buttons hit now tumble backwards into
   the crowd behind them and knock those over too. The player starts walking *into* the front of a crowd on purpose.
3. Next run they try the Stuffing Cloud: evolved, it leaves a trail of fluff behind them and every zombie that pops
   in it mends a little stuffing. They start running loops so the zombies follow through the trail.
4. In the pause menu, Recipes now lists **12** recipes; the Scrapbook has 12 evolution pages to fill.

## 3. The rule (unchanged)

Same as spec 02 §5: a weapon at **level 5** + its **partner item** (any level) → the next **gift box** evolves it.
The weapon is replaced, the item stays. The partner items are the ones spec 02 §4 already promised (the weapon
cards show them today), so nothing a player has learned changes:

| Weapon | + Partner item | → Evolution |
|---|---|---|
| Bouncy Yarn Ball | Magnet Pocket | **Cat's Cradle** |
| Button Shotgun | Quick Hands | **Bowling Buttons** |
| Stuffing Cloud | Extra Stuffing | **Comfy Cloud** |
| Thimble Mortar | Big Spool | **Hopscotch Mortar** |
| Thread Whip | Sharp Scissors | **Lasso Lash** |
| Zipper Ray | Long Thread | **Unzipper** |

After this every item is some weapon's partner: Quick Feet (1 weapon), Quick Hands (1), Magnet Pocket (1),
Thick Felt (1), Extra Stuffing (2), Sharp Scissors (2), Long Thread (2), Big Spool (2).

All six base weapons are on everyone's cards, so the new evolutions need no hero unlock.

## 4. The six evolutions

Each one = the level-5 weapon a bit stronger (numbers below) **plus one new behaviour** that changes how you play,
its own **sting** (sound), its own **evolved look** (bigger, still quieter than zombies, rule 9) and the M6
**evolution moment** (spec 10 §3: sewing reveal, slow motion, pulse, big first attack). Every number lives in the
evolved weapon's `.tres` (rule 8); these are first guesses for the playtest.

### 4.1 Cat's Cradle (Bouncy Yarn Ball + Magnet Pocket)

- **Stronger:** 3 balls (was 2), bounces between 10 zombies (was 8), damage 16 (was 12), every 1.4 s (was 1.6).
- **New: the ball unwinds.** Every bounce stretches a yarn thread from the last bounce point to the new one. Threads
  stay **2.5 s** and hurt any zombie touching them (**4 damage every 0.5 s**). At most **20 threads** on the floor
  (the oldest one goes). In a crowd the ball draws a string figure that keeps cutting.
- **Partner flavour (Magnet Pocket):** the ball snags XP buttons it rolls over and sends them flying to the hero.
- *Plays differently:* you want zombies spread around you so the ball criss-crosses the screen.

### 4.2 Bowling Buttons (Button Shotgun + Quick Hands)

- **Stronger:** 9 buttons (was 7), damage 12 (was 9), every 1.0 s (was 1.2), stronger push.
- **New: zombie bowling.** A zombie knocked back by a button tumbles for **0.4 s**. While tumbling it hurts
  (**10 damage**) and knocks back every zombie it bumps into. Bumped zombies do **not** tumble themselves (one
  step only, so it can't run forever). A tumble that knocks over 3 or more plays a little "strike" sound.
- Elites tumble half as far. **Bosses never tumble** (they take the button damage only), so boss patterns stay
  intact (#327).
- *Plays differently:* you walk into the front of a crowd on purpose and bowl it over.

### 4.3 Comfy Cloud (Stuffing Cloud + Extra Stuffing)

- **Stronger:** cloud radius 180 (was 160), damage 8 (was 6), same puff beat (0.3 s).
- **New: fluff trail.** While the hero walks, a puff of fluff drops behind them every **0.4 s**. Puffs stay
  **3 s**, are **60 px** wide and hurt zombies inside them on the cloud's beat (**5 damage**). At most **8 puffs**.
- **Partner flavour (Extra Stuffing): mend.** Each zombie that pops inside the cloud or a puff mends the hero
  **1 health**, at most **4 health per second**. Only the cloud's own hero is mended (co-op).
- *Plays differently:* you run loops so the zombies chase you through your own trail.

### 4.4 Hopscotch Mortar (Thimble Mortar + Big Spool)

- **Stronger:** damage 24 (was 20), blast 64 (was 54), every 1.8 s (was 2.0), still 3 thimbles.
- **New: hopscotch.** After landing, each thimble **hops onward twice** in the direction it was flying (away from
  the hero), **110 px** per hop. Every landing is a full blast; the last one is **1.3× bigger**. The ring on the
  floor shows the next landing spot before each hop (as the mortar ring does today, spec 02 §20).
- *Plays differently:* every thimble clears a short line outwards, so blasts reach the second and third row of a
  crowd.

### 4.5 Lasso Lash (Thread Whip + Sharp Scissors)

- **Stronger:** damage 30 (was 24), arc length 170 (was 150), same beat (1.0 s, front and back).
- **New: lasso.** Every **3rd lash** ropes the **toughest zombie** in the front arc (an elite first, never a
  boss), swings it **once around the hero** (0.5 s), hurting every zombie it passes (**20 damage** + push), then
  **flings it towards the cursor**. While swung it can't hurt anyone.
- **Partner flavour (Sharp Scissors): snip.** Where the thrown zombie lands, the thread is snipped: it takes
  **3× lash damage**.
- If a boss is the only big target in the arc, that lash hits it for **double damage** instead (bosses are never
  moved).
- *Plays differently:* you aim at the big ones and use them as a club against the crowd.

### 4.6 Unzipper (Zipper Ray + Long Thread)

- **Stronger:** damage 12 (was 9), beam 700 long (was 650), lasts 1.4 s (was 0.9), every 2.0 s (was 2.2).
- **New: the zipper opens.** The beam fires towards the cursor as today, then splits into **two halves that sweep
  apart, 50° to each side**, over the beam's time (like a zipper opening), and then **snap shut** back to the
  middle. Every zombie a half swept over takes a **zip-shut hit of 25** when the halves meet again.
- *Plays differently:* instead of a thin line, it covers a wide wedge towards the cursor; you point it at the
  middle of a crowd.

## 5. Where it shows (all from the data, nothing hand-made)

- **Weapon cards:** the partner icon (already there).
- **Recipes** (pause menu): 12 recipes, unseen evolutions as "?" (as today). Must fit the screen (fit check).
- **Scrapbook:** 12 evolution pages; the text is the evolution's one-liner.
- **Loadout page** (spec 04b): "next evolution" / "Ready" works for all 12.
- **Gift box:** the sewing reveal (weapon icon + item icon → evolved icon).
- **End screen and run titles:** each evolved weapon gets its own row and its own run title (e.g. "Strike!"
  for Bowling Buttons).
- **New hint `evolution_how`** (PO OK'd 2026-11-21, was to be added to spec 10 §6): the first time a weapon reaches
  level 5 **without** its partner item: *"Maxed! Its partner item (icon on the card) evolves it"*. Shows once per
  save like the other hints (no save change: `hints_seen` is a list of ids).

## 6. Co-op (hard rule 11)

Each hero evolves their own weapons. Every new effect belongs to the hero who owns the weapon: Cat's Cradle sends
XP to its own hero, Comfy Cloud mends only its own hero, Lasso Lash throws towards its own hero's cursor. Two heroes
can both have the same evolution.

## 7. Siege

Evolutions work in the siege like any weapon (the siege uses the run's cards). Thrown or tumbling zombies never
damage buildings or the fort. Turrets keep using base weapons.

## 8. Save (hard rule 10)

Nothing new is saved. Seen evolutions go into the Scrapbook and `RecipeBook` as today (save v3 lists); the new hint
id goes into `hints_seen`. Test: the Scrapbook save/reload test covers a new evolution page.

## 9. Developer menu and log

- Run dev menu: "Evolve now" and "Max everything" work for the new six (they read the pool).
- Run log: `evolutions` lists the new names (as today).

## 10. Readability and performance

- Every new visual (threads, tumbling zombies, fluff puffs, mend sparkle, hop rings, lasso rope, zipper halves)
  goes into the colour sweeps: no danger colours, quieter than the zombies' ink on every floor (dusk too).
- A tumbling or swung zombie keeps its normal zombie look (it's still a danger), with a calm motion streak.
- Lasting effects are drawn batched (one draw call for all threads, pooled puffs/shots), like the M6 evolutions.
- Benchmark (`tools/benchmark.gd`) with the **six new evolutions at once** and 500 zombies: at most **+15 draw calls**
  compared to the same six base weapons at level 5, no new hitches (worst frame).

## 11. Acceptance criteria

- **AC-120** Each base weapon at level 5 + its partner item (§3) evolves at the next gift box into its evolution;
  the item stays.
- **AC-121** Cat's Cradle leaves threads between bounce points that hurt zombies for their lifetime (max 20) and
  sends XP buttons it touches to its hero.
- **AC-122** Bowling Buttons makes knocked-back zombies tumble and knock over the zombies they bump into (one step
  only); bosses never tumble.
- **AC-123** Comfy Cloud drops fluff puffs while the hero walks (max 8) that hurt zombies, and kills inside the cloud
  or puffs mend its hero (capped per second).
- **AC-124** Hopscotch Mortar thimbles hop twice onward after landing, each landing a blast, the last one bigger.
- **AC-125** Lasso Lash ropes the toughest non-boss zombie every 3rd lash, swings it through the crowd and throws it
  towards the cursor, where it takes the snip damage; a boss takes double damage instead.
- **AC-126** Unzipper's beam splits, sweeps open to both sides and snaps shut, hitting every swept zombie again.
- **AC-127** Each new evolution plays the evolution moment with its own sting, shows on Recipes (12 recipes, fits the
  screen), Scrapbook, loadout page, end screen and run titles; the MVP content test checks that **every weapon in
  the pool has an evolution**.
- **AC-128** The `evolution_how` hint shows the first time a weapon is maxed without its partner, once per save.
- **AC-129** The new visuals pass the colour sweeps; the benchmark stays within §10.
- **P-43** (playtest) I now max any weapon, not just the six that used to evolve.
- **P-44** (playtest) Each of the six new evolutions made me play a bit differently.

## 12. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Partner items as already shown on the cards (spec 02 §4)? **Yes**: players don't have to relearn anything.
2. Lasso Lash and Bowling Buttons never move bosses (bosses take extra damage instead)? **Yes**: moving bosses
   breaks their attack patterns (like the near-permanent slip in #327).
3. Comfy Cloud heals (max 4 health per second)? **Yes**, and we tune it down after the playtest if it makes runs too
   easy.
4. Names: Cat's Cradle, Bowling Buttons, Comfy Cloud, Hopscotch Mortar, Lasso Lash, Unzipper? **Yes** (rename any you
   don't like, it's one line of data each).

## 13. Not in this spec

- Evolutions for BamBam and Robbar (they have no own weapon yet), double evolutions (evolving an evolved weapon),
  evolutions with two items.
- Changes to the six existing evolutions.
- New weapons or items.

## 14. Proposed tickets (after approval)

1. Cat's Cradle + Bowling Buttons — AC-120, AC-121, AC-122
2. Comfy Cloud + Hopscotch Mortar — AC-120, AC-123, AC-124
3. Lasso Lash + Unzipper — AC-120, AC-125, AC-126
4. Recipes / Scrapbook / titles fit, `evolution_how` hint, MVP content test, colour sweeps, benchmark — AC-127,
   AC-128, AC-129

Tickets 1-3 each add their evolutions with sting, look, recipe and scenario tests; ticket 4 closes the readability
and performance check over all six.
