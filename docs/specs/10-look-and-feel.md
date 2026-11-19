# 10 — Look & feel (MVP finish)

Status: **DRAFT** (spec PR, waiting for the PO).
Milestone: **M6 — Look & feel** (the last milestone before the MVP is done, vision §10).
Based on: vision §6.1 (readability, "effect intensity and damage numbers can be turned down"), §6.9 (reveal
systems when needed, no long tutorial), §6.11 (rebindable keys, windowed/fullscreen, volume sliders), §8.1 (sounds
and music made by us), §11 (when the MVP is done). PO answers 2026-11-19: all four parts below are in; art gets
a **small polish only** ("features first"); the night look and walking into buildings stay parked.

## 1. Goal

One question: **would a new player pick this up, understand it without help, and keep the sound on?**

After this spec:

- every **evolution** changes how the weapon plays (not just more damage) and arrives with a **big moment**,
- the game has **real music** (a track per place, the run gets more intense over time) and the most frequent
  sounds feel punchy without turning into noise when 300 zombies pop at once,
- **Settings** has everything a PC player expects: window mode, keys you can change, and dials to turn down
  screen shake, flashes and your own effects,
- a **first-time player** gets short notes the first time each thing shows up (run, level-up, gift box, town,
  siege ...), never a long tutorial,
- the **MVP checklist** (vision §11) is checked and green.

Not in this spec: a big art redraw, a night look, building interiors, controller support and a second player's
keys (M7 co-op), music from outside sources, voice acting, a story.

## 2. What the player experiences

1. Run 1, a new save: a taped note says "WASD to walk, Space to dash". The first XP button gets a small note
   "Walk over buttons to grow". The first level-up screen explains the cards and Reroll / Skip / Banish once.
2. The music starts calm. After a few minutes, and when the screen fills up, drums and a bass line join in. The
   boss gets its own track. Back home, the town has a cosy daytime tune; the siege has its own dusk track.
3. Mid-run a gift box holds an evolution: the screen shows the weapon and the item **being sewn together** into
   the new weapon with an "EVOLVED!" stamp. Back in the run, time slows for a moment, a ring pulses from the
   hero and the first shot is huge. The weapon now does something new (§3).
4. In Settings the player turns screen shake down to 40%, switches to borderless window and moves dash to Shift.
   Every hint in the game now says "Shift".

## 3. Evolutions: the "wow" pass

Every evolution gets **one new behaviour** on top of what it does today, a **unique sting** (sound) and an
**evolved look** that is clearly bigger than the base weapon while staying quieter than zombies (rule 9). All
numbers in the evolved weapon's `.tres` (first guesses, tuned in the playtest).

