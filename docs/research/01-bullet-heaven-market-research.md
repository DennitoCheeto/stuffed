# Bullet hell + base building: market research

Research date: 2026-10-21
Purpose: input for `docs/specs/00-product-vision.md` (factory station 1).

## Summary

1. **The genre that sells is "bullet heaven", not classic bullet hell.** The big hits since 2022 (Vampire Survivors, Brotato, Halls of Torment, Megabonk, Ball x Pit) all reverse the classic shmup: *you* are the bullet storm and the enemies are a horde. The player's job is **movement plus build choices**, not precise dodging. Classic skill bullet hells (Enter the Gungeon, Nova Drift) are loved too, but by a smaller and more hardcore audience, and their top complaint is a steep early difficulty.
2. **The closest model for our idea already exists and is a hit: Ball x Pit** (Oct 2025, 2M+ copies, Metacritic 84–89, nominated for The Game Awards' Best Independent Game). Short action runs, then a small city builder between runs. Its base building is also its **most criticised part**. That tells us where the opportunity is.
3. **The single most important lesson for the base:** reviewers like base building when it's **the core mechanic in a different mode** (Ball x Pit's harvest: you *bounce your heroes* through your town to collect resources). They dislike it when it becomes **menu busywork** (Ball x Pit: "never really feels fun in comparison to the rest of the game", "dull and time-consuming"; Cult of the Lamb: "feels like two opposite games").
4. **Every successful game here has the same five pillars:** runs of 10–30 minutes, a choice at every level-up, items that combine or evolve, a chest/reward moment that feels like a slot machine, and a long list of unlocks. Low price ($5–15) and runs well on weak hardware / Steam Deck.
5. **The same complaints come up in every game:** gets repetitive after 5–20 hours, slow or grindy start, RNG ruining runs, too much visual clutter late in a run, crashes that lose a run, and meta-progression that feels like a stat grind instead of new toys.

## The games we looked at

| Game | Type | Size of success | Player sentiment* |
|---|---|---|---|
| **Vampire Survivors** (2022) | 2D bullet heaven, auto-fire | ~6M sold, 260k+ Steam reviews, BAFTA winner | 93% |
| **Brotato** (2022) | Arena waves, shop between waves | 1M+ by Sept 2022, one of the top roguelites of 2022–23 | 84% |
| **Halls of Torment** (2023) | Diablo-style bullet heaven | Overwhelmingly Positive, Game Pass | 75% |
| **Megabonk** (2025) | 3D bullet heaven | 1M in 2 weeks, ~117k peak concurrent players, 94% on Steam | 58% recent |
| **Ball x Pit** (2025) | Breakout × bullet heaven × **city builder** | 2M+ sold, Metacritic 84 (PC) / 88–89 (console), mobile launch Mar 2026 | 83% |
| **Deep Rock Galactic: Survivor** | Licensed bullet heaven + mining | Large IP launch | 58% recent |
| **Enter the Gungeon** (2016) | Classic skill bullet hell roguelite | Genre classic | 91% |
| **Nova Drift** | Skill bullet hell, deep builds | 95–96% positive on Steam | — |
| **Dome Keeper** | Mining + defending a base + roguelite | Strong indie hit | 80% |
| **Cult of the Lamb** | Dungeon runs + cult/base sim | Metacritic 82 | — |
| **Survivor.io / Archero** (mobile) | Free-to-play bullet heaven | $500M+ lifetime IAP, $5–6M/month | Pay-to-win complaints |

\*Sentiment = VaporLens AI summary of recent Steam reviews, not Steam's overall score. It's useful for **which themes** come up, less so for the exact percentage (Megabonk shows 58% here but 94% on Steam overall, because recent reviews are complaining about it being abandoned).

## Why they're fun

### 1. Low input, high decisions
Auto-fire takes aiming away, so all your attention goes to **where to stand** and **what to pick**. Vampire Survivors players list "easy to learn" (31) and "addictive and simple" (28) among their top praise. Developers defend auto-fire because nobody can aim 4–6 weapons at once while also keeping ahead of the swarm. The cost: some players feel "hamstrung" and want control. 20 Minutes Till Dawn and Halls of Torment add manual aiming; Halls of Torment gets criticised for it in comparison to VS.

