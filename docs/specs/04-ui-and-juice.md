# 04 — UI and juice: the Stitched Scrapbook look

Status: **DRAFT**, waiting for the product owner's approval.
Milestone: **M3.5 — UI and juice** (between M3 Town and M4 Night siege).
Based on: the M2 + M3 playtest (2026-10-24: "We REALLY need to work on the UI", "basic, not fun", end screen
"really bad"), [`../research/02-game-ui-research.md`](../research/02-game-ui-research.md), the mockup canvas
(looks A Sewing box / B Scrapbook / C Toy-box arcade) and the product owner's pick: **a mix of A and B**
("B feels alive but the sewed look of A is really cool"). Vision §6 (principle 1, readability) still rules.

## 1. Goal

One question: **do the menus feel like part of a plushie game, and do I enjoy looking at my end screen?**

Today every screen is a dark grey box with a gold border and plain text. After this spec:

- every menu shares **one look**, the *Stitched Scrapbook* (§2),
- everything you can click **reacts** (lift, squish, sound),
- the **end screen** is a celebration *and* a report: each weapon with its damage, kills and DPS, a
  **Star of the run**, and fun **run titles**,
- **no screen ever spills off the screen** or lets text out of its box, on 16:9 and 16:10.

Not in this spec: the town and Bedroom art (spec 05), bigger evolution moments (evolution pass), new game rules.

## 2. The look: Stitched Scrapbook (A + B)

The rule of the mix: **A builds the furniture, B brings it to life.**

| From **A — Sewing box** (the structure) | From **B — Scrapbook** (the life) |
|------------------------------------------|-----------------------------------|
| Panels are **felt patches**: soft rounded cream felt with a **dashed stitch line** just inside the edge | Panels sit **slightly tilted** (±1–3°) and wobble into place when they appear |
| Buttons are **sewn-on fabric buttons**: rounded, chunky, a stitch ring, a "thick" bottom edge you press into | **Washi tape** strips hold the big panels and photos onto the background |
| Small labels are **fabric tags** (the level, "EVO", key hints) | Headings are **hand-written** ("You survived!", "Brought home", page titles) |
| Bullet points are little **sewing buttons** | Weapons on the end screen are **photos** (white frame, a bit crooked, taped on) |
| The background behind menus is a **dark felt cloth** (dimmed game behind it) | Run titles and "new!" markers are **stickers** that slap on with a bounce |

### 2.1 Colours (one colour per thing, everywhere)

| Thing | Colour | Used in |
|-------|--------|---------|
| Panel felt | warm cream `#f6ecd9`, stitches `#c9b48e` | every panel |
| Menu cloth | dusty purple felt `#6a5a8e` (darker, dimmed in a run) | behind menus |
| Main button | sunny gold `#f2b52e` | the one "go on" button per screen |
| Other buttons | cream felt | secondary buttons |
| Coins / stuffing / thread | gold / cream-white / teal (the jar colours) | HUD, end screen, town, costs |
| XP | green | HUD, cards |
| Danger | red / orange | **only** enemy things (vision §6); menus never use them for decoration |
| Win / lose title | gold "You survived!" / soft coral "Banane got stuffed" | end screen |

Text on felt always reaches a 4.5:1 contrast.

### 2.2 Fonts

Two free fonts (SIL Open Font License, so allowed under "no purchased assets"; listed in `docs/art/credits.md`):

- **Headings / big numbers:** a round, friendly font (proposal: *Fredoka*).
- **Hand-written bits** (B): titles of pages, stickers, photo captions (proposal: *Patrick Hand*).
- Body text stays a clean round sans (proposal: *Nunito*), so stats and card text stay easy to read.

### 2.3 In the run: the HUD stays quiet

Readability first (vision §6, hard rule 9): during a fight, the HUD only gets the **new colours and fonts**, small
felt backings and stitch edges. No tilting, no tape, no wobble on the HUD. The loud look is for menus and moments:
title, pause, settings, level-up, gift box, goal screen, end screen, town cards, Scrapbook.

