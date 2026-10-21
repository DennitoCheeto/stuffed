# 00 — Product vision: Stuffed (working title)

Status: **APPROVED** by the product owner, 2026-10-21.
Based on: [`docs/research/01-bullet-heaven-market-research.md`](../research/01-bullet-heaven-market-research.md)

## 1. One sentence

A PC bullet-heaven roguelite where a band of brave stuffed animals goes on short, chaotic expeditions into a world overrun by zombie plushies, brings home buttons and stuffing to grow their pillow-fort town, and then defends that town from the horde in night-time waves.

## 2. The problem

Bullet heavens (Vampire Survivors, Brotato, Megabonk) are extremely fun for 10–20 hours, and then players drop them. The reasons come up again and again in reviews: it gets repetitive, meta-progression is a grind of +5% upgrades, and the start is slow. The one hit with a town between runs (Ball x Pit, 2M+ sold) proves people want a base to come back to, but its own players call the town building "dull menu busywork".

**Our answer:** the town is not a menu, it's a second battlefield. Everything you build in the town you also fight with.

## 3. Who it is for

- PC players who like Vampire Survivors / Brotato / Ball x Pit and want a reason to keep coming back.
- Players with 15–30 minutes: one expedition + one town visit is a complete session.
- First audience: the product owner and their girlfriend (whose stuffed animals are the heroes).

## 4. Product test

After any session, the player should be able to say:

> "I had a cool run, my town got visibly better, and I already know what I want to build next."

If a feature doesn't support one of those three, it doesn't go in the MVP.

## 5. Core concepts

### The loop

```
        ┌────────────────────────────────────────────────┐
        ▼                                                │
  EXPEDITION (8–12 min)  ──>  TOWN (1–3 min)  ──>  NIGHT SIEGE (2–4 min)
  bullet heaven run           build / upgrade       zombie plushies attack
  collect buttons,            unlock heroes,        your town; you fight
  stuffing, blueprints        weapons, areas        alongside your buildings
```

- **Expedition:** a classic bullet-heaven run in a hand-built area (bedroom, playground, attic, ...). Level up → pick 1 of 3 upgrades. Mini-boss in the middle, boss at the end. Dying ends the run, but you **keep part of what you collected**: no run is wasted.
- **Town:** the pillow fort / toy box town. Spend materials on buildings. Each building does two things: an **effect in the town** (unlock a hero, a weapon, production) and a **role in the siege** (wall, turret, healing spot, trap).
- **Night siege (invasion):** a short wave defense in the town itself, with the same controls as an expedition. Your buildings shoot, block and heal. Surviving gives a bonus; losing damages buildings (repairable, never deleted).
  - **Rhythm:** the invasion doesn't come after every expedition. The town shows a warning like "The horde arrives in 2 nights", and after 2–3 expeditions it hits. That gives the player a goal ("build walls before the invasion"), creates tension, and keeps the siege special instead of repetitive. Each invasion is a bit bigger than the last.
- **Equipment, sewn onto the plushie:** stuffed animals don't wear armour, they get things **sewn on**. Three slots: **Head** (hats, bows, ears), **Body** (scarves, raincoats, patches) and **Charm** (a button, a bell, a key ring).
  - **Visible:** every piece shows on the hero in-game. Banane in a rain hat looks different from Banane with a bell.
  - **Changes how you play, not just numbers.** Each piece has one clear effect, e.g. *Raincoat:* your dash leaves a puddle that slows zombies; *Jingle Bell:* every 10th kill rings out a shockwave; *Lucky Button:* gift boxes have one extra choice. Small stat bonuses are allowed on top, but never the main point.
  - **Found and crafted, not gambled:** zombies and bosses drop **sewing patterns**; you sew the piece in the town's **Sewing Workshop** with materials from expeditions. That connects equipment to the town loop.
  - **Town upgrades unlock equipment, too.** Two ways to get patterns:
    - *Drops* (a surprise): from bosses, elites and gift boxes.
    - *Buildings* (guaranteed, so you can plan): each building unlocks a themed piece when it's built or upgraded. *Watchtower → Lookout Cap* (bigger pickup range), *Rain Barrel → Raincoat*, *Bell Tower → Jingle Bell*. Upgrading the **Sewing Workshop** unlocks more stitch levels and new kinds of pieces.
    - That gives the player a reason to pick one building over another: "I want the Raincoat, so I build the Rain Barrel first."
  - **Upgraded by stitching:** each piece has a few upgrade levels (more stitches = stronger effect), paid with materials. No rarities, no merging duplicates, no gacha.
  - **Gear is shared:** any hero can wear any piece, so new heroes don't start from zero (a key complaint about Survivor.io).
  - **Combos with weapons:** some pieces boost certain weapon types (e.g. *Pin Cushion Hat* makes aimed weapons pierce), so equipment becomes part of planning a build before the run.
