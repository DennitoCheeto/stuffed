# 02 — Build variety: the Bedroom, complete (M2)

Status: **DRAFT**, waiting for product owner approval.
Milestone: **M2 — Build variety** (vision §10).
Based on: [`00-product-vision.md`](00-product-vision.md) §5 (Enemies, Combat, Banane), §6; builds on
[`01-core-run.md`](01-core-run.md) (accepted 2026-10-21).

## 1. Goal

One question for this milestone: **do I want to try a different build next run?**

M1 proved that a single run feels good. The playtest said: *"I wanna see how much I can upgrade my character and how
crazy my attacks get."* M2 answers that. There are many more weapons and items to choose from, weapons **evolve**
into something spectacular, the player gets some control over bad luck, and the Bedroom becomes a complete area
with a mini-boss in the middle and a boss at the end.

Still no town, materials or saving (M3). Banane is still the only hero (M5).

## 2. What the player experiences

1. **Start run** → the Bedroom, now with furniture (bed, toy box, rug, building-block towers) to move around.
2. At each level-up you pick from a much bigger pool: **10 weapons** and **8 items**. Each run you can carry up to
   **6 weapons and 6 items**, so every run is a different mix.
3. The horde gets more varied: **spitters** shoot slow stuffing balls you dodge, **bloaters** burst when killed,
   **tanks** soak up damage. Now and then an **elite** (a big zombie with a gold patch) appears.
4. Elites drop a **gift box**. Opening it is a short, big moment (Banane puts on his sunglasses) and gives you
   upgrades, or an **evolution** if you have the right weapon + item pair.
5. At **4:00** the **mini-boss** arrives: Big Ted. At **8:00** the **boss** arrives: the Sock Puppet King. Beating the
   boss is the area's goal → **End run** or **Keep going (endless)**, as in M1.
6. Bad cards? Use one of your **rerolls**, **skips** or **banishes**.

## 3. Weapons (10)

All weapons fire on their own (spec 01 decision 1). Each has **5 levels**. The two M1 weapons stay as they are.
Every weapon has an **evolution partner** (an item, §4). Evolutions are in §5.

| # | Weapon | Kind | What it does |
|---|--------|------|--------------|
| 1 | **Peel Boomerang** (M1) | auto | Thrown at the nearest zombie, flies back, hits on both legs |
| 2 | **Sewing-Pin Sniper** (M1) | aimed | Long pin towards the cursor, pierces a few zombies in a line |
| 3 | **Orbiting Needles** | auto | Needles circle around Banane and hit whatever they touch |
| 4 | **Button Shotgun** | auto | A short-range spread of buttons at the nearest zombie, with knockback |
| 5 | **Stuffing Cloud** | auto | A soft cloud around Banane that hurts zombies inside it a few times a second |
| 6 | **Bouncy Yarn Ball** | auto | A yarn ball that bounces between zombies and off walls |
| 7 | **Thimble Mortar** | auto | Lobs a thimble at a random zombie on screen; it lands with a small area hit (shadow shows where) |
| 8 | **Yarn Cannon** | aimed | A slow, heavy yarn ball towards the cursor that bursts on impact |
| 9 | **Thread Whip** | aimed | A quick lash in a wide arc towards the cursor |
| 10 | **Zipper Ray** | aimed | Every few seconds, a short-lived beam towards the cursor that hits everything in the line |

Levels add things the card names exactly: more projectiles, damage, area, speed, pierce, duration. The numbers are
in the weapon's `.tres` file (hard rule 8).

## 4. Items (8)

Items replace the four M1 boosts. They're simple, readable bonuses with up to **5 levels**. Each one is also the
evolution partner of one or two weapons.

| Item | Effect per level | Partner of |
|------|------------------|------------|
| **Quick Feet** (M1) | + move speed | Peel Boomerang |
| **Quick Hands** (M1) | all weapons fire faster | Button Shotgun |
| **Magnet Pocket** (M1) | + pickup range | Bouncy Yarn Ball |
| **Extra Stuffing** (M1) | + max health (also heals that much) | Stuffing Cloud |
| **Sharp Scissors** | + damage for all weapons | Sewing-Pin Sniper, Thread Whip |
| **Long Thread** | + duration and range | Orbiting Needles, Zipper Ray |
| **Big Spool** | + area (cloud, bursts, arcs get bigger) | Yarn Cannon, Thimble Mortar |
| **Thick Felt** | − damage taken | (no partner; pure defence) |