### 2. A power fantasy that grows during the run
You start weak and end with a screen full of explosions. Luca Galante (VS) tested with only 2–3 weapons and was "more focused on trying to put as much stuff as possible on-screen". The *run itself* is the progression arc: weak → godlike in 15–30 minutes.

### 3. Build combinations and evolutions
Top praise in every title is variety: Gungeon "large, creative arsenal" (96), Brotato "wide range of characters and weapons" (67), Ball x Pit "ball fusion and evolution" (22), VS "weapon evolution system" (16). The fun is **discovering a combo** that suddenly breaks the game.

### 4. Slot-machine reward moments
Galante came from the gambling industry and used that knowledge for the chest animation: lights, music, a cascade of items. The first chests are scripted to give generous results before the odds drop. This is the most-cited "why is it addictive" reason, and it's also why critics talk about "gambling psychology". **We should use the *feeling* (anticipation, spectacle, payoff) without real-money gambling.**

### 5. Short runs → "one more go"
Runs of 10–30 minutes. Brotato waves last 20–90 seconds, runs under 30 minutes. Cult of the Lamb dungeons are under 15 minutes. Halls of Torment's 30-minute runs are a listed complaint ("too long", 15). Survivor.io's 15-minute levels are criticised for making grinding painful. **Shorter is safer.** Gungeon gets praise for "suiting both short and long sessions" (64).

### 6. A long unlock list, "death is progress"
VS: "extensive unlockable content" (50) is the second-highest praise. Hades made losing feel good by unlocking new dialogue, upgrades and story on every death; nearly every roguelite since has copied "meta-progression + characters who talk to you".

### 7. Cheap, runs anywhere
Nearly every review summary praises low system requirements and Steam Deck performance. Price is part of the hook: $3–15.

## What graphics work

**What succeeds is readable and cheap, not high-fidelity.**

- **Pixel art and low-poly both work.** VS is crude pixel art (and "simple/unappealing graphics" is one of its complaints, 29), but it sold 6M anyway. Halls of Torment's *strong single theme* (Diablo 1 nostalgia) is its #1 praise (63). Dome Keeper's "beautiful pixel art" (28). Megabonk's cheap low-poly 3D with goofy characters (skeleton on a skateboard with sunglasses) became a streaming hit. **A strong, consistent theme and personality matter more than detail.** NME criticised VS for an inconsistent art style between stages.
- **Readability beats spectacle.** Recurring complaints: late-run visual clutter (VS, Entropy Survivors "eye strain"), "couldn't tell why I died", flashing chest effects that go on too long (VS). Rules from shmup designers:
  - Hostile things must contrast with *everything else* — player shots, pickups, background. Player shots should be visually quieter than enemy danger.
  - Darker, low-contrast backgrounds; bright, saturated danger.
  - Player hitbox much smaller than the sprite, with a visible core. Enemy bullet hitboxes smaller than their sprites. This makes near misses feel great and deaths feel fair.
  - Telegraph big attacks with shape and colour before they hit.
  - Options to dim your own effects, turn off damage numbers and flashing (Halls of Torment players turn off damage numbers to fix late-game lag).
- **Juice, in measured doses:** hit-stop (50–100 ms on big hits), small screen shake, flash on hit, pickups that pop/scale, satisfying XP gem vacuum, big level-up moment. Guides warn: "juice is seasoning — too much becomes noise".
- **Performance is part of the art direction.** Lag/stutter late in runs and crashes come up for VS, Halls of Torment, DRG Survivor and Megabonk. Hundreds of enemies + particles must stay smooth on weak hardware/phones. Design the look around that (sprite batching, pooled effects, a cap on on-screen effects).

## What players love (across all games)