- **Idle production:** some buildings (e.g. a stuffing mill) produce materials while the game is closed, up to a cap. Opening the game always rewards you.
- **Rescued plushies make the town alive.** On expeditions you sometimes find a plushie that isn't fully zombified yet. Bring it home, stitch it up in the town's Plush Hospital, and it moves into town: it walks around, works a building, and helps in the invasion. The town gets visibly busier over time, and every expedition has a small extra goal ("save the bunny").

### The long-term goal

Repetition after 10–20 hours is the genre's #1 complaint, so the player always needs goals at three distances:

- **Now (this run):** survive, find the evolution, beat the boss.
- **Soon (the next few sessions):** the next building, the next piece of equipment, getting ready for the coming invasion.
- **Later (the big goal):** find out where the zombie curse comes from. Each area ends with a boss that leads to the next area, and the last boss is the source of the curse (e.g. *the Moth Queen*, who eats plushies from the inside). Beating it is a real ending with credits.
- **After the ending:** optional harder levels ("Moth-ball difficulty"), with extra rewards for players who want a challenge.
- **Collection book:** every weapon, evolution, equipment piece, enemy and rescued plushie you've found, with blank spots for what's missing. A low-pressure goal for completionists, and it explains every item so nobody needs a wiki.
- **Unlock goals are visible and happen naturally** ("Defeat 500 zombies with the Peel Boomerang"). No hidden or tedious grind tasks: those are a top complaint about Megabonk and Halls of Torment.

### Enemies

The zombie plushies need variety, and some of them bring the actual bullet hell:

- **Shamblers:** slow, come in big swarms. The basic horde.
- **Runners:** fast and fragile; force you to keep moving.
- **Spitters:** shoot stuffing balls in patterns that you must dodge. These bring classic bullet hell into the game, introduced slowly and more often in later areas.
- **Bloaters:** burst into a cloud of stuffing when killed; don't kill them close up.
- **Tanks:** big, slow, lots of health; a target for strong aimed weapons.
- **Elites and bosses:** clear, readable bullet patterns that are telegraphed before they fire. Elites drop sewing patterns.
- **Pacing inside a run:** intensity comes in waves, with short breathers to collect XP and catch your breath, instead of a constant flat stream.

### Combat

- **Move with WASD, dash on Space.** Moving is the main skill.
- **Two kinds of weapons**, and the upgrade decides which:
  - **Auto weapons** fire by themselves at the nearest / strongest enemy (orbiting needles, button shotgun, stuffing clouds).
  - **Aimed weapons** fire towards the mouse cursor (yarn cannon, sewing-pin sniper, thread whip). Stronger or more precise, as a reward for aiming.
- Weapons combine or evolve (e.g. needle + thread → "Sewing Storm"). Recipes are visible in the game, so nobody needs a wiki.
- One reward moment per run: the **gift box** (our version of the treasure chest), short and spectacular.
- **Control over bad luck:** randomness ruining runs is a top complaint (Enter the Gungeon, Megabonk). Players get a few **rerolls** (new choices), **skips** and **banishes** (this item never shows up again this run) per run, and more can be unlocked in the town.
- **Game feel from day one:** hit flash, short hit-stop on big hits, small screen shake, enemies popping into stuffing, XP buttons flying into you, a big level-up moment, and a sound for every action. This isn't polish for the end: it's a large part of *why* these games are fun.

### Theme

- **Heroes:** stuffed animals, modelled on the girlfriend's real plushies. Each hero has a starting weapon and one passive ability that changes how they play (sidegrades, not "stronger versions").
- **Enemies:** zombie plushies: torn seams, missing button eyes, leaking stuffing, mismatched patches. Creepy-cute, never gory.
- **Materials:** buttons (the common currency), stuffing, thread, fabric scraps, blueprints (from bosses and gift boxes).
- **Tone:** cozy plus a little spooky, with humour. Strong personality over detail.

### Heroes

Each hero is one of the girlfriend's real stuffed animals. More will be added as the product owner describes them.

#### 1. Banane, the banana duck (starter hero)

