# 09 — Sewn-on gear (equipment)

Status: **DRAFT** (spec PR, waiting for the PO).
Milestone: **M4.5 — Equipment** (after M5 Plushie heroes, PO order 2026-11-18).
Based on: vision §5 ("Equipment, sewn onto the plushie"), §6.3 (sideways unlocks), §6.9 (reveal when needed),
§7 ("Equipment progression"), §8.1 (pieces are separate felt shapes), §11 (MVP needs 8 pieces of equipment).

## 1. Goal

One question: **do I already know which piece I want to sew next, and do I see it on my hero?**

After this spec:

- there are **9 pieces of gear**, 3 per slot: **Head**, **Body**, **Charm**,
- every piece **shows on the hero** and has **one clear effect that changes how you play** (not just a number),
- you get a piece's **sewing pattern** either for sure from a building (plannable) or as a surprise from a boss or
  an elite (a find),
- you **sew** the piece and **stitch** it stronger (3 stitch levels) at a new town building, the **Sewing Workshop**,
  paid with coins, stuffing and thread,
- gear is **shared**: any hero can wear any piece, and swapping hero at the Wardrobe keeps your gear on.

Not in this spec: rarities, random stats, duplicates, merging, selling (vision §5: "no rarities, no merging, no
gacha"), more than 9 pieces, Workshop tricks, gear evolutions.

## 2. What the player experiences

1. You build the **Watchtower to Lv 2**. Besides its usual effect, a paper pattern flutters down:
   **"New pattern: Lookout Cap!"**. (Or you beat Big Ted for the first time and he drops one.)
2. With the first pattern, a new ruin appears next to the fort: the **Sewing Workshop** ("New building!").
   Building it works like every other building.
3. E at the Workshop opens the **sewing table**: three slots on a hero photo (Head, Body, Charm), and next to them
   every pattern you own, plus silhouettes for the ones you haven't found ("Build the Party Shop to Lv 2",
   "Big Ted drops this").
