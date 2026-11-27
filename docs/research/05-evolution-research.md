# 05 — Evolutions for every weapon (research)

Date: 2026-11-26. Input for spec 11 (issue #333). PO playtest 2026-11-21: *"all weapons need an evolved state"*.

## 1. What the genre does

Looking at how bullet-heaven / survivor-like games handle weapon evolutions (from the market research in
`01-bullet-heaven-market-research.md` and general genre knowledge):

- **Every weapon evolves** in most of the well-liked games of the genre. A weapon without an evolution feels like a
  dead end: players learn to skip it, so it shrinks the build space instead of growing it. That is exactly what the
  PO felt.
- **The recipe is visible.** Good games show the partner on the card or in a recipe list. We already do this (card
  partner icon, Recipes page, Scrapbook, loadout page "next evolution").
- **One weapon + one item, any item level.** Simple, readable rule. Items are shared between two weapons so the
  item pool stays small. Ours: spec 02 §5, unchanged.
- **The evolution changes the verb, not just the numbers.** The memorable evolutions make the weapon *do something
  new* (a new shape on the screen, a new way zombies move or die), plus a stat bump. A pure "+50% damage" evolution
  is forgotten at once.
- **The partner item flavours the new behaviour** where it can (a speed item gives a weapon that rewards moving, a
  health item gives a weapon that heals). It helps players guess and remember recipes.
- **One big moment.** A clear "this just changed" beat when it happens (we have this since M6: sewing reveal, slow
  motion, pulse, big first attack, own sting).

## 2. What our 6 evolutions already use

To keep the new six from feeling like copies, these "verbs" are taken:

| Evolution | Verb |
|---|---|
| Banana Split | split on the way back + **slippery floor traps** (stun) |
| Sewing Storm | permanent orbit + **threads that pull zombies back in** |
| Pincushion Volley | fan + **chain on kill** (killed zombies fire more pins) |
| Yarn Bomb | sticky slow + **yank to the middle and pop** |
| Snow Day | **bait** (snowman) + **freeze** |
| Bear Slam | every Nth attack = **ground ring** knock-down |

Still free and readable for our weapons: **lines left on the floor**, **zombies as projectiles**, **a trail behind
the hero**, **an attack that travels onward on its own**, **grab and throw**, **a beam that sweeps an area**.

## 3. The six weapons and what fits them

| Weapon | How it plays today | Partner (spec 02 §4) | Fitting new verb |
|---|---|---|---|
| Bouncy Yarn Ball | bounces between zombies | Magnet Pocket | the ball unwinds: **thread lines** between bounce points; it snags XP on the way |
| Button Shotgun | close fan, big push | Quick Hands | pushed zombies **become bowling balls** that knock others over |
| Stuffing Cloud | aura around the hero | Extra Stuffing | **fluff trail** behind you + kills inside it **mend** you |
| Thimble Mortar | lobs at random zombies | Big Spool | the thimble **hops onward** twice (hopscotch), each landing a blast |
| Thread Whip | wide arc towards the cursor | Sharp Scissors | **lasso** a big zombie, swing it through the crowd, throw it, snip |
| Zipper Ray | short beam towards the cursor | Long Thread | the zipper **opens**: two halves sweep apart, then snap shut |

## 4. Risks

- **Readability (rule 9):** floor lines, trails and swung zombies add screen noise. Keep them in calm, own-shot
  colours, under the zombies' ink contrast, and capped in number (max threads, max puffs).
- **Performance:** six more lasting effects. Draw them batched (one `draw_multiline` for all threads, pooled
  shots), as the M6 evolutions do. Benchmark with all six at once.
- **Bosses:** grab/throw and bowling must not move bosses (they'd break boss patterns, see #327). Bosses take
  extra damage instead.
- **Healing (Comfy Cloud)** could make the run too easy: cap it per second, tune after the playtest.
