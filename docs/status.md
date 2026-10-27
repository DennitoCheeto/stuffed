# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-27 (spec 06 building tricks drafted)_

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
| M3 Town | ✅ accepted 2026-10-24: spec 03 approved (PR #91); issues #92–#103; M3-01 save system (PR #105), M3-02 town + flow (PR #106), M3-03 materials (PR #107), M3-04 Way Home portal (PR #109), M3-05 rebuilding (PR #110), M3-06 Toy Box Armory (PR #114), M3-07 Lucky Jar + Watchtower + Snack Bar (PR #115), M3-08 Party Shop (PR #116), M3-09 rescue in the run (PR #117), M3-10 Plush Hospital + plushies in town (PR #118), M3-11 Scrapbook (PR #119), M3-12 co-op in town + dev menu + sounds (PR #120) |

## Next step

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
  **Spec 06 Building tricks (skill tree) drafted** (`docs/specs/06-building-tricks.md`, AC-66 … AC-73,
  P-26 … P-28, milestone M3.7). PO picks 2026-10-27: each building = a branch of 3 tricks, mostly new mechanics,
  small first version (18). Spec PR open: the PO approves by merging, then create milestone M3.7 + 10 issues.
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
- No Python on the dev PC: gdlint/gdformat run only in CI. Keep lines ≤ 100 chars (tabs count as 4) and gdformat
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
  at exit once (PR #29). The CI test job now times out after 20 minutes (raised from 12 on 2026-10-24: 645 tests take ~9 min + setup).
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
- Local only: `test_03_town_flow` "Esc in town" fails when run alone on the dev PC (passes in the full run and CI).
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