| Evolution (recipe) | Today | New behaviour |
|---|---|---|
| **Banana Split** (Peel Boomerang + Quick Feet) | splits into 3 on the way back | **Peel trail:** every split peel that hits a zombie drops a banana peel there; zombies that step on it slip and are stunned (like Banane's Slippery, max 6 peels on the floor). |
| **Sewing Storm** (Orbiting Needles + Long Thread) | permanent storm, flings needles every 3 s | **Stitch-up:** flung needles trail thread; after 0.6 s the threads pull tight, dragging every zombie they passed through towards the hero and hitting them again when they snap. |
| **Pincushion Volley** (Sewing-Pin Sniper + Sharp Scissors) | fan of 7 piercing pins | **Chain pins:** a zombie killed by a pin fires 2 new pins from where it fell (one more generation at most, so it can't run forever). |
| **Yarn Bomb** (Yarn Cannon + Big Spool) | sticky yarn slows and hurts | **Tangle:** after 2 s the yarn web yanks everything inside it to its middle and pops (a second burst). |
| **Snow Day** (Snowball Toss + Thick Felt) — *new* | — | Every landing builds a **snowman** for 4 s; zombies nearby attack it (bait), then it bursts and freezes them for 1.5 s. Max 3 snowmen. |
| **Bear Slam** (Paw Swat + Extra Stuffing) — *new* | — | Every 4th swat is a **ground slam**: a ring that knocks zombies down (short stun) and hurts everything in it. |

- The two new evolutions belong to Pip's and Böbö's weapons, so they only show up once that hero is unlocked
  (like their weapons, `HeroStats.unlocks_weapon`). That makes 6 evolutions (MVP needs 3+).
- **The evolution moment:** the gift box screen shows "weapon icon + item icon → sewn together by a needle →
  evolved weapon" with an "EVOLVED!" stamp (~1.5 s, any key skips to the end). After closing it: 0.4 s slow motion,
  a ring pulse from the hero and the first attack drawn at 1.5× size. Slow motion and the pulse only for the
  **first** evolution of each kind per run; Reduced motion turns the slow motion off.
- Recipes stay discoverable as today (Scrapbook, pause → Recipes); the evolved Scrapbook page gets the new text.

## 4. Music and sound

### 4.1 Music (made in code, no outside files)

- Today's music player gets a small **pattern sequencer**: drums (kick, snare, hats made by the synth), bass,
  chords, melody. Each track is a `.tres` in `data/audio/music/` (tempo, key, patterns, layers), so tuning is
  data, not code.
- Tracks: **title**, **town** (daytime, cosy), **run** (layers: calm → + drums after 2:00 or 150 zombies on screen
  → + bass/melody after 5:00), **boss**, **siege** (new, dusk + drums, gets busier each wave), **endless** (run
  track at full intensity, slightly faster).
- **Stingers** (short one-shots over the music): goal reached, hero died, siege won, siege lost, evolution.
- Changing place **crossfades** (~1 s). Pause muffles the music (as today). Volumes stay on the Music slider.

### 4.2 Sound pass

- The 8 most frequent sounds (hit, zombie death, XP pickup, level-up, dash, coin, own shot base sounds, hurt) get
  a richer voice (layered, "soft" felt thump under the click) and **random pitch and volume** each time.
- **Voice limits:** each sound has a max number playing at once (data in `SfxBank`); the rest are skipped. A crowd
  of 300 deaths in one frame stays one big "pop", not a crackle. A limiter on the Master bus stops clipping.
- **Hero voices:** each hero gets a little level-up sound in their character: Banane's deadpan quack (exists), Pip a
  squeak, Böbö a low grumble, BamBam a happy trill, Robbar a seal bark.
- Enemy danger sounds stay louder than the player's own (as today, `test_audio.gd`).

## 5. Settings and options

Settings becomes a panel with **4 tabs** (same felt style, sewn tab buttons): **Sound**, **Screen**,
**Controls**, **Readability**. Everything is saved in `settings.json` and survives a restart (rule 10).

- **Sound:** Master / Effects / Music (as today).
- **Screen:** Window mode (Windowed / Fullscreen / Borderless), V-Sync on/off. F11 / Alt+Enter keep working and
  update the switch.
- **Controls:** a list of player 1's actions (move ×4, dash, interact, tricks, pocket, card 1-4, reroll, skip,
  banish). Click a row, press a key → bound. A key that is already used **swaps** with the other action (never two
  actions on one key). "Reset to defaults". Esc (pause/back) and F1 (dev menu) can't be rebound. Every in-game key
  hint reads the bound key (`player.key_text`). Bindings are stored **per player index**, so M7 can add player 2.
- **Readability:**
  - Damage numbers on/off (as today),
  - **Screen shake** 0-100% (scales every camera shake; 0 = none),
  - **Flashes** on/off (screen flashes and the white hit flash on big hits; the hero's hit flash stays, smaller),
  - **Own effects** 50-100% (opacity of your own shots and effects; zombies and enemy bullets never change),
  - Reduced menu animations (as today, now also turns off the evolution slow motion),
  - **Hints** on/off + "Show hints again".

## 6. First-time hints

- A hint is a small **taped paper note** (UI kit: paper + `TapeStrip` + hand-written font) next to what it
  explains, with the bound key on a `FabricTag`. It never covers the hero, never pauses the game by itself, and
  goes away when the player does the thing (or after ~8 s, then shows once more next time).
- Each hint shows **once per save** (ids remembered in the save; a new save version after M4.5's). The list:

| Id | When | Says (first draft) |
|---|---|---|
| `move` | first run starts | WASD to walk · Space to dash |
| `xp` | first XP button drops | Walk over buttons to grow |
| `level_up` | first level-up screen | Pick one card · R new cards · S skip (heals) · B banish a card forever |
| `gift_box` | first gift box drops | Gift box! Grab it before it's gone |
| `floor_pickup` | first floor pickup drops | Toys help once: grab it when you need it |
| `evolution_ready` | first maxed weapon whose partner item you own | Maxed! The next gift box can evolve it |
| `boss` | first boss appears | Beat the King to win the run |
| `way_home` | first Way Home portal | Stand in the portal to go home with everything |
| `town` | first time in town | Walk to a ruin and press E to build |
| `can_build` | first "Can build!" tag | You have enough: press E |
| `tricks` | first building at Lv 1 | T opens the tricks (folds in today's first-time hint) |
| `siege_warning` | first "horde is coming" | The moon counts down: when it's full, defend the fort |
| `siege` | first siege starts | Keep the fort standing until the last wave |
| `wardrobe` | Wardrobe appears | Swap heroes at the Wardrobe |
| `sewing` | Sewing Workshop appears (M4.5) | Sew the patterns you find into gear |

- The texts live in `data/ui/hints.tres` (id, text, key action, where it sits), so new features add a line.
- Co-op: hints show for player 1's keys only (until M7).

## 7. Small art polish

- **Low health:** below 25% the hero's heart patch pulses and a soft heartbeat plays (no red screen edge: red is
  the zombies' danger colour, rule 9).
- **Playtest nitpicks:** what the PO reports in the big playtest batch (P-22 … P-37) that is a look/feel nitpick
  gets fixed in one or two tickets here. Bigger wishes become their own issues/specs.

## 8. Co-op (hard rule 11)

Bindings are stored per player index; readability options are shared (one screen). Evolutions, hint notes and
the low-health warning work per hero (each hero's own bar/heart).

## 9. Save (hard rule 10)

- `settings.json`: window mode, V-Sync, bindings, shake, flashes, own effects, hints on/off. Test: save, reload,
  compare (also with a broken/old settings file → defaults, never a crash).
- Save file: `hints_seen` (bump after M4.5's version). Test: save, reload, compare. An older save that already
  has a town loads with the basic run/town hints (`move` … `can_build`) marked seen: that player knows them.

## 10. Developer menu and log

- Run dev menu: "Evolve now" (picks the first possible evolution and plays the moment), "Music layer +1".
- Town dev menu: "Reset hints".
- Run log: field `hints` (ids shown this run).

## 11. Readability and performance

- Every new visual (evolution behaviours, snowman, slam ring, peels, hint notes, low-health pulse) goes into the
  colour sweeps (`color_sweep.gd`): no danger colours, zombies keep the strongest contrast on every floor.
- Benchmark (`tools/benchmark.gd`) with all 6 evolutions at once and 500 zombies: no worse than +15 draw calls
  and no frame over 16 ms on the PO's PC compared to `main` before M6.
- The music sequencer runs in the audio thread budget: no frame hitches from it (measured in the benchmark).

## 12. MVP check (vision §11)

A test that checks the content counts: ≥ 3 heroes, ≥ 10 weapons, ≥ 3 evolutions, 1 area with a boss,
≥ 6 buildings, ≥ 8 gear pieces, a working siege. Plus a 10-minute benchmark run with 500 zombies (real GPU, on the
PO's PC). Then the PO's playtest decides "MVP done".

## 13. Acceptance criteria

- **AC-105** Each of the 6 evolutions does its new behaviour from §3 (one scenario each).
- **AC-106** The evolution moment plays: sewing reveal on the gift screen (skippable), then slow motion + pulse +
  big first attack once per evolution kind per run; Reduced motion skips the slow motion.
- **AC-107** Snow Day and Bear Slam only appear once Pip / Böbö are unlocked; Scrapbook and Recipes show them.
- **AC-108** Each place plays its track (title, town, run, boss, siege, endless), changes crossfade, the run's
  layers grow at the times/crowd in §4.1, stingers play at their moments.
- **AC-109** A crowd of 300 deaths in one frame plays no more than the voice limit of each sound and the Master
  output never clips; frequent sounds vary in pitch; each hero has their own level-up voice.
- **AC-110** Settings has 4 tabs; window mode and V-Sync apply at once and survive a restart.
- **AC-111** Screen shake 0% means no camera shake; Flashes off removes screen flashes; Own effects lowers only
  own shots/effects (zombies and enemy bullets unchanged); all survive a restart.
- **AC-112** Every listed action can be rebound; a used key swaps; Reset restores defaults; Esc/F1 are fixed;
  in-game key hints show the bound key; bindings survive a restart.
- **AC-113** Each hint in §6 shows once at its moment, goes away when done, never covers the hero, is remembered
  in the save; Hints off shows none; "Show hints again" brings them back; a returning player skips the basics.
- **AC-114** The new Settings tabs and the hint notes pass the fit check (all window sizes).
- **AC-115** Below 25% health the heart pulses and the heartbeat plays; it stops when healed.
- **AC-116** The MVP content check passes; new visuals pass the colour sweeps; the benchmark stays within §11.
- **P-38** (playtest) An evolution feels like a big moment and I play differently with it.
- **P-39** I keep the music and sounds on; a big crowd dying sounds great, not noisy.
- **P-40** A new player (your girlfriend?) gets through run → town → siege without asking you anything.
- **P-41** I found the setting I wanted, and changing a key worked everywhere.

## 14. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Music made in code (no outside files)? **Yes**: consistent with the sounds and no licences. If it doesn't
   sound good enough after the playtest, we look at CC0 music then.
2. Two new evolutions for Pip and Böbö (Snow Day, Bear Slam)? **Yes**: hero weapons should evolve too.
   BamBam and Robbar have no own weapon yet, so none for them.
3. Hints as taped notes next to the thing, shown once per save? **Yes**.
4. Rebinding only for keyboard player 1 now; controllers and player 2 come with M7 co-op? **Yes**.
5. Evolution slow motion only the first time per kind per run? **Yes** (twice in a run gets annoying).
6. Low-health warning without a red screen edge (red = danger)? **Yes**.

## 15. Not in this spec

Big art redraw, night look variant, building interiors, controller support, player 2 keys, outside music,
difficulty levels, more areas, Steam. The playtest nitpicks are only fixed if they're small (§7).

## 16. Proposed tickets (after approval)

Tickets 1-9 don't touch the save file and can be built while M4.5 is still being built; 10-11 need M4.5's save
version merged first.

1. Settings tabs + Screen options (window mode, V-Sync) — AC-110, AC-114
2. Readability options (shake, flashes, own effects, hints switch) — AC-111
3. Key rebinding + key hints everywhere — AC-112
4. Music sequencer + 6 tracks + crossfade + stingers — AC-108
5. Sound pass: richer frequent sounds, variation, voice limits, limiter, hero voices — AC-109
6. Evolution moment (sewing reveal, slow motion, pulse, stings) + dev "Evolve now" — AC-106
7. Banana Split + Sewing Storm new behaviours — AC-105
8. Pincushion Volley + Yarn Bomb new behaviours — AC-105
9. Snow Day + Bear Slam (new evolutions) — AC-105, AC-107
10. Hint system + run hints (save `hints_seen`) — AC-113, AC-114
11. Town, siege, Wardrobe, Sewing hints — AC-113
12. Low-health warning + playtest nitpicks — AC-115
13. MVP check: content counts, colour sweeps, benchmark — AC-116