## 3. Juice: everything you touch reacts

| When | What happens |
|------|--------------|
| **Hover / keyboard focus** on a button or card | lifts a little (~8 px) and grows (~1.05×) with a soft spring, soft "felt pat" sound; the stitch line gets brighter |
| **Press** | squishes down into its thick bottom edge (~0.92×), "boop" sound, springs back |
| **Disabled** button | flatter, faded, a loose thread; no hover lift; a short "nope" wiggle if pressed |
| **A screen opens** | the cloth fades in, panels drop in one after the other (~0.08 s apart) with a little overshoot and settle at their tilt |
| **A screen closes** | panels slide down quickly (≤ 0.2 s): closing never feels slow |
| **Numbers** (damage, kills, haul) | count up with rising "plips" (reuse the haul count-up), big ones end with a small pop |
| **Stickers** (run titles, "New!") | slap on: big → normal size, small rotation, "thwap" sound |

- All motion is short (≤ 0.4 s per element) and **never blocks input**: pressing a key during an animation works
  at once (the animation jumps to the end).
- Keyboard and mouse both work on every menu; the focused button is always clearly visible.
- The numbers (lift, grow, spring, durations, tilts) live in one data file `data/ui/ui_style.tres`
  (hard rule 8).
- One setting **"Menu animations: full / reduced"** (reduced = no tilt wobble, no drops, instant count-ups).

## 4. The new end screen ("Today's page")

Layout on 1920×1080 (mockup "Mix" on the canvas):

