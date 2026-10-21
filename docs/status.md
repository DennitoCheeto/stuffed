# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-21 (M2-01 … M2-06 merged)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md` |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | ✅ done (PR #1) |
| M1 Core run | ✅ accepted 2026-10-21 (PRs #17–#29; playtest P-1 … P-6 passed, 144 fps on the PO's PC) |
| M2 Build variety | 🔨 spec 02 approved; issues #32–#46 (milestone "M2 — Build variety"); M2-01…M2-06 merged (PRs #47–#49, #51–#53) |

## Next step

- Next: M2-07 (#38, spitters + enemy bullets, AC-13), then the rest of M2 in order (spec 02 §18 list).

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
- The Linux CI test job can hang at exit after all tests passed (M2-04: 12-min timeout). Re-run the failed job
  once (`gh run rerun <run> --failed`); if it hangs again, look for a real cause.
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
- Scenario tests write the run log to `user://test_run_log.jsonl`, never the real `run_log.jsonl`.
- `docs/` has a `.gdignore`; shell scripts need the executable bit in git (`git update-index --chmod=+x`).
- Optional later: `@claude` GitHub workflow (as in Tastey) needs the `CLAUDE_CODE_OAUTH_TOKEN` repo secret.
