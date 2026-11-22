# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-11-22 (milestone **Playtest fixes (Nov 2026)**: #323 rug buttons vs XP buttons fixed; earlier: #324 (PR #335), #325 (#343), #326 music (#345), #327 boss slips (#346), #328 Raincoat puddle (#349), #329 Stuffing Cloud (#348), #330 dash display (#350); next: the second player's #336-#342 one per PR, look board for #331; P-22 … P-37 answers still open. **M6 done**: all 13 tickets merged (M6-13 = PR #351), worktree `Game-m6` removed 2026-11-22; M6 playtest P-38 … P-41 waits for the PO)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md`, `02-game-ui-research.md` (UI, 2026-10-24), `03-town-and-bedroom-look-research.md` (2026-10-25) |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | ✅ done (PR #1) |
| M1 Core run | ✅ accepted 2026-10-21 (PRs #17–#29; playtest P-1 … P-6 passed, 144 fps on the PO's PC) |
| M2 Build variety | ✅ accepted 2026-10-24 (played with M3): all 19 tickets merged (PRs #47–#49, #51–#55, #57, #58, #60, #61, #63, #67, #69, #77, #78, #80, #81); + spec 02b floor pickups approved (#83): M2-20 (PR #88), M2-21 (PR #89) and M2-22 (PR #90) merged |
| M3.5 UI and juice | ✅ accepted 2026-10-25: spec 04 (PR #123), M3.5-01 … 08 (PRs #133, #137, #138, #140, #141, #143, #149, #150) + PO fixes #136, #146, #152, #154, #156 (late-game hitches), #158 |
| M3.6 Sunny patchwork | 🚧 spec 05 approved 2026-10-25 (PR #160; AC-58 … AC-65, P-22 … P-25); milestone M3.6, issues #162–#170 (M3.6-01 … 09); M3.6-01 world palette (#162): merged (PR #171); hero clarity #172 (part 1): merged (PR #173, floors calmer #174); M3.6-02 art kit + Lucky Jar + Armory (#163): merged (PR #175); M3.6-03 other four buildings + fort + Scrapbook stand (#164): merged (PR #179); M3.6-04 town ground + compact layout (#165): merged (PR #181); M3.6-05 town text (#166): merged (PR #188); spec update #186 merged by the PO; M3.6-10 Party Shop + Hospital redraw (#187): merged (PR #190); M3.6-06 town life (#167): merged (PR #192); M3.6-07 Bedroom floor and room (#168): merged (PR #193); M3.6-08 Bedroom zones (#169): merged (PR #195); M3.6-09 perf check (#170): merged (PR #197), all 10 M3.6 tickets merged |
| M3.7 Building tricks | 🚧 spec 06 approved 2026-10-27 (PR #199; AC-66 … AC-73, P-26 … P-28); issues #200–#209 (M3.7-01 … 10); M3.7-01 trick data + save v4 (#200): merged (PR #210); M3.7-02 Tricks panel (#201): merged (PR #212); M3.7-03 trick runtime (#202): merged (PR #214); M3.7-04 Armory tricks (#203): merged (PR #216); M3.7-05 Lucky Jar tricks (#204): merged (PR #218); M3.7-06 Watchtower tricks (#205): merged (PR #219); M3.7-07 Snack Bar tricks (#206): merged (PR #221); M3.7-08 Party Shop tricks (#207): merged (PR #222); M3.7-09 Plush Hospital tricks (#208): merged; M3.7-10 readability + prices (#209): merged, all 10 M3.7 tickets merged |
| M4 Night siege | 🚧 spec 07 approved 2026-11-16 (PR #226; AC-74 … AC-84, P-29 … P-31); milestone M4, issues #228–#236 (M4-01 … 09); M4-01 siege data + save v5 + moon calendar (#228): merged (PR #237); M4-02 siege flow (#229): merged (PR #238); M4-03 zombie targeting + building health + Lucky Jar bait (#230): merged (PR #239); M4-04 turrets: Armory + Watchtower (#231): merged (PR #240); M4-05 Snack Bar heal ring + Party Shop confetti trap (#232): merged (PR #241); M4-06 plushies help + Plush Hospital revive (#233): merged (PR #242); M4-07 after the siege: reward, damage, repair, end screen (#234): merged (PR #244); M4-08 siege HUD, tricks, co-op, run log (#235): merged (PR #245); M4-09 readability + perf (#236): merged (PR #246), all 9 M4 tickets merged; **acceptance playtest (P-22 … P-31) waiting for the PO** |
| M5 Plushie heroes | ✅ built (playtest pending). PO decision 2026-11-18: M5 next (before M4.5 equipment). Research `docs/research/04-hero-variety-research.md`; spec 08 approved (PO merged PR #249; `docs/specs/08-playable-plushies.md`, AC-85 … AC-94, P-32 … P-34); milestone M5, issues #250–#258 (M5-01 … 09); M5-01 hero data + save v6 + unlock + dev menu (#250): merged (PR #259); M5-02 hero puppets (#251): merged (PR #260); M5-03 Wardrobe + hero picker (#252): merged (PR #261); M5-04 Pip: Snowball Toss + Chilly Hug (#253): merged (PR #263); M5-05 Böbö: Paw Swat + Bear Hug (#254): merged (PR #264); M5-06 BamBam (#255): merged (PR #265); M5-07 Robbar (#256): merged (PR #266); M5-08 co-op heroes (#257): merged (PR #267); M5-09 readability (#258): merged (PR #268). **All 9 M5 tickets merged; acceptance playtest (P-32 … P-34) goes into the big batch** |
| M4.5 Equipment | 🚧 spec 09 approved 2026-11-19 (PO merged PR #270; incl. PO request: hide gear per slot) (`docs/specs/09-sewn-on-gear.md`, AC-95 … AC-104, P-35 … P-37): 9 pieces (3 Head / 3 Body / 3 Charm), patterns from building Lv 2 + Big Ted / King / elites, new 7th building Sewing Workshop, gear owned by the town and worn per player. Milestone M4.5, issues #271–#280 (M4.5-01 … 10). M4.5-01 gear data + save v7 + rules + dev menu (#271): merged (PR #297). M4.5-02 patterns (#272): merged (PR #301). M4.5-03 Sewing Workshop (#273): merged (PR #305). M4.5-04 sewing table (#274): merged (PR #306). M4.5-05 gear on the hero + hide toggles (#275): merged (PR #308). M4.5-06 head pieces (#276): merged (PR #310). M4.5-07 body pieces (#277): merged (PR #313). M4.5-08 charm pieces (#278): merged (PR #314). M4.5-09 co-op wearing, Scrapbook Gear tab, end screen tags, run log (#279): merged (PR #318). M4.5-10 readability + perf + prices (#280): merged (PR #319). **All 10 M4.5 tickets merged; playtest P-35 … P-37 is in the big batch (PO 2026-11-20: playtest next). M6-10/11 (hints, save bump) can start now** |
| M3 Town | ✅ accepted 2026-10-24: spec 03 approved (PR #91); issues #92–#103; M3-01 save system (PR #105), M3-02 town + flow (PR #106), M3-03 materials (PR #107), M3-04 Way Home portal (PR #109), M3-05 rebuilding (PR #110), M3-06 Toy Box Armory (PR #114), M3-07 Lucky Jar + Watchtower + Snack Bar (PR #115), M3-08 Party Shop (PR #116), M3-09 rescue in the run (PR #117), M3-10 Plush Hospital + plushies in town (PR #118), M3-11 Scrapbook (PR #119), M3-12 co-op in town + dev menu + sounds (PR #120) |
| M6 Look & feel | ✅ built (playtest pending; was a parallel chat in worktree `../Game-m6`, removed 2026-11-22). PO answers 2026-11-19: evolution wow pass, sound + music, options + key rebinding, first-time hints in; small art polish only; night look + interiors stay parked. Spec 10 approved (PO merged PR #282; `docs/specs/10-look-and-feel.md`, AC-105 … AC-116, P-38 … P-41). Milestone M6, issues #283–#295 (M6-01 … 13). M6-01 … 09 don't touch the save: build them alongside M4.5; M6-10/11 (hints, save bump) wait until M4.5 is merged. M6-01 Settings tabs + Screen options (#283): merged (PR #298). M6-02 Readability options (#284): merged (PR #299). M6-03 Key rebinding + key hints (#285): merged (PR #302). M6-04 Music sequencer (#286): merged (PR #303). M6-05 Sound pass (#287): merged (PR #304). M6-06 Evolution moment (#288): merged (PR #311). M6-07 Banana Split peel trail + Sewing Storm stitch-up (#289): merged (PR #315). M6-08 Pincushion Volley chain pins + Yarn Bomb tangle (#290): merged. M6-09 Snow Day + Bear Slam (#291): merged (PR #320). M6-12 low-health warning (#294): merged (PR #322; the playtest nitpicks are handled as issues #323-#333). M6-10 run hints + save v8 (#292): merged (PR #344). M6-11 town hints (#293): merged (PR #347). M6-13 MVP check (#295): merged (PR #351). **All 13 M6 tickets merged; playtest P-38 … P-41 by the PO** |

## Next step

- **2026-11-19: spec 09 Sewn-on gear approved** (PR #270), milestone M4.5, issues #271–#280: build M4.5-01 … 10 in order
  (1-2 tickets per chat). Playtest batch (P-22 … P-34) still waits for the PO.
- **2026-11-18: M5 done** (heroes Pip, Böbö, BamBam, Robbar playable; Wardrobe; co-op-ready picking; clarity
  ladder #172 part 2). Playtest batch now covers M3.6, M3.7, M4 and M5 (P-22 … P-34). Next per vision: M4.5
  equipment (parked by the PO for M5) or another milestone: ask the PO. Co-op joining stays at M7 (PO 2026-11-18).
- **M2 + M3 accepted** (PO, 2026-10-24: "very good progress"). End-screen buttons fell off the screen: fixed (#121).
- PO-approved order: (1) **spec 04 UI and juice** (one themed menu style, juicy buttons, new end screen with
  per-weapon damage/kills/DPS + "Star of the run" + run titles; screens always fit 1920×1080 and 16:10). Input:
  `docs/research/02-game-ui-research.md` and the mockup canvas with looks A Sewing box / B Scrapbook / C Toy-box
  arcade (https://claude.ai/artifact/JGFf3Co4vVR6emnQvs4Q4q). PO picked **a mix of A + B** ("Stitched
  Scrapbook": A's felt patches/sewn buttons as structure, B's tilt/tape/hand-written/photos/stickers as life; mockup
  "Mix" on the canvas). **Spec 04 approved** (PR #123; `docs/specs/04-ui-and-juice.md`, AC-49 … AC-57,
  P-18 … P-21). Milestone **M3.5 — UI and juice**, issues **#124–#131** (M3.5-01 … 08). M3.5-01 style
  foundation (#124): merged (PR #133). PO feedback #135 (Settings from fort + title): merged (PR #136). M3.5-03 weapon
  stats (#126): merged (PR #137). M3.5-02 fit check (#125): merged (PR #138). M3.5-04 end screen (#127): merged (PR #140). M3.5-05 run titles (#128): merged (PR #141). M3.5-06 title, pause, settings (#129): merged (PR #143).
  M3.5-07 level-up, gift box, goal screen (#130): merged (PR #149). M3.5-08 town cards, Scrapbook, HUD (#131): PR #150.
  The repo is **public** since 2026-10-24 (free Actions minutes ran out while private; public = unlimited).
  **M3.5 accepted 2026-10-25** (PO: "Ill trust you. M3.5 accepted"; didn't replay the final card lift / lag fix).
  If the PO still notices late-game stutter, profile their exact weapons next (see Gotchas: Crowd deaths).
  **Next: (2) spec 05** below — research + draft a spec PR (the PO approves specs).
  Spec 05 (2026-10-25): research `docs/research/03-town-and-bedroom-look-research.md` (branch
  `docs/spec-05-town-bedroom-look`), look canvas https://claude.ai/artifact/WzwePbqRnbNVD5EcRx3vic (today's screenshots +
  A Sunny Saturday / B Night-light glow / C Sewn diorama, town + Bedroom each). PO: **mix A + C**, wants "moooore
  details and cooler"; B "too dark" but maybe a night variant for a later level (parked). Round 2 on the canvas
  ("Sunny patchwork": detailed town + Bedroom, building growth ruin → Lv 3, Bedroom map with zones).
  PO OK'd the Mix but buildings "a bit too round", wants more texture/detail → round 3 board "Building style"
  (S1 Felt cut-out / S2 Built toy / **S3 Stitched toy box**, proposed). **Spec 05 drafted**
  (`docs/specs/05-town-and-bedroom-look.md`, AC-58 … AC-65, P-22 … P-25, milestone M3.6 Sunny patchwork) in the
  spec PR #160. PO picked **S3 with cleaner borders** (one even ~2 px outline, seams inside the edges; board
  "Picked: S3, clean borders"), "besides that i love it". **Spec 05 approved** (PO merged #160, 2026-10-25). Milestone M3.6 + issues #162–#170 created. M3.6-01 world palette + felt grain (#162): merged (PR #171). PO: floor "looks nice" but the hero blended in → #172: Banane got the zombies' outline + a coloured ring under each hero (part 1, PR open). #172 part 2 (whole-screen clarity ladder: enemies > hero > own shots > pickups) still open; the benchmark frame shows own pins can bury the hero.
  M3.6-02 building art kit + Lucky Jar and Armory (#163): merged (PR #175).
  M3.6-03 the other four buildings + fort + Scrapbook stand (#164): merged (PR #179).
  M3.6-04 town ground: quilt, tape measure, thread paths, compact layout, props (#165): merged (PR #181).
  M3.6-05 town text (#166): merged (PR #188).
  M3.6-10 redraw: Party Shop = gift-box shop, Plush Hospital = dollhouse (#187): merged (PR #190).
  M3.6-06 town life: plushie spots, flutter, sparkles, paper plane (#167): merged (PR #192).
  M3.6-07 Bedroom floor and room: floorboards, patchwork rug, top wall + 2 windows, sunbeams, vignette (#168): merged (PR #193).
  M3.6-08 Bedroom zones: bed's shadow, block city, crayon corner, sewing corner, train loop (#169): merged (PR #195).
  M3.6-09 perf check (#170): merged (PR #197). Benchmark: before M3.6 ~8.4 fps / 833 draw calls, after ~12.9 fps /
  319 (AC-65 ✅). Floorboards are now tiles.
  **Next: M3.6 acceptance playtest (P-22 … P-25) by the PO (2026-10-27: "didn't test yet, let's continue").**
  **Spec 06 Building tricks (skill tree) approved** (PO merged PR #199, 2026-10-27;
  `docs/specs/06-building-tricks.md`, AC-66 … AC-73, P-26 … P-28). Each building = a branch of 3 tricks, mostly new
  mechanics, 18 in total. Milestone **M3.7 — Building tricks**, issues **#200–#209** (M3.7-01 … 10).
  M3.7-01 trick data + save v4 + buying rules + dev menu (#200): merged (PR #210). M3.7-02 Tricks panel (#201): merged (PR #212). The panel opens with **T** (not E as the spec says: E
  still builds/upgrades); PO to confirm. M3.7-03 trick runtime (#202): merged (PR #214). M3.7-04 Armory tricks (#203): merged (PR #216). M3.7-05 Lucky Jar tricks (#204): merged (PR #218). M3.7-06 Watchtower tricks (#205): merged (PR #219). M3.7-07 Snack Bar tricks (#206): merged (PR #221). M3.7-08 Party Shop tricks (#207): merged (PR #222). M3.7-09 Plush Hospital tricks (#208): merged. M3.7-10 readability + prices (#209): merged (prices kept at the first guess, ~11.1k coins; tune after the playtest). M3.6 + M3.7 playtests **postponed by the PO** (2026-11-16: "didnt play anything, lets just do more implementation ... i will do it then when we have more"): batch them with M4. **Spec 07 Night siege approved** (PO merged PR #226, 2026-11-16; `docs/specs/07-night-siege.md`, AC-74 … AC-84, P-29 … P-31). Milestone **M4 — Night siege**, issues **#228–#236** (M4-01 … 09). M4-01 siege data + save v5 + moon calendar + dev menu (#228): merged (PR #237). M4-02 siege flow (#229): merged (PR #238). M4-03 zombie targeting + building health + Lucky Jar bait (#230): merged (PR #239). M4-04 turrets: Toy Box Armory + Watchtower (#231): merged (PR #240). M4-05 Snack Bar healing ring + Party Shop confetti trap (#232): merged (PR #241). M4-06 plushies help + Plush Hospital revive (#233): merged (PR #242). M4-07 after the siege (#234): merged (PR #244). M4-08 siege HUD, tricks in the siege, co-op, run log (#235): merged (PR #245). M4-09 readability + performance check (#236): merged (PR #246). **All M4 tickets merged. Next: the PO plays the batched acceptance playtest (M3.6 P-22 … P-25, M3.7 P-26 … P-28, M4 P-29 … P-31) with the "latest" build (2026-11-18 steps in the chat); record the results here and fix what comes up.** **PO (2026-11-18): "continue more before i playtest", wants a big batch to test.** #147 (plushie looks + walk): merged (PR #248). **PO (2026-11-18): next feature = M5 playable plushies; all acceptance playtests (M3.6, M3.7, M4 and onwards) postponed to one big batch later, keep building.** Spec 08 PO answers: the four hero kits (Pip slows, Böbö tanks, BamBam heals, Robbar slides), pick at a **Wardrobe** next to the fort (swapped-out heroes, Banane too, become town members), hero's own weapon by default (Armory picker can override), one of each hero in co-op, new weapons join everyone's cards once their hero is unlocked, **unlock when freed in the Bedroom**. Build M5-01 … 09 in order. Still approved and open: #172 part 2 (clarity ladder): between M5 tickets.
  **PO direction (2026-10-27): features first, polish later.** Fewer look rounds / option boards; ship
  "good enough" art and batch nitpicks for a later iteration pass. After M3.6: skill / progress tree spec, M4 siege.
  Speedy Stitcher = "King beaten before 9:00": PO OK (2026-10-25).
  (2) Spec 05 town + Bedroom visual pass ("still not too appealing", "a tiny bit
  dark"). (3) Evolution
  "wow" pass (new behaviour + bigger moment per evolution). (4) Skill / progress tree spec, then M4 night siege.
- **PO decision (2026-10-24): rescued plushies become playable heroes in M5** (Pip, Böbö, BamBam, Robbar; rescue
  = unlock). Goes into the M5 spec. Böbö still has no photo (drawn as the classic IKEA bear).
- PO feedback (2026-10-24): rough felt edges fixed (#145, PR #146). Plushies: Robbar needs work, Böbö should look
  like the IKEA bear, all need a walking animation like Banane → issue #147 (PO: **own ticket after M3.5**. Böbö "a bit more
  chonky", Robbar's "face looks a bit weird"). Photos are in #147's comments (Robbar = chubby round seal plush,
  Böbö = IKEA Djungelskog bear); look notes in the issue. GitHub serves one as AVIF: convert with PowerShell WPF
  `BitmapDecoder` → PNG to view it.
- PO idea (2026-10-26): **use the buildings differently, as a skill tree for upgrades** ("might be more fun, we can add
  cooler stuff that also makes the player more powerful"). Fold into the planned skill / progress tree spec (step 4
  in the order above): ask then how buildings and the tree fit together.
- PO feedback after M3.6-04 (2026-10-26): town "better". Banane's outline looked pixelated + Armory weapon rack
  messy → #183. Party Shop should be "a real shop", Plush Hospital not a tissue box → #184 (options P1-P3 /
  H1-H3 on the look canvas, round 4). PO picked **Party Shop = P3 gift-box stack + P1 shopfront** ("I like that it
  looks like a shop") and **Hospital = H2 dollhouse**; canvas board "Picked: Party Shop P3 + P1, Plush Hospital H2";
  spec PR #186 (PO merges), redraw ticket #187.
- PO idea (2026-10-24, "idk"): **walk into the buildings** (interiors). Park it; ask again when the town visual
  pass or the siege is specced.
- Economy (M3-05/PR #113): cheapest rebuild 200 coins, all 6 at level 3 ≈ 17k coins.

## Playtest notes (big batch, 2026-11-21, first round)

- Free-form feedback + screenshots, no P-22 … P-37 yes/no yet (ask again after the fixes).
- Liked: Banana Split evolution "really cool", sewing table "really nice!!!".
- Bugs, milestone "Playtest fixes (Nov 2026)": #323 XP buttons look like rug buttons, #324 town card off the
  bottom of the screen, #325 sewing table changes size on "Hide all" + panels need a close X, #326 two music
  tracks at once (King fight?), #327 Banana Split near-perma-slips bosses + odd slip-in-attack animation,
  #328 Raincoat puddle looks odd, #329 Stuffing Cloud too short (Piggy's death cloud always hits you),
  #330 dash readiness invisible (one dash, 1.5 s cooldown; only a thin ring today).
- PO decisions: #331 gear "glued on top" → **look board first**, then redraw ("not visible in a run" was
  most likely "Hide all" on: confirm). #332 loadout view in the **pause menu and in town** (short spec addendum).
  #333 **every weapon gets an evolution** (6 more: Bouncy Yarn Ball, Button Shotgun, Stuffing Cloud, Thimble
  Mortar, Thread Whip, Zipper Ray): own spec later.
- Second player (PO's GF, 2026-11-21), same milestone: #336 Space on the gift screen also dashes, #337 "New
  pattern" banner too short, #338 Banane's sewing-table photo grey/blurry, #339 Banane's head can't be hit,
  #340 floor toy drop + elite arrival need a short text ("A toy appeared!"), #341 Banana Split peel = real
  banana, #342 gift box opening stiff. Extra hint `evolution_how` on #292: **PO OK** (add to spec 10 §6 via a
  small spec PR). #339 hitbox: **PO picked A** (keep the
  small area, make it clearly visible; maybe together with the dash display #330).
- Fixes 2026-11-21 (tell the PO what to re-check): #326 no double start was found in code; the King's
  death stacked boss → run → endless crossfades plus a loud goal stinger. Now the boss track fades to
  silence (`MusicPlayer.SILENCE`), the fanfare plays alone, stingers duck the music (`stinger_duck`).
  If the PO still hears two tracks, ask exactly when. #327 bosses: `BossDef.stun_guard_seconds` (4 s) +
  no stun mid-pattern (all stuns). #329 cloud area 120-160 (was 55-85), damage 4 at Lv 1-2: a clear
  buff, tune `area` down if too strong (not under ~115). #330 HUD `DashPatch` + pip under each hero's bar.

## Playtest notes (M3.5, 2026-10-24, first look)

- "Looks really nice", "It feels amazing!!!! i like all that alot. menus feel good" (P-18 / P-19 positive).
- Level-up cards: the PO likes the lift; the problem was card 1 staying raised by keyboard focus while the mouse
  was elsewhere ("different height" = sits higher). Now: the mouse moves the choice, the chosen card lifts + gold
  ring, never grows (#151, #153, #157).
- 2026-10-25: end screen good (P-20 ✅), zombies readable (P-21 ✅). "Endless +4 min feels reaaally laggy when many
  die at once, fps 144": hitches from mass deaths + unlimited hit-stops → fixed (#155, PR #156).
  After #155: ask the PO to replay endless; if still laggy, profile their exact build (weapons) next.

## Playtest notes (M2 + M3, 2026-10-24)

- Town still doesn't look very appealing → spec 05. Evolved weapons could be more exciting → evolution pass.
- "We REALLY need to work on the UI": basic, not fun. End screen "really bad": wants weapons with stats
  (damage done), buttons slipped out of the viewport → spec 04 (+ fix #121).

## Playtest notes (M2, first round)

- "Looking really good", "I enjoy this a lot".
- Gift box: the moment closes by itself, hard to see what you got, no confirmation → spec 02 §20.
- Thimble Mortar: not clear what it does or where it lands → spec 02 §20.
- P-2 evolution felt good but visuals could be stronger; P-3, P-4, P-5 (smooth with Max everything), sounds: good.
- P-6: never noticed reroll/skip/banish → clearer buttons (spec 02 §20). P-1: "idk, let's continue" (no clear yes).
- Wish: single-use floor pickups (big magnet, freeze, "something fun") → own short spec after M2 acceptance.

## Playtest notes (M1)

- "Feels insanely good for a first demo." Boomerang, sniper, upgrades and dash feel good. Clean readability, satisfying
  hits and sounds. Wants to see "how crazy my attacks get" → drives M2.
- Felt "a tiny bit laggy sometimes" at first, but FPS showed a constant 144. Keep an eye on it in M2 (spec 02 §14).

## Gotchas

- Local Godot lives outside the repo: `C:\Users\denhu\Tools\Godot\` (use the `_console.exe` for headless runs).
- No Python on the dev PC, but gdformat/gdlint can run locally from a portable Python (2026-11-19): download
  the python.org 3.12 "embeddable" zip into a scratch folder, enable `import site` in `python312._pth`, run
  `get-pip.py`, then `python.exe -m pip install gdtoolkit==4.5.0` (CI's version) and use `Scripts/gdformat.exe --diff`.
  Enums want one blank line between them. Keep lines ≤ 100 chars (tabs count as 4) and gdformat
  style. gdlint also rejects loading the same file twice in one script (`duplicated-load`): use one `preload` const.
- Watch the screen without a monitor: a scratch `extends SceneTree` script run with
  `-s <script> --write-movie out.png --fixed-fps 60` (call `FeltAtlas.bake(root)` first) writes PNG frames.
- Shots and enemy bullets live in the run's `ProjectileManager` (pooled, one physics loop, sprites from
  `ProjectileLook`). New weapons: subclass `Projectile`, `projectiles().spawn(MyShot)`, then `launch`. Never `new()`
  shots under the weapon. Enemy bullets: `EnemyBullet` (drawn on the top layer). Real-GPU fps check:
  `Godot_v4.7.2-stable_win64.exe --path . -s tools/benchmark.gd` (M2-01: 500 zombies + 1000 shots → ~190 fps).
- Items: `UpgradeDef.Kind.ITEM` + `Effect`. Weapons must read numbers via `Weapon.current()` (item bonuses applied:
  damage, reach, duration, area) and `Weapon.hit_radius()`, never `stats.at_level()` directly. Lasting shots use
  `WeaponLevel.duration` and `WeaponStats.hit_interval`; `Projectile.size_to(weapon.area_scale())` for Big Spool.
  New weapon = `.tres` in `data/weapons/` + entry in `upgrade_pool.tres` + icon in `UpgradeIcon` + shot look in
  `ProjectileLook`. Look up pool cards with `pool.find(id)`, not by index.
- gdlint `class-definitions-order`: signals, consts, plain vars, then `@onready` vars, and all consts at the top of
  test files too. gdformat joins a call or dictionary onto one line whenever it fits in 100 chars.
- Godot on Linux CI often hangs at exit after all tests ran (most runs since M2-12, even docs-only PRs).
  `tools/test.sh` handles it (PR #65): 30 s after `junit.xml` is written it stops Godot and judges the run by
  the report ("Godot did not quit ... stopping it" in the log is fine). A hang *during* the tests still hits the
  20-min job timeout: then look for a real cause. Timing asserts in scenarios: allow one frame (PR #64).
- Level-up screen: Reroll (R) / Skip (S) / Banish (B, then 1/2/3). Counts per run + skip heal in `upgrade_pool.tres`,
  per player in `Player.card_controls` (`CardControls`). `UpgradePool.roll(levels, rng, excluded, avoid, count)`:
  banished ids go in `excluded`. S is also "move down": watch for accidental skips in the playtest.
- `Player.apply_upgrade` adds one level per card: tests that need level N apply N-1 cards in a loop.
- CI checks can show "pending" forever after all steps finished (GitHub glitch): re-run that job
  (`gh run rerun <run> --job <job>`), don't merge on pending.
- Performance: felt parts are baked once into `FeltAtlas` and drawn as sprites. Never draw hundreds of shapes per
  frame with `draw_*` (500 zombies went from 6 fps / 30k draw calls to 60 fps / ~600).
- Pausing: the run **freezes itself** (`Run.freeze(reason)`, process mode disabled) instead of `get_tree().paused`,
  because GUT's waiting helpers stop when the tree is paused. Menus that must work while frozen use process mode
  "always".
- Tests on Linux CI: never `watch_signals` / keep references to objects that free themselves (peels, runs) — it
  segfaulted once. Connect a lambda that records into an array instead.
- Headless has no mouse position: `PlayerInput` remembers mouse-motion events. Tests convert world → canvas →
  window coordinates (`get_canvas_transform()`, then `get_screen_transform()`) before sending mouse motion.
- Don't touch DisplayServer/Input (e.g. the cursor) in `_exit_tree` of long-lived nodes: the Linux test run hung
  at exit once (PR #29). CI tests run as 4 parallel jobs (2026-11-22, one job had reached 30 min): Typecheck, Unit tests,
  Scenario tests 00-04, Scenario tests 05+ (`tools/test.sh --shard=unit|scenarios-1|scenarios-2`; the shard
  writes its own `test-results/shard.gutconfig.json`), 25 min timeout each. New scenario files go to shard 2:
  if it outgrows shard 1, move the split in `tools/test.sh`.
- Enemies: types are `EnemyStats` .tres + a look (`ZombieLook.for_look`, parts merged in `all_parts`). Ranged:
  `EnemyStats.attack` (`SpitAttack`, wind-up/puff in `EnemyManager._attack`). Burst on death:
  `EnemyStats.death_cloud` (`EnemyCloud`, hostile, pooled). Schedule = `SpawnSchedule.entries` (`SpawnEntry`);
  tests find a type with `schedule.entry_named("Runner")`. Dev menu builds in `setup` (needs `run.rules`).
  Dev menu: `give(id, level)`, `max_everything()`, `choose_upgrade(id)` + "Give Lv N"; it scrolls. `test_m2_data.gd` fails
  if any `src/` script calls `.new(` on a balance resource class (keep numbers in `.tres`).
- GUT `wait_physics_frames(1)` in a loop is not exactly one frame per call: measure time with `run.elapsed`.
- Scenario tests write the run log to `user://test_run_log.jsonl`, never the real `run_log.jsonl`.
  M2 log fields: `evolutions` (name, time, player), `rerolls_used`/`skips_used`/`banishes_used` (from
  `CardControls.*_used`, a dev refill doesn't reset them), `mini_boss_defeated_at`/`boss_defeated_at` (null = not beaten).
- `docs/` has a `.gdignore`; shell scripts need the executable bit in git (`git update-index --chmod=+x`).
- Optional later: `@claude` GitHub workflow (as in Tastey) needs the `CLAUDE_CODE_OAUTH_TOKEN` repo secret.
- Elites: `EliteRules` (`data/elite_rules.tres`) on top of any type: `enemies.spawn(stats, at, elite)` /
  `spawner.spawn_elite(stats)`. Read `zombie.attack`, `zombie.display_name`, `zombie.radius()`,
  `zombie.xp_button()`, never `zombie.stats.*` for those. Elite times: `SpawnSchedule.elites` / `elite_time(i)`.
- Gift box: `run.drop_gift_box(at)`; contents from `GiftBoxRules.contents` (evolution first, else 1-3
  level-ups, else heal), given at touch; the moment is `run.gift_screen` (freeze reason `gift_box`): ~1 s opening
  (`opening_seconds`), then `GiftCardView` cards from `GiftContents.cards()` that stay until `confirm()` (Enter /
  Space / E / Continue, after `confirm_delay`). Tests force-close with `gift_screen.close()` or wait for
  `showing_contents`. Level-ups and gift moments wait for each other. Scenario tests: clear `run.pickups.buttons` before walking onto a box
  (the elite's XP button would open a level-up first).
- Evolutions: `UpgradePool.evolutions` (`EvolutionDef`) + evolved weapon `.tres` with `evolved_from` and one
  level; `Player.evolve`. `upgrade_levels()` reports the old weapon at `Player.EVOLVED_LEVEL` so it is never
  offered again. `RecipeBook.seen` is static (per session; tests clear it). Maxed boomerang + Quick Feet is
  now a Banana Split: gift box tests that need "all maxed" must avoid recipe pairs.
- gdformat wants exactly one newline at the end of a file. Bash heredocs containing apostrophes broke in this
  tool twice: write files with the Write tool instead.
- Bosses: `BossDef` / `BossBrain` subclasses (`BigTedDef`/`BigTedBrain`, `SockKingDef`/`SockKingBrain`; the def
  builds its brain via `make_brain`). Spawn with `enemies.spawn_boss` / `spawner.spawn_boss`; find them with
  `enemies.bosses()`; `run.is_final_boss(z)`. Telegraphs are `BossTelegraph` (child of the boss, z -1).
  gdlint max-returns is 6: put a pattern `match` in its own `_pattern_step`.
- The goal is beating the King (not 8:00). Scenario tests use `beat_the_boss(run)` + `wait_for_goal_screen(run)`
  from `run_scenario.gd`. Endless time counts from `run.goal_time`.
- Furniture: `data/arena/bedroom_furniture.tres` (`FurnitureLayout` of `FurniturePiece`, kind + rect + blocks).
  Players are blocked by physics bodies (wall layer), zombies/enemy bullets/spawns by `Obstacles`
  (`run.enemies.obstacles`, `push_out`, `steer` with a per-zombie `detour`). Player shots ignore it. Keep the
  first screen around the arena centre free (scenario tests play there) and wide gaps between pieces.
- Sounds: all made in code in `SfxBank` (`LENGTHS` + a voice function). Weapon attack sounds live in data:
  `WeaponStats.sound` / `sound_pitch`, played by the `Weapon` base on each attack (never in weapon scripts).
  `test_audio.gd` checks every weapon has its own sound, quieter than enemy-danger sounds. Scenario tests read
  `Sfx.history` (clear it first) to see what played.
- Thimble Mortar: the `ThimbleProjectile` node *is* the landing ring (`ProjectileLook.RING`, z -1 under zombies),
  scaled to `blast_radius()` (Big Spool included); fill disc child, thimble/shadow/dust are `top_level` sprites.
  Tests read `ring_radius()`, `fill_share()`, `height()`. Perl/regex edits that insert functions: check blank
  lines (exactly two between functions) or gdformat fails in CI.
- Level-up buttons: `CardControlButton` (icon, key badge, dots, hint; `uses_text()` for tests). `LevelUpScreen`
  pulses them on its first `open` (`is_pulsing()`); banish mode marks cards (`UpgradeCard.set_marked`), Esc cancels.
- Evolved shot looks: `WeaponStats.shot_look` (`ShotLook` .tres sub-resource: part, size, trail, flash). Projectiles
  call `dress(from)` at the end of `launch` and hurt zombies via `hurt()` (sparkle pop = `SparkleProjectile`).
  Pooled shots drop the look in `reset`. A new evolved weapon needs its own part in `ProjectileLook` + a `ShotLook`.
- gdformat joins a function signature onto one line when it fits in 100 chars (tabs = 4), and splits inline
  lambdas in calls onto their own lines: in tests prefer small wait helpers over `func() -> bool:` arguments.
  Avoid `\"` escapes in strings (it rewrote one).
- Floor pickups (spec 02b): kinds are `FloorPickupDef` sub-resources in `data/floor_pickup_rules.tres` (id, banner,
  weight, sound); drop timing in `FloorPickupDrops` (`run.floor_pickup_drops.next_drop_at`). Drop one with
  `run.drop_floor_pickup(id, at)`; the effect is a `match kind.id` in `Run._on_floor_pickup_touched` (add new kinds
  there + a part in `FloorPickupLook` + a sound). Pickups free themselves on touch: tests check
  `run.floor_pickup_log` / `run.floor_pickups()`, never a held reference. Edge arrows: `run.pickup_arrows.points`.
- Snow Globe: `run.freeze_the_horde()` → `enemies.freeze(seconds, boss_speed, crack_seconds)` (numbers in
  `floor_pickup_rules.tres`), `spawner.pause(seconds)`, `projectiles.pop_enemy_bullets()` (+ `FluffPoofs`). Frozen
  zombies: `zombie.frozen` / `zombie.thaw_shake`, tint `ZombiePuppet.ICE_TINT`; bosses run their whole turn at
  `delta * freeze_boss_speed`. `enemies.ice_cracking` plays `ice_crack`. Spawn tests at 120 s hit a breather
  (almost no spawns): use 150 s (a surge).
- Party Popper: `run.party_pop(player)` hits every zombie inside `spawner.visible_rect()` (normal ones get their
  full health, elites/bosses `popper_elite_share`/`popper_boss_share` of max health, in `floor_pickup_rules.tres`)
  and adds a `ConfettiBlast` (one node draws all bits; `piece_offset(i)` / `piece_color(i)` for tests).
- Save (spec 03 §9): `TownSave` (data) + `SaveStore` (static, JSON in `user://save.json`, temp file + `.backup.json`,
  `last_source`). Main owns `main.town`, loads it in `load_town()` (settles a closed run at `keep_share_lost`),
  `save_now()` on checkpoints/quit/window close, `_bank_run(result)` after every run. A run's haul is `run.haul`
  (`RunHaul`); `Run.checkpoint_due` fires every `CHECKPOINT_SECONDS`. Scenario tests use `user://test_save.json`
  (`run_scenario.gd`); unit tests set `SaveStore.path` themselves. New autosave points: call `main.save_now()`.
- Town (spec 03 §5): `Town` scene (`src/town/`), layout in `data/town/pillow_fort.tres` (`TownLayout`; one `TownSpot`
  per building: rect, `needs_rebuilds`, `needs_rescue`; buildings are `TownBuilding` in `town.buildings`). Flow in Main: title
  (New game / Continue) → `show_town()` → E at the door (`p1_interact`, `town.enter_bedroom()`) → `start_run` →
  `show_end` (also on give up, `run.gave_up`) with `EndScreen.brought_home` (`BroughtHomePanel`) → "Back to the
  fort" (`fort_requested`) → town. Town players are `armed = false`. Scenario helpers: `go_to_town()`, and
  `start_run()` now goes title → town → door. The headless test window is square (1920×1920): check camera follow
  sideways only.
- Materials (spec 03 §3): `MaterialRules` (`data/town/material_rules.tres`) holds one `MaterialReward` per zombie
  type / boss, matched by the **base** name `zombie.stats.display_name` (not the elite's), plus `elite_extra`,
  `gift_box`, `big_gift_box`, `victory_bonus`. `run.collect(amounts, at, burst)` adds to `run.haul` and the HUD
  (`hud.jars`: `RunJars`, bursts are `MaterialBurst`, `hud.jars.bursts`). Rolls use `run.material_rng`. The victory
  bonus goes into the haul when the King dies. Rebuild costs (M3-05): a 5-min dying run brings ~250-300 coins.
- Way Home portal (spec 03 §4): `WayHomePortal` (`src/town/`, numbers in `data/town/way_home_rules.tres`) opens via
  `run.open_way_home(near)` when a non-final boss dies (once per run, never after the goal); `run.way_home`,
  `portal.fill` (0..1, pauses when nobody stands in it), `entered` → `finished(make_result("way_home"))`.
  `_reach_goal` calls `close_way_home()`. `PickupArrows` points to pickups and the portal (`colors`).
  `hud.show_banner` takes an optional title colour.
- Rebuilding (spec 03 §5-6): each `TownSpot` has a `BuildingDef` (`data/town/buildings/<id>.tres`: summary, 3
  `BuildingLevel`s with coins/stuffing/thread + effect text, colours). `town.try_build(building)` pays via
  `TownSave.spend(cost)` (`missing()`, `can_afford()`), sets `building_levels`, plays the moment
  (`TownBuilding.play_build`: shake, `TownPuff`, pop; `shown_level` catches up) and emits `changed` (Main saves).
  `settle()` ~1 s later grows the fort (`TownFort.pieces_for(total_levels, fort_piece_every)`) and reveals newly
  unlocked ruins ("New building!", ids saved in `TownSave.revealed`, also on arrival after a rescue). Info card:
  `town.card` (`BuildingCard`, `action_text` / `missing_text`). Tests wait with `town.is_settling()`. Looks per
  level: `BuildingArt`.
- Town perks (M3-06): `TownPerks.from_save(save, layout)` gathers what buildings change in a run; Main sets
  `run.perks` before the run starts (a run without Main has every weapon). Armory data: `BuildingLevel.unlocks_weapons`
  (weapons listed on a level stay off the cards until it's built; `run._excluded` adds them to banished) and
  `start_weapon_choice`; the choice is `TownSave.start_weapon`, applied via `Player.starting_weapon` in
  `run.spawn_player`. Town: `town.interact(building)` (picker at a maxed Armory: `town.picker`,
  `StartWeaponPicker`), `town.unlock_toast` ("New weapons for your cards!"). Scenario tests about a weapon the
  Armory unlocks call `unlock_all_weapons()` before `start_run()`.
- Town bonuses (M3-07): `BuildingLevel.extra_card_uses` / `pickup_range_bonus` (share of the hero's own) /
  `max_health_bonus` are **totals at that level** (not per level); `BuildingDef.reached(level)` gives the level
  the building stands at. `TownPerks.from_save` sums them; the run passes them to `CardControls.new(pool, extra)`
  and `Player.bonus_max_health` / `bonus_pickup_share` (set before the hero is added, applied in `_ready`).
- Party Shop (M3-08): `BuildingLevel.pickup_gap_cut` (total share, 0.45 = waits 45% shorter) and
  `first_pickup_at` (0 = normal) → `TownPerks` → `FloorPickupDrops.new(rules, rng, cut, first_at)`
  (`drops.gap_cut`). The cut shortens both `min_gap` and `gap_spread`; Lv 3's first drop is due at exactly 15 s.
- Rescue (M3-09): `RescueRules` (`data/town/rescue_rules.tres`, plushies are `PlushieDef` in `data/town/plushies/`).
  Main sets `run.run_number` (= `town.runs_started`) and `run.rescued_before`; `rescue_rules.plan(...)` (uses
  `run.rescue_rng`) gives `run.rescue_plan` (null = none). `run.start_rescue(who)` puts a `TangledPlushie` on
  `floor_items` (ring around `middle()`, `fill`, `used`, `freed`); freeing sets `run.haul.rescued` and saves at once.
  Log field `rescue` (null or plushie/time/freed/freed_at). Placeholder look: `PlushieLook.draw`. Scenario tests
  that start run 2+ should set `run.rescue_plan = null` if a surprise rescue would get in the way.
- Plushies at home (M3-10): looks are `PlushieLook` shapes (`PlushieDef.shape` + colours in
  `data/town/plushies/*.tres`). Beds: `BuildingLevel.plushie_beds` (totals per level); town rules (walk, sit, wave,
  stitch-up, +5% coins) in `data/town/plushie_town_rules.tres`. `town.move_in_waiting()` runs in `settle()` (after a
  build and on arrival), `town.plushies` (`TownPlushie`), `town.tent` (`PlushieTent`). Coin bonus: `main.coin_bonus()`
  → `RunHaul.kept(share, bonus)`. Save v2 renames the old placeholder ids (`TownSave.OLD_PLUSHIE_IDS`). Scenario
  tests put a plushie down with `town.spawn_plushie(def, at, true)` away from the door (random spots can wave).
- Scrapbook (M3-11): pages are built from the game's own data by `ScrapbookRules` (`data/scrapbook.tres`: pool,
  enemy types, elite, bosses, floor pickups, plushies), so a new weapon/enemy/pickup/plushie shows up by itself; it
  needs a text (weapons: level-1 card text, items: card text, others: `scrapbook_text` in their `.tres`). Page ids
  are `ScrapbookRules.WEAPONS` ...; enemy ids = `ScrapbookRules.enemy_id(stats)` (snake-case name), elites "elite".
  The run notes finds in `run.haul.seen` (`haul.see(page, id)`: loadout, `enemies.zombie_added`, floor pickup
  touch); `TownSave.bank` puts all of them in the book (any keep share). Save v3. `RecipeBook.load_from(save)` in
  `Main.load_town`. UI: `ScrapbookBook` (`town.book`, `title.book`; `tile_for(id)`, `tabs`, `detail_*`,
  Q/E turn pages), `ScrapbookPicture.is_silhouette()`.
- Co-op in town (M3-12): `main.player_count` (set in `show_end` from the run's players, dead ones too) → `town.player_count`
  / `run.player_count` spawn that many heroes. No keys for player 2 yet (joining comes with co-op later): scenario
  tests call `add_controls(1)` (temporary `p2_*` actions, removed in `after_each`) and press `p2_interact` etc.
  Town dev menu: `TownDevMenu` (`town.dev_menu`, F1, `press(TownDevMenu.GIVE_MATERIALS)`, `build_label(building)`,
  "Reset town" needs two presses → `town.reset_requested` → `Main._reset_town`). `town.dev_build(building)` = free
  next level, even on a locked ruin. Town sounds: `coin` (burst piece lands, `RunJars.JAR_PITCH`), `page`, `hello`
  (`PlushieTownRules.wave_sound`). F1 in tests: send `KEY_F1` with `sender.key_down`, not `tap_action("dev_menu")`.
  The run/boss music has random hiss, so only title/town are checked for an exact loop.
- UI style (spec 04, M3.5-01): pieces in `src/ui/style/` (`FeltPanel`, `SewnButton`, `FabricTag`, `Sticker`,
  `TapeStrip`, `PhotoFrame`, `HandTitle`), colours `UiColors`, fonts `UiFonts` (`assets/fonts/`, OFL), juice numbers
  `data/ui/ui_style.tres` (`UiFeel.STYLE`, `UiFeel.reduced()`). Containers reset their children's rotation/scale:
  moving pieces extend `Wobbly` (fixed layout frame + moving `body`; `tilt`, `lift`, `grow`, `spin`, `fade`).
  Panel content goes into `panel.content`. `SewnButton` keeps `text` (the face copies it in `_draw`); tests read
  `lift_amount()`, `grow_amount()`, `is_raised()`, `box.press`. Screens: `ScreenMotion.open(parts)` /
  `close(parts, done)`; any key or click finishes the motion. Project theme `data/ui/stuffed_theme.tres` (default
  font Nunito; `FeltLabel` variation = ink on felt). Felt shapes skip empty rects (triangulation errors fail GUT).
  Settings are saved: `GameSettings.save()` / `load_saved()` (Main `_ready`), scenario tests use
  `user://test_settings.json`. Look check: scratch `extends SceneTree` gallery + `--write-movie` (see above).
- Settings (#135): one `SettingsPanel` (`src/settings/`), opened via `pause_menu.settings`, `town.menu.settings`,
  `title.settings` (`show_settings()` / `open_settings()`); Back/Esc returns to the menu. Tests open it first
  (the switches sync from `GameSettings` in `open()`).
- Fit check (M3.5-02, AC-55): `tests/scenarios/test_04_fit_check.gd` boots the game in a stretched SubViewport at
  4 window sizes and checks every screen with `screen_fit.gd` (buttons/panels 24 px margin, labels inside the
  window and their box, nothing cut off). New screens: add a step to `_visit_all` and bump the count.
- Weapon stats (M3.5-03): `run.enemies.tally` (`WeaponTally`). New damage paths must pass the weapon:
  `enemies.damage(zombie, amount, push, weapon)`, or `enemies.damage_from(WeaponTally.X, zombie, amount)` for
  non-weapon sources; code that removes zombies must add the kill to the tally, or the totals stop adding up.
  `RunResult.weapons` / `total_damage`, log field `weapons`.
- End screen (M3.5-04): built in code (`end_screen.tscn` is only the root). Pieces in `src/ui/end_screen/`:
  `WeaponReport` (rules: `rows_of`, `star_of`, `extras`, `short_number` "12.3k", `grouped` "4,321"),
  `WeaponColumn` (one per player: `star`, `star_photo`, `star_sticker`, `rows`, `item_tags`, `listed()`),
  `WeaponRow` (`texts()`). `RunResult.items` / `player_count` feed the tags and columns. Run titles go into
  `end.sticker_row`. `brought_home.show_rescue(name, def)` adds the plushie photo. Fit check: Main loads the
  settings on boot, so set `GameSettings.reduced_motion` *after* booting or screens are measured mid-motion.
- Local only: `test_03_town_flow` "Esc in town" and `test_03_scrapbook` "Esc closes it" fail when run alone on the
  dev PC (pass in the full run and CI).
- Run titles (M3.5-05): list in `data/ui/run_titles.tres` (`RunTitleRules` of `RunTitleDef`: id, text with
  `{weapon}` / `{kills}`, `check` enum + `amount`, rarity, bad). Weapon titles are `WeaponStats.run_title`. Main
  picks them in `show_end` (`_earn_titles`, before banking) and marks first-timers via `TownSave.note_title`
  (`titles_seen`). Run facts for titles: `run.unhurt` (`UnhurtClock`), `run.gift_boxes_opened`,
  `run.lowest_health_at_goal`, `TownSave.new_entries(haul)`; floor pickup log entries now carry `id`. End screen:
  `end.show_titles(titles, gap)`, `title_stickers`, `new_stickers`, `slap_order`; log field `titles`.
- Menu look (M3.5-06): title, pause (+ Recipes), town Esc menu and Settings are built in code (their .tscn is only
  the root). Background = `MenuCloth` (felt cloth; `opacity` < 1 over a run/town, `plain` = only a dim layer).
  Settings: `ThreadSlider` (thread + sewing-button knob, `knob_center()`, `knob_grow`) and `FeltSwitch` (toggle
  Button, `slide`, `show_pressed(on)` = no slide), knobs drawn by `SewingButtonArt`. A `SewnButton` resets its own
  `custom_minimum_size` (`_fit`): set a menu's button width on the column instead. AC-49 check:
  `unthemed(root)` in `test_04_menu_look.gd` (plain Button/slider/ColorRect, flat panels, other fonts): later
  tickets add their screens there. Clicks in tests: wait `open_seconds` first (panels drop in), and wait a frame
  after `tap_action("ui_accept")` (buttons fire on release).
- Level-up, gift box, goal (M3.5-07): built in code. `UpgradeCard` and `CardControlButton` are `SewnButton`s (content
  in `face`, `caption` hidden, size via `face.custom_minimum_size`); key / level on `FabricTag`s (`key_tag`,
  `level_tag`). Cards drop in with `motion.open([cards_holder], false)` (`turn` false = no tilt) and their arrow-key
  neighbours are set by hand (`_link_focus`; Godot's guess jumped to the buttons). `GiftCardView` is a `Wobbly`
  (`box`, `level_tag`). Disabled Reroll/Skip/Banish say "nope" on R/S/B. CPUParticles2D has no `alpha_curve`.
- Smooth edges (#145): filled UI shapes go through `FeltDraw.fill(canvas, points, color)` / `fill_smooth(rid, ...)`
  (fill + a 1.2 px fade ring outside the edge). Plain `draw_colored_polygon` has jagged edges: don't use it in UI.
- Town / Scrapbook / HUD look (M3.5-08): `BuildingCard` is a taped felt PanelContainer (world space, `rotation`
  tilt, pops in on a new building; `level_label` is `level_tag.label`). `StartWeaponPicker` and `ScrapbookBook`
  have `cloth`, a `FeltPanel` and `motion`; picker tiles and Scrapbook tabs/tiles are `SewnButton`s
  (`ScrapbookTile.lean()`, photo = `box.fill == UiColors.PHOTO`). Own stitch colour on a sewn button:
  `set_stitch(color)` (setting `box.stitch` gets undone on hover). Town `banner` is a `FeltPanel`. HUD (AC-51):
  backings `StyleBoxFelt.hud()`, bar fills stay `StyleBoxFlat` (a felt shape a few px wide can't be drawn),
  `UiColors.is_danger(color)` = enemy red/orange; only `hud.boss_bar` may use it (`test_04_hud_look.gd`).
  The fit check measures without rotation: keep tilts of wide pieces small (≤ 1°) or their edge items "stick out".
- Crowd deaths (#155): killed zombies are hidden at once and freed `EnemyManager.FREE_PER_FRAME` per frame
  (`dying_count()`), so a zombie node can stay valid (dead, hidden) for a few frames: check `.dead`, not only
  `is_instance_valid`. Bursts: `MAX_BURSTS` total, `MAX_NEW_BURSTS_PER_FRAME`. `RunJars.show_haul` applies at the
  next frame (`shown()` is right at once). Hit-stop numbers + cooldown in `run_rules.tres` (`run.hit_stop()`).
  The lookup grid may hold zombies freed since the last physics tick: check `is_instance_valid(item)` before casting.
  Shots `fired_by(weapon)` include evolved sparkle pops: filter by class. Stutter check: frame times, not fps
  (scratch bench: kill 300 at once, print the worst frame; before #155 ~24 ms, after ~7 ms).
- World palette (M3.6-01): every town/Bedroom colour lives in `data/art/world_palette.tres` (`WorldPalette`,
  `WorldPalette.current()`, `pick(colors, i)`). New world art reads colours from it and its script goes into
  `WORLD_ART_SCRIPTS` in `test_world_palette.gd` (that test fails on any `Color("#..")` / `Color(0.1, ..)` /
  `Color.RED` in those files). Floor groups (`floor_groups()`) must stay inside the brightness band and
  `floor_max_step`. World nodes get the felt grain via `material = palette.grain_material()` (costs no draw
  calls). Trap: warm wood / brown shadows easily count as danger in `UiColors.is_danger` (hue < 35°,
  saturation ≥ 0.45, value ≥ 0.35): keep wood saturation under ~0.43 and shadows darker than value 0.35.
  Signs on the light floor: dark ink text with a light outline (`sign_text` / `sign_outline`).
- Benchmark (`tools/benchmark.gd`) now walks title → fort → Bedroom and uses its own save/settings files.
  Absolute fps from Claude's sessions on the PO's PC are low (~9 fps on `main` too, 2026-10-25): compare
  branch vs `main` and draw calls, not against old numbers. Outlined `draw_rect` on every wall block added ~250
  draw calls: keep repeated small shapes plain or bake them.
- Hero clarity (#172): Banane's felt pieces carry the zombies' ink outline (`BananePuppet.OUTLINE`,
  `outlined_pieces()`); each hero has a `HeroMarker` ring on the floor (`Marker` node in `player.tscn`, z -1,
  colour `UiColors.PLAYER_MARKERS[player_index]`). `test_hero_clarity.gd` checks outline and ring contrast against
  every `WorldPalette.floor_groups()` colour: new floors or new heroes must keep it green. A calm look check:
  scratch script that starts a run, turns `run.spawner.active` off, places the hero and a few zombies, saves a PNG.
- PO feedback 2026-10-25 on the bright floors: ring "not bad, keep it for now"; floor "a bit too bright" and
  pattern "a tad too strong" → floors ~10% darker (boards ~0.69, rug ~0.77-0.83, quilt ~0.80-0.82 brightness),
  neighbouring colours closer, `WorldPalette.pattern_alpha` (town plaid strength), grain 0.045. Teal/green hero
  rings one shade deeper to keep the contrast rule. If still too bright: lower these in `world_palette.tres`.
- Building art kit (M3.6-02, spec 05 §2.2): a look is a `BuildingSketch` (`src/town/art/`) built in design units
  around the building's bottom middle (y up negative), times `BuildingDef.art_scale` (data). `piece`/`block`/
  `disc`/`rod` get the ink outline (all ink is drawn before all fills, so only the silhouette shows), `shade`/
  `dot`/`line`/`stripes` don't; `sewn = true` adds a seam `seam_inset` px inside. Numbers (outline, seams,
  ruin grey) are in `world_palette.tres` ("Building art"). Each look is baked into one `ArrayMesh` (one draw
  call per building; town went from ~510 to ~440 draw calls). Looks per building: `BuildingLooks.sketch(def,
  level)` (cached; all six buildings since M3.6-03, `BuildingArt` is gone). New look = a
  `XxxLook.build(level, unit)` + a `match` line in `BuildingLooks._build` + its script in `WORLD_ART_SCRIPTS`.
  `test_building_looks.gd` checks every level adds a part name, fits the spot, no danger colour and
  `broken_shapes()` is empty (self-crossing polygons can't be filled). Look check: scratch gallery that calls
  `BuildingLooks.sketch(def, level).draw(self)` + `--write-movie`. Kit ruins show no loose yarn (locked ones
  keep the tangle) and no sign post.
- Kit looks (M3.6-03): shared pieces in `LookParts` (reel, flange, pin flag, fairy lights, bunting, teddy head,
  oval, `box_shadow` / `footprint_shadow` = footprint nudged right/down by `SHADOW_NUDGE`). Seams are drawn after
  all fills, so they show through anything in front: keep sewn pieces out from behind other pieces (the fort's
  wall ends inside the towers, its seams are clipped around the door). Fort: `FortLook.build(layout, pieces)`,
  `town.fort.look()` (cached per piece count, parts = `TownFort.PIECES` names); stand: `ScrapbookLook` /
  `ScrapbookStand.look()`. Building size = `art_scale` in the building's `.tres` (watchtower 1.25, jar 1.3,
  party shop 1.0). `BuildingDef.wall_color`/`roof_color` were removed. Tests: `test_building_looks.gd`
  (`RUIN_PARTS`, `TOP_PARTS`), `test_fort_look.gd`. Gallery scratch: draw `fort.look()` / sketches + `--write-movie`.
- Town ground (M3.6-04, spec 05 §3.1): room 2500×1500, buildings within `TownLayout.max_building_distance`
  (585 px door middle → spot middle, AC-62). `TownGroundLook.layers(layout)` = 4 baked `BuildingSketch` meshes
  (quilt, paths, props, walls; cached per layout, ~150 ms once): separate layers because the kit draws all ink
  before all fills. Road = `layout.road` (smoothed, `road_line()`), thread paths = `TownSpot.thread_path`
  (`thread_line(spot)`), props are `PackedVector2Array`s in `pillow_fort.tres`. Tests check paths never cross a
  blocking rect and props stay free of buildings: moving a building means moving its path/props too. Tape numbers
  are `draw_string` in `TownFloor` (reset `draw_set_transform` before drawing more meshes!). Lamps are gone.
  Camera scenario: `test_05_town_ground.gd` (Town in a SubViewport at 1920×1080 / 1920×1200). Town draw calls
  339 → 223.
- `BuildingSketch.line` with a closed path (last point = first) bakes as a *filled* shape: draw outlines
  side by side or as an open arc (#183). Puppet pieces (`FeltPiece`) fill with `FeltDraw.fill_smooth` and a
  feather of ~1.2 screen px (`_feather()` divides by the global scale): Banane is drawn at 0.34, plain polygons
  looked jagged.
- Town text (M3.6-05, AC-61): `TownBuilding` has no name/effect labels any more. `price_tag` (open ruins only,
  `cost_counters`, `is_short_of`), `can_build_tag` (`shows_can_build()`, `affordable` set in `refresh`, hidden while
  `is_busy()` or `card_shown`), `shown_texts()` for tests. Remove old counters with `remove_child` before
  `queue_free`, or the tag is sized with them. Scenario: `test_05_town_text.gd`.
- Party Shop + Hospital redraw (M3.6-10, #187): `PartyShopLook` (gift-box stack, shopfront) and `HospitalLook`
  (dollhouse; Lv 2 adds a storey). Colours `gift_boxes` / `gift_box_sides` / `gift_box_tops`, `awning*`,
  `hospital_*`, `bush` in `world_palette.tres`. Sign text is sewn into the mesh with `LookParts.letters` (stroke
  glyphs in `LookParts.GLYPHS`, add letters there). Details inside a window lose the kit outline (the glass is
  filled after all ink): use `LookParts.outlined`. `sketch.mark(part)` names a part drawn with shades/lines.
- Town life (M3.6-06, spec 05 §3.4): plushie hangout spots are `PlushieSpot`s in `pillow_fort.tres`
  (`layout.plushie_spots`: pose READ/SIT/NAP/WAVE, `at`, `approach` = climb foot, `building` + `needs_level`).
  `town.hangouts` (`PlushieHangouts`: `free_spots()`, `claim`, `release`, one plushie per spot). Plushie:
  `visit(spot)`, `is_hanging_out()`, `pose()`; states CLIMBING / HANGING_OUT; numbers `spot_*`, `climb_speed` in
  `plushie_town_rules.tres`. Flutter: `BuildingSketch.sway(anchor, toward)` / `still()` stores a 0..1 weight in
  the mesh UV.x; `felt.gdshader` moves it only when `flutter_pixels` > 0 (`palette.building_material()`, used
  by buildings + fort; floors/puppets keep `grain_material()`). `town.life` (`TownLife`, numbers in
  `data/town/town_life_rules.tres`): `beam(i)`, `sparkle_positions()`, `plane_flying`, `next_plane_at`,
  `planes_flown`. Sunbeams are very soft on the bright quilt: raise `sunbeam_strength` if the PO wants them stronger.
- Bedroom room (M3.6-07, spec 05 §4.1): `BedroomLook.layers(size, wall, room, rugs)` = 4 baked `BuildingSketch`
  meshes (boards, rug, walls, details = rug buttons + windows; cached) drawn by `Arena._draw` (furniture between
  rug and walls), plus `BedroomLook.sunbeams()` (own gradient mesh; meshes need UVs or the felt shader draws
  nothing). Numbers in `data/arena/bedroom_room.tres` (`BedroomRoom`, `arena.room`). The top wall is taller
  than the side walls: `arena.outer_rect()` reaches up `top_wall_height` (camera limit), `play_rect()` is
  unchanged. `run.vignette` (`RoomVignette`, a CanvasLayer on the HUD's layer, moved just before the HUD).
  Window positions: `BedroomLook.window_rect(room, i)`, beams `beam(room, i)`. Furniture: see "Bedroom zones". Tests: `test_bedroom_look.gd`, `test_05_bedroom_room.gd`.
- Bedroom zones (M3.6-08, spec 05 §4.2): `FurniturePiece.zone` (`Zone` enum) + new kinds (crayon, sharpener,
  scribbles, sewing box, pincushion, scissors, spool = spool + thread trail across its rect, train track); new kinds
  go at the end of `Kind` (the .tres stores numbers). `layout.in_zone(zone)`. Looks: `FurnitureLook.sketches(layout,
  room, layer)` (FLOOR = walk-over parts, PIECES = blocking parts), one baked sketch per piece, each drawn on its own
  `BakedMeshNode` child of the Arena (off-screen ones are skipped; one big mesh cost ~25% fps). Sunbeams are a
  `BakedMeshNode` too. Look numbers in `bedroom_room.tres` ("Zones"), `palette.crayons`. `Obstacles` has a lookup
  grid (`CELL_SIZE`, `CELL_MARGIN`; circles bigger than the margin check all rects). Stroke letters: a stroke must
  never touch itself (closed loops bake as blobs), stems are their own stroke. Tests: `test_furniture.gd`,
  `test_furniture_look.gd`, `test_05_bedroom_zones.gd`. Scenario tests pick the *first* piece of a kind: keep free
  space around the first tower/toy box in the list.
- Bedroom draw (M3.6-09, #170): `Arena` has no `_draw`; every room mesh is a `BakedMeshNode` child, back to front:
  board tiles (`BedroomLook.board_tiles`, `arena.board_tiles()`, size `room.board_tile`), then `look_layers()`
  (`Layer` = RUG, WALLS, DETAILS), furniture, sunbeams. Big meshes: cut them so off-screen parts get skipped.
- Tricks (M3.7-01, spec 06): `TrickDef` (`data/town/tricks/<id>.tres`: id, name, text, `needs_level`, price),
  listed in order on `BuildingDef.tricks`. Rules in `TrickBook` (`state_of` → `State`, `buy`, `buyable`,
  `all_tricks(layout)`); bought ids in `TownSave.tricks` (save v4, `has_trick(id)`). Town: `town.tricks.try_buy(building,
  index)` pays + saves. Dev menu `GIVE_TRICKS` / `CLEAR_TRICKS`. Tests: `test_tricks.gd`, `test_06_trick_buying.gd`.
- Tricks panel (M3.7-02, AC-67): `town.tricks` (`TownTricks`) owns `panel` (`TricksPanel`, `src/town/tricks/`) and
  `toast` (`TricksToast`, "New: X tricks!" at Lv 1, waits for the weapons toast via `unlock_toast.time_left()`).
  **T** (`p1_tricks`, per player) at a built building opens it (`town.tricks.open(building, by)`; E still builds).
  Patches are `TrickPatch` (`SewnButton`: `state`, `badge`, `check` = `CheckStitch`, `cost_counters`,
  `state_label`); 1/2/3 (`pick_card_*`) or click buys, T/Esc closes. First-time hint while `save.tricks` is
  empty (`shows_first_hint()`). Card line `card.tricks_label`; building tag `new_trick_tag` / `shows_new_trick()`
  ("Can build!" wins). Fit check step "tricks panel". Tests: `test_06_tricks_panel.gd`.
- Trick runtime (M3.7-03, AC-70/71): `run.perks.tricks` (`TrickDef`s in branch order; `has_trick`, `trick`,
  `trick_ids`), every hero gets `player.tricks` / `player.has_trick(id)`. Trick code calls
  `run.tricks.note(id, player)` (`RunTricks`, `src/run/run_tricks.gd`) each time it fires: the first time per run it shows `hud.trick_banner`
  (`TrickBanner`, hero ring colour lightened, `trick_banner_seconds` in `run_rules.tres`) and adds to
  `run.tricks.moments` (log fields `tricks`, `trick_moments`). Run dev menu: `dev_menu.tricks_label`.
  Scenario tests buy tricks with `main.town.tricks.append(id)` before `start_run()`. Run one test file with
  `tools/test.sh -gselect=<name>` (`-gtest` is ignored with the config and runs everything).
- Armory tricks (M3.7-04): `TrickDef.amount` = the trick's one number (Head Start level 2, Second Toy count 1).
  `RunTricks.prepare_hero` sets `player.starting_weapon_level` / `player.extra_weapons` (random from
  `run.tricks.rng`), `hero_added` notes them. Show-and-Tell: `run._card_excluded(player)` →
  `tricks.card_excluded` (all but new weapons on the first level-up; `player.first_level_up_done` set on pick or
  skip; normal cards if fewer than `cards_per_level_up` new weapons fit). gdlint `max-file-lines` is 1000:
  `run.gd` is ~940, so new trick logic goes into `RunTricks`, not `run.gd`.
- Lucky Jar tricks (M3.7-05): numbers in `TrickDef.amount` (Shiny Card = chance 0.1, Lucky Gift = +1, Four of a
  Kind = 4 cards). Level-up cards are dealt by `run._deal(player, excluded, avoid)` →
  `tricks.card_count(player)` + `tricks.dealt(offers, player)`; `tricks.start_level_up(player)` rolls
  `shiny_level_up` once per level-up (the shine moves to a new card after a reroll/banish). `UpgradeOffer.shiny`,
  `levels()`, `can_shine()`; `Player.apply_upgrade` applies every level of the card. Card look: `card.shiny_tag`,
  `card.sparkle` (`ShinySparkle`). Key 4 = `pick_card_4`. Gift cards narrow when more than 5 share the row
  (`GiftBoxScreen.card_width(count)`; big box + Lucky Gift = up to 6). Tests force a shiny level-up by seeding
  `run.tricks.rng` (`_lucky_seed` in `test_06_lucky_jar_tricks.gd`).
- Watchtower tricks (M3.7-06): `RunTricks.run_started()` (end of `Run._ready`) and `leveled_up(player)`
  (`_on_leveled_up`). Spyglass: `pickup_arrows.threats = run.enemies` → extra arrows (`THREAT_COLOR` soft pink,
  bosses `BOSS_SCALE`; `pickup_arrows.sizes`), `threat_pointed` signal. Magnet Whistle:
  `pickups.attract_in(spawner.visible_rect(), player)` + the floor magnet sound at a higher pitch. Treasure Map:
  `tricks.treasure` (big `GiftBox` with `treasure = true`, gets an edge arrow in `GiftBoxLook.GLOW_COLOR`);
  `TrickDef.amount` = px outside the start screen (`tricks.start_rect(at)`), wall margin / furniture radius in
  `gift_box_rules.tres`. Tests: `test_06_watchtower_tricks.gd`.
- Snack Bar tricks (M3.7-07): `Player.shield` / `max_shield` (Second Helping, `TrickDef.amount` = biggest shield):
  `heal()` puts what goes past full into `add_shield`, `take_hit` takes the shield first; `shield_changed`.
  `Player.spare_stuffing` = share of max health to pop back up with (0 = none/used), `has_spare_stuffing()`,
  `popped_back_up` instead of `died`. `RunTricks.pop_back_up(player)` pushes zombies (`zombie.knockback`) and adds a
  `SpareShockwave` (numbers `spare_shockwave_*` in `run_rules.tres`; calm zombies don't move, tests check
  `knockback`). Picnic: `tricks.mini_boss_beaten()` from `Run._note_boss_defeat`. HUD: `hud.shield_outline`
  (`ShieldOutline`, closes as the shield fills; label "+N"), `hud.spare_heart` (`SpareHeartPatch`); every hero's
  small bar (`player_overlay.gd`) shows both too (co-op). Tests: `test_06_snack_bar_tricks.gd`. Shell heredocs
  piped through perl emptied a file once: edit with the Edit tool.
- Party Shop tricks (M3.7-08): `TrickDef.seconds` (Confetti Rush = 4 s, `amount` 0.25 speed) →
  `Player.boost_speed(share, seconds)` / `speed_boost_left()`. Double Fun: `tricks.rolls_double()` in
  `run.drop_floor_pickup(id, at, double)`; `FloorPickup.double` / `twin` (second toy + outer ring); double numbers
  `double_*` in `floor_pickup_rules.tres` (magnet = `LastingMagnet` keeps pulling, globe freezes longer, popper hits
  elites/bosses harder). Effects now go through `run.use_floor_pickup(kind, player, double)` (log field `double`).
  Pocket: `p1_use_pocket` (Q), `Player.pocket` / `pocket_double` / `put_in_pocket` / `use_pocket` (`pocket_used`
  → run), `tricks.pocket(...)`; HUD `hud.pocket` (`PocketPatch`, `is_full()`) in `hud.trick_row` with the heart
  patch; the small per-hero bar shows the toy. Key names for hints: `player.key_text("use_pocket")`.
  `run_scenario.CONTROLS` lists the per-player actions `add_controls` makes. Tests: `test_06_party_shop_tricks.gd`.
- Plush Hospital tricks (M3.7-09): Quick Untangle = `TrickDef.amount` share of `RescueRules.fill_seconds`
  (`TangledPlushie.fill_seconds`, `helped` signal on the first fill). Thank-you Gift: `tricks.plushie_freed`
  drops a gift box at the plushie's spot. Plushie Buddy: `TownSave.last_rescued` (set in `bank`; older saves take
  any plushie) → `TownPerks.buddy` → `run.tricks.buddy` (`PlushieBuddy` in `run.actors`, follows player 1, no
  body); `pickups.attract_near(point, radius, player)` sends untargeted buttons within `TrickDef.amount` px to
  the hero. Look numbers `buddy_*` in `rescue_rules.tres`. Tests: `test_06_plush_hospital_tricks.gd`.
- Trick readability (M3.7-10, AC-73): `test_06_trick_readability.gd` buys all 18 tricks, shows every trick visual
  and reads every colour the nodes carry (tints, Color vars, theme overrides, style boxes, `PlushieDef`, script
  constants): a new trick visual goes into its list. Plushies in a run use `PlushieDef.calmed()`
  (`UiColors.calmed`: danger colours down to `CALM_SATURATION`; Böbö's brown and Pip's scarf count as danger).
  The buddy is baked once into a `SubViewport` (`buddy.picture`, UPDATE_ONCE) shown by one `buddy.sprite`
  (premultiplied blend): drawn per frame it cost ~49 draw calls. Banner: names that fire together share a line
  (`TrickBanner.NAMES_PER_LINE`, `MAX_LINES`), so it never covers the hero. Prices: `test_tricks.gd` checks each
  trick is cheaper than the next building level and the total stays 10k-12k coins.
- Siege data (M4-01, spec 07): `SiegeRules` (`data/siege/siege_rules.tres`: trigger, nights, waves, growth, reward,
  consolation, repair share, texts). Countdown = `TownSave.siege_nights` (-1 = no warning, 0 = due; save v5 also
  `sieges_played` / `sieges_won` / `damaged`, `is_damaged(id)`). `night_passed(save)` in `Main.show_end` and when
  an unfinished run is settled; `warn_if_ready` in `town.settle()` (`_warn_of_the_horde()`, waits for another
  banner) and on arrival; `siege_ended(save, won)` restarts it. Town: `town.calendar` (`MoonCalendar`,
  `MoonCalendarLook`, `layout.calendar_position`, `shown_text()`), end screen `brought_home.horde_label`. Dev
  menu `SIEGE_NOW`, `damage_one()`, `REPAIR_ALL`. Tests: `test_siege_rules.gd`, `test_07_siege_calendar.gd`.
  `Town` is at gdlint's limit of 30 public methods: new town helpers must be private (`_name`) or live in
  their own class.
- Siege flow (M4-02, spec 07 §2, §5): `Siege` (`src/siege/siege.gd`, `siege.tscn` = inherited `run.tscn`) **extends
  `Run`**: same heroes, cards, pause, dev menu; it overrides `_on_player_died` (stand up after
  `stand_up_seconds` via `Player.stand_up`), `collect` (no haul yet, M4-07), `open_way_home` (none), `make_result`,
  `_show_clock`. Its `Arena` node is a `SiegeArena` (town floor, fort, buildings, `TownDusk`; built in `setup`
  *before* `super()` in `Siege._ready`). Waves: `SiegeWaves` (pure clock: `tick`, `take_elites`, `take_boss`,
  `next_wave`) over `SiegeRules.wave_list` (`SiegeWave`: rate, enemies + weights, elites, boss, `boss_at`);
  zombies spawn at `arena.edge_point` (outside the pillow walls, `enemies.play_rect` = `spawn_area`). Fort:
  `SiegeFort` (health from `fort_health_for(total_levels)`, `fell`); zombies walk to it via `enemies.siege`
  (see "Siege targets"). HUD fort bar `FortHealthBar` (top middle,
  under the boss bar's place). Faster XP = `data/siege/siege_xp_rules.tres` on the siege's Pickups. Main:
  `start_siege` / `_end_siege` (→ `siege_ended`, town `welcome_banner`), `start_run` goes to the town while
  due, `save_now` never writes a siege as `unfinished_run`. Town: `town.dusk` (`TownDusk`: `CanvasModulate`
  `palette.dusk_tint` + baked fairy lights, `lit`), door prompt `SIEGE_RULES.door_prompt`, `siege_requested`;
  the "horde is coming" banner waits for other banners (`_tell_the_horde_is_coming` in `settle`). Dev menu `DevMenu.NEXT_WAVE` / `WIN_SIEGE` / `HURT_FORT`. Tests:
  `test_siege_waves.gd`, `test_07_siege_flow.gd`.
- Siege targets (M4-03, spec 07 §4-5, AC-77): `SiegeTarget` (rect, health, `touch`, `walk`, `fell`, `is_hurt`) is the
  base of `SiegeFort` and `SiegeBuilding` (health `BuildingLevel.siege_health`, bait radius
  `BuildingLevel.siege_bait`, Lucky Jar only; others draw zombies within `SiegeRules.building_reach`).
  `SiegeTargets` (`siege.targets`, `enemies.siege`) picks a zombie's goal: bait → hero within `hero_reach` →
  what it touches → nearest building in reach → fort (`goal_for`, null = chase the hero); `touch` hurts every
  standing target it touches. Only built, undamaged buildings are in `targets.buildings` (`building(id)`,
  `knocked_down()`). Fallen: `TownBuilding.knock_down(tilt, sink, tint)` (numbers `knocked_*` in
  `siege_rules.tres`), bars `siege.building_bars` (`BuildingHealthBar`, shows only while hurt). Plushies join as
  targets in M4-06 (another `SiegeTarget`). Zombies slide around a building slowly (~4 s past the armory).
  Tests: `test_siege_targets.gd`, `test_07_siege_targeting.gd`.
- Siege turrets (M4-04, spec 07 §4, AC-78): a turret is a real `Weapon` with no hero: `weapon.mount(stats, level,
  range, tally_source)` (`is_turret()`, fires only while a zombie is within `mount_range`). Weapons and shots never
  read `player.global_position` / `aim_point()` / `facing` directly any more: use `weapon.origin()`,
  `weapon.aim_point()` (turret = nearest zombie), `weapon.facing()`, `weapon.damage_scale()`. Data:
  `BuildingLevel.siege_weapon_level` (0 = no turret) / `siege_range`, `BuildingDef.siege_weapon` (empty = player 1's
  starting weapon; Watchtower = `data/siege/watchtower_pin.tres`, behaviour `TowerPin`: toughest zombie in range).
  `SiegeTurret` (`siege.turrets[id]`, `is_firing()`, `stop()` on fall and at the end). Tally rows
  `WeaponTally.ARMORY` / `WATCHTOWER` (player -1). Older siege tests call `silence_turrets(siege)` so zombies reach
  their goal. Tests: `test_siege_turrets.gd`, `test_07_siege_turrets.gd`.
- Siege rings (M4-05, spec 07 §4, AC-78/82): `SiegeRing` (base: stitched circle on the floor, `covers(point)`,
  `glow`, `stop()` on fall / siege end; `arena.add_to_floor(node)` puts it above the town floor, under buildings)
  → `SiegeHealRing` (Snack Bar, heals every hero inside `BuildingLevel.siege_heal` per s, `healing`, `healed`) and
  `SiegeConfettiTrap` (Party Shop, `siege_trap_seconds` / `siege_trap_damage`, waits loaded until a zombie is in
  reach, `pops`, `popped`, `time_left()`, tally row `WeaponTally.PARTY_SHOP`). Reach = `siege_range` from the
  footprint middle. Look/sound in `siege_rules.tres` ("Building helpers"). `siege.rings[id]`;
  `silence_turrets` also stops traps. A siege with no waves and no zombies is won at once: tests keep one still
  zombie far away. Tests: `test_siege_helpers.gd`, `test_07_siege_helpers.gd`.
- Siege plushies (M4-06, spec 07 §4, AC-79): every plushie with `TownSave.plushies[id] == "in_town"` becomes a
  `SiegePlushie` (`siege.plushies[id]`) at `TownLayout.siege_plushie_spots` (by the fort). It owns a plain
  `SiegeTarget` (`target`, in `siege.targets.plushies`; `SiegeTarget.pull` / `pulls()` / `revive()` / `revived` now
  live in the base) and a mounted `PlushieThrow` weapon (`data/siege/plushie_ball.tres`, `StuffingBall` = the
  cloud part drawn small, tally row `WeaponTally.PLUSHIES`). Knocked out: `is_out()`, tilt + dizzy stars
  (`star_position(i)`), no throws; `BuildingLevel.siege_revive_seconds` (Hospital 12 / 8 / 5) stands it back up
  while the Hospital stands (`hospital`, `can_revive()`). Numbers in `siege_rules.tres` ("Plushies").
  `PlushiePicture` = a plushie baked once into a sprite (buddy + siege plushies); build it in `setup`, not
  `_ready`, if it may be used before entering the tree. `silence_turrets` stops plushie throws too.
  Tests: `test_siege_plushies.gd`, `test_07_siege_plushies.gd`.
- After the siege (M4-07, spec 07 §6, AC-80): `Main._end_siege` banks `SiegeRules.haul_for(number, won)` via
  `TownSave.add_materials`, on a loss `TownSave.damage(result.knocked_down)` (built ones only), then shows the
  run's `EndScreen` (siege title from `RunResult.title()`, `is_siege()`, `waves_held` / `wave_count`, no Try
  again / seed; `brought_home.show_siege(note, damage_line)`, `damage_label`) → "Back to the fort". Giving up =
  lost (knocked-down ids read at that moment). A won siege stands knocked buildings up (`TownBuilding.stand_up`).
  Damaged: `TownBuilding.damaged` / `show_damaged` (lean, `damaged_tint`, `DamageLook` felt patches; palette
  `damage_patches` / `loose_thread`), price tag = `repair_cost()`; card says `damaged_card`, E = `Town._repair`
  (via `interact`; `try_build` refuses until repaired). `TownPerks` treats damaged buildings as level 0 and skips
  their tricks. Scripts that siege_rules' own resources depend on (RunResult, TownBuilding, BuildingCard) use
  `SiegeRules.current()`: a `preload` there is a parse-time cycle. Tests: `test_07_after_the_siege.gd`.
- Siege HUD, tricks, log (M4-08, spec 07 §4, §7, §10, AC-82/84): `siege.wave_counter` (`WaveCounter`, right of
  the fort bar; texts `wave_counter` / `breather_counter` / `last_ones_counter` in `siege_rules.tres`). Fort edge
  arrow: `pickup_arrows.watch_fort(fort, fort_arrow_seconds)` (`fort_alarm`, `FORT_COLOR` = fort bar teal), only
  while no part of the fort is on screen. Tricks: `TrickDef.in_siege` (false = Bedroom-only: Treasure Map, Picnic,
  the three Plush Hospital tricks); `Siege._ready` calls `perks.keep_siege_tricks()`. Confetti Rush, Double Fun and
  Pocket Pickup stay on but have nothing to act on (no floor pickups in the siege). Log: `RunLog.siege_entry`
  (`kind: "siege"`, written by `Main._end_siege`; `RunResult.fort_health_left` / `damaged`); expedition lines now
  carry `kind: "run"`. Fit check (25 screens) visits the repair card + calendar (world-space labels only checked for
  cut-off text), the siege HUD and the siege end screen. Tests: `test_siege_hud.gd`, `test_07_siege_hud.gd`.
- Siege readability + draw cost (M4-09, AC-83, spec 07 §11): colour sweeps live in `tests/scenarios/color_sweep.gd`
  (`colors_of(root)`, also reads `BuildingSketch.colors()`), used by `test_06_trick_readability.gd` and
  `test_07_siege_readability.gd` (all siege visuals; dusk-floor contrast: zombie ink beats every siege floor colour).
  Benchmark: `tools/benchmark.gd -- --siege` (all buildings Lv 3, 4 plushies, 300 zombies at the fort; prints
  process/physics ms too). 2026-11-18: Bedroom 161 / siege 159 draw calls. Draw-call traps found: one `draw_arc`
  per stitch (~96 calls per ring → `SiegeRing.stitch_lines` + one `draw_multiline`), `DamageNumbers` alternating
  outline/fill (2 calls per number → all outlines first, then fills: Bedroom 319 → 161), anti-aliased StyleBoxFlat
  bars (→ plain `draw_rect` on a shared `z_index`). The siege hides `hud.jars` (kills bring nothing home).
- Plushie walks (#147): each `PlushieDef` has a `gait` (`PlushieGait` sub-resource in its `.tres`: `STEP` = feet in
  turn + arm swing + body bob, a big `tilt` = Böbö's waddle; `HOP` = Robbar's hop with squash/stretch).
  `gait.pose(seconds, amount)` → `PlushiePose` (feet/arms/body_lift in drawing units, hop/tilt/squash for the caller's
  transform). `PlushieLook.draw(..., wave, pose)`; `TownPlushie.walk_pose()` / `is_moving()`, ease in/out speed
  `stride_blend_speed` in `plushie_town_rules.tres`. Look check: scratch gallery drawing each def at rest + a few
  poses with `--write-movie`. Tests: `test_plushie_gait.gd`, `test_03_plushie_walk.gd`.
- Heroes (M5-01, spec 08): `HeroStats.id` / `plushie` (null = Banane); roster `data/heroes/hero_roster.tres`
  (`HeroRoster`, Banane first) via **`HeroRoster.current()`** in game code: a `preload` of the roster in
  `TownPerks` loads in a circle (hero → weapon `.tres` → weapon script → TownPerks). Unlocked = any
  `TownSave.plushies` entry (freed + banked). `TownSave` v6 `heroes` (id per player slot, `hero_id(slot)` /
  `set_hero`). `TownPerks.heroes` / `hero(index)` → `Run.spawn_player` sets `player.stats` before anything else;
  town players use `HeroRoster.current().hero_for(save, index)`. Town dev menu `UNLOCK_HEROES`, `NEXT_HERO`
  (swaps player 1 in place). Pip / Böbö start with Thimble Mortar / Thread Whip until their own weapons
  (M5-04/05). Tests: `test_heroes.gd`, `test_08_hero_data.gd`.
- Hero puppets (M5-02, spec 08 §6, AC-90): a plushie hero's `Player._enter_tree` swaps the scene's `BananePuppet`
  for a `PlushiePuppet` (still named `Puppet`). It bakes the calmed `PlushieLook` once into one `SubViewport`
  sheet (`picture`: rest frame, `WALK_PHASES` walk frames at each `WALK_AMOUNTS` stride, 2 waving frames) shown by
  one `sprite` (region = `frame`) with `hero_sprite.gdshader` (ink outline around the silhouette, grain, flash;
  premultiplied). Hop / waddle tilt / squash, dash, hit, cheer and fall move `body` live; the floor `shadow`
  stays down. Numbers `puppet_height` / `walk_speedup` / `stride_blend_speed` in `data/heroes/<id>.tres`.
  `PlushieLook.draw(..., shadow = false)` leaves the shadow out. Tests: `test_hero_clarity.gd` (every hero, dusk
  floors too), `test_08_hero_puppets.gd`. In scenarios the first frames of a run have a 0.15 s delta: wait
  ~0.5 s before checking short effects like the hit flash.
- Wardrobe (M5-03, spec 08 §2, §4, §5, AC-85/86): `town.wardrobe` (`TownWardrobe`, `src/town/wardrobe/`; spot
  `TownLayout.wardrobe_rect`, texts/sounds/size in `data/town/wardrobe_rules.tres`, look `WardrobeLook`). Shown once
  a plushie hero is unlocked and announced; "X wants to play!" banners are remembered in `TownSave.revealed`
  (`"wardrobe"`, `"hero:<id>"`, no save bump) and wait for other banners in `settle()`. `wardrobe.open(slot)` →
  `HeroPicker` (`tiles`, `photos` = `HeroPhoto`, `notes`, `can_pick`, 1-4 = `pick_card_*`, 5 = key). Locked/taken
  tiles stay *enabled* (a disabled `SewnButton` fades its face and silhouettes show their pieces) and say "nope".
  `wardrobe.swap(slot, hero)` saves, respawns in place, puffs and calls `refresh_members`: played plushies leave
  `town.plushies` and the tent, the others hop out beside the Wardrobe (`door()`); Banane not played =
  `wardrobe.banane`, a `TownPlushie` with `PlushieDef.Shape.BANANE` (`data/heroes/banane_town.tres`, via
  `HeroStats.town_member`) whose `puppet` is a `BananePuppet` walked by it (`walker`). Picker texts per hero:
  `HeroStats.passive_name` / `passive_text` / `strength` / `weakness` / `try_on_text`. Dev menu "Next hero" uses
  `swap`. Fit check: 26 screens ("hero picker"). Tests: `test_08_wardrobe.gd`.
- Pip (M5-04, spec 08 §3, AC-87/88/89): Snowball Toss = `SnowballToss` (extends `ThimbleMortar`: `_pick_target` =
  biggest group among the 8 closest, `_shot_kind`) + `SnowballProjectile` (extends `ThimbleProjectile`: `_ball_part`,
  `_landed_on` → `zombie.slow(WeaponStats.slow, slow_seconds)`); data `data/weapons/snowball_toss.tres`, part
  `ProjectileLook.SNOWBALL`, icon `snowball`, sound `snowball`. `HeroStats.unlocks_weapon` keeps a hero's new weapon
  in `TownPerks.locked_weapons` until that hero is unlocked (counts in old Armory/Scrapbook tests include it).
  Chilly Hug = `ChillyHug` node (`src/passives/`, added in `Player._ready` when `stats.chilly_hug`; numbers
  `chilly_*` in `pip.tres`): slows zombies within `chilly_radius` each physics frame (`LINGER_SECONDS`), bosses by
  `chilly_boss_slow`; frost ring only while armed. Tests: `test_snowball_toss.gd`, `test_08_pip.gd`.
- Clarity ladder (#172 part 2, PR #262): draw order in `WorldLayers` (`src/core/world_layers.gd`): floor marks -1 <
  pickups 0 < own shots 1 < zombies / bursts / damage numbers 2 < heroes 3 < enemy bullets 50 (`run.tscn`,
  `ProjectileManager`, `Player`). Rings on the floor under a hero use `z_as_relative = false` +
  `WorldLayers.FLOOR_MARKS` (hero ring, Chilly Hug). `test_clarity_ladder.gd` checks every `ProjectileLook`
  own-shot colour is non-danger and quieter than the zombie ink on every floor; `WorldLayers.absolute_z(node)` for
  tests. #172 stays open until the PO's playtest.
- Böbö (M5-05, spec 08 §3): Paw Swat = `PawSwat` (extends `ThreadWhip`, `_aim` = `facing()`) + `PawProjectile`
  (extends `WhipProjectile`: `_part` / `_part_radius`); data `data/weapons/paw_swat.tres`, part `ProjectileLook.PAW`
  (calm tan: Böbö's brown is a danger colour), icon `paw`, sound `paw`. Bear Hug = `BearHug` node (`src/passives/`):
  while dashing, zombies within `bear_hug_reach` are shoved (`bear_hug_shove`) and hurt once per dash via
  `enemies.damage_from(WeaponTally.BEAR_HUG, zombie, amount, push)` (push param is new). `HeroStats.damage_taken`
  (Böbö 0.8) sets `Player.damage_taken_multiplier` at the start. Tests: `test_paw_swat.gd`, `test_08_bobo.gd`
  (scenario tests that take a hit: kill nearby zombies first or they keep the hero invulnerable / dead).
- BamBam (M5-06, spec 08 §3): Big Heart = `BigHeart` node (`src/passives/`, numbers `big_heart_*` in `bambam.tres`):
  on `player.progress.leveled_up` heals every living hero within `big_heart_heal_reach` by `big_heart_heal` of their
  max health and adds knockback to zombies within `big_heart_push_reach` (no damage); pink heart ring drawn on
  `WorldLayers.OWN_SHOTS`. `pulses` / `pushed` for tests. Test: `test_08_bambam.gd` (co-op partner healed too).
- Robbar (M5-07, spec 08 §3): Belly Slide = `BellySlide` node (`src/passives/`, `belly_slide_*` in `robbar.tres`;
  the long slide itself is `dash_distance` 180 / `dash_duration` 0.3): while dashing, zombies within
  `belly_slide_reach` take `belly_slide_damage` once per slide (`WeaponTally.BELLY_SLIDE`), wet streak drawn
  top-level on `WorldLayers.FLOOR_MARKS` (`trail_size()`). Passives are created in `Player._add_passives()` (node
  named after its class, `setup(player)` after `add_child`). Test: `test_08_robbar.gd`.
- Co-op heroes etc. (M5-08, spec 08 §7-9, §11, AC-91): `HeroRoster.heroes_for(save, count)` = one of each (a taken
  or locked saved hero → first free unlocked one); used by `TownPerks.heroes` (`MAX_PLAYERS` slots),
  `Town.spawn_player`, the Wardrobe and the picker. Siege helpers: `siege.helpers()` = in-town plushies nobody
  plays + Banane's `town_member` when someone else plays (a `BananePuppet` child of the `SiegePlushie`; a
  `BananePuppet` with no player/walker shows itself standing in `_ready`). Armory picker: first tile
  `StartWeaponPicker.OWN` "Hero's own weapon" (default, sets `TownSave.start_weapon` = ""). Scrapbook plushie note
  `ScrapbookBook.note_of(entry)` (+ `HeroRoster.plays_with`). `RunResult.heroes` / `hero_names` (id per player index) → log field `hero` (runs + sieges),
  end screen `WeaponColumn.heading_text` ("Player 2 · Pip") / `star_caption` ("Pip's Snowball Toss").
  Test: `test_08_coop_heroes.gd`.
- Script cycles (M5-08): CI's typecheck (`tools/check.sh`) fails with "N resources still in use at exit" when a
  new class reference closes a loop of scripts (here `ScrapbookRules` → `HeroRoster`, and `WeaponColumn` →
  `HeroRoster`). Tests still pass, so check locally: `<godot_console> --headless --path . --check-only --script
  res://src/arena/arena.gd` must print no ERROR. Fix: look the roster up from a UI/runtime script
  (`ScrapbookBook.note_of`) or copy what is needed into the data (`RunResult.hero_names`).
- Hero readability + cost (M5-09, spec 08 §13, AC-93/94): `test_08_hero_readability.gd` sweeps every hero effect
  colour (`chilly_ring_color`, `big_heart_color`, `belly_slide_trail_color`, `EFFECT_SHOTS` in `ProjectileLook`) and
  each plushie puppet for danger colours and checks the zombie ink keeps the strongest contrast on every floor
  (dusk too); a new hero effect colour goes into that list. Draw-cost proxy: a plushie hero's puppet has no more
  drawn canvas items than Banane's. Real GPU: `tools/benchmark.gd -- --hero=<id>`. 2026-11-18 (500 zombies, ~590
  shots, 400 bullets): Banane 160 draw calls, Pip 119, Böbö 103, BamBam 99, Robbar 102. Hero picker is in the fit
  check (M5-03).
- Gear (M4.5-01, spec 09): pieces are `GearDef` (`data/gear/<id>.tres`: slot, text, `source_kind` BUILDING /
  BOSS / ELITE + `source` = building id or boss file name, `drop_chance`, 3 `GearLevel`s with price, `amount`,
  `effect`; piece-wide numbers `seconds` / `every` / `radius` / `factor`). `GearRules.current()`
  (`data/gear/gear_rules.tres`: `pieces`, `workshop` id `sewing_workshop`, `slot_levels`, `stitch_caps`).
  Save state lives in `TownSave.gear` (`TownGear`: `patterns`, `stitches`, `worn` / `hidden` per player slot;
  JSON fields `patterns`, `gear`, `worn`, `hidden`, save v7) because `TownSave` is near gdlint's 30 public
  methods. Rules in `GearBook` (static: `step_of` → `Step`, `sew` (also stitches, puts a new piece on an empty
  slot), `wear_state` / `wear` (one copy per piece), `take_off`, `slot_open`, `stitch_cap` (0 while the Workshop
  is damaged), `worn_pieces`, `total_cost`). Town dev menu `GIVE_PATTERNS` / `SEW_ALL` / `MAX_STITCHES` /
  `CLEAR_GEAR`. Tests: `test_gear.gd`, `test_09_gear_dev_menu.gd`.
- Patterns (M4.5-02, spec 09 §4): building patterns come in `Town._give_patterns` (end of `settle`, waits for other
  banners; old saves catch up on arrival) via `GearBook.building_patterns_due` / `give_building_patterns`. Run:
  `run.patterns` (`RunPatterns`, `src/gear/`): `zombie_killed` (boss id = boss `.tres` file name, elites roll
  `rng` against `GearDef.drop_chance`), `drop(piece, at)`, `next_drop()`, `envelopes`, `found` (log
  `patterns_found`). `PatternEnvelope` frees itself on touch (tests count envelopes on `run.floor_items`). Found ids go
  into `RunHaul.patterns`, banked whole by `TownSave.bank`; owned ones are `TownPerks.patterns`. Off in the siege
  (`patterns.enabled`). Texts/numbers in `gear_rules.tres` ("Patterns"). Run dev menu `DevMenu.DROP_PATTERN`.
  `run.gd` is at 1000 lines (the limit, after M6-06): new run logic goes into helpers. Local "saved" flakes came from the
  M6 worktree testing at the same time (see "Parallel worktrees").
- Sewing Workshop (M4.5-03, spec 09 §5, AC-97): 7th `TownSpot` (`sewing_workshop`, top middle above the fort),
  `data/town/buildings/sewing_workshop.tres` (prices, `siege_health`, no turret/ring), look `WorkshopLook`.
  `TownSpot.needs_pattern`: unlocked once `gear.patterns` is non-empty; `is_hidden_in(save)` = nothing drawn and
  nothing blocks until its "New building!" played (`TownBuilding.waiting_for_reveal`, `hide_until_revealed`,
  `appear()` adds the building's own wall body; `_raise` and dev "Build all" call it too). Town walls and the
  siege use `layout.blocking_rects(save)` (skips hidden spots); `blocking_rects()` without a save lists all 7
  (layout tests). After a pattern banner `_give_patterns` schedules another settle so the Workshop's reveal
  follows it. Its thread path is drawn in the baked ground from the start. Tests: `test_09_sewing_workshop.gd`.
- Key rebinding (M6-03, spec 10 §5, AC-112): `KeyBindings` (`src/settings/key_bindings.gd`, static): `ACTIONS` (ids
  like `dash`, `card_1`, `reroll`), `action_name(id, player)` (player 1's card keys are the shared `pick_card_*` /
  `reroll_cards` ... actions), `bind` (returns the swapped id), `reset`, `key_text`, `fill(text)` replaces
  `{interact}`, `{tricks}` ... with the bound key. Keys are unique **per group** (play keys vs level-up card keys:
  S skips and walks down by default). Esc / F1 / F11 are fixed. Saved as `bindings: {"p1": {...}}` in
  settings.json (`GameSettings.to_dict` / `apply_dict`; `GameSettings.reset()` restores the shipped keys, read from
  `ProjectSettings` `input/<action>`). UI: `ControlsPage` (`settings.controls`: `keys[id]`, `listen`, `press_key`,
  `note`, `reset_button`). **Never write a key letter into a hint**: use `KeyBindings.fill("{interact}   ...")`
  (also in `.tres` texts) or `player.key_text(...)`; nodes that show a key outside a per-frame prompt join
  `KeyBindings.HINTS` and get `show_keys()`. GUT's `sender.key_down` sets only `keycode`: actions are bound by
  `physical_keycode`, so scenario tests send their own `InputEventKey` with both (`test_10_key_rebinding.gd`).
- Parallel worktrees (like the former `Game-m6`) share the same `user://` folder (same project name): two test runs at
  the same time overwrite each other's `test_save.json` etc. and save tests fail at random. Run local tests only
  while no other Godot is running (`tasklist | grep -i godot`); CI is unaffected.
- Music (M6-04, spec 10 §4.1, AC-108): tracks and stingers are `MusicTrack` .tres in `data/audio/music/` (bpm, one
  chord root per bar, `MusicLayer`s: instrument, 16-step pattern string, octave, volume, `level` 0/1/2), listed in
  `music_rules.tres` (`MusicRules`: crossfade, layer fade, run drums at 120 s / 150 zombies on screen, full at 300 s,
  `siege_level(wave)`). `MusicRender` renders note by note (notes wrap round, so loops are seamless); `MusicJob`
  renders on the `WorkerThreadPool`; `MusicPlayer` (a Node now) keeps the clips in a **static** cache (rendered once
  per game, every Main shares it), plays a `MusicDeck` per track (one player per layer, all started together) and
  crossfades (`deck`, `fading_out`, `deck.layer_volume(i)`). `intensity` / `play_stinger(id)` / `stingers_played`.
  Runs talk to it through `MusicPlayer.GROUP` via `RunMusic` (`run.music`: time + crowd, hero died, evolution, goal,
  endless track; the siege calls `music.follow_wave(index)`). Main plays `siege` and the siege won/lost stingers.
  Scenario tests wait for `MusicPlayer.is_ready(id)` (render takes a few seconds after the first boot).
  Unit test `test_music.gd` checks no track clips at full intensity (sum of layers × loudness < 1).
- Sound pass (M6-05, spec 10 §4.2, AC-109): play rules in `data/audio/sfx_rules.tres` (`SfxRules`: `voices` per
  sound, `default_voices`, `starts_per_frame` = 2 new starts of one sound per frame, `varied` sounds get wider pitch
  + up to `varied_volume_db` quieter, `pitch_overrides` keeps the XP chain clean). `Sfx` counts a voice busy from
  `play()` on (`_busy_until`, not only `player.playing`); `Sfx.last_pitch` for tests. `SfxBank.FELT_THUMP` (sound →
  gain) layers `felt_thump(t)` under the frequent sounds. Master bus has an `AudioEffectHardLimiter` (-0.5 dB,
  `default_bus_layout.tres`). Hero voice = `HeroStats.level_up_sound` (quack / squeak / grumble / trill / bark),
  played on `player.celebrated`. Tests: `test_audio.gd`, `test_10_sound_pass.gd`.
- Sewing table (M4.5-04, spec 09 §6, AC-98): `town.sewing` (`TownSewing`, `src/town/sewing/`) owns `table`
  (`SewingTable`: `tiles[id]` = `GearTile`, `slot_labels` / `slot_text(slot)`, `photo_frame`, `upgrade_button`,
  `focused_tile()`). **E at a built, undamaged Workshop opens the table** (`TownSewing.opens_table`, via
  `town.interact(building, by)`), so the Workshop's own upgrade is a button on the table (it closes the table so
  the build moment plays). Tile action rules are pure in `GearBook.action_for` / `can_act` / `act` (SEW, STITCH
  only on a worn piece, WEAR, TAKE_OFF, NONE); `GearBook.can_sew_any` drives the Workshop's tag (the
  `new_trick_tag` says "Can sew!" there, `TownBuilding.is_workshop()`). Texts and the sewing moment numbers are in
  `gear_rules.tres` ("Sewing table"); pieces have `GearDef.color` (calm) and `found_text` (boss/elite source).
  `GearTile` only draws: `SewingTable._show_tile` works out its action, label, note (`note_for`) and price.
  `GearPicture` is a placeholder felt shape per slot until M4.5-05 draws the real pieces. R = the opener's
  `reroll` action. Fit check: 30 screens. Tests: `test_sewing_table_rules.gd`, `test_09_sewing_table.gd`.
- Local only: `test_04_menu_look` "Esc opens the pause menu" fails when that file runs alone (also on `main`).
- Typecheck "resources still in use" traps (M4.5-04, CI `tools/check.sh` checks every script as the entry; locally
  run an `--import` first, results without it are unreliable): (1) a static function that calls static functions
  defined **further down** in the same file leaked `TownSave`/`RunHaul`/`TownGear` (`GearBook`): add new static
  helpers below the ones they call. (2) A `SewnButton` subclass holding both a `GearDef` and a `GearRules` leaks
  `FeltDraw`/`StyleBoxFelt` (also on `main`): `GearTile` is a pure view that gets its numbers and texts from
  `SewingTable`. Bisect with leave-one-out scratch scripts in `src/zz_tmp/` (delete them afterwards).
- Gear on the hero (M4.5-05, spec 09 §6-7, AC-100/100b): what a player wears is a `WornGear` (`WornGear.of(save,
  slot)`: `pieces`, `levels`, `hidden`, `shown()`, `has(id)`); `Player.gear` (set before adding the hero:
  `Town.spawn_player`, `Run.spawn_player` via `TownPerks.gear(index)`), `player.wear_gear(worn)` →
  `gear_changed`. **Gear effects (M4.5-06…08) read `player.gear.has(id)` / `level_of(piece)`, never the
  save** (hidden pieces still work). Looks: `GearLook.draw` (shapes + one detail per stitch level; also the
  sewing table's `GearPicture`). Puppets own `gear_view` (`HeroGear`: shown pieces baked once into one
  SubViewport, one sprite per slot with the hero outline shader, `sprite(slot)`, `flash()`); plushie heroes
  hang the sprites on `body`, Banane the cap on his head joint and the rest on `_root`. Anchors =
  `HeroStats.head_anchor` / `body_anchor` / `charm_anchor` (pixels from the feet, facing right) +
  `gear_scale`. `town.refresh()` → `sewing.dress_players()` re-dresses every hero (rebakes only if the
  look changed). Photos: `HeroPhoto.wear(worn)` (drawn, not baked). Hiding: `TownSewing.set_hidden(slot, on,
  by)` (-1 = all), `TownGear.slot_hidden`; eye toggles `GearEyeToggle` on the table (`eye_toggles`,
  `hide_all_toggle`) and the picker (`gear_row`, only while something is worn); key `hide_gear` (H, in
  `KeyBindings.ACTIONS`). Effect moments on a piece (spinning key ...) should use `gear_view.sprite(slot)`
  and do nothing when it is null (hidden). The end screen has no hero photo: gear shows there as tags
  (M4.5-09). Tests: `test_worn_gear.gd`, `test_09_gear_on_hero.gd`.
- Never `git checkout <file>` to undo a deliberate test break while the branch has uncommitted work in that
  file: break and restore with the Edit tool.
- Typecheck trap (M4.5-05): a unit test calling `HeroRoster.current()` next to a preloaded `gear_rules.tres`
  leaked resources at exit; tests preload `res://data/heroes/hero_roster.tres` as a const instead.
- Gear effects (M4.5-06, spec 09 §3, AC-99): `GearEffects` (`src/gear/effects/`) has the piece ids and
  `apply(player)` (called in `Player._ready` for armed heroes, before weapons): sets plain numbers
  (`player.extra_pierce`) and adds one node per lasting effect, named after its class (`LookoutCap`,
  `PropellerCap`; M4.5-07/08 add theirs here). Numbers via `player.gear.amount_of(id)` (per stitch level) and
  `gear.find_piece(id)` (piece-wide numbers; new `GearDef.damage` / `sound`). Pins: `WeaponStats.pins`
  (sniper, volley, shotgun) + `Weapon._with_bonuses`; a pierce below 0 stays unlimited. Pickup range is read
  through `GearEffects.pickup_reach(player)` (Lookout Cap's `pickup_factor`), dash length through
  `GearEffects.dash_distance(player)`; `Player.dash_landed(at)` fires when a dash ends. Tally row
  `WeaponTally.PROPELLER_CAP`. `Player` is at gdlint's 30 public methods: new hero helpers go into
  `GearEffects` or their own node. Test: `test_09_head_pieces.gd` (other heroes per level via
  `_hero_wearing`).
- Body pieces (M4.5-07, spec 09 §3, AC-99): `Raincoat` (dash start → landing makes a `RaincoatPuddle`: capsule
  `GearDef.radius` wide, slows zombies with `zombie.slow`, pops enemy bullets via
  `ProjectileManager.pop_enemy_bullets_where(callable)`), `PatchVest` (`Player.patch_up` is checked first in
  `take_hit`, before the shield; `patch_blocked` signal), `PicnicApron` (`ApronSnack` on the floor, eaten only by a
  hurt hero, max `MAX_SNACKS`). New `GearDef.effect_color` (puddle, patch, napkin). The patch is part of the vest
  look: `GearLook.draw(..., patch)`; `HeroGear` bakes a spare patch-less vest cell and `show_patch(on)` swaps the
  sprite region (a separate patch node broke AC-104's 3-draw limit). `FeltDraw.dashes` can loop forever on some
  dash/gap lengths (float `fmod`; a test run grew to 19 GB): use `GearLook.stitches` on an open path instead.
  Test: `test_09_body_pieces.gd`.
- Charm pieces (M4.5-08, spec 09 §3, AC-99): `JingleBell` counts `EnemyManager.killed_by(weapon, zombie)` (only
  hero weapons, emitted in `damage`) for its own hero, rings via `damage_from(WeaponTally.JINGLE_BELL, ...)`.
  Lucky Button: `GearEffects.golden_odds(tree)` (luckiest living wearer) rolled in `PickupManager.drop` with
  `pickups.golden_rng` (seeded by `RunPatterns.seed_dice`, since `run.gd` is at exactly 1000 lines);
  `XpButton.make_golden(factor)` / `golden`, part `XpButtonLook.GOLDEN_KEY`. `WindUpKey` adds to
  `player.attack_speed` while wound up and spins `gear_view.sprite(CHARM)`. Test: `test_09_charm_pieces.gd`.
  **Never use `gh pr merge --auto`**: `main` has no branch protection, so it merges at once, even with tests
  still pending (#313 went in that way, 2026-11-20). Wait for all checks green, then `gh pr merge --squash`.
- Evolution moment (M6-06, spec 10 §3, §10, AC-106): numbers in `data/ui/evolution_moment.tres`
  (`EvolutionMomentRules`). Gift screen: after the lid pops an evolution plays `gift_screen.reveal`
  (`EvolutionReveal`: `stage()`, `is_done()`, `shows_stamp()`, `finish()`) while `gift_screen.revealing`, holds
  `REVEAL_HOLD` s, then the cards (an evolution now takes ~2.9 s to its cards: tests wait ≥ 4 s); any key jumps
  to the reveal's end, a second key to the cards. `GiftContents.evolution_partner_icon`. Run: `run.evolution_moment`
  (`EvolutionMoment`, waits until the run is unfrozen and the gift screen closed; `moments`, `slowed`,
  `has_played(id)`): `Engine.time_scale` slow motion (skipped with Reduced motion), `EvolutionPulse` ring on the
  hero (`WorldLayers.OWN_SHOTS`), `WeaponStats.sting` (`sting_*` in `SfxBank`), `weapon.boost_next_attack(1.5)` →
  `Projectile.dress` draws the shot big and tweens it back (`big_attack_seconds`, so Sewing Storm's lasting orbit
  isn't stuck big). Run dev menu `DevMenu.EVOLVE_NOW`. Fit check: 31 screens ("evolution reveal").
  Tests: `test_10_evolution_moment.gd`.
- Peel trail + stitch-up (M6-07, spec 10 §3, AC-105): numbers are sub-resources on the evolved weapon
  (`WeaponStats.peel_trail` = `PeelTrail`, `WeaponStats.stitch_up` = `StitchUp`). Banana Split: on the way back
  each `SplitPeelProjectile` (`dropped_peel`) calls `BananaSplit.drop_peel(at)` on its first hit; floor peels are
  pooled `FloorPeelProjectile` shots (part `SPLIT_PEEL`, `age`, `used`, `slipped`, `is_armed()`), so
  `fired_by(split)` now also returns them: filter by class. `split.floor_peels()`. Sewing Storm: `storm.needles()`;
  a flung `StormNeedleProjectile` records `stitched` zombies and a thread (`is_sewing()`, `thread_points()`,
  `snaps`); `storm.threads` (`StitchThreads`, one `draw_multiline` for all needles, `segments`).
  Tests: `test_10_split_and_storm.gd`.
- Chain pins + tangle (M6-08, spec 10 §3, AC-105): `WeaponStats.chain_pins` (`ChainPins`) and `yarn_tangle`
  (`YarnTangle`). Pincushion Volley now has its own behaviour `PincushionVolley` (extends `SewingPinSniper`,
  `_pin_kind()`) firing `ChainPinProjectile`s (`generation`, `chains_left`, `launch_chain`); `PinProjectile` keeps
  its own `reach` / `damage` per shot. Yarn Bomb: `StickyYarnProjectile.stage` (WEB → KNOT → POP), `tangle_in()`,
  `popped`; the web ends at the pop. Tests: `test_10_chain_pins_and_tangle.gd`. Kill counts in tests: connect
  `enemies.zombie_killed` (killed zombies are freed a few frames later; a typed arg holding a freed one errors).
  Right after an evolution the slow motion stretches game time: wait for a condition, not a fixed frame count.
- Co-op gear, Gear tab, tags, log (M4.5-09, spec 09 §8, §10, AC-101/103): co-op rules were already in `GearBook`
  (`Wear.TAKEN`, table `note_for` = "Player N wears it"); each player opens the table with their own
  `interact` (`table.opener`). Scrapbook page `ScrapbookRules.GEAR` (built by `ScrapbookBook.gear_page()`, `all_pages()` = rules pages + Gear: GearRules inside `ScrapbookRules` leaked "resources still in use" via TownSave; `ScrapbookEntry.gear` is typed `Resource` for the same reason): seen = pattern found
  (`ScrapbookPage.is_seen`, not `TownSave.seen`; dev "Fill scrapbook" skips it), `ScrapbookEntry.Picture.GEAR`
  drawn by `GearLook`, note = `GearRules.source_text(piece, building name)` (shown on unseen tiles too).
  `RunResult.gear` ({player, slot, id, name, level}; filled by `RunPatterns.fill_result` since `run.gd` is at 1000
  lines) → end screen `WeaponColumn.gear_tags` ("Lookout Cap Lv 2", sticker teal) and log `gear` =
  `RunResult.gear_log()` (one dict per player, slot → "id:level", runs and sieges). `run_scenario.CONTROLS` has
  `reroll` (the table reads `p2_reroll`). Test: `test_09_coop_gear.gd`.
- Gear readability + cost (M4.5-10, spec 09 §12, AC-104): `test_09_gear_readability.gd` checks every piece colour
  (`GearLook.colors` per stitch level), effect colours (`GearDef.color` for rings/key, `effect_color` for puddle,
  patch, napkin, `ApronSnack.COOKIE`/`CRUMBS`, `XpButtonLook.GOLDEN_COLOR` above `UiColors.DANGER_HUE_LOW`) and a
  live sweep of the gear nodes only (`src/gear/` children + `gear_view`; Banane's own puppet has danger oranges and
  is swept in test_08). `color_sweep.gd` now reads into `GearDef`s. A new gear effect colour goes into
  `_effect_colors()`. Price rule (each step < the Workshop level after the one that opens it) in `test_gear.gd`.
  Benchmark `tools/benchmark.gd -- --gear` (Lv 3 Lookout Cap, Picnic Apron, Jingle Bell): 2026-11-20 160 → 165
  draw calls (3 piece sprites + Lookout ring + snacks), fps within noise (~9-10 both).
- Snow Day + Bear Slam (M6-09, spec 10 §3, AC-105/107): evolutions 5 and 6 (`snow_day.tres`, `bear_slam.tres`,
  icons `snow_day` / `slam`, sounds `snow_day` / `bear_slam` / `snowman_burst` / `slam` + stings). Numbers in
  `WeaponStats.snowmen` (`Snowmen`) and `ground_slam` (`GroundSlam`). `SnowDay.build_snowman(at)` / `snowmen()`;
  `SnowmanProjectile` (pooled, `lure`, `burst`, `froze`). Lures: `EnemyManager.lures` (`ZombieLure`: zombies
  within `reach` walk to it instead of a hero; bosses and siege goals ignore/win over it). Per-zombie freeze:
  `zombie.freeze_for(seconds)` / `ice_left` (counts as stunned, ice tint, no touch damage). `BearSlam.swats` /
  `slams`, ring = `SlamRingProjectile` (hits at launch). Every evolution needs a `ShotLook` (`test_evolved_looks`):
  Bear Slam's paw calls `dress`; Snow Day's ball only takes the look's part size in `_place` (the ring stays). Recipes of heroes not unlocked yet stay
  off the Recipes page: `TownPerks.locked_hero_weapons` → `pause_menu.set_recipes(pool, hidden)`.
  Snow Day and its snowball must not reference each other (`SnowDay` ↔ `SnowDayProjectile` leaked
  368 resources in the typecheck once the pool loaded it): the shared logic lives in static
  `SnowmanProjectile.standing` / `build_for`. Check a new evolution with a scratch script that preloads
  `upgrade_pool.tres` (`--check-only`), not just the new script.
  Tests: `test_10_snow_day_and_bear_slam.gd`. Perl one-liners with non-ASCII text ("Böbö") wrote Latin-1: use
  ASCII in perl replacements or the Edit tool.
- Low-health warning (M6-12, spec 10 §7, AC-115): every armed hero gets a `LowHealthWarning` node
  (`LowHealthWarning.of(player)`; numbers in `data/ui/low_health.tres`: threshold 0.25, beat, pulse). Below the
  line (and not fallen) it plays `heartbeat` (`SfxBank`) every `beat_seconds`, first beat at once; `pulse()`,
  `heart_scale()`, `heart_color(base)` (lighter rose, never red). The HUD's `SpareHeartPatch` now also shows while
  low (`shows_low_health()`, `pulse_scale()`), each hero's small bar draws the heart too (`Overlay`
  `shows_low_heart()`). No red screen edge. Tests: `test_low_health.gd`, `test_10_low_health.gd`.
- First-time hints (M6-10, spec 10 §6, §9, AC-113/114): texts in `data/ui/hints.tres` (`HintRules`: `HintDef` id,
  text with `{key_id}` tokens (neighbouring tokens share one key tag: "WASD"), `place` TOP/BOTTOM, `margin`;
  `show_seconds`, `basics`). Rules in `HintBook` (static: `is_due`, `mark_done`, `timed_out` = once more next
  screen, then seen; `forget`). Save v8 `TownSave.hints_seen` / `hints_once` (older saves with runs or buildings
  get `basics` marked seen). `HintBoard` (CanvasLayer 25, one `HintNote` at a time, flips edge if a hero is
  under it, `note_rect()` / `hero_rects()`, never re-shows an id on the same screen) → `RunHints` (attached by
  `Main.start_run` via `RunHints.attach(run, town)`, found with `RunHints.of(run)`; polls the run, never called by
  it; new notes wait while the run is frozen, the level-up note pushes an older note aside). Log field `hints`
  (`RunResult.hints`, set in `Main.show_end`). "Show hints again" → `Main.forget_hints` (HINT_KEEPERS group).
  Town dev menu `RESET_HINTS`. Fit check 35 screens. Wide tilted pieces fail the fit check's "sticks out of its
  box": notes tilt less the wider they are (`tilt_width`). Runs without Main (unit-ish scenario setups) have no
  hints. Tests: `test_hints.gd`, `test_10_hints.gd`.
- Town hints (M6-11, spec 10 §6, AC-113): `TownHints` (extends `HintBoard`, attached by `Main.show_town` via
  `TownHints.attach(town, save)`, `TownHints.of(town)`): town, can_build, tricks, siege_warning, wardrobe, sewing.
  Notes wait while a banner shows or the town settles, and hide (clock stopped) while a menu / tricks panel /
  sewing table / hero picker is open. The `siege` hint lives in `RunHints._watch_siege` (Main attaches RunHints to
  the siege too; done at wave 2; siege log has `hints`). The tricks panel keeps its own in-panel first-time line.
  `HintBoard.show_now(id)` shows a note at once (fit check "town (hint note)", 36 screens). Test:
  `test_10_town_hints.gd`.
- MVP check (M6-13, spec 10 §11-12, AC-116): `tests/unit/test_mvp_content.gd` (≥ 3 heroes, ≥ 10 weapons, ≥ 3
  evolutions with both halves on the cards, Bedroom + King, ≥ 6 buildings with 3 levels, ≥ 8 gear pieces, siege
  waves + a boss). `test_10_m6_readability.gd` sweeps every evolved weapon's behaviour sub-resources + the
  evolution moment (no danger colour, quieter than the zombie ink on every floor incl. dusk), the low-health rose
  at every pulse, and a live run with all 6 evolutions, a hint note and low health. Benchmark
  `tools/benchmark.gd -- --evolutions` (all evolved weapons; hints off; also prints `worst_frame_ms`).
  2026-11-21 on the PO's PC (other Godot running, fps noisy): pre-M6 main with its 4 evolutions 275 draw calls,
  now with 6: 286-287 (+12, AC ✅); plain run 160 both. Worst frame ~230 ms in Claude's sessions (~6 fps on this
  machine for every build): the 16 ms rule is judged by the PO's own play / 10-minute run (P-38 … P-41).
- Playtest fixes (2026-11-21): merge PRs with `gh pr merge <n> --squash` only (adding `--delete-branch`
  was blocked by the permission check). `Zombie.stun` ignores bosses mid-pattern / in `stun_guard_left`:
  tests that stun a boss twice reset `stun_guard_left`. Music "silence" = `play_track(MusicPlayer.SILENCE)`;
  `audible_decks()` for tests. A headless run with Stuffing Cloud levels up on its kills: disable
  `run.pickups` processing in probes. Look checks of a whole run: scratch `extends SceneTree` that sets
  `SaveStore.path` / `GameSettings.path` first (like `tools/benchmark.gd`) so the real save stays untouched.
- XP buttons vs floor (#323): rug buttons are flat (no ink), cross-stitched, in their own calm
  `palette.rug_buttons`; XP buttons have a white rim shine (`XpButtonLook.SHINE_*`). `test_bedroom_look`
  fails if any board/rug colour comes within `XP_LOOKALIKE_GAP` (RGB) of an XP colour; the crayon corner
  is left out on purpose (long crayon shapes).
