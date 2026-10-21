# Status & handoff

> Read this at the start of every session. Update it at the end of every work block
> (what changed, what's next). Keep it short; details live in specs, issues and PRs.

_Last updated: 2026-10-21 (spec 01 drafted, waiting for product owner approval)_

## Where we are

| Milestone | State |
|-----------|-------|
| Research | ✅ `docs/research/01-bullet-heaven-market-research.md` |
| Vision | ✅ approved 2026-10-21 (`docs/specs/00-product-vision.md`) |
| Art direction | ✅ felt style "B — Soft", puppet animation (`docs/art/`) |
| M0 Factory setup | ✅ done (PR #1): Godot 4.7.2, GUT, CI (lint, typecheck, tests, Windows export), PR build comments, "latest" release |
| M1 Core run | ⏳ spec `docs/specs/01-core-run.md` drafted (spec PR), waiting for product owner approval |

## Next step

- Product owner reviews the spec 01 PR, answers its 3 open questions (§16) and merges it.
- Then: fold the answers into the spec, create the 12 tickets from spec §15 as GitHub issues, start with ticket 1.

## Gotchas

- Local Godot lives outside the repo: `C:\Users\denhu\Tools\Godot\` (use the `_console.exe` for headless runs).
- No Python on the dev PC: gdlint/gdformat run only in CI. Keep GDScript in gdformat style (tabs, two blank
  lines between functions).
- `docs/` has a `.gdignore` so Godot doesn't import the HTML concept pages.
- Smoke-test an exported exe without a screen: `Stuffed.exe --write-movie out.png --fixed-fps 10 --quit-after 15`
  writes PNG frames you can look at.
- Shell scripts need the executable bit in git (`git update-index --chmod=+x`), Windows doesn't set it.
- Optional later: `@claude` GitHub workflow (as in Tastey) needs the `CLAUDE_CODE_OAUTH_TOKEN` repo secret.