4. You **sew** the Lookout Cap (it costs materials, a short sewing animation, then it's yours) and it goes onto your
   hero at once: Banane now wears a little felt cap in the town.
5. In the next run the cap does its thing. Later you come back and **stitch** it to Lv 2 and Lv 3 (stronger effect,
   one more visible stitch row on the piece).
6. Swap to Pip at the Wardrobe: she wears the same cap.
7. The Scrapbook gets a **Gear** tab; the end screen shows what you wore.

## 3. The 9 pieces (first numbers, tuned in the playtest; all in `data/gear/<id>.tres`)

Each piece has 3 stitch levels; the numbers below are Lv 1 → Lv 3.

| Slot | Piece | Pattern comes from | Effect |
|------|-------|--------------------|--------|
| Head | **Pin Cushion Hat** | Toy Box Armory Lv 2 | Pins and buttons (Sewing Pin Sniper, Pincushion Volley, Button Shotgun, their evolutions) pierce **+1 / +1 / +2** more zombies. A weapon combo: plan your build around it. |
| Head | **Lookout Cap** | Watchtower Lv 2 | Stand still for 1 s and your pickup range grows to **×1.6 / ×1.8 / ×2.2** until you move. Stop-and-collect rhythm. |
| Head | **Propeller Cap** | Big Ted (first time beaten) | Your dash goes **30 / 40 / 50%** farther and lands with a **thump** that hurts zombies around you (~60 px). |
| Body | **Raincoat** | Elites (25% chance, until found) | Your dash leaves a **puddle** for 3 s: zombies in it are **30 / 40 / 50%** slower, enemy bullets that fly into it fizzle out. |
| Body | **Patch Vest** | Plush Hospital Lv 2 | A felt patch blocks one hit, then grows back after **20 / 16 / 12 s**. The patch is visible on the vest (there or gone). |
| Body | **Picnic Apron** | Snack Bar Lv 2 | Every **60 / 50 / 40 s** you drop a snack behind you; picking it up heals **15%** (co-op partners can take it too). |
| Charm | **Jingle Bell** | Party Shop Lv 2 | Every **30 / 25 / 20** kills the bell rings out a shockwave (~120 px) that pushes zombies back and hurts them a little. |
| Charm | **Lucky Button** | Lucky Jar Lv 2 | **4 / 6 / 8%** of XP buttons drop as golden buttons worth **×5 XP**. Worth a detour. |
| Charm | **Wind-up Key** | Sock Puppet King (first time beaten) | Every 20 s the key winds up and your weapons fire **40 / 55 / 70%** faster for **4 s**; the key spins on your back while it lasts. |

Rules:

- **One effect per piece.** No piece adds plain stats on top in this milestone (vision allows small ones; leave
  them for tuning).
- Effects work the same for every hero and stack with tricks and items (e.g. Patch Vest + Snack Bar shield: the
  patch blocks first).
- Gear works in **runs and sieges** (in the siege there are no floor pickups or bosses, so the Lucky Button still
  works on buttons, the others work as normal).
- The "pattern comes from" rule is in data (`GearDef.source`), so it can be moved to another building or drop.

## 4. Getting patterns

- **From buildings (sure, plannable):** reaching **Lv 2** of a building gives its pattern (banner after the build
  moment, waits for other banners). Saves that already have the building at Lv 2 get the pattern on the next load
  (one banner listing all of them).
- **From bosses (sure):** the first time Big Ted / the Sock Puppet King is beaten, it drops its pattern on the floor
  where it fell: a paper **pattern envelope** with an edge arrow. Touch it to get it.
- **From elites (surprise):** each elite killed has a 25% chance to drop the Raincoat pattern until you own it.
- A pattern you touched is **saved at once and kept** even if the run is lost or you give up (like a rescue).
- No pattern ever drops twice. Owned patterns never drop again, so the drops stop when you have them all.

## 5. The Sewing Workshop (town)

- A **7th building** with the usual 3 levels, art kit look (a sewing table with a giant spool, a pin cushion roof,
  thread bunting; Lv 0 = ruin), spot near the fort in `pillow_fort.tres` (inside `max_building_distance`).
- **Reveal:** the ruin appears with the **first pattern** you own (vision §6.9), with "New building!".
- **Levels** (first prices, in data):
  - Lv 1 (~400 coins): sewing table opens; **Head** and **Body** slots; pieces can be sewn (stitch Lv 1).
  - Lv 2 (~1000 coins + stuffing): **Charm** slot; stitching up to **Lv 2**.
  - Lv 3 (~1800 coins + stuffing + thread): stitching up to **Lv 3**; the Workshop's sewing machine runs in town
    (just a look).
- **Sewing a piece:** ~300-600 coins + a little stuffing/thread per piece; stitching to Lv 2 / Lv 3 costs more.
  Total for all 9 pieces at Lv 3 about **9-11k coins** (similar to the 18 tricks). Each stitch level must cost less
  than the next Workshop level (same rule as tricks).
- Siege: the Workshop is a normal siege target with health; it has **no turret** (gear already helps you fight).
  A damaged Workshop still lets you wear what you sewed but not sew or stitch until it's repaired.
- No tricks for the Workshop in this milestone.

## 6. The sewing table (panel)

- E at a built Workshop opens the **sewing table** (`FeltPanel`, same look family as the Tricks panel and the hero
  picker): left a photo of your hero with the 3 slots on it; right the 9 pattern tiles (`SewnButton`s) by slot.
- A tile shows: piece picture, name, effect in one line, stitch dots (●●○), the price of the next step, and one of
  **Sew** / **Stitch** / **Wear** / **Take off** / **"Build the X to Lv 2"** (locked silhouette) / **"Needs
  Workshop Lv 2"**.
- Sewing a piece **puts it on** if that slot is empty. Wearing another piece of the same slot swaps it (free,
  any time). Taking off is free.
- **Hide (PO request 2026-11-19):** each slot on the hero photo has a small eye toggle **"Show on hero" / "Hidden"**
  (key **H** on the selected slot). A hidden piece still works fully (effect, stitch level, end screen tag), it just
  isn't drawn on the hero, for players who want the plain plushie look. A **"Hide all"** toggle sits under the
  photo. The same toggles are on the Wardrobe's hero picker, so you can change it where you pick your hero too.
- Keys: arrows / mouse, E or click = the main action on the tile, **R** = take off, Esc closes. Short sewing moment
  (needle bobs, stitches appear, pop) like the build moment.
- The town tag "Can sew!" shows on the Workshop when you can afford something new (like "Can build!").

## 7. Gear on the hero (visible)

- Each piece is a small felt shape (baked once, like the buddy and hero puppets), drawn **on top of the puppet** at
  an anchor the hero's data defines: `head_anchor`, `body_anchor`, `charm_anchor` (+ scale per hero), so the cap
  sits on Banane's head and on Böbö's ears.
- It moves with the puppet (bob, waddle tilt, hop, squash, dash stretch, hit flash) and shows in the town, the
  Bedroom, the siege, the Wardrobe photos and the end screen photo.
- Each stitch level adds a visible detail (an extra stitch row / a button / a tassel).
- Effect moments are visible too: the patch disappears and grows back, the key spins, the bell swings when it rings.
- Gear colours are calm (no danger colours) and stay inside the hero's outline/contrast rules (#172).
- A **hidden** slot (§6) draws nothing on the hero and shows no effect moment on the piece (no swinging bell, no
  spinning key); the effect itself (shockwave, faster firing, ...) still shows in the world as normal.

## 8. Co-op (hard rule 11)

- What you **own** (patterns, sewn pieces, stitch levels) belongs to the **town**, shared by everyone.
- What you **wear** is saved **per player slot**, like the hero choice. Each sewn piece exists once: a piece player 1
  wears shows "Player 1 wears it" on player 2's table and can't be worn twice (same rule as heroes).
- Each player opens the table with their own keys.

## 9. Save (hard rule 10)

- `TownSave` v7: `patterns` (ids found), `gear` (id → stitch level, 0 = not sewn), `worn` per player slot
  (`{"head": id, "body": id, "charm": id}`), `hidden` per player slot (slot names that are hidden). Older saves load with nothing, then get the patterns of buildings
  already at Lv 2 (§4).
- Tests save, reload and compare all three; another loads a v6 save.

## 10. Scrapbook, end screen, log

- Scrapbook: new **Gear** tab, 9 tiles (silhouette until the pattern is found, text = effect + where it comes from).
- End screen: worn pieces as item tags in each player's column (with the stitch level).
- Run log: field `gear` per player (`{"head": "lookout_cap:2", ...}`), runs and sieges; `patterns_found` per run.

## 11. Developer menu

- Town dev menu: **"Give all patterns"**, **"Sew all"** (Lv 1), **"Max all stitches"**, **"Clear gear"**.
- Run dev menu: shows worn gear; **"Drop pattern"** (next unowned drop pattern at the hero).

## 12. Readability and performance (vision §6.1, §6.7)

- New effects (puddle, thump, shockwave, golden buttons, snack, spinning key) are quiet: no danger colours, less
  contrast than zombies, in the colour sweeps (`color_sweep.gd`). Golden buttons must stay below the danger hue.
- A hero wearing 3 pieces costs at most **+3 draw calls** over the same hero without gear; the benchmark with full
  gear stays within ~5% of today.
- The sewing table fits every window size of the fit check.

## 13. Acceptance criteria

- **AC-95** Reaching Lv 2 of the Armory, Watchtower, Snack Bar, Party Shop, Lucky Jar or Plush Hospital gives its
  pattern with a banner; old saves get the patterns of buildings already at Lv 2.
- **AC-96** The first Big Ted / Sock Puppet King kill drops its pattern envelope (with an edge arrow); elites drop
  the Raincoat pattern at the data chance until owned; a touched pattern is kept even when the run is lost.
- **AC-97** The Sewing Workshop ruin appears with the first pattern, builds to Lv 3 like the other buildings, and its
  levels open the Charm slot and stitch levels 2 and 3.
- **AC-98** The sewing table sews, stitches, wears, swaps and takes off pieces, takes the right materials, and
  shows locked tiles with where their pattern comes from.
- **AC-99** Each of the 9 pieces does what §3 says at each stitch level (one scenario per piece).
- **AC-100** Worn pieces show on every hero at that hero's anchors, move with the puppet, show their stitch level,
  and stay on after a Wardrobe swap.
- **AC-100b** Each slot can be hidden (and "Hide all") on the sewing table and the Wardrobe picker: a hidden piece
  is not drawn on the hero but its effect still works; the choice is saved per player.
- **AC-101** In co-op each player wears their own pieces; a piece can't be worn by two players at once.
- **AC-102** Patterns, sewn pieces, stitch levels and worn gear survive closing and reopening (save, reload, compare);
  a v6 save loads.
- **AC-103** Scrapbook Gear tab, end screen tags and the run log `gear` field show the right pieces.
- **AC-104** No gear visual uses a danger colour; zombies stay the strongest contrast; +3 draw calls at most per
  fully geared hero; the sewing table passes the fit check.
- **P-35** (playtest) After a few runs I know which piece I want next and what to build or beat to get it.
- **P-36** I can see my gear on my hero and it feels like *my* plushie.
- **P-37** At least one piece changes how I play (where I stand, when I dash, which weapons I pick).

## 14. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Where do you sew? **A new 7th building, the Sewing Workshop**, revealed with the first pattern (vision). The
   alternative would be to add it to the Wardrobe (no new building).
2. The 9 pieces and their effects: **the table in §3**. The vision's examples Rain Barrel / Bell Tower don't exist as
   buildings, so their pieces come from today's six buildings and from bosses/elites instead.
3. Building patterns at **Lv 2** of each building (not Lv 1: gives Lv 2 one more reason).
4. Gear is **owned by the town, worn per player**, one copy of each piece (co-op: no piece twice).
5. Patterns found in a run are **kept even when the run is lost** (like rescues).
6. **No plain stat bonuses** on pieces for now (effects only); add small ones later if the playtest wants more power.
7. Hiding gear (PO request 2026-11-19): **per slot + "Hide all", saved per player, on the sewing table and the
   Wardrobe picker**; hidden pieces keep working.

## 15. Not in this spec

Rarities, random rolls, duplicates or merging, selling or breaking pieces, more pieces or slots, gear only for one
hero, Workshop tricks, idle production, gear evolutions, set bonuses.

## 16. Proposed tickets (after approval)

1. Gear data (`GearDef` per piece, 3 stitch levels, source) + `TownSave` v7 + rules (own / sew / stitch / wear) +
   town dev menu — AC-102
2. Patterns: building Lv 2 patterns + old-save catch-up, boss / elite drops, pattern envelope pickup + arrow + banner,
   run dev menu — AC-95, AC-96
3. Sewing Workshop building: spot, look Lv 0-3, reveal, levels, siege target, damaged rule — AC-97
4. Sewing table panel + "Can sew!" tag + fit check — AC-98
5. Gear on the hero: baked pieces, per-hero anchors, stitch details, Wardrobe photos, hide toggles — AC-100, AC-100b
6. Head pieces: Pin Cushion Hat, Lookout Cap, Propeller Cap — AC-99
7. Body pieces: Raincoat, Patch Vest, Picnic Apron — AC-99
8. Charm pieces: Jingle Bell, Lucky Button, Wind-up Key — AC-99
9. Co-op wearing, Scrapbook Gear tab, end screen tags, run log — AC-101, AC-103
10. Readability + performance + prices check — AC-104
