# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-23 (M3-04 Way Home portal)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md` |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | ✅ done (PR #1) |
| M1 Core run | ✅ accepted 2026-10-21 (PRs #17–#29; playtest P-1 … P-6 passed, 144 fps on the PO's PC) |
| M2 Build variety | ✅ built (not yet accepted): all 19 tickets merged (PRs #47–#49, #51–#55, #57, #58, #60, #61, #63, #67, #69, #77, #78, #80, #81); + spec 02b floor pickups approved (#83): M2-20 (PR #88), M2-21 (PR #89) and M2-22 (PR #90) merged; PO playtest postponed, played with M3 |
| M3 Town | 🔨 spec 03 approved (PR #91); issues #92–#103; M3-01 save system (PR #105), M3-02 town + flow (PR #106), M3-03 materials (PR #107), M3-04 Way Home portal (PR #109) |

## Next step

- M2 is fully built (spec 02 + §20 fixes + spec 02b floor pickups, PRs up to #90). The PO **postponed the M2
  acceptance playtest** (2026-10-22): P-1 … P-11 get played later, together with M3.
- **Spec 03 (M3 Town) approved** (PR #91, `docs/specs/03-town.md`). Issues **#92–#103** (M3-01 … M3-12, milestone
  "M3 — Town"). M3-01 #92 save system (PR #105) and M3-02 #93 town + title → town → run → "Brought home" flow (PR #106) done.
  M3-03 #94 materials in the run (PR #107) and M3-04 #95 Way Home portal done.
  Next: **M3-05** #96 ruins and rebuilding (spec 03 §5–6).
- M3 ACs are AC-37 … AC-48, playtest P-12 … P-17. **M3-10** (#101) needs photos + names of the girlfriend's
  plushies from the PO: ask when starting it (M3-09 uses placeholder looks).
- PO ideas for later: a skill / progress tree (own spec, after M3).

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
  12-min job timeout: then look for a real cause. Timing asserts in scenarios: allow one frame (PR #64).
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
  at exit once (PR #29). The CI test job now times out after 12 minutes.
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
  per building: rect, `needs_rebuilds`, `needs_rescue`; ruins are `TownRuin` in `town.ruins`). Flow in Main: title
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
