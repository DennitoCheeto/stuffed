# 05 — Town and Bedroom look: Sunny patchwork

Status: **DRAFT**, waiting for the product owner's approval.
Milestone: **M3.6 — Sunny patchwork** (after M3.5 UI and juice, before the evolution pass and M4 Night siege).
Based on: the M2 + M3 playtest (2026-10-24: the town is "still not too appealing", everything is "a tiny bit
dark"), [`../research/03-town-and-bedroom-look-research.md`](../research/03-town-and-bedroom-look-research.md), the
mockup canvas (https://claude.ai/artifact/WzwePbqRnbNVD5EcRx3vic) and the product owner's picks (2026-10-25):
**a mix of A Sunny Saturday and C Sewn diorama** ("moooore details and cooler"), buildings **less round, more
texture**. B Night-light glow is "too dark" for now; maybe a night variant for a later level (not in this spec).
Vision §6 principle 1 (readability: danger first) still rules.

## 1. Goal

One question: **when I come home to the fort or start a run, do I *want* to look around?**

After this spec:

- the town and the Bedroom are **bright, warm daylight places** instead of near-black floors,
- the Bedroom reads as a **giant room seen by a toy**: floorboards, a patchwork rug, huge furniture, sunbeams,
- the run has **places** (rug, block city, crayon corner, ...) instead of one endless floor,
- every building has **its own silhouette** made from a household or sewing object, with **texture** (felt grain,
  stitches, wood, metal) and it **visibly grows** with each level,
- zombies and enemy shots are **still the easiest thing to see** on screen.

Not in this spec: a night look, walking into buildings, new game rules for the zones, plushie walking animations
(#147), the evolution "wow" pass.

## 2. The look: Sunny patchwork (A + C)

The rule of the mix: **A brings the light and the scale, C brings the materials.**

| From **A — Sunny Saturday** | From **C — Sewn diorama** |
|-----------------------------|---------------------------|
| Daylight: warm honey floorboards, sunbeams from a window, soft dust sparkles | Patchwork everywhere: gingham, polka dot, corduroy and plain felt patches sewn together with big hand stitches |
| Huge furniture and toys at the edges (bed corner, block towers, crayons) | Sewing things as landmarks: cotton reels, thimbles, button jar, pincushion, tape measure, thread trails |
| A soft warm vignette at the screen edges | Big sewn-on buttons where seams cross |

### 2.1 Light and colour

- **No near-black ground any more.** Every floor colour (boards, rug patches, quilt patches) is a light-to-mid warm
  tone. Today's floors (`#2b2733`, `#34405a`) are replaced.
- **Calm patterns.** Neighbouring floor colours differ only a little (small steps in lightness), so the ground never
  competes with zombies.
- **Sunbeams** are see-through light shapes drawn on top of the floor (no real lighting engine).
- **Danger colours stay reserved.** No red or orange anywhere in the town or Bedroom art (rule from spec 03 §11 and
  vision §6). Red items in the mockups become pink, raspberry or teal (the Party Shop's pincushion is a **strawberry
  pincushion in pink**, scissor handles and the pencil sharpener are teal or violet).
- All world colours live in **one data file** (`data/art/world_palette.tres`), so tuning brightness takes minutes
  (hard rule 8).

### 2.2 Building style: "Stitched toy box" (S3), clean borders

Canvas boards "Building style" (S1 Felt cut-out, S2 Built toy, S3 Stitched toy box) and "Picked: S3, clean
borders". PO pick (2026-10-25): **S3 "but a little bit more clean borders"**.

- **Hard, chunky shapes**: straight edges and sharp corners, a visible side face and top (3/4 view), small corner
  rounding only. No more soft round blobs.
- **One even, clean ink outline** (about 2 px at game size, the same on every piece, like the zombies, so the world
  feels like one family) + a contact shadow on the floor.
- **Stitched seams sit inside the shapes** (a few pixels in from the edge), never on top of the outline.
- **Texture**: felt grain on every surface (the game's felt shader) and drawn-in materials: wood planks and grain,
  nails, metal corner brackets, cardboard, glass highlights, thread windings.
- Light from the top-left (vision §8.1 "B — Soft"): top faces lighter, side faces darker.

## 3. The town

### 3.1 Ground and layout

- The Pillow Fort stands on a **sunny patchwork quilt**; a **tape measure** is the main road from the fort door,
  **coloured thread paths** lead to each building. Pillow walls with a rick-rack trim around the edge.
- **About 20% more compact** than today, so the camera always sees 3–4 buildings and something nice in between.
- Props between the buildings: felt flowers, loose buttons, a safety pin, a marble, a spool with a thread trail.

### 3.2 Buildings: one object each

| Building | Made from | Ruin → Lv 3 (each level adds visible pieces) |
|----------|-----------|-----------------------------------------------|
| Pillow Fort | Two cushion towers, a patchwork quilt roof | Grows as today (flag, second tower, bunting, lights) every 3 builds |
| Toy Box Armory | An open wooden sewing box with the weapons inside | Broken box → box with a few toys → trays and more weapons → painted, brass corners, weapon rack |
| Lucky Jar | A glass jar of buttons and coins, gingham cloth lid | Tipped-over cracked jar → small jar → full jar with bow → big gold-lid jar, fairy lights, clover flag |
| Watchtower | Stacked cotton reels, thimble lookout, pencil telescope | Fallen reels → one reel + flag → two reels + ladder → three reels, lookout, telescope, plushie on watch |
| Snack Bar | A cookie tin with a striped awning | Dented open tin → tin + cookie → awning, spool stool, button table → cupcake tower, lights, two tables |
| Party Shop | A pink strawberry pincushion with pins as flag poles, balloons | Flat cushion → cushion + pins → balloons → bunting, confetti, pennants on every pin |
| Plush Hospital | A tissue box with a plaster cross | Squashed box → box + cross → windows, tissue puff → little bed outside with a napping plushie |
| Scrapbook stand | An open book on a wooden stand | (no levels) |

- A **ruin** is the same object broken or tipped over, greyed a little, so you can guess what it becomes.
- **Locked** ruins keep the zombie-yarn tangle from spec 03.

### 3.3 Less text, more town

- Built buildings show **no text** until you walk up (the info card from M3.5 does that job).
- Ruins keep a **small price tag** (jar icons + numbers) so the town stays a visible to-do list (spec 03 §5).
- A golden **"Can build!"** tag floats over a building whose next level you can afford right now.

### 3.4 Life

- Plushies keep their spec 03 behaviour, plus a few **spots** where they like to be: reading by the fort, sitting at
  the Snack Bar table, napping on the Hospital bed, waving from the Watchtower lookout.
- Small ambient motion: dust sparkles in the sunbeam, bunting and flags flutter, now and then a paper plane glides
  over the town. All cheap (a handful of sprites).

## 4. The Bedroom

### 4.1 Floor and room

- **Honey floorboards** everywhere; the **patchwork rug** in the middle is where every run starts.
- The **top wall** is visible with two windows; **sunbeams** fall across the middle of the room.
- The room keeps today's size (about 4 × 4 screens) and the same walls.

### 4.2 Places (zones)

Canvas board "The whole Bedroom". Each zone has its own props and floor details, so you always know where you are:

| Zone | Where | What's there | Blocks movement? |
|------|-------|--------------|------------------|
| Patchwork rug | Middle (start) | Big patches, seams, sewn-on buttons | No (open space) |
| Bed's shadow | Top-left | The bed (huge, partly off-screen), its shadow makes this corner a bit dimmer | Bed: yes |
| Block city | Top-right | Alphabet block towers with lanes between them | Towers: yes |
| Crayon corner | Bottom-right | Giant crayons, a sharpener with shavings, scribbles on the floor | Crayons: yes, scribbles: no |
| Sewing corner | Bottom-left | Sewing box, giant scissors, pincushion, a spool with a thread trail across the floor | Box, pincushion: yes |
| Train loop | Bottom-middle | A toy train track ring (decoration you can kite zombies around) | No |

- Zones are **only looks** in this spec: same spawns, same rules everywhere. ("Bed's shadow" is where a night look
  could start later.)
- Furniture keeps the spec 02 rules: blocks heroes, zombies and enemy bullets; hero shots fly over it; wide gaps;
  the first screen around the start stays free.
- Big pieces near the walls may stick out of the room (only the part on the floor blocks).

## 5. Readability (vision §6, hard rule 9)

- Zombies keep their **dark outline and contact shadow**; on the lighter floor they now stand out by being darker,
  not lighter. Enemy shots keep the strongest contrast of anything on screen.
- No danger colours in world art (§2.1), checked by a test.
- Floor colours stay inside a brightness band with small steps between neighbours (numbers in
  `world_palette.tres`), checked by a test.
- Decorations under the action (scribbles, thread trails, sunbeams) are soft and see-through.

## 6. Performance

- The whole floor, the rug and all furniture are drawn **once** (baked), never redrawn every frame (gotcha:
  hundreds of `draw_*` calls per frame killed fps in M1).
- Ambient motion uses a few pooled sprites.
- `tools/benchmark.gd` (500 zombies + 1000 shots) must stay within 5% of today's fps; the numbers go into the PR.

## 7. Acceptance criteria

- **AC-58** All town and Bedroom colours come from `data/art/world_palette.tres`; none of them is a danger colour
  (`UiColors.is_danger`). *(unit)*
- **AC-59** Every floor colour (boards, rug patches, quilt patches) lies inside the palette's brightness band, and
  neighbouring floor colours differ by less than the palette's maximum step. *(unit on the palette)*
- **AC-60** Each of the 6 buildings has its own look for ruin, Lv 1, Lv 2 and Lv 3, and each level adds at least one
  visible piece; building a level in town shows the new look after the build moment. *(unit on the art data +
  scenario)*
- **AC-61** In town, a built building shows no text until a player stands next to it; a ruin shows its price tag;
  the "Can build!" tag shows exactly when the next level is affordable, and disappears after building or when you
  can no longer afford it. *(scenario)*
- **AC-62** The town layout is more compact: from the fort door, every building is within the distance set in
  `pillow_fort.tres` (≈ 20% closer than today), and the camera never shows outside the room. *(unit on the layout +
  scenario)*
- **AC-63** The Bedroom has the 6 zones of §4.2 in `bedroom_furniture.tres`; the start screen around the middle has no
  blocking piece, and the gaps between blocking pieces are at least the minimum from spec 02. *(unit on the layout)*
- **AC-64** New furniture kinds block heroes, zombies and enemy bullets like the old ones, hero shots pass over them,
  and zombies get around them. *(scenario, like AC-20 / AC-21)*
- **AC-65** The benchmark stays within 5% of the fps measured on `main` before this milestone. *(manual check, numbers
  in the PR)*
- **P-22** (playtest) The town is a place you like to walk around in; it looks clearly nicer after a few builds.
- **P-23** Nothing feels "dark" any more; the Bedroom feels like a giant sunny room.
- **P-24** Zombies and enemy shots are still easy to see, also in big crowds.
- **P-25** You notice which part of the Bedroom you are in.

## 8. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. The mix: **A's daylight and scale + C's materials ("Sunny patchwork")**?
2. Building style: **S3 Stitched toy box with clean borders** (hard shapes, one even ink outline, felt grain,
   stitched seams inside the edges)? *(PO picked this, 2026-10-25)*
3. Text: **no text on built buildings until you walk up; ruins keep a price tag; a "Can build!" tag**? (changes spec
   03 §5, where every ruin had a sign with name, price and effect)
4. Town **about 20% more compact**?
5. Bedroom: **the 6 zones of §4.2, looks only** (no new rules), same room size?
6. **No red or orange** in world art; the mockups' red items become pink/teal?
7. Night look (B): **parked**, maybe a later level or the "Bed's shadow" after dark?

## 9. Not in this spec

- A night variant, weather, time of day.
- Walking into buildings (PO idea, parked).
- Zone rules (traps, slow floors, zone-specific enemies).
- Plushie walking animation and looks (#147), new heroes (M5), evolution "wow" pass.

## 10. Proposed tickets (after approval)

1. World palette data + felt grain for world art + danger/brightness tests — AC-58, AC-59
2. Building art kit (ink outline, grain, stitched seams, side shading, ruin state) + Lucky Jar and Armory, ruin to
   Lv 3 — AC-60
3. Watchtower, Snack Bar, Party Shop, Plush Hospital, fort and Scrapbook stand in the new style — AC-60
4. Town ground: quilt, tape-measure road, thread paths, compact layout, props — AC-62
5. Town text: price tags on ruins, text only on approach, "Can build!" tag — AC-61
6. Town life: plushie spots, dust sparkles, flutter, paper plane
7. Bedroom floor and room: floorboards, patchwork rug, top wall with windows, sunbeams, vignette — AC-58, AC-59
8. Bedroom zones + new furniture kinds (crayons, sewing box, scissors, pincushion, block city, train loop) — AC-63,
   AC-64
9. Performance check and polish pass — AC-65
