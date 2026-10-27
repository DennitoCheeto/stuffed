# 06 — Building tricks (the skill tree)

Status: **APPROVED** (PO merged PR #199, 2026-10-27).
Milestone: **M3.7 — Building tricks** (after M3.6 Sunny patchwork, before M4 Night siege).
Based on: the product owner's idea (2026-10-26: "use the buildings differently, as a skill tree for upgrades ... we
can add cooler stuff that also makes the player more powerful") and their picks (2026-10-27): **each building is a
branch**, **mostly new tricks** (few stat boosts), **small first version (~18 nodes)**. Vision §6.3 still rules:
unlocks are mostly sideways, stat bonuses are small and capped.

## 1. Goal

One question: **when I come home, do I already know which trick I want next, and do I feel it in my next run?**

After this spec:

- every built building has a **branch of 3 tricks** you buy with materials,
- most tricks **change how a run plays** (a 4th card, a second life, a pocket pickup), not just a bigger number,
- the town has a clear "next goal" even when the next building level is far away,
- the building levels keep their current bonuses: tricks come **on top**.

Not in this spec: siege roles of buildings (M4), equipment (M4.5), choosing between tricks (forks), resetting tricks,
new buildings.

## 2. What the player experiences

1. You rebuild the Snack Bar (Lv 1). A toast: **"New: Snack Bar tricks!"**
2. You walk up to it. The building card now shows **"E: Tricks"**.
3. E opens the **Tricks panel** for that building: 3 felt patches sewn onto a strip of cloth, joined by a thread.
   - Trick 1 needs the building at **Lv 1**, trick 2 at **Lv 2**, trick 3 (the **★ star trick**) at **Lv 3**.
   - Each patch shows an icon, the name, one line of text and the price (coins / stuffing / thread).
   - Bought: the patch is sewn on with a check stitch. Can't buy yet: greyed with "Needs Lv 2" or a list of the
     missing materials (same rule as the building card: no danger colours in town).
4. You buy a trick: the patch gets sewn on (stitch animation, pop sound, small puff), the game saves at once.
5. Next run, the trick just works. The first time a trick fires in a run it shows a small banner
   ("Spare Stuffing!"), so you notice what you bought.

Tricks are bought **in order** inside a branch (1 → 2 → ★). Different branches are independent, so the real choice
is **which building to invest in next**.

## 3. The 18 tricks

All numbers live in data (`data/town/tricks/*.tres`, hard rule 8). The numbers below are first guesses for tuning.

| Building | Trick 1 (Lv 1) | Trick 2 (Lv 2) | ★ Star trick (Lv 3) |
|----------|----------------|----------------|---------------------|
| **Toy Box Armory** | **Head Start:** your starting weapon starts at Lv 2. | **Show-and-Tell:** the first level-up of every run offers only weapons you don't have yet. | **Second Toy:** you start every run with a second weapon (random, from the unlocked ones). |
| **Lucky Jar** | **Shiny Card:** each level-up has a 10% chance that one card is shiny: it gives **2 levels** at once. | **Lucky Gift:** gift boxes give one more level-up (1-3 → 2-4). | **Four of a Kind:** level-ups show **4 cards** instead of 3. |
| **Watchtower** | **Spyglass:** edge arrows also point to elites and bosses that are off-screen. | **Magnet Whistle:** when you level up, every button on screen flies to you. | **Treasure Map:** every run hides one **big gift box** in the Bedroom; an edge arrow shows the way from the start. |
| **Snack Bar** | **Picnic:** beating the mini-boss heals you to full. | **Second Helping:** healing past full health becomes a **shield** (up to 20) that takes hits first. | **Spare Stuffing:** once per run, when you would fall, you pop back up with 50% health and a shockwave that pushes zombies away. |
| **Party Shop** | **Confetti Rush:** after you touch a floor pickup you run 25% faster for 4 s. | **Double Fun:** 15% of floor pickups are doubles (stronger or longer, per kind). | **Pocket Pickup:** you can carry one floor pickup instead of using it, and use it with **Q** when you want. |
| **Plush Hospital** | **Quick Untangle:** freeing a tangled plushie takes half the time. | **Thank-you Gift:** freeing a plushie drops a gift box. | **Plushie Buddy:** one rescued plushie comes along in your runs, follows you and collects buttons near it. |

Only two tricks are plain numbers in disguise (Head Start, Confetti Rush); the rest add a new moment or choice.

**Prices (first guess, in data):** trick 1 = 250 coins + 5 stuffing, trick 2 = 600 coins + 15 stuffing,
★ = 1000 coins + 25 stuffing + 6 thread. All 18 ≈ 11k coins (all buildings at Lv 3 ≈ 17k). A trick is always
cheaper than the next building level, so there's often something affordable after a run.

### 3.1 Rules for the tricky ones

- **Four of a Kind:** the level-up screen and the gift box must fit 4 cards at every window size of the fit check
  (AC-55). Reroll/skip/banish work as before.
- **Shiny Card:** a shiny card has a gold sparkle and says "+2 levels". Never on a card that is one level from max
  (it becomes a normal card) and never on an evolution.
- **Spare Stuffing:** works per player in co-op. It shows on the HUD as a small felt heart patch until used.
- **Second Helping:** the shield is a light outline on the health bar (the player's colour, never danger red).
- **Pocket Pickup:** the carried pickup shows in a small HUD pocket next to the health bar. A new **`p1_use_pocket`**
  action (Q, rebindable later) goes through the player index (hard rule 11). Touching another pickup with a full
  pocket uses the new one at once (as today).
- **Treasure Map:** the box spawns at a random free spot away from the start screen, not inside furniture.
- **Plushie Buddy:** uses the plushie's existing town look (`PlushieLook`), drawn small with a soft outline, so it
  never looks like a zombie or an enemy shot. It can't be hurt and doesn't attack. Which plushie comes along: the
  last one rescued (choice comes with M5 heroes).

## 4. Town and reveal (vision §6.9)

- The **"E: Tricks"** line shows only on built buildings. Ruins keep their price tag (AC-61 stays true).
- When a trick can be bought, the building gets a small **"New trick!"** tag next to "Can build!", using the same
  tag style (spec 05 §3.3). Only one tag at a time per building ("Can build!" wins).
- The very first trick panel opens with a one-line hint: "Tricks work in every run. Buy them in order."
- Tricks are **town-wide**: in co-op they apply to every hero.

## 5. Saving (hard rule 10)

- `TownSave` stores the bought trick ids (save v4). Old saves load with no tricks.
- Buying a trick saves at once. A test saves, reloads and compares.
- "Reset town" in the dev menu also resets tricks.

## 6. Developer menu and run log

- Town dev menu: **"Give all tricks"** and **"Clear tricks"**.
- Run dev menu: shows which tricks are on.
- Run log field `tricks` (list of ids), and `trick_moments` (id + time, for the first time each one fired).

## 7. Feel and readability

- Buying a trick gets the same "juicy" moment as a build, but smaller (no camera shake).
- In-run banners for tricks use the player's colour, never enemy red/orange (`UiColors.is_danger`).
- Spare Stuffing's shockwave and the Magnet Whistle stay quieter than enemy danger (hard rule 9).

## 8. Acceptance criteria

- **AC-66** Each of the 6 buildings has 3 tricks in data; a trick can be bought only if the building has reached its
  level, the trick before it is bought and the player can pay. Buying takes the materials once.
- **AC-67** The Tricks panel opens with E at a built building, shows all 3 tricks with state (bought / can buy /
  needs level / missing materials) and fits every window size of the fit check.
- **AC-68** Bought tricks are saved and come back after closing and reopening the game (save, reload, compare).
- **AC-69** Every trick of §3 does what its line says in a run (one scenario test per trick).
- **AC-70** The first time a trick fires in a run, a banner names it; the run log lists the active tricks.
- **AC-71** In co-op, every hero gets the tricks; Spare Stuffing and Pocket Pickup are per player.
- **AC-72** Level-up screen and gift box fit 4 cards at every window size of the fit check.
- **AC-73** No trick visual (banner, shield, shockwave, buddy, shiny card) uses a danger colour.
- **P-26** (playtest) After a run you usually know which trick you want next.
- **P-27** You can feel at least 3 tricks in a run without looking them up.
- **P-28** The star tricks feel like a reward worth saving up for.

## 9. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Name in the game: **"Tricks"** (short and playful) — or "Skills", "Upgrades", "Patches"?
2. Order inside a branch: **fixed 1 → 2 → ★** — or free order once the building level allows it?
3. Forks (choose 1 of 2 at a step): **not now**, maybe later when there are more tricks.
4. Pocket key: **Q** — fine for keyboard; controller comes later.
5. Plushie Buddy: **the last rescued plushie** comes along (picking one comes with M5).
6. Prices: **the first guess above**; tune after the playtest.

## 10. Not in this spec

Siege roles of buildings (M4), equipment and the Sewing Workshop (M4.5), playable plushies (M5), forks and resetting
tricks, idle production, new buildings.

## 11. Proposed tickets (after approval)

1. Trick data + `TownSave` v4 + buying rules + dev menu buttons — AC-66, AC-68
2. Tricks panel in town ("E: Tricks", patches, buy moment, "New trick!" tag, first hint) — AC-67
3. Trick runtime: `TownPerks` carries tricks, first-fire banner, run log fields — AC-70, AC-71
4. Armory tricks: Head Start, Show-and-Tell, Second Toy — AC-69
5. Lucky Jar tricks: Shiny Card, Lucky Gift, Four of a Kind (+ 4-card layout) — AC-69, AC-72
6. Watchtower tricks: Spyglass, Magnet Whistle, Treasure Map — AC-69
7. Snack Bar tricks: Picnic, Second Helping (shield), Spare Stuffing — AC-69, AC-71
8. Party Shop tricks: Confetti Rush, Double Fun, Pocket Pickup (+ Q action, HUD pocket) — AC-69, AC-71
9. Plush Hospital tricks: Quick Untangle, Thank-you Gift, Plushie Buddy — AC-69
10. Readability check of all trick visuals + balance pass on prices — AC-73
