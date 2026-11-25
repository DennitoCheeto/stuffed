# 04b — Loadout view: pause menu + town (playtest add-on)

Status: **DRAFT**, waiting for the product owner's approval (spec PR).
Milestone: **Playtest fixes (Nov 2026)**, issue #332.
Based on: the big playtest (2026-11-21): *"need a way to view the current loadout"*. The PO picked **both** places.
Builds on [`04-ui-and-juice.md`](04-ui-and-juice.md) (menu look), [`06-building-tricks.md`](06-building-tricks.md),
[`08-playable-plushies.md`](08-playable-plushies.md) and [`09-sewn-on-gear.md`](09-sewn-on-gear.md).

## 1. Goal

One question: **can I always see what my hero is carrying?**

- **In a run:** "what do I have, how far is each thing levelled, and what can still evolve?" so the next card pick is
  an informed one.
- **In town:** "what am I taking into the next run?" (hero, starting weapon, worn gear, bought tricks), so it's clear
  what the town has already done for me and what to build next (product test, hard rule 6).

## 2. In a run: the "Loadout" page in the pause menu

1. Esc → the pause menu gets a new button **Loadout**, right under Resume (Resume / Loadout / Settings / Recipes /
   Give up).
2. It opens a page in the same felt look as Recipes (taped felt sheet on the dimmed cloth), with a **Back** button;
   Esc / Back returns to the pause menu.
3. **One column per player** (co-op: side by side, like the end screen), headed "Player 1 · Banane" with the hero's
   ring colour. Each column lists:
   - **Weapons**: icon, name, level as dots (filled = owned levels) or a gold **MAX** tag. An evolved weapon shows a
     small gold star and "Evolved".
   - **Evolution hints**, under each weapon that can still evolve: "→ **Banana Split** with Quick Feet". The
     partner's name is green when the hero already owns it, grey when not. When both halves are maxed: "Ready! Find
     a gift box". Weapons of heroes that aren't unlocked never show a recipe (same rule as the Recipes page).
   - **Items**: icon, name, level dots.
   - **Worn gear**: one short line per slot, "Lookout Cap Lv 2" (empty slots left out; nothing worn = no line).
4. The run stays frozen while the page is open (like the rest of the pause menu).
5. Empty spots (fewer weapons/items than the maximum) show faint felt outlines, so you can see how many slots are
   still free.

## 3. In town: the "My loadout" board

1. A small **corkboard by the Bedroom door** (next to where you enter a run). Walk up to it, the usual prompt
   "{interact} Loadout" appears, E opens it. The same page can also be opened from the town Esc menu (**My loadout**
   button), so it's easy to find.
2. The page has one column per player in town, each showing:
   - **Hero**: photo (the Wardrobe's), name, passive name + one-line text.
   - **Starting weapon**: icon, name and starting level ("Lv 2" with Head Start), and where it comes from
     ("Hero's own weapon" or "Picked at the Armory").
   - **Worn gear**: the three slots (Head / Body / Charm) with the piece picture, name, stitch level, effect text;
     an empty slot says "Nothing yet: sew one at the Sewing Workshop" (only once the Workshop is revealed).
3. Below the columns, one shared strip **Town bonuses** (shared by everyone):
   - Bought **tricks**, grouped by building (building name, then trick names; the trick text shows on hover/focus).
     Tricks that only work in the Bedroom (not in the siege) carry a small "Bedroom only" tag.
   - Building **bonuses** in plain words: "+1 Reroll, Skip and Banish", "+20 max health", "+15% pickup range",
     "Toys come 45% sooner" (the totals the run really uses; numbers here are examples).
4. Read only: nothing can be changed on this page (changing happens at the Wardrobe, Armory, Sewing Workshop and the
   tricks panels). E / Esc / Back closes it.

## 4. Look and fit

- Built from the spec 04 pieces (`FeltPanel`, `SewnButton`, `FabricTag`, `PhotoFrame`, `HandTitle`); no new style.
- Both pages pass the fit check at every window size, with 1 and 2 players, and with the fullest loadout (all weapon
  and item slots full, all gear, all 18 tricks).
- Nothing in the run is visible behind the page clearly enough to compete with it (the cloth dims it as today).

## 5. Co-op (hard rule 11)

- Columns come from the players actually in the run / town (no "the player"). Two columns fit side by side at
  1920×1080 and 16:10.
- In town, each player can open the board with their own interact key; the page always shows every player.

## 6. Save, data, log

- Nothing new is saved (the page only reads the run and the town save).
- No new balance numbers. Texts (button names, hints like "Ready! Find a gift box") live in a `.tres`, not in code.
- No new log fields.

## 7. Acceptance criteria

- **AC-117** In a run, Esc → Loadout shows, for every player, each weapon and item with its current level, evolved
  weapons marked, and for every weapon that can still evolve its partner (owned or not) and "Ready!" when both are
  maxed. Back / Esc returns to the pause menu; the run stays frozen.
- **AC-118** In town, the corkboard by the door (E) and the Esc menu's "My loadout" open the town page: hero,
  starting weapon with its level and source, worn gear per slot with level, bought tricks by building and the
  building bonuses, for every player in town.
- **AC-119** Both pages pass the fit check (all window sizes, 1-2 players, fullest loadout) and use only the spec 04
  menu pieces.

## 8. Playtest question

- **P-42** Mid-run I opened the pause menu and knew right away what I have and what my next evolution is; in town I
  could see what I'm taking into the next run.

## 9. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Town place: **a corkboard by the door + a button in the Esc menu**, or only the Esc menu button (no new object in
   town)?
2. Run: **only through the pause menu** (Esc → Loadout), or also a direct key (e.g. Tab) that opens it straight away?
   A direct key can come later without changing the page.

## 10. Not in this spec

- Changing anything from these pages (equip, swap, buy).
- Exact weapon numbers (damage, cooldown) on the pages: the end screen already shows damage done; detailed stats can
  come with the evolutions spec (#333).

## 11. Proposed tickets (after approval)

1. Run loadout page in the pause menu — AC-117, AC-119
2. Town loadout page: corkboard + Esc menu button — AC-118, AC-119
