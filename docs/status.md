# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-21 (spec 01 approved, M1 tickets #3–#15 created)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md` |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | ✅ done (PR #1): Godot 4.7.2, GUT, CI (lint, typecheck, tests, Windows export), PR build comments, "latest" release |
| M1 Core run | ⏳ spec approved (PR #2), 13 tickets #3–#15 in GitHub milestone "M1 — Core run", none started |

## Next step

- Start ticket M1-01 (#3): arena, camera, Banane movement + dash, title screen. Branch `feat/3-movement-dash`.
- Then work through #4–#15 in order (spec 01 §15). Ticket PRs are merged by Claude once CI is green.

## Gotchas

- Local Godot lives outside the repo: `C:\Users\denhu\Tools\Godot\` (use the `_console.exe` for headless runs).
- No Python on the dev PC: gdlint/gdformat run only in CI. Keep GDScript in gdformat style (tabs, two blank
  lines between functions).
- `docs/` has a `.gdignore` so Godot doesn't import the HTML concept pages.
- Smoke-test an exported exe without a screen: `Stuffed.exe --write-movie out.png --fixed-fps 10 --quit-after 15`
  writes PNG frames you can look at.
- Shell scripts need the executable bit in git (`git update-index --chmod=+x`), Windows doesn't set it.
- Optional later: `@claude` GitHub workflow (as in Tastey) needs the `CLAUDE_CODE_OAUTH_TOKEN` repo secret.