1. Addictive core loop — #1 theme everywhere.
2. Lots of characters/weapons that actually play differently.
3. Discovering combos/evolutions.
4. Constant flow of unlocks and a sense of progress.
5. Short sessions that respect your time.
6. Great value for a low price; free content updates (Ball x Pit gave 3 free updates; VS keeps major mechanics free and puts characters/stages in paid DLC).
7. Local co-op (Brotato 42, Dome Keeper's most-discussed topic).
8. A clear theme and humour (Gungeon's gun puns, Megabonk's silly cast, Halls' Diablo mood).
9. Smooth on low-end hardware and handhelds.

## What players hate

| Complaint | Where | Size |
|---|---|---|
| **Repetitive after a while** | Every game. Megabonk "drops after 5–10 h", Survivor.io "loses its charm in a week or two" | Top complaint almost everywhere (VS 29, Brotato 37, Ball x Pit 27, DRG-S 37) |
| **Grindy / unrewarding meta-progression** | DRG-S "excessive grind" (37), "upgrades unrewarding" (19); Halls "flat meta-progression"; Ball x Pit "unlocks grindy" (12) | High |
| **Base building as busywork** | Ball x Pit "dull and time-consuming" (11), "replace buildings and rearrange constantly"; Cult of the Lamb "two games that don't mesh", resources "thrown at you like candy" early | Our biggest risk |
| **Slow or brutal start** | VS "slow start" (24), Gungeon "steep early difficulty" (76), Ball x Pit (12), Megabonk | High |
| **RNG decides runs** | Gungeon (75), Megabonk (19) | High |
| **Visual clutter / can't see what's happening** | VS, Entropy Survivors, flashing chests | Medium |
| **Crashes that lose the run, late-run lag** | Halls (25 + 13 "lost progress"), DRG-S, VS, Megabonk | Medium-high, and it destroys trust |
| **Unlocks hidden behind tedious achievements** | Megabonk silver coins, weapon slots behind achievements; Halls quest busywork | Medium |
| **Unclear item text → need a wiki** | Gungeon, Megabonk | Low-medium |
| **Abandonment / no updates** | Megabonk (15) | Hurts recent reviews heavily |
| **Pay-to-win, energy, progression walls** | Survivor.io / Archero | Defines mobile F2P reviews |
| **DLC-locked content/achievements** | Brotato, Dome Keeper (43), DRG-S "overpriced DLC" | Medium |

**The meta-progression debate.** Hardcore players argue permanent stat upgrades make wins feel hollow ("I only won because of the upgrades") and make losses meaningless for learning. The fix that most players accept: **sideways unlocks** (new weapons, characters, options; Hades' weapons are "mostly sidegrades and those are fun too") over pure +5% damage, and difficulty that starts gentle and ramps up with optional heat/curse levels (Hades' Pact of Punishment, Soulstone's curses).

## Base building in roguelites: what we learned

| Game | How the base works | Verdict |
|---|---|---|
| **Ball x Pit** | Resources from runs → buildings that unlock heroes and boost starting stats. **Harvest = bounce your heroes through the town** (same mechanic as combat). Layout matters for bounce angles. Workers gather passively while you play. Boss kills open deeper levels. | Clever, and it's a big part of why the game stands out. But: confusing at first, clunky building UI, constant rearranging, "never as fun as the runs". |
| **Cult of the Lamb** | Full town sim (followers, food, rituals) between short dungeon runs. | Some critics call it the highlight; others say the two halves don't fit, and early resources are too plentiful to matter. |
| **Hades** | No building; Mirror (stat upgrades) + House Contractor (cosmetics and run-changing upgrades) + story. | Gold standard for "losing still feels like progress". |
| **Dome Keeper** | Mine resources underground, return to defend your dome from waves, upgrade between waves. | The base *is* the game. Loved; criticised for slow mining. |
| **Survivor.io / Archero** | Gear, talents, heroes; energy gated. | Strong early power, then walls, then pay-to-win frustration. D1 retention ~45%, D30 below 10%. |

**What makes a base "rewarding to jump back into":**
1. **Something happened while you were away.** Ball x Pit workers gather passively. Idle/offline income is the strongest return hook on mobile. Coming back to a full storehouse is a reward with zero effort.
2. **Every run moves something visible on the base.** Even a lost run should end with "you can now build X" or "Y upgraded".
3. **The base unlocks *new ways to play*, not just numbers.** New hero, new weapon, new biome, a new mechanic. The Habby CEO: "systems should be revealed when players need them — not before."
4. **The base is played, not managed.** Ball x Pit's harvest is the best idea in the genre; the menus around it are the weakest part.
5. **Several visible progress tracks at once** (Naavik on AFK Arena vs Survivor.io): heroes, base, biomes, collection. If there's only one track, players hit a wall and quit.
6. **Short base visits.** 1–3 minutes between runs. The run is the main course.

## What this means for our game (proposed principles for the vision)

1. **Bullet heaven core, with movement as the skill.** Auto-fire by default; one active ability or dash for skill expression. Consider manual aim as an *option*, not a requirement.
2. **Runs of 8–15 minutes**, with a boss at the end and mini-bosses in between. Shorter than Halls of Torment, about Survivor.io's length or less.
3. **Level-up = pick 1 of 3**, with visible evolution/fusion recipes so players can *plan* combos (fewer wiki trips).
4. **One spectacular reward moment** per run (chest equivalent), tuned so it doesn't flash for ages.
5. **The base is played with the core mechanic.** Example directions: defend the base yourself in a short wave ("Dome Keeper" style), or fly/move through the base to collect what's grown. Never a menu-only screen.
6. **The base keeps working while you're away** (workers/production with a cap), so coming back always pays.
7. **The base unlocks sidegrades first**: new heroes, weapons, biomes, mechanics. Stat boosts are small and capped. Optional difficulty levels for players who want a challenge.
8. **Generous, fast start.** First runs scripted to feel great (like VS's first chests); first building in the first 5 minutes.
9. **Readability is a requirement, not polish:** danger always has the most contrast, own effects are quieter, small visible hitbox, effect-intensity option, damage numbers optional.
10. **Strong single theme with humour/personality** over detailed graphics. Cheap pixel art or low-poly is fine.
11. **Performance and save safety are acceptance criteria:** hundreds of enemies stay smooth on target hardware; a crash or closing the app never loses a run (save mid-run).
12. **No pay-to-win, no energy.** If ever monetised: premium price or cosmetics only.

## Open questions for the product owner

1. **Platform:** PC (Steam), phone, or both? Tastey and DaysUntil are Expo/React Native phone apps. A bullet heaven with hundreds of sprites needs a game engine or a canvas/WebGL renderer, so this choice decides the tech stack.
2. **Controls:** auto-fire (genre standard, phone-friendly) or twin-stick aiming (more skill, smaller audience)?
3. **Theme:** what's the world? (The research says theme and personality do more than graphics quality.)
4. **What kind of base?** a) a base you defend yourself in waves, b) a town you develop with a played harvest (Ball x Pit), c) a hub with characters and story (Hades)?
5. **Session target:** how long should one sitting be — one 10-minute run + 2 minutes in the base?
6. **Monetisation:** none (personal project), premium, or free?

## Sources

- Vampire Survivors: [Wikipedia](https://en.wikipedia.org/wiki/Vampire_Survivors), [The Conversation: gambling psychology](https://theconversation.com/vampire-survivors-how-developers-used-gambling-psychology-to-create-a-bafta-winning-game-203613), [80.lv interview](https://80.lv/articles/vampire-survivors-developer-on-its-design-sudden-success), [PC Gamer: "didn't have a vision"](https://www.pcgamer.com/uk/vampire-survivors-creator-didnt-have-a-vision-when-he-started-making-the-game-that-allowed-him-to-quit-his-job/), [Secret sauce of VS](https://jboger.substack.com/p/the-secret-sauce-of-vampire-survivors), [NME review](https://nme.com/reviews/game-reviews/vampire-survivors-review-3332668), [Family Gaming Database accessibility](https://www.familygamingdatabase.com/accessibility/Vampire+Survivors), [TheGamer on chest effects](https://www.thegamer.com/vampire-survivors-flower-venus-flytrap-circle-annoying/)
- Review sentiment (VaporLens): [Vampire Survivors](https://vaporlens.app/app/1794680), [Ball x Pit](https://vaporlens.app/app/2062430), [Brotato](https://vaporlens.app/app/1942280), [Halls of Torment](https://vaporlens.app/app/2218750), [Megabonk](https://vaporlens.app/app/3405340), [DRG: Survivor](https://vaporlens.app/app/2321470), [Enter the Gungeon](https://vaporlens.app/app/311690), [Dome Keeper](https://vaporlens.app/app/1637320), [Entropy Survivors](https://vaporlens.app/app/2602030/entropy_survivors)
- Ball x Pit: [Wikipedia](https://en.wikipedia.org/wiki/Ball_x_Pit), [Push Square: 2M sales](https://www.pushsquare.com/news/2026/08/devolvers-brilliant-roguelite-dopamine-factory-ball-x-pit-is-a-smash-hit-at-2-million-sales), [Mobalytics review](https://mobalytics.gg/gamebase/reviews/ball-x-pit-review), [FullCleared review](https://fullcleared.com/reviews/ball-x-pit-review/), [Press Start GOTY](https://press-start.com.au/features/2025/12/23/press-starts-goty-9-ball-x-pit/), [Deltia's harvest guide](https://deltiasgaming.com/?p=379919), [Deltia's buildings guide](https://deltiasgaming.com/?p=382037), [Nintendo World Report review](https://www.nintendoworldreport.com/review/72918/ball-x-pit-switch-review)
- Megabonk: [Wikipedia](https://en.wikipedia.org/wiki/Megabonk), [Game World Observer: 1M sales](https://gameworldobserver.com/2025/10/03/megabonk-is-a-new-indie-hit-on-steam-the-games-sales-have-surpassed-one-million-copies), [Outlook Respawn](https://respawn.outlookindia.com/gaming/gaming-guides/megabonk-the-3d-vampire-survivors-like-taking-over-steam)
- Brotato: [Wikipedia](https://en.wikipedia.org/wiki/Brotato), [Steam page](https://store.steampowered.com/app/1942280)
- Genre rankings: [Steam250 bullet hell](https://steam250.com/tag/bullet_hell), [wasdland bullet heaven](https://www.wasdland.com/games/bullet-heaven/), [Summer Engine: games like VS](https://www.summerengine.com/blog/games-like-vampire-survivors)
- Mobile: [Naavik: Survivor.io deep dive](https://naavik.co/deep-dives/survivorio-archeros-footsteps/), [Global Games Forum: $5M/month](https://www.globalgamesforum.com/news/how-survivor.io-continues-to-pull-in-5-million-a-month-three-years-later), [mobilegamer.biz: $75M in 2 months](https://mobilegamer.biz/two-months-in-survivor-io-passes-75m-from-37m-downloads/), [PocketGamer.biz on Survivor.io iteration](https://www.pocketgamer.biz/feature/79592/how-innovation-and-iteration-has-transformed-survivorio/), [Game Developer: Archero progression](https://www.gamedeveloper.com/design/finding-the-fun-archero-part-2---progression), [Marlvel Survivor.io reviews](https://marlvel.ai/apps/survivor-io/reviews)
- Hades / meta-progression: [AV Club: Hades and failure](https://www.avclub.com/hades-and-failure), [Loops and arcs in Hades](https://mechanicsofmagic.com/2025/11/04/loops-and-arcs-in-hades/), [Meta progression is starting to feel unrewarding (discussion)](https://piefed.keyboardvagabond.com/c/games/p/232999/meta-progression-in-roguelites-was-fun-for-a-while-but-it-s-starting-to-f)
- Cult of the Lamb: [Game Informer review](https://www.gameinformer.com/review/cult-of-the-lamb/follow-the-leader), [MP1st review](https://mp1st.com/reviews/cult-of-the-lamb-review-the-sacrificial-lamb-pc), [Notebookcheck](https://www.notebookcheck.net/Macabre-roguelite-with-95-positive-reviews-for-under-10-on-Steam.1366468.0.html)
- Nova Drift: [Rogueliker review](https://rogueliker.com/nova-drift-review/), [Nodal](https://nodal.gg/game/nova-drift-858210)
- Aiming debate: [DRG: Survivor discussion](https://steamcommunity.com/app/2321470/discussions/0/5374541530377856353/?ctp=2), [20 Minutes Till Dawn review](https://www.keengamer.com/articles/reviews/pc-reviews/20-minutes-till-dawn-review-surviving-the-swarm/), [HoloCure aiming](https://www.gfinityesports.com/article/holocure-how-to-aim)
- Readability and game feel: [TV Tropes: Danmaku](https://tvtropes.org/pmwiki/pmwiki.php/Main/Danmaku), [shmups forum on hitboxes](https://shmups.system11.org/viewtopic.php?p=1405669), [Wayline: game feel and juice](https://www.wayline.io/learn/game-feel/1), [Mega Cat juice guide](https://megacatstudios.com/blogs/game-development/mega-cat-developer-juice-guide-v1-0-08-23-17)

**Caveats:** sales numbers are from press releases and third-party estimates. VaporLens sentiment is an AI summary of recent reviews, so its counts show how often a theme comes up, not exact percentages. Forum quotes are anecdotes; they're only used here where several games show the same pattern.