- **Looks:** a duck dressed as a half-peeled banana. A fluffy white peel hood covers his head and back, with three peel flaps hanging open over a round yellow body. Small brown dot eyes, a big orange beak and stubby orange feet. Short and round, with a waddle.
- **Personality:** quirky, straightforward, pretty cool. No-nonsense, unbothered, does his thing. He has the coolest lines in the game.
- **Playstyle: "the simple one who's secretly great."** Banane is the hero every new player starts with, so he must be easy to learn and still fun after 50 runs.
  - **Starting weapon: Peel Boomerang** (auto). Throws a banana peel boomerang at the nearest zombie. It flies out and comes back, hitting enemies on both legs of the trip.
  - **Passive: Slippery.** Every dash leaves a banana peel on the floor; zombies that step on it slip and are stunned for a moment. A simple way to get out of trouble, and it rewards good dashing.
  - **Signature evolution (idea):** Peel Boomerang + a speed item → **Banana Split**: the boomerang splits into three on the way back.
- **Voice/feel:** a deadpan "quack" when leveling up; a little sunglasses moment when the gift box opens.

## 6. Principles

1. **Readability first.** Danger always has the most contrast; your own effects are quieter; your hitbox is small and visible; effect intensity and damage numbers can be turned down. You always know why you died.
2. **Fast, generous start.** The first run feels great; you build your first building within the first 10 minutes of play.
3. **Unlocks are mostly sideways:** new heroes, weapons, areas, mechanics. Stat bonuses exist but are small and capped.
4. **No run is wasted.** Even a loss moves the town forward.
5. **The town is played, not managed.** Base visits are short; the siege is where the town really counts.
6. **Never lose progress.** Autosave after every phase; closing the game mid-run can resume it.
7. **Smooth with hundreds of enemies** on a mid-range PC (target: 60 fps with 500 enemies on screen).
8. **Respect the player.** No energy, no pay-to-win, no fake timers.
9. **Reveal systems when they're needed, not before.** The first session is only "run → one building". The workshop, equipment, rescues and invasions appear one by one over the first hours. No long tutorial.
10. **Fun is tuned, not guessed.** All balance numbers (damage, spawn rates, costs) live in data files so they can change in minutes. A developer menu (spawn enemies, give XP, jump to the boss, skip time) and a local run log (how long, what killed you, what you picked) make tuning fast. Automated tests prove that things *work*; only playing proves they're *fun*, so every milestone ends with a playtest by the product owner.
11. **Normal PC basics:** pause at any time, rebindable keys, windowed/fullscreen, volume sliders.

## 7. Decisions (product owner, 2026-10-21)

- **Platform:** PC (Windows) first.
- **Controls:** mix of auto-fire and mouse-aimed weapons; the weapon/upgrade decides.
- **Base:** town + defend it in waves.
- **Theme:** zombie plushies vs. the girlfriend's stuffed animals.
- **First hero:** Banane, the banana duck: quirky, straightforward, cool. Other heroes will follow.
- **Engine:** Godot 4 (product owner: "whatever is best").
- **Invasion rhythm:** a siege is announced in advance and comes every 2–3 expeditions (nights).
- **Equipment progression:** items sewn onto the plushies, crafted in the town; town upgrades unlock new equipment (details in §5).
- **Local co-op:** yes, for 2 players on one PC (keyboard + mouse and a controller, or two controllers). Not in the MVP, but the code supports a second player from M1, and co-op is the first milestone after the MVP.
- **Art and sound: made from scratch, nothing bought.** See §8.1.

## 8. Tech (approved)

**Godot 4 (GDScript)**, exported as a Windows .exe.

- It's built for 2D, free and open source, and proven in exactly this genre: Brotato is made in Godot.
- Godot can run headless, so the factory's quality gate still works: unit tests (GdUnit4) and **scenario tests** (scripted runs: "start an expedition, wait 60 seconds, check that enemies spawned and XP was collected") run in GitHub Actions on every PR.
- Every merged PR produces a downloadable Windows build, the PC version of the "QR code on the PR" from Tastey.
- Alternative: Phaser + TypeScript (closer to the Tastey/DaysUntil stack, runs in the browser), but it's weaker for a Steam-style PC game and for 500+ enemies.

### 8.1 Art and sound pipeline (no purchases)

