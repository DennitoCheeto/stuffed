# 02b — Floor pickups: magnet, freeze, party popper (M2 add-on)

Status: **DRAFT**, waiting for the product owner's approval.
Milestone: **M2 — Build variety** add-on, played together with the M2 acceptance playtest.
Based on: the M2 playtest wish (spec 02 §20, "Wish for later"); builds on [`01-core-run.md`](01-core-run.md) and
[`02-build-variety.md`](02-build-variety.md).

## 1. Goal

One question: **does the floor give me exciting little surprises during a run?**

Now and then a killed zombie drops a special toy on the floor. Grabbing it does one big thing right away: pull in all
XP, freeze the horde, or blow it up with confetti. It's a small "yes!" moment between level-ups, and a reason to run
into the crowd instead of only away from it.

## 2. What the player experiences

1. Every minute or so a zombie drops a **floor pickup**: a felt toy that bobs gently on the floor with a soft glow.
   It looks nothing like an XP button or a gift box.
2. Banane walks over it → it works **immediately** (no inventory, no button to press).
3. A short banner shows its name ("BIG MAGNET!"), with its own sound.

## 3. The three pickups

| Pickup | Look | What it does |
|--------|------|--------------|
| **Big Magnet** | blue-and-silver felt horseshoe magnet | **Every XP button in the arena** flies to the player who grabbed it. |
| **Snow Globe** | small felt snow globe with a tiny Banane inside | **Every zombie freezes for 5 s**: it can't move, attack or hurt on touch, and still takes damage. Enemy bullets in the air pop into fluff. Spawning pauses for the same time. **Bosses** (Big Ted, the King) aren't frozen, only slowed to half speed. In the last second the ice cracks and the zombies shake, so you see the danger coming back. |
| **Party Popper** | felt party popper with a curly ribbon | A **confetti blast over the whole screen**: every zombie on screen takes a big hit. Normal zombies pop (and drop their XP as usual), elites lose a big chunk of health, bosses take a small hit. |

The fun one: the Party Popper is my pick because it's the most satisfying with what we already have (lots of pops,
lots of XP buttons, which the magnet then pulls in). Alternatives in §8.

## 4. Drop rules

- Dropped by **killed zombies**, at random, at most **one every ~60 s** on average (never in the first 30 s of a run).
- At most **2 floor pickups** lie on the floor at the same time; while 2 are there, no new one drops.
- They **stay** until someone grabs them (no timer). If they drop far away, a small arrow at the screen edge shows
  where they are.
- Which one drops: Magnet 40%, Snow Globe 30%, Party Popper 30%.
- All numbers (drop chance, minimum gap, freeze time, popper damage, odds) live in
  `data/floor_pickup_rules.tres` (hard rule 8).

## 5. Readability and feel (vision §6, hard rule 9)

- On the floor: a soft white/gold glow ring and a gentle bob, so you notice them, but quieter than enemy danger.
- Effects use Banane's soft colours (light blue ice, multicolour confetti), never the red/orange of enemy attacks.
- Frozen zombies get a pale icy tint but keep their outline, so you always know where they are.
- Each pickup has its own sound, made in code like the rest (`SfxBank`): magnet "zwoop", snow globe "tinkle +
  crackle", popper "pop + confetti rustle".
- The magnet's XP rush plays the normal rising "plip" chain, so it sounds like a jackpot.

## 6. Co-op, developer menu, run log

- **Co-op (hard rule 11):** whoever touches a pickup triggers it. Freeze and popper work for everybody; the magnet's
  buttons fly to the player who grabbed it.
- **Developer menu:** "Drop Magnet / Snow Globe / Popper" next to Banane.
- **Run log:** `floor_pickups` (name, time, player).

## 7. Acceptance criteria

- **AC-31** With the drop rules from data, zombies drop floor pickups; never in the first 30 s, never more than 2 on
  the floor, never closer together than the minimum gap. *(unit on the drop rules + scenario)*
- **AC-32** Touching a pickup triggers it at once, removes it, shows its banner and plays its sound; it is logged in
  the run log. *(scenario)*
- **AC-33** Big Magnet: every XP button in the arena (also far off screen) flies to the player who grabbed it and adds
  XP. *(scenario)*
- **AC-34** Snow Globe: for 5 s zombies don't move, attack or deal touch damage and still take damage; enemy bullets
  in the air are removed; no new spawns; bosses only move at half speed; afterwards everything continues normally.
  *(scenario)*
- **AC-35** Party Popper: every normal zombie on screen dies and drops its XP; zombies off screen are untouched;
  elites and bosses only lose the health set in data. *(scenario)*
- **AC-36** A pickup outside the screen shows an edge arrow pointing to it. *(scenario)*
- **P-10** (playtest) You notice floor pickups on your own and want to grab them.
- **P-11** (playtest) Each of the three feels like a fun little moment, and it's clear what it did.

## 8. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. The fun one: **Party Popper** (screen-wide confetti blast)? Alternatives: *Sugar Rush* (10 s of double speed and
   fire rate) or *Pillow Fort* (5 s of no damage).
2. Roughly **one pickup per minute**, at most 2 on the floor?
3. Pickups **stay until grabbed** (no timer), with an edge arrow?
4. Bosses are **slowed, not frozen**, by the Snow Globe?

## 9. Not in this spec

- Healing food on the floor, chests or breakable furniture that drops pickups (could come later).
- Town upgrades that make pickups more common (M3+).

## 10. Proposed tickets (after approval)

20. Floor pickup base: drop rules, floor look, edge arrow, banner, dev menu, run log + **Big Magnet** —
    AC-31, 32, 33, 36
21. **Snow Globe** (freeze) — AC-34
22. **Party Popper** — AC-35
