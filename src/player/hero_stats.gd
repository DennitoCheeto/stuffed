class_name HeroStats
extends Resource
## Balance numbers for one hero. Tune them in data/heroes/*.tres, not in code. The heroes in
## pick order live in data/heroes/hero_roster.tres (HeroRoster, spec 08).

## Saved per player slot in TownSave.heroes, e.g. "pip". Never change it.
@export var id: StringName = &""
@export var display_name: String = "Hero"
## The rescued plushie this hero is (null = Banane, always playable). Freeing that plushie in
## the Bedroom unlocks the hero (spec 08 §4).
@export var plushie: PlushieDef
@export var max_health: float = 100.0
## Pixels per second.
@export var move_speed: float = 150.0
## How far one dash carries the hero, in pixels.
@export var dash_distance: float = 120.0
## How long the dash burst lasts, in seconds. The hero can't be hurt during it.
@export var dash_duration: float = 0.15
## Seconds from the start of one dash until the next dash is possible.
@export var dash_cooldown: float = 1.5
## Seconds the hero can't be hurt again after taking a hit.
@export var hurt_invulnerability: float = 0.5
## Radius of the real hitbox (smaller than the drawing).
@export var hitbox_radius: float = 12.0
## XP buttons closer than this (pixels) fly to the hero.
@export var pickup_range: float = 60.0
## The weapon the hero starts every run with.
@export var starting_weapon: WeaponStats
## A new weapon this hero brings (Snowball Toss, Paw Swat): it joins the level-up cards for
## every hero once this hero is unlocked (spec 08 §3). Null = none.
@export var unlocks_weapon: WeaponStats

@export_group("Slippery (Banane's passive)")
## Every dash drops a banana peel where it started (off for heroes without the passive).
@export var slippery: bool = false
## Seconds a peel stays on the floor if nobody steps on it.
@export var peel_lifetime: float = 4.0
## Seconds a zombie is stunned after slipping.
@export var peel_stun: float = 1.0
## Peels on the floor at once (the oldest goes when a new one would be too many).
@export var peel_max: int = 3
## Radius of a peel's slippery area, in pixels.
@export var peel_radius: float = 18.0

@export_group("Chilly Hug (Pip's passive)")
## Zombies close to the hero move slower; shown as a soft frost ring (spec 08 §3).
@export var chilly_hug: bool = false
## How close (pixels from the hero's middle).
@export var chilly_radius: float = 90.0
## How much slower (0.3 = 30%); bosses get `chilly_boss_slow` instead.
@export var chilly_slow: float = 0.3
@export var chilly_boss_slow: float = 0.15
## The frost ring on the floor: colour, and how fast it breathes (per second).
@export var chilly_ring_color: Color = Color(0.72, 0.86, 0.98, 0.35)
@export var chilly_ring_pulse: float = 0.6

@export_group("Puppet (plushie heroes)")
## How tall the hero puppet is, feet to the top of the head, in pixels (Banane is about 75).
@export var puppet_height: float = 72.0
## The town walk (PlushieGait) runs this much faster on a hero, who moves faster than a plushie
## strolling around the fort.
@export var walk_speedup: float = 1.5
## How fast the walk eases in and out when the hero starts and stops (1 / seconds).
@export var stride_blend_speed: float = 6.0

@export_group("Wardrobe (spec 08 §5)")
## The passive's name and what it does, in one line for the hero picker.
@export var passive_name: String = ""
@export var passive_text: String = ""
## One strength and one weakness, shown as two small tags.
@export var strength: String = ""
@export var weakness: String = ""
## The banner's subtitle the first time this hero is unlocked, e.g. "Try her on at the
## Wardrobe." (its title is WardrobeRules.unlock_title).
@export var try_on_text: String = ""
## Banane only: how he lives in town while someone else is played (a PlushieDef with the
## BANANE shape: his hero puppet walks around). Plushie heroes use `plushie`.
@export var town_member: PlushieDef
