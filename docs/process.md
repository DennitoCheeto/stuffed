# How the Stuffed factory works

This is the same workflow ("assembly line") as the Tastey and Days Until factories, adapted to a PC game.

```
Vision ──> Spec ──> Issues ──> Branch + Code + Tests ──> Pull Request ──> CI checks ──> Merge ──> Milestone acceptance
 (you)     (both)   (Claude)        (Claude)              (Claude)         (automatic)  (Claude)        (you)
```

## Stations

| # | Station | Who | Output |
|---|---------|-----|--------|
| 1 | **Vision** | Product owner | `docs/specs/00-product-vision.md` |
| 2 | **Feature spec** | Claude drafts, product owner approves | `docs/specs/NN-feature-name.md` with acceptance criteria |
| 3 | **Issues** | Claude | Small GitHub issues, each doable in one PR |
| 4 | **Implementation** | Claude | Branch per issue, code + tests |
| 5 | **Quality gate** | GitHub Actions | Lint, format, import (static typing), unit tests, **scenario tests** and a Windows build must pass |
| 6 | **Merge** | Claude | Change lands on `main` as soon as CI is green |
| 7 | **Milestone acceptance** | Product owner | At the end of a milestone: play the build, accept or request changes |

The product owner works only at the ends of the line: **specs in, milestone acceptance out.**
Everything in between is checked by automated tests, not by manual review.
The product owner can still look at or comment on any PR at any time.

**Milestone acceptance is a playtest, not a checklist.** Every acceptance criterion is already proven by a
scenario test. What tests can't prove is whether it's **fun**: how it feels, whether it's readable, whether
you want "one more run". So Claude gives a short tour (what's new, what to try) plus a few feel questions,
and the product owner plays freely and reports anything odd or boring.

## Playing a build

- **One pull request:** open the PR on GitHub → the bot comment "🎮 Windows build" → download the zip →
  unzip → run `Stuffed.exe`.
- **Latest `main` (milestone acceptance):** GitHub repo → **Releases** → **latest** → download
  `Stuffed-windows.zip`.
- Windows may show "Windows protected your PC" because the exe isn't signed: **More info → Run anyway**.

## Opening the project yourself (optional)

Run `C:\Users\denhu\Tools\Godot\Godot_v4.7.2-stable_win64.exe`, choose **Import**, and pick the
`project.godot` file in this folder. Press **F5** to play.

## Milestones

See vision §10. M0 is the factory setup.
