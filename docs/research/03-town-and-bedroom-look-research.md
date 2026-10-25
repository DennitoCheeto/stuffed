# Research 03 — A town and a Bedroom that look inviting

_2026-10-25. Input for spec 05 (town + Bedroom visual pass). Trigger: M2 + M3 playtest, PO: the town is
"still not too appealing", everything is "a tiny bit dark"._

## 1. What we have today (screenshots of build `fd9203f`)

| Place | What the eye sees | Why it feels off |
|-------|-------------------|------------------|
| **Bedroom** (run) | A near-black purple checkerboard (`#2b2733` / `#302b39`), a dark brown oval rug, a few small toy-block piles, a bed and toy box at the far edges | It doesn't read as a *room*: no walls, no light, no big furniture on screen. Most of the 4 × 4-screen floor is empty. The dark ground is the main reason for "a tiny bit dark" |
| **Town** (Pillow Fort) | A navy plaid blanket (`#34405a`), seven small houses with the same shape (pentagon roof, door), pillow walls, two lamps whose "glow" is a grey disc | Buildings are small (260 × 180 px) and all look alike, so the town has no landmarks. Lots of empty blanket between them. The lamp glow reads as grey fog, not light. Every building shows 3 lines of text at all times, which makes it look like a menu rather than a place |

What already works and must stay: the felt pieces themselves (buildings, plushies, zombies), the build moment, the
fort growing, plushies walking around, the "Stitched Scrapbook" UI.

## 2. What other games do

| Game | What people like | Lesson for Stuffed | Source |
|------|------------------|--------------------|--------|
| **Tinykin** | A whole house seen "from a bug's-eye view": furniture becomes landscape, "the house is the real star". Each room has **its own palette** (warm browns in the music room, blues in the bathroom). Reviewers call it bright, "a Saturday morning cartoon" | Our Bedroom should look like a *giant* room: huge furniture, floorboards, a rug as big as a field. Different parts of the floor can have their own colours, so you always know where you are | PC Gamer, Maxi-Geek, GodisAGeek reviews |
| **It Takes Two** (Rose's room) | Toys and objects from the room become the level; reviewers praise how the light and depth of a space set the mood | Light (a window, a lamp) is what makes a room feel like a room | Reviews, architecture critique |
| **Cult of the Lamb** | The base is "the safe, cute space"; the world outside is the creepy part. Clean, icon-like 2D shapes that stay readable | Our town is the safe space: it can be the warmest, brightest place in the game. The Bedroom can be a little moodier, but never murky | Interviews (Stevivor, Devolver) |
| **Cozy town games** (Animal Crossing, Stardew, Hokko Life) | The cozy feeling comes from **visible change** (empty plots → lived-in village), small life everywhere (villagers, events), warm light sources and many small decorations | Each building needs its own silhouette so you notice it grow. Decorations and life fill the gaps between buildings | Roundups, reviews |
| **Bullet heavens** (Brotato, Vampire Survivors) | Brotato's single bland map is a common complaint. Shmup developers: bullets and enemies need clear contrast to the ground; a busy or similar-coloured ground hides danger | The ground can be lighter and prettier, as long as it stays **low-contrast and calm**; danger (zombies, enemy bullets) keeps the strongest contrast (vision §6). A dark outline on zombies keeps them readable on a lighter floor | TrueAchievements reviews, itch.io dev threads |

## 3. What this means for Stuffed

1. **Brighter isn't the same as busier.** The ground can move from near-black to a mid or light tone, as long
   as its own pattern stays soft (small value steps). Zombies and enemy bullets keep the strongest contrast, helped
   by a dark outline and a contact shadow. We check this with the same "danger first" rule as spec 04 (AC-51).
2. **Light sources make it cozy.** A window with a sun patch, a lamp, fairy lights. Real light pools (warm, a bit
   brighter) instead of grey discs.
3. **Scale tells the story.** We are toys: furniture should be *huge* (a bed corner bigger than the screen, crayons
   like tree trunks, a book like a hill). Today's furniture is drawn at "map icon" size.
4. **Every building gets its own silhouette**, made from a household or sewing object (toy box, glass jar, cookie
   tin, cotton-reel tower, gift box, tissue-box hospital, book). Then you recognise a building at a glance and
   see it change when you build.
5. **Fill the gaps with small life**: paths (ribbon or stitched trails), little props, plushies, sparkles. Make the
   town a bit more compact, so the camera always sees something nice.
6. **Text only when it's useful.** Names and costs show when you walk up to a building (the card already does
   this), not as three lines under every house all the time.
7. **Parts of the Bedroom feel different** (rug, floorboards, under the bed, by the window), so a run has places,
   not just an endless floor.
8. **Performance stays first** (spec 02 §14): big new pieces are drawn once (baked), never redrawn every frame.

## 4. Look options (PO to choose in spec 05)

Shown on the mockup canvas (town + Bedroom for each, with zombies to judge readability):

- **A — Sunny Saturday:** daylight. Honey-coloured floorboards, a big soft rug, sun patches from a window, huge
  furniture at the edges. Town on a pastel patchwork quilt in the sun; buildings made from household objects.
  Brightest and most cheerful.
- **B — Night-light glow:** cozy evening, but lifted: dusky lavender instead of near-black, warm pools of lamp light,
  fairy lights and glowing windows in town. Closest to today's mood; least "different".
- **C — Sewn diorama:** everything is fabric. The Bedroom floor is a giant patchwork rug (gingham, corduroy,
  polka-dot patches sewn together, each patch a "zone"); the town sits on a sewing/cutting mat with buildings
  made from sewing things (cotton reels, tomato pincushion, thimble, button roofs). Most "on theme" with the
  felt style and the Stitched Scrapbook UI.

A mix is possible (for example A's daylight Bedroom with C's sewn town).

## Sources

- [Tinykin review (PC Gamer)](https://www.pcgamer.com/tinykin-review/)
- [Tinykin review (Maxi-Geek)](https://www.maxi-geek.com/con/tinykin-review)
- [Tinykin review (GodisAGeek)](https://godisageek.com/reviews/tinykin-review/)
- [Tinykin review (Checkpoint Gaming)](https://checkpointgaming.net/reviews/2022/09/tinykin-review-a-little-insect-as-a-treat/)
- [It Takes Two review (Xbox Tavern)](https://www.xboxtavern.com/it-takes-two-review/)
- [It Takes Two, an architecture critique](https://modarchcrit.substack.com/p/it-takes-two)
- [Cult of the Lamb preview (Stevivor)](https://stevivor.com/previews/cult-lamb-preview-aussie-made-diabolical/)
- [Cult of the Lamb art director interview (DreadXP)](https://www.dreadxp.com/?p=27832)
- [Cult of the Lamb x Don't Starve interview (Devolver)](https://www.devolverdigital.com/blog/post/Cult-of-the-Lamb-Dont-Starve-Together-Crossover-but-make-it-an-interview)
- [Cozy games like Animal Crossing and Stardew (TheGamer)](https://www.thegamer.com/games-perfect-mix-animal-crossing-stardew-valley/)
- [Brotato reviews (TrueAchievements)](https://www.trueachievements.com/game/Brotato/reviews)
- ["Stage 4's background should be a different color" (itch.io)](https://itch.io/t/836959/stage-4s-background-should-be-a-different-color)
- [Game art colour theory (Pixune)](https://pixune.com/?p=23264)
