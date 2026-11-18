# 08 — Playable plushies

Status: **DRAFT** (spec PR, waiting for the PO).
Milestone: **M5 — The plushie heroes** (after M4 Night siege; M4.5 Equipment comes later, PO choice 2026-11-18).
Based on: vision §5 ("Heroes"), §6.3 (sideways unlocks), §7 (local co-op), the PO decision of 2026-10-24
("rescued plushies become playable heroes, rescue = unlock"), research
[`04-hero-variety-research.md`](../research/04-hero-variety-research.md) and the PO answers of 2026-11-18 (hero kits,
a Wardrobe by the fort, hero's own weapon by default, one of each hero in co-op).

## 1. Goal

One question: **when I rescue a plushie, do I want to play as it right away?**

After this spec:

- the four rescued plushies (**Pip, Böbö, BamBam, Robbar**) are playable heroes; rescuing one and bringing it
  home unlocks it,
- each hero plays differently: **its own starting weapon, one passive that changes a rule, one clear strength and
  one clear weakness**,
- you pick your hero at a **Wardrobe next to the fort**; the hero you swap out (Banane too) becomes a town member,
- the heroes walk like real puppets (the `PlushieGait` walk from #147: feet, arm swing, Böbö's waddle, Robbar's hop).

Not in this spec: equipment (M4.5), new heroes beyond the four, evolutions for the two new weapons (evolution
"wow" pass), hero levels or hero-only upgrade trees, active special attacks on a button.

## 2. What the player experiences

1. You free Pip in the Bedroom. That unlocks her as a hero right away (PO answer 2026-11-18); the Plush Hospital
   and moving in work as today.
2. The first time you come home with a freed plushie, a felt **Wardrobe** pops up next to the fort door with a banner:
   **"Pip wants to play! Try her on at the Wardrobe."**
3. E at the Wardrobe opens the **hero picker**: one photo per hero (Banane first), with name, weapon, passive and a
   strength/weakness line. Heroes you haven't rescued yet are felt silhouettes: **"Rescue me in the Bedroom"**.
4. Pick Pip: a puff of stuffing, and you *are* Pip in the town. Banane hops out of the Wardrobe and wanders the
   town like the other plushies.
5. The fort door starts the run as Pip, with her own weapon and passive. The siege uses her too.
6. The choice is saved: next time you open the game you're still Pip. Swap back any time at the Wardrobe.
7. In co-op both players use the Wardrobe; a hero player 1 plays is shown as **"Player 1 plays Pip"** and can't be
   picked twice.

## 3. The heroes (first numbers, tuned in the playtest; all in `data/heroes/<id>.tres`)

| Hero | Starting weapon | Passive (the rule it bends) | Strength | Weakness |
|------|-----------------|-----------------------------|----------|----------|
| **Banane** (as today) | Peel Boomerang | **Slippery:** every dash leaves a peel; zombies slip | easy, all-round | none, the baseline |
| **Pip**, round polar bear in a scarf | **Snowball Toss** (new) | **Chilly Hug:** zombies close to Pip move slower | crowd control | low damage |
| **Böbö**, big chonky bear | **Paw Swat** (new) | **Bear Hug:** the dash is a shoulder charge that shoves zombies away; takes less damage | most health | slowest hero |
| **BamBam**, long proper bear with a heart | Sewing Pin Sniper | **Big Heart:** every level-up heals him and pushes zombies back (heals co-op partners nearby too) | steady healing | small pickup range |
| **Robbar**, smol chubby seal | Bouncy Yarn Ball | **Belly Slide:** the dash is a long slide that hits zombies on the way, shorter cooldown | fastest, tiny hitbox | least health |

First guesses (all in data):

- **Pip:** health 100, speed 150. Snowball Toss: every ~1.4 s lobs a snowball at the nearest group; it bursts in a
  small area (~50 px), low damage, slows hit zombies ~40% for ~1.5 s. Chilly Hug: zombies within ~90 px move ~30%
  slower (bosses ~15%), shown as a soft frost ring around her.
- **Böbö:** health 150, speed 125, dash cooldown 1.8 s. Paw Swat: every ~1.1 s a wide swipe (~120°, ~70 px) in the
  direction he faces, good damage, small knockback. Bear Hug: zombies in the dash path are shoved ~80 px and take a
  little damage; he takes ~20% less damage from everything.
- **BamBam:** health 100, speed 145, pickup range 45 (Banane 60). Big Heart: each level-up heals ~25% max health
  for him and every hero within ~250 px, and a heart pulse pushes zombies within ~150 px back.
- **Robbar:** health 70, speed 175, hitbox 9 (Banane 12), dash cooldown 1.0 s. Belly Slide: a ~180 px slide over
  ~0.3 s; each zombie on the way takes a small hit once per slide; can't be hurt while sliding (like any dash).

Rules:

- A passive is active the whole run (an aura, the dash, level-ups), so the shared card pool never washes it out.
- Item and trick bonuses work for every hero the same way (e.g. Snack Bar's Spare Stuffing, Party Shop's Confetti
  Rush). Banane's Slippery stays Banane's.
- The two **new weapons** (Snowball Toss, Paw Swat) work like every other weapon: levels 1-5 in a `.tres`, own sound,
  shot look, card icon, card text, Scrapbook page. They join the level-up cards **for every hero** once that hero is
  unlocked (rescuing Pip also brings Snowball Toss to the cards, a sideways unlock). No evolution for them yet.

## 4. Unlocking

- A hero is playable once its plushie is **freed in the Bedroom** and the run is banked (any entry in
  `TownSave.plushies`, "waiting" in the tent or "in_town"; PO answer 2026-11-18). Rescue rules don't change.
- A plushie you play is not also in the tent or the town; if you swap away from a plushie still waiting for the
  Hospital, it goes back to the tent.
- The Wardrobe appears on the first arrival home with an unlocked plushie (vision §6.9: reveal when needed), with
  the banner above.
  Each later unlock shows a short banner **"Böbö wants to play!"**.
- Banane is always playable.

## 5. The Wardrobe (town)

- A felt wardrobe (Sunny-patchwork kit, `BuildingSketch` like the buildings) at a fixed spot next to the fort door,
  position in `pillow_fort.tres`. Not a building: no level, no price, no siege role, zombies ignore it.
- **E** at it opens the **hero picker** (`SewnButton` photo tiles like the Armory's weapon picker, a `FeltPanel`,
  arrow keys / mouse / 1-5, Esc closes). Each tile: hero photo (the hero puppet in a `PhotoFrame`), name, weapon icon,
  passive in one line, strength / weakness as two small tags. Locked tiles: silhouette + "Rescue me in the Bedroom".
- Picking swaps the hero **in the town at once** (stuffing puff + pop sound, hero ring stays the player's colour).
- **Town members:** the hero you're *not* playing lives in town like the other moved-in plushies (walks, sits,
  waves, hangout spots). That includes Banane, who gets a town-plushie walk with his puppet. The plushie you *are*
  playing does not also wander around.
- Tests can open it with `town.wardrobe.open(by)`.

## 6. Hero puppets and walk

- Each hero is a puppet like Banane (separate felt pieces: feet, body, head, arms, face), drawn from the same
  look as its town plushie (`PlushieLook` shapes and colours), at the hero size.
- The walk comes from the plushie's **`PlushieGait`** (#147): feet in turn, arm swing, body bob; Böbö's big tilt =
  waddle; Robbar's `HOP` = hop with squash and stretch. Same ease-in/out when starting and stopping.
- Every hero has the clarity basics of #172: the zombies' ink outline and the coloured `HeroMarker` ring. Böbö's
  brown counts as a danger colour, so heroes use calmed colours (`PlushieDef.calmed()`, as plushies in runs do).
- Hurt flash, dash pose, fall and stand-up (siege) work for every hero like for Banane.

## 7. Weapons from the Armory (PO answer 2026-11-18)

- Every hero starts with **its own weapon** by default.
- The maxed Toy Box Armory's weapon picker gets a first tile **"Hero's own weapon"** (the default; the saved
  `start_weapon` stays empty). Picking another weapon replaces the hero's own weapon for every hero, as today.

## 8. Co-op (hard rule 11)

- Each player picks at the Wardrobe with their own keys; the choice is saved **per player slot**.
- **One of each:** a hero another player plays shows "Player 1 plays Pip" and can't be picked. If player 2 joins and
  their saved hero is taken, they get the first free one.
- Big Heart heals every hero nearby; Chilly Hug slows zombies near Pip for everyone's benefit.

## 9. Siege

- You defend the fort as your hero.
- The **siege helpers** are the moved-in plushies you're *not* playing, plus Banane when someone else plays: they
  stand by the fort and throw stuffing balls (spec 07 §4) and get revived by the Plush Hospital as before.

## 10. Save (hard rule 10)

- `TownSave` v6: `heroes` = hero id per player slot (`["pip"]`, `["pip", "bobo"]`). Older saves load as Banane.
- A test saves, reloads and compares the hero choice; another loads a v5 save.

## 11. Scrapbook, end screen, log

- Scrapbook plushie pages get a line "Plays with: Snowball Toss · Chilly Hug" once unlocked; the two new weapons
  get weapon pages by themselves.
- End screen: the "Star of the run" photo and the weapon column header show the hero played.
- Run log: field `hero` per player (runs and sieges).

## 12. Developer menu

- Town dev menu: **"Unlock all heroes"** (moves every plushie in) and **"Next hero"** (cycles player 1's hero).
- Run dev menu: shows the hero's name; `give` works for the new weapons.

## 13. Readability and performance (vision §6.1, §6.7)

- New hero effects (frost ring, snowballs, paw swipe, heart pulse, slide trail) are quiet: no danger colours, less
  contrast than zombies, in the trick/siege colour sweeps (`color_sweep.gd`).
- `test_hero_clarity.gd` covers every hero against every Bedroom, town and dusk floor colour.
- Draw cost: each hero puppet costs no more than Banane's (+ a few draw calls); the benchmark with each hero stays
  within ~5% of Banane on draw calls.

## 14. Acceptance criteria

- **AC-85** A plushie freed in the Bedroom is playable once the run is banked; the Wardrobe appears with the first one (banner); locked heroes
  show as silhouettes with "Rescue me in the Bedroom"; Banane is always playable.
- **AC-86** E at the Wardrobe opens the hero picker; picking swaps the hero in the town at once; the swapped-out
  hero (Banane too) becomes a town member; the next run and siege use the picked hero.
- **AC-87** Each hero starts with its own weapon and its stats from data (one scenario per hero).
- **AC-88** Each passive does what §3 says (one scenario each: Chilly Hug slows, Bear Hug shoves and cuts damage,
  Big Heart heals and pushes on level-up, Belly Slide hits zombies during the dash).
- **AC-89** Snowball Toss and Paw Swat level up 1-5, have their own sound, card icon and Scrapbook page, and appear
  on the cards for every hero once their hero is unlocked.
- **AC-90** Hero puppets walk with their plushie's gait (step, waddle, hop), have the ink outline and hero ring, and
  pass the hero clarity test on every floor.
- **AC-91** In co-op each player picks their own hero, no hero twice; siege helpers are the plushies not being
  played (and Banane when not played).
- **AC-92** The hero choice is saved per player and comes back after closing and reopening the game (save, reload,
  compare); a v5 save loads as Banane.
- **AC-93** No hero effect uses a danger colour; zombies stay the strongest contrast.
- **AC-94** The hero picker fits every window size of the fit check; draw calls per hero stay within ~5% of Banane.
- **P-32** (playtest) Each hero feels different within the first minute of a run.
- **P-33** Rescuing a plushie makes you want to play as it.
- **P-34** The Wardrobe swap is clear and fun; you know what each hero is good and bad at before picking.

## 15. Open questions (my proposal in bold; approving the spec means "yes" to all)

1. Hero kits: **the four in §3** (PO said yes 2026-11-18).
2. Picking: **a Wardrobe next to the fort door; swapped-out heroes become town members** (PO idea 2026-11-18).
3. Armory: **hero's own weapon by default, the Armory picker can still override it** (PO said yes).
4. Co-op: **one of each hero** (PO said yes).
5. New weapons for everyone: **Snowball Toss and Paw Swat join everyone's cards once their hero is unlocked** (PO
   said yes).
6. Unlock moment: **when the plushie is freed in the Bedroom** (PO answer 2026-11-18).

## 16. Not in this spec

Equipment and the Sewing Workshop (M4.5), more heroes, evolutions for Snowball Toss / Paw Swat, hero levels or
hero skill trees, active special attacks, voice lines, building interiors.

## 17. Proposed tickets (after approval)

1. Hero data (`HeroStats` per hero, passive numbers) + `TownSave` v6 + unlock rule + dev menu — AC-85 (rule), AC-92
2. Hero puppets from plushie looks + `PlushieGait` walk, outline, ring, clarity test — AC-90
3. Wardrobe + hero picker + swap in town; swapped-out heroes (Banane too) as town members — AC-85, AC-86
4. Pip: Snowball Toss + Chilly Hug — AC-87, AC-88, AC-89
5. Böbö: Paw Swat + Bear Hug — AC-87, AC-88, AC-89
6. BamBam: Big Heart — AC-87, AC-88
7. Robbar: Belly Slide — AC-87, AC-88
8. Co-op picking, siege helpers, Armory "Hero's own weapon" tile, end screen / Scrapbook / log — AC-91
9. Readability + performance + fit check — AC-93, AC-94
