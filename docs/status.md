# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-21 (M0 factory setup in progress)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md` |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | 🔧 in progress |
| M1 Core run | ⏳ next: spec 01 to be drafted |

## Next step

- Finish M0: Godot project, GUT tests, CI (lint, import, tests, Windows export), PR build comments, "latest" release.
- Then draft `docs/specs/01-core-run.md` for M1 (Banane's first run) for product owner approval.

## Gotchas

- Local Godot lives outside the repo: `C:\Users\denhu\Tools\Godot\` (use the `_console.exe` for headless runs).
- `docs/` has a `.gdignore` so Godot doesn't import the HTML concept pages.