- **Art style: "felt cut-out".** Every character, enemy, building and effect is built from simple shapes in code, with a felt texture shader (fuzzy grain, slightly wobbly edges), stitched outlines and button eyes. Proof of concept: [`docs/art/felt-style-concept.html`](../art/felt-style-concept.html) shows Banane, a zombie teddy and a readability test scene, all drawn in code without a single image file.
- **Why it fits:** it matches the plushie theme, stays readable with hundreds of enemies, stays consistent (every piece is made the same way), and costs nothing. Equipment pieces are separate shapes sewn onto the hero, so wearing a hat is just one more shape.
- **Depth: "B — Soft"** (product owner decision, 2026-10-21): rounded edges lit from the top-left, contact shadow on the floor, seams slightly pressed in. Not flat, not glossy. See the comparison in the concept page.
- **Animation: puppet-style ("cut-out") animation, all in code.** Every plushie is built from separate pieces (feet, body, head, flaps/arms, beak/eyes) that move independently. Demo: [`docs/art/animation-concept.html`](../art/animation-concept.html).
  - *Walk:* the body waddles and bobs, feet step one after another, floppy parts swing a moment later than the body (this delay is what makes them feel soft).
  - *Squash and stretch:* squish on landing and on hits, stretch on dashes.
  - *Hit:* a white flash, a squish that wobbles back, a small knockback.
  - *Zombie death:* the zombie bursts into its pieces plus a cloud of stuffing, and the button eye pops off.
  - *Personality moves:* e.g. Banane's deadpan quack with sunglasses on level-up.
  - In Godot this is a skeleton of `Node2D` pieces animated by code (or by `AnimationPlayer` for one-off moves); no frame-by-frame drawing.
- **The real plushies:** each hero is designed from photos of the real stuffed animal, as with Banane.
- **Sound effects:** generated with a free, open-source retro sound generator (sfxr-style, e.g. jsfxr), plus code-generated "soft" sounds (quack, plop, fabric rip). Free CC0 (public domain) packs only if something is missing.
- **Music:** free CC0 music or simple generated tracks for the MVP; revisit later.
- **Only free, open licences:** CC0 or self-made. Licences are recorded in `docs/art/credits.md` (created when the first external file is added).

## 9. Explicitly NOT MVP

- Local co-op (the first milestone after the MVP; the code is ready for it from M1). Online multiplayer is not planned.
- Steam release, achievements, store page.
- Story / dialogue system.
- Controller support (later), Mac/Linux builds.
- Endless mode, difficulty levels beyond normal.
- Final polish of the art. The felt style is used from M1 in a simple form and refined in M6.

## 10. Milestones (proposal)

- **M0 — Factory setup:** repo, Godot project, CI with headless tests, Windows build on every PR.
- **M1 — Core run:** Banane (simple felt art), WASD + dash, one auto and one aimed weapon, shamblers + runners, XP, level-up pick 1 of 3, death screen, **basic game feel and sounds**, developer menu, balance in data files. *Is the 5-minute run fun?*
- **M2 — Build variety:** 8–10 weapons, evolutions, passive items, gift box, reroll/skip/banish, all enemy types including spitters, elites, mini-boss + boss, one complete area.
- **M3 — Town:** pillow fort town, materials, 5–6 buildings, unlock heroes/weapons, rescued plushies, collection book, autosave.
- **M4 — Night siege:** wave defense in the town, buildings fight along, repair.
- **M4.5 — Equipment:** Sewing Workshop, 3 slots, ~8 pieces that show on the hero, sewing patterns as drops, stitch upgrades.
- **M5 — The plushie heroes:** 3–4 heroes based on the real stuffed animals, each with their own playstyle.
- **M6 — Look & feel:** final art direction, effects, sound, readability options → **MVP done**.
- **M7 — Local co-op:** a second player joins on the same PC; shared town, shared invasions.
- **M8+ — later:** more areas up to the final boss and the ending, idle production, harder difficulty levels, Steam.

## 11. MVP is done when

- A new player can play the full loop: expedition → town → siege → next expedition, without explanation outside the game.
- There are at least 3 heroes, 10 weapons with 3+ evolutions, 1 area with a boss, 6 buildings, 8 pieces of equipment and a working siege.
- A run of 10 minutes stays smooth with 500 enemies on screen.
- The product owner (and their girlfriend) want to play "one more".

## 12. Open questions

1. **More heroes:** the next stuffed animals (name, animal, personality, photo). Needed by M5; Banane is enough until then.
2. **Name:** "Stuffed" is a placeholder. Ideas: *Stuffed & Undead*, *Plush Defense*, *Night of the Living Plush*.