```
┌──────────────────────────────────────────────────────────────────────────────┐
│   [ You survived! ]  (hand-written, gold)    [sticker: Mortar Maniac] [sticker]│
│   8:00 + 1:15 endless · Level 38 · 4,321 zombies stuffed                      │
│ ┌──────────────── Your weapons (felt patch) ───────────┐ ┌─ Brought home ────┐ │
│ │ [photo: Banana Split ★ STAR OF THE RUN]  182.4k dmg  │ │ +1,234 coins      │ │
│ │  EVO · 1,912 kills · 381 DPS · held 6:40             │ │ +56 stuffing      │ │
│ │ Thimble Mortar   Lv 5  ████████░░  96.1k  1,204  201 │ │ +7 thread         │ │
│ │ Orbiting Needles Lv 4  ████░░░░░░  41.7k    866  104 │ │ BamBam is coming  │ │
│ │ Sewing-Pin Sniper Lv 3 █░░░░░░░░░  12.0k    339   41 │ │ home! (photo)     │ │
│ └──────────────────────────────────────────────────────┘ │ New in Scrapbook: │ │
│                                                          │ Sock King, …      │ │
│                                                          └───────────────────┘ │
│              ( Back to the fort )        ( Try again )                        │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Weapon report

- **Every weapon** the hero had in this run gets a row: icon, name, level (or an **EVO** tag if evolved), a damage
  bar (share of the run's total), **total damage**, **kills**, **DPS** and **time held**.
- Sorted by damage, biggest first. The top weapon is the **Star of the run**: shown big as a taped-on **photo** with a
  gold "★ Star of the run" sticker.
- An evolved weapon counts the damage of its old weapon too (Peel Boomerang → Banana Split is one row, "EVO").
- DPS = damage ÷ time held. Big numbers are short: 12,345 → "12.3k", 1,234,567 → "1.23M".
- Items (Quick Feet, Big Spool …) are **not** rows; they show as small fabric tags under the weapons
  ("Quick Feet 3 · Big Spool 2"), replacing today's long "Upgrades:" line.
- Damage that didn't come from a weapon (e.g. the Party Popper) shows as one extra small row "Party Popper".
- The run log gets a field `weapons`: per weapon id: damage, kills, seconds held, level, evolved, player.

### 4.2 Run titles (stickers)

After each run, up to **2 titles** are stuck on the page (the rarest first). Each title has a name, a condition and a
rarity in `data/ui/run_titles.tres`, so new ones take minutes. Starting list:

| Title | When |
|-------|------|
| **[weapon] title**, e.g. *Mortar Maniac*, *Boomerang Buddy*, *Needle Ninja* | one weapon did ≥ 60% of all damage (each weapon has its own title text in its `.tres`) |
| **Untouchable!** | no damage taken for 3 minutes in a row |
| **Close Call** | beat the King with less than 15% health |
| **Speedy Stitcher** | beat the King before 7:00 |
| **Evolution Expert** | 2 or more evolutions in one run |
| **Gift Grabber** | opened 3 or more gift boxes |
| **Party Animal** | grabbed 3 or more Party Poppers |
| **Hero of the Fort** | freed a tangled plushie |
| **Endless Explorer** | 5+ minutes in endless |
| **Collector** | 3+ new Scrapbook entries in one run |
| **Stuffed Already?** | got stuffed before 2:00 (a gentle joke, never two "bad" titles) |
| **Steady Paws** | fallback when nothing else fits: "You stuffed 1,234 zombies" style, always something nice |

New titles you've never got before get a small "New!" sticker. (Collecting them in the Scrapbook: later, §9.)

### 4.3 Brought home

The existing haul panel (count into the jars, rescue message, new Scrapbook entries), restyled as a felt patch with a
hand-written heading. The rescued plushie gets a small photo. Nothing about the rules changes.

### 4.4 Co-op

With 2 players, "Your weapons" shows **one column per player** (each with its own Star of the run), titles are
shared for the run, and the screen still fits (§5). With up to 4 players later, the columns get compact rows.

## 5. Every screen fits (16:9 and 16:10)

- Every screen is laid out with containers that **shrink to fit**: on 1920×1080, 1920×1200 (16:10), 1280×720 and
  2560×1440 all buttons and panels are fully inside the window, with at least 24 px margin.
- Text never leaves its box: long names shrink a little or wrap; lists that can get long (weapons, items, Scrapbook)
  scroll inside their panel instead of pushing buttons off the screen.
- A scenario test opens **every screen** in each of these sizes with "worst case" content (6 weapons, long names,
  2 players, a rescue, many new Scrapbook entries) and checks that every button and label is inside the window and
  no label is cut off.

## 6. Screens that get the new look

All of them, using one shared Godot **Theme** (`data/ui/stuffed_theme.tres`) plus a few reusable pieces
(`FeltPanel`, `SewnButton`, `FabricTag`, `Sticker`, `TapeStrip`, `PhotoFrame`, `HandTitle`), drawn in code (no image
files, like the rest of the art):

1. **Title screen** (New game / Continue / Settings / Quit as sewn buttons on a felt patch, game name hand-written).
2. **Pause menu** and **Settings** (sliders look like a thread with a button as the knob).
3. **Level-up screen**: cards become felt patches, the card buttons (Reroll / Skip / Banish) become sewn buttons with
   fabric-tag key badges. Cards still must be readable at a glance, so they don't tilt while you choose.
4. **Gift box moment** and **goal screen** ("You beat the King!").
5. **End screen** (§4).
6. **Town**: building info card, start-weapon picker, "New weapons for your cards!" toast, "New building!" banner.
7. **Scrapbook**: already a book; gets the same panels, tabs as fabric tags, entries as photos/stickers.
8. **HUD**: colours and fonts only (§2.3).
9. **Developer menus**: the theme applies automatically, no extra work (they're for tuning, not for show).

## 7. Sounds

New code-made sounds in `SfxBank` (soft, quieter than any enemy sound, `test_audio.gd` rule): `ui_hover` (felt pat),
`ui_press` (boop), `ui_nope` (disabled), `ui_open` (soft whoosh), `sticker` (thwap), `star` (little fanfare for the
Star of the run).

## 8. Acceptance criteria

- **AC-49** Every menu screen listed in §6 uses the shared theme: felt panels, sewn buttons and the fonts from §2.2;
  no screen still shows the old grey/gold box. *(scenario: opens each screen and checks its panels/buttons are the
  themed pieces)*
- **AC-50** Hovering or focusing a button lifts and grows it and plays `ui_hover`; pressing squishes it and plays
  `ui_press`; a disabled button doesn't lift and plays `ui_nope`; a key pressed during an opening animation works at
  once. *(scenario)*
- **AC-51** During a run the HUD keeps its quiet style: no tilt, tape or wobble, and nothing in it uses the danger
  colours. *(scenario + unit on the style data)*
- **AC-52** The run counts damage, kills and time held per weapon and per player (evolved weapons include their
  old weapon); the numbers add up to the run's total kills and damage. *(unit + scenario)*
- **AC-53** The end screen lists every weapon with level/EVO, damage, kills, DPS and time held, sorted by damage,
  with the top one shown as the Star of the run; items show as tags; the run log has the `weapons` field.
  *(scenario)*
- **AC-54** Run titles from `run_titles.tres` are given by their conditions (at most 2, rarest first, never two "bad"
  ones, a fallback when none fits); a first-time title shows "New!". *(unit on the rules + scenario)*
- **AC-55** On 1920×1080, 1920×1200, 1280×720 and 2560×1440, every screen from §6 with worst-case content keeps all
  buttons and panels inside the window and no label is cut off. *(scenario)*
- **AC-56** "Menu animations: reduced" turns off tilt wobble, drop-ins and slow count-ups, and is saved.
  *(scenario: save → reload → compare, hard rule 10)*
- **AC-57** Two players: the end screen shows one weapon column per player, each with its own Star of the run, and
  still fits (AC-55). *(scenario)*
- **P-18** (playtest) The menus feel like they belong to a plushie game: "cosy and alive", not "basic".
- **P-19** Clicking around is fun: buttons feel nice to press.
- **P-20** After a run you **look at the end screen** and enjoy it: you see what your best weapon was and want to
  try a different build next time.
- **P-21** The run is still easy to read (the new look doesn't steal attention from the zombies).

## 9. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. The mix: **A builds the structure (felt patches, sewn buttons, tags), B brings it to life (tilt, tape,
   hand-written headings, photos, stickers)**?
2. Fonts: **Fredoka (headings) + Patrick Hand (hand-written) + Nunito (body)**, free OFL fonts bundled with the game?
3. End screen: **Star of the run as a big photo + a compact table for the rest**?
4. Run titles: **up to 2 per run**, the list in §4.2? Collecting all titles in the Scrapbook is **later** (not here).
5. Level-up cards **don't tilt** (so they stay readable); only frames and headings do?
6. A **"reduced menu animations"** setting?

## 10. Not in this spec

- Town and Bedroom visuals (spec 05), evolution "wow" pass, walking into buildings.
- A title collection page in the Scrapbook, controller support, rebinding keys UI.
- Damage numbers over zombies (they exist and stay as they are).

## 11. Proposed tickets (after approval)

1. UI style foundation: `stuffed_theme.tres`, `ui_style.tres`, fonts, the reusable pieces (`FeltPanel`, `SewnButton`,
   `FabricTag`, `Sticker`, `TapeStrip`, `PhotoFrame`, `HandTitle`), juice (hover/press/open/close), UI sounds,
   "reduced animations" setting — AC-50, AC-56
2. Fit check: worst-case screen test harness for the 4 window sizes — AC-55 (grows with each later ticket)
3. Weapon stats tracking per weapon and player + run log `weapons` field — AC-52
4. New end screen: weapon report, Star of the run, items as tags, Brought home restyle, co-op columns —
   AC-53, AC-57
5. Run titles: data, rules, stickers, "New!" (seen titles saved) — AC-54
6. Title, pause and settings screens in the new look — AC-49
7. Level-up screen, gift box moment and goal screen in the new look — AC-49
8. Town cards, picker, toasts, banners and the Scrapbook in the new look; HUD colours and fonts — AC-49, AC-51
