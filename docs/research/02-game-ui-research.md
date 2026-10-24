# Research 02 — Game UI that players enjoy

_2026-10-24. Input for spec 04 (UI and juice). Trigger: M2 + M3 playtest, PO: "the UI feels super basic and
not fun", the end screen is "really bad" (no weapon stats, buttons fall off the screen)._

## 1. What players and critics praise

| Game | What people like | Source |
|------|------------------|--------|
| **Balatro** | "Juice": every click and score has layered feedback. Cards lift and grow a little on hover (~12 px, 1.05×, 0.15 s), bounce with a spring, numbers roll up like slot-machine digits, each scored card plays a higher note, shake grows with the size of the moment, one fixed colour per resource (chips blue, mult red, money gold). Also praised: a clean, simple layout | Crosley design study; GMTK; itch.io players |
| **Hades** | The UI belongs to the world: prompts sit next to the object you use, menus share the game's art style, menus unfold with small animated details. Fun **run-clear titles** for what you did in a run ("Perfect Clear", "Decathlete") | Medium UI/UX case studies; Hades wiki |
| **Vampire Survivors** | Its **results screen** is loved and copied: every weapon with level, total damage, time held and DPS, and the **top weapon highlighted**. Its menus are criticised as "ugly", "placeholder", text spilling out of boxes | VS wiki "Results"; reviews; Steam threads |
| **Brotato** | Players use the per-weapon damage numbers to decide what to invest in. They asked for a **detailed scoreboard at the end of runs** | Patch notes 0.6.1.6; Steam discussion |
| **Halls of Torment** | A UI with a strong theme (Diablo homage: orbs, old fonts) gives the game identity. Criticised: a cluttered screen | Reviews (Rogueliker, Softpedia, Xbox Hub) |
| **Cozy games** (farming / life sims) | Warm frames, cream surfaces, soft colours, hand-made details; the UI "stays out of the way" of the cozy part | Cozy UI articles, UI kits |
| **Persona 5** | Most-named "best menus ever": over-the-top style, every menu has motion and attitude | "Best game UI" lists |

## 2. What this means for Stuffed

1. **Theme beats tidy.** The best UIs look like they belong to their game. Ours should look like **felt and
   sewing**: stitched patches, sewn-on buttons, fabric tags and labels, thread, buttons used as bullet points.
   Today our menus are dark grey rectangles with a gold border, a generic look that fits no particular game.
2. **Juice on everything you touch.** Hover = lift + grow a little + soft sound; press = squish; screens
   arrive with a spring instead of just appearing; numbers count up with rising "plips" (we already have this
   for the haul, so reuse it everywhere).
3. **The end-of-run screen is a celebration and a report.** Players want proof of "how crazy my attacks got"
   (M1 playtest): per-weapon damage, kills, DPS, level, evolution marker, and a **"Star of the run"** for the best
   weapon. Add Hades-style **run titles** ("Untouchable!", "Mortar Maniac", "Speedy Stitcher") for fun.
4. **One colour per thing, everywhere.** Coins gold, stuffing cream-white, thread teal (the jar colours), XP green, danger red/orange,
   and keep them the same in the run, end screen and town (vision §6: danger keeps the strongest contrast).
5. **Never spill, never fall off.** Every screen must fit on 1920×1080 and on 16:10, and text never leaves its box.
   Scenario tests check this, so VS's most common UI complaint can't happen to us.
6. **Information at the right place (Hades).** Town prompts float over the building they belong to; tooltips
   appear next to the thing you hover.
7. **Not cluttered.** Readability rule (vision §6) stays: in the run, the HUD is quiet; the loud UI is for menus
   and moments (level-up, gift box, end screen).

## 3. Options for the look (PO to choose in spec 04)

- **A — Sewing box:** felt patches with dashed stitch borders, buttons are big sewn-on buttons, labels are
  fabric tags. Calm and cosy, closest to the art direction "B — Soft".
- **B — Scrapbook:** pages, tape, stickers, hand-written headings, photos of the weapons. Fits the Scrapbook we
  already have; the end screen becomes "today's page".
- **C — Toy-box arcade:** bold, bouncy, bright colours and big numbers, like Balatro/Persona with plush. Most
  exciting, but loudest (careful with readability in the run).

A mix is possible (for example A for menus and B for the end screen and Scrapbook).

## Sources

- [Balatro design study (Blake Crosley)](https://blakecrosley.com/guides/design/balatro)
- [Game Maker's Toolkit on Balatro (transcript)](https://amara.org/videos/qZaMrU6iDy4J/en/4529388)
- [Good Game Feel: framework for juicy design (DiGRA)](https://dl.digra.org/index.php/dl/article/view/936)
- [Hades HUD redesign case study](https://medium.com/@bramhadalvi/hud-redesign-fdc332d05291)
- [UI Noir: Hades](https://medium.com/@donxu29/wip-9e7289c913e4)
- [Hades in the Game UI Database](https://www.gameuidatabase.com/gameData.php?id=534)
- [Hades run-clear messages](https://hades.fandom.com/wiki/Run_Clear_Messages)
- [Vampire Survivors results screen (wiki)](https://vampire.survivors.wiki/w/Results)
- [Vampire Survivors review (Games Asylum)](https://www.gamesasylum.com/2022/11/25/vampire-survivors-review/)
- [Vampire Survivors "UI improvements needed" (Steam)](https://steamcommunity.com/app/1794680/discussions/0/3880471632102389416/)
- [Brotato 0.6.1.6 stats screen](https://www.player.one/brotato-update-0616-improves-stats-screen-implements-gladiator-changes-152839)
- [Brotato "needs a detailed scoreboard" (Steam)](https://steamcommunity.com/app/1942280/discussions/0/685238092472261136/)
- [Halls of Torment review (Rogueliker)](https://rogueliker.com/halls-of-torment-review/)
- [Halls of Torment review (Softpedia)](https://www.softpedia.com/reviews/games/pc/halls-of-torment-review-537631.shtml)
- [Intuitive UI in cozy games](https://sdlccorp.com/post/the-art-of-designing-intuitive-user-interfaces-in-cozy-games/)
- [Top 5 best video game UIs (SuperJump)](https://medium.com/super-jump/top-5-best-video-game-uis-db941d6a9357)
- [Best video game menus (Hardcore Gamer)](https://hardcoregamer.com/best-unique-game-menu-designs/)
