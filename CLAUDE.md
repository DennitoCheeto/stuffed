# CLAUDE.md — Rules of the Stuffed Software Factory

Stuffed (working title) is a PC bullet-heaven roguelite: stuffed animals vs. zombie plushies, with a town to build
and defend. The product source of truth is [docs/specs/00-product-vision.md](docs/specs/00-product-vision.md).
The workflow is described in [docs/process.md](docs/process.md).
**Current status, next step and solved gotchas** (update at the end of every work block):
@docs/status.md

## Roles

- **Product owner (human):** decides *what* gets built. Works only at the two ends of the line:
  approves **specs** and does the **milestone acceptance** by playing the game on their PC.
  A PC gamer, not an experienced developer: explain decisions in plain language, avoid jargon or explain it.
- **Claude (factory):** turns approved specs into issues, code, tests and PRs, and **merges ticket PRs
  itself once CI is green**.

### Merge rules

| PR type | Who merges |
|---------|------------|
| Spec PRs (`docs/specs/…`) and anything that changes a product decision | Product owner only |
| Implementation / chore PRs for an approved spec | Claude, as soon as CI is green |

Never merge on red or pending CI. Tell the product owner in the chat what was merged.

## Communication

- Talk to the product owner in **English** (their choice for this project).
- End **every** reply with a clearly marked section **"👉 Your task now"**: concrete numbered steps
  (exact clicks, expected result, what to report back). If nothing is needed, say so explicitly.
- Code, comments, commit messages, issues, PRs and docs in the repo are in **English**.

## Tech stack

- **Godot 4.7.2** (standard build, no .NET), **GDScript with static typing everywhere**
  (untyped declarations are errors, see `project.godot`).
- Tests: **GUT 9.7.1** (`addons/gut/`), run headless.
- Target: Windows desktop. The exe is built in CI from Linux.
- Local Godot: `C:\Users\denhu\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe` (not in the repo).
- No purchased assets. Art is drawn in code (felt style, see vision §8.1); sounds are generated or CC0.

## Project layout

```
src/            game code and scenes (one folder per feature: src/main, src/player, ...)
tests/unit/     unit tests for pure logic (test_*.gd)
tests/scenarios/ scenario tests: real scenes, simulated input and time (test_NN_*.gd)
addons/gut/     vendored test framework, never edit
docs/           vision, specs, research, art concepts (ignored by Godot via .gdignore)
tools/          helper scripts (run tests, export)
```

## Hard rules

1. **Spec first.** No feature code without an approved spec in `docs/specs/` and a GitHub issue.
2. **Never commit directly to `main`.** One branch per issue: `feat/<issue-nr>-short-name`, `fix/...`, `chore/...`.
3. **Small PRs.** One issue = one PR. Reference the issue (`Closes #12`).
4. **Tests are part of done.** Pure logic (damage, XP curve, spawning rules, costs) needs unit tests.
   Every **player-visible acceptance criterion** of a spec gets a **scenario test** in `tests/scenarios/`
   (real scene, simulated input/frames, see `tests/scenarios/README.md`).
   Prove new tests can fail: break the code on purpose once and check the test turns red.
5. **CI must be green** (lint, format, import with warnings-as-errors, tests, Windows export).
6. **Product test.** After a session the player should be able to say: *"I had a cool run, my town got
   visibly better, and I already know what I want to build next."* Features that serve none of this wait.
7. **Respect the "Explicitly NOT MVP" list** in the vision (§9).
8. **Balance lives in data**, not in code: numbers go into `.tres` resources or data files so tuning takes minutes.
9. **Readability first** (vision §6): enemy danger always has the strongest contrast; the player's own effects are quieter.
10. **Never lose progress.** Anything that saves must be covered by a test that saves, reloads and compares.
11. **Code ready for local co-op.** Never assume a single player: input goes through a player index /
    device, and systems look players up instead of using a global "the player".

## Builds for the product owner

- Every PR gets a comment with a link to a downloadable Windows build (`.github/workflows/ci.yml`).
- Every merge to `main` updates the GitHub pre-release **"latest"** with `Stuffed-windows.zip`:
  that's what the product owner plays for milestone acceptance.

## Definition of Done

- Acceptance criteria of the issue are met
- Tests added/updated and passing
- Lint, format and import checks pass
- PR description explains what changed and how to try it
- CI is green (then Claude merges; see merge rules)

A **milestone** is done when all its tickets are merged and the product owner has accepted it by playing it.
