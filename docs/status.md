# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-21 (M0 done with PR #1, next: spec 01)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md` |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | ✅ done (PR #1): Godot 4.7.2, GUT, CI (lint, typecheck, tests, Windows export), PR build comments, "latest" release |
| M1 Core run | ⏳ next: draft `docs/specs/01-core-run.md` for product owner approval |

## Next step

- Draft spec 01 (Banane's first run: movement + dash, Peel Boomerang + one aimed weapon, shamblers + runners,
  XP buttons, level-up pick 1 of 3, death screen, basic game feel + sounds, dev menu, balance in data files,
  code ready for a second player). Spec PR is merged by the product owner.

## Gotchas

- Local Godot lives outside the repo: `C:\Users\denhu\Tools\Godot\` (use the `_console.exe` for headless runs).
- No Python on the dev PC: gdlint/gdformat run only in CI. Keep GDScript in gdformat style (tabs, two blank
  lines between functions).
- `docs/` has a `.gdignore` so Godot doesn't import the HTML concept pages.
- Smoke-test an exported exe without a screen: `Stuffed.exe --write-movie out.png --fixed-fps 10 --quit-after 15`
  writes PNG frames you can look at.
- Shell scripts need the executable bit in git (`git update-index --chmod=+x`), Windows doesn't set it.
- Optional later: `@claude` GitHub workflow (as in Tastey) needs the `CLAUDE_CODE_OAUTH_TOKEN` repo secret.