## 5. Evolutions

- **Rule:** a weapon at **level 5** + its **partner item** (any level) → the next **gift box** evolves the weapon.
  The weapon is replaced by its evolved form; the item stays.
- **Visible recipes, no wiki:** the level-up card of a weapon shows its partner item's icon, and the pause menu has a
  **Recipes** page listing all pairs (evolved forms you haven't seen yet are shown as "?").
- **In M2: 4 evolutions**, each clearly bigger than the base weapon:

| Evolution | From | What changes |
|-----------|------|--------------|
| **Banana Split** | Peel Boomerang + Quick Feet | On the way back the boomerang splits into three |
| **Sewing Storm** | Orbiting Needles + Long Thread | A permanent storm of needles; every few seconds it flings them outward |
| **Pincushion Volley** | Sewing-Pin Sniper + Sharp Scissors | A fan of piercing pins; no pierce limit |
| **Yarn Bomb** | Yarn Cannon + Big Spool | The burst leaves sticky yarn that slows and hurts zombies |

The other weapons get their evolutions in later milestones (vision MVP: 10 weapons, 3+ evolutions).

## 6. Gift box

- **Dropped by** elites, the mini-boss and the boss. It sits on the floor with a soft glow until Banane touches it.
- **Opening** pauses the game for a short, big moment: the box wobbles, the lid pops, Banane puts his sunglasses on,
  confetti. It takes about 2 seconds and can be skipped with a key press.
- **Contents:** if a weapon is ready to evolve → that evolution. Otherwise **1–3 level-ups** of items or weapons Banane
  already has (more from the boss's box). If everything is maxed → a big heal.

## 7. Control over bad luck

On the level-up screen, with keys and mouse:

| Button | Key | What it does | Per run (M2) |
|--------|-----|--------------|--------------|
| **Reroll** | R | 3 new cards | 3 |
| **Skip** | S | Take nothing, get a small heal | 3 |
| **Banish** | B, then 1/2/3 | That card never shows up again this run, and its slot is redrawn | 2 |

The remaining count is shown on each button. In M3 the town will unlock more of these.

## 8. Enemies

M1's shamblers and runners stay. New:

| Enemy | Behaviour | From about |
|-------|-----------|------------|
| **Spitter** (zombie frog) | Keeps some distance and shoots slow stuffing balls in simple patterns (single shot, then 3-shot fans). A short wind-up (it puffs up) shows a shot is coming. | 1:30 |
| **Bloater** (zombie balloon pig) | Slow; when killed it bursts into a stuffing cloud that hurts Banane for a moment. Don't kill it up close. The cloud's area is shown clearly. | 2:30 |
| **Tank** (zombie elephant) | Big, slow, lots of health, heavy contact damage. A target for aimed weapons. | 3:00 |

**Elites:** a bigger version of a normal enemy with a gold patch and a crown of stitches. More health, and it fires
one telegraphed pattern. Each elite drops a **gift box**. Roughly 3–4 per run before the boss.

**Readability (vision §6.1):** enemy bullets are the highest-contrast thing on screen (bright, with a dark outline),
always slower than Banane, and always fired after a visible wind-up. Banane's own effects stay softer, also when
many weapons are evolved.

## 9. Mini-boss and boss

Both are announced with a short banner and sound, have a big health bar at the top of the screen, and use clear
patterns that are **telegraphed before they fire**. While they're on the field, normal spawning is lighter.

**Big Ted (mini-boss, 4:00).** A giant zombie teddy. Patterns: (1) **charge**: a red line shows the path, then he
charges along it; (2) **stomp**: a ring of stuffing balls spreads out. Drops a gift box.

**The Sock Puppet King (boss, 8:00).** A zombie sock puppet wearing a cardboard crown. Patterns: (1) **sock spiral**:
a slow rotating spiral of stuffing balls; (2) **summon**: calls a ring of runners; (3) at half health he gets angry
and adds a **lunge** with a telegraphed landing spot. Beating him: all zombies pop, a big gift box, then **"You beat
the Bedroom!" → End run / Keep going (endless)** as in M1.

If Banane hasn't beaten the boss, the run continues until he does (or until Banane falls). Dying before the boss is
beaten is a loss.

## 10. The Bedroom, complete

- **Length:** the run is now about **8 minutes** to the boss (M1: 5). Same surge/breather rhythm.
- **Spawn schedule** (data file): shamblers → runners (1:00) → spitters (1:30) → bloaters (2:30) → tanks (3:00),
  elites spread out, mini-boss at 4:00, boss at 8:00.
- **Furniture:** a few large pieces (bed, toy box, block towers) that block Banane, zombies and zombie bullets. Zombies
  slide around them; Banane's projectiles pass over them, so they never feel unfair. Placed by hand, the same each run.
- **Endless** after the boss works as in M1 (tougher every minute), now with all enemy types and elites.
- **Music:** a boss track for the boss fight (generated or CC0, recorded in `docs/art/credits.md`).

## 11. HUD and level-up cards

- The HUD shows owned weapons and items as two rows of small icons with their level (6 slots each).
- With full slots, only upgrades for owned weapons and items are offered.
- Cards show: icon, name, "New!" or "Lv 2 → 3", one line of effect, and the partner icon for weapons.
- Card odds and slot counts live in `upgrade_pool.tres`.

## 12. Sounds and feel

New sounds for each weapon (soft, not noisy, limited like in M1), spitter wind-up and shot, bloater burst, elite
appears, gift box open, evolution, boss banner, boss hit and boss defeated. Evolutions get a stronger, distinct
sound and look so they *feel* bigger.

## 13. Developer menu and run log

**Developer menu adds:** give any weapon or item at any level; make a weapon ready to evolve; drop a gift box;
spawn 1 / 10 of each enemy type; spawn an elite; jump to the mini-boss / boss; refill rerolls/skips/banishes;
**"Max everything"** (6 weapons and 6 items at level 5, all possible evolutions) for performance checks.

**Run log adds:** evolutions (and when), rerolls/skips/banishes used, mini-boss and boss defeat times, enemy type that
killed Banane.

## 14. Performance

M1 runs at 144 fps on the product owner's PC. M2 adds far more projectiles, so the target from the vision has to hold
in the worst case: **500 zombies + "Max everything" + boss bullets → 60 fps**. Projectiles and enemy bullets use the
same baked-sprite approach as zombies (no per-frame shape drawing).

## 15. Ready for local co-op (hard rule 11)

As in M1: weapons, items and rerolls belong to a player; bosses target the nearest player; a gift box opens for the
player who touches it; enemy bullets hurt any player.

## 16. Acceptance criteria

Scenario tests in `tests/scenarios/test_02_build_variety.gd` unless marked *(unit)*.

**Weapons and items**
- **AC-1** Each of the 8 new weapons can be picked from a card and then fires on its own as described in §3
  (aimed ones towards the cursor). *(one scenario per weapon)*
- **AC-2** Weapon levels 2–5 change the weapon as their card says. *(unit for the numbers, scenario for one visible
  change per weapon)*
- **AC-3** Each item's effect applies (e.g. Thick Felt reduces damage taken, Big Spool makes areas bigger).
  *(unit + one scenario)*
- **AC-4** Banane can hold at most 6 weapons and 6 items; with full slots only owned things are offered. *(unit)*
- **AC-5** The HUD shows owned weapons and items with their levels.

**Evolutions and gift box**
- **AC-6** An elite drops a gift box; touching it opens it with the gift box moment.
- **AC-7** With a level-5 weapon and its partner item, the next gift box evolves it; the evolved weapon behaves as
  described in §5. *(one scenario per evolution)*
- **AC-8** Without anything to evolve, a gift box gives 1–3 level-ups of owned things; if all is maxed, a heal.
  *(unit)*
- **AC-9** Weapon cards show the partner icon; the Recipes page lists all pairs, unseen evolutions as "?".

**Control over bad luck**
- **AC-10** Reroll gives 3 new cards and uses one reroll; with 0 left the button is disabled. *(scenario + unit)*
- **AC-11** Skip closes the level-up without an upgrade, heals a little, uses one skip.
- **AC-12** A banished card is never offered again in this run. *(unit)*

**Enemies, mini-boss, boss**
- **AC-13** Spitters wind up visibly before firing; their bullets hurt Banane and are slower than Banane.
- **AC-14** A killed bloater leaves a cloud that hurts Banane while he's in it, then disappears.
- **AC-15** Tanks have more health and are slower than shamblers. *(unit on data)*
- **AC-16** Each enemy type first appears around the time in §10. *(unit on the schedule)*
- **AC-17** Big Ted appears at 4:00 with a health bar; his charge is shown before it happens; he drops a gift box.
- **AC-18** The Sock Puppet King appears at 8:00; beating him pops all zombies, drops a big gift box and offers End
  run / Keep going.
- **AC-19** Dying before the boss is beaten shows "Banane got stuffed"; after beating him, dying shows "You
  survived!" (as M1).

**Area**
- **AC-20** Furniture blocks Banane, zombies and enemy bullets; Banane's projectiles pass over it.
- **AC-21** Zombies get around furniture instead of getting stuck behind it.

**Developer menu, data, co-op**
- **AC-22** The new developer-menu actions from §13 do what they say.
- **AC-23** The run log contains the new fields from §13.
- **AC-24** All new numbers (weapons, items, evolutions, enemies, bosses, rerolls, schedule) live in `.tres` files.
  *(unit)*
- **AC-25** With a second player spawned in code, the boss targets the nearer player and a gift box opens for the
  player who touched it.

**Playtest (product owner)**
- **P-1** You want to try a different build next run.
- **P-2** Getting an evolution feels like a big moment, and the evolved weapon feels clearly stronger.
- **P-3** Spitter, elite and boss bullets are always readable; when you get hit, you know why.
- **P-4** Big Ted and the Sock Puppet King feel like fair, fun fights.
- **P-5** With "Max everything" + "Spawn 500" + boss, the game stays smooth (60 fps or better).
- **P-6** Reroll / skip / banish make bad luck feel like your choice, not the game's.

## 17. Not in this spec

- Town, materials, saving, unlocks, sewing patterns, rescued plushies (M3 / M4.5).
- Evolutions for the other 6 weapons (later), more areas (M8+), other heroes (M5).
- Equipment (M4.5), siege (M4), key rebinding and controller (M6 / M7).

## 18. Proposed tickets (after approval)

1. Performance base for projectiles: shared pooled/baked projectile and enemy-bullet system — §14
2. Item system: items replace boosts, slot limits, HUD icons, Sharp Scissors / Long Thread / Big Spool / Thick Felt —
   AC-3–5
3. Weapons: Orbiting Needles + Button Shotgun — AC-1, 2
4. Weapons: Stuffing Cloud + Bouncy Yarn Ball + Thimble Mortar — AC-1, 2
5. Weapons: Yarn Cannon + Thread Whip + Zipper Ray — AC-1, 2
6. Reroll / skip / banish — AC-10–12
7. Spitters + enemy bullets — AC-13
8. Bloaters + tanks, new spawn schedule, 8-minute run — AC-14–16
9. Elites + gift box — AC-6, 8
10. Evolutions + Recipes page (4 evolutions) — AC-7, 9
11. Mini-boss Big Ted — AC-17
12. Boss: the Sock Puppet King + boss music, end of area — AC-18, 19
13. Bedroom furniture + zombies steering around it — AC-20, 21
14. Sounds and feel pass for M2 — §12
15. Developer menu, run log, data checks, co-op test — AC-22–25

## 19. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Run length: **8 minutes to the boss**, mini-boss at 4:00? (Vision says later areas are 8–12 minutes.)
2. Gift boxes from **elites, mini-boss and boss** (several per run, so evolutions happen in a normal run)?
3. Slot limits: **6 weapons and 6 items**?
4. Per run: **3 rerolls, 3 skips, 2 banishes**?
5. Bedroom **furniture that blocks movement**, or keep the open floor for now?
