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

## Share of every hit the hero takes (Böbö's Bear Hug: 0.8 = 20% less). Thick Felt lowers it more.
@export var damage_taken: float = 1.0

@export_group("Bear Hug (Böbö's passive)")
## The dash is a shoulder charge: zombies it touches are shoved away and take a little damage
## (once per dash each).
@export var bear_hug: bool = false
## How far from the hero's middle the charge reaches (pixels).
@export var bear_hug_reach: float = 34.0
## How hard it shoves (like a weapon's knockback) and how much it hurts.
@export var bear_hug_shove: float = 260.0
@export var bear_hug_damage: float = 6.0

@export_group("Big Heart (BamBam's passive)")
## Every level-up heals the hero and every hero nearby, and a heart pulse pushes zombies back.
@export var big_heart: bool = false
## Share of each hero's max health healed, and how close other heroes must be (pixels).
@export var big_heart_heal: float = 0.25
@export var big_heart_heal_reach: float = 250.0
## How far the pulse reaches and how hard it pushes (like a weapon's knockback).
@export var big_heart_push_reach: float = 150.0
@export var big_heart_push: float = 320.0
## The pulse ring: colour and how long it grows and fades (seconds).
@export var big_heart_color: Color = Color(0.96, 0.66, 0.78, 0.8)
@export var big_heart_seconds: float = 0.5

@export_group("Belly Slide (Robbar's passive)")
## The dash is a long belly slide (set `dash_distance` / `dash_duration`): every zombie on the way
## takes a small hit, once per slide.
@export var belly_slide: bool = false
## How far from the hero's middle the slide hits (pixels) and how much.
@export var belly_slide_reach: float = 26.0
@export var belly_slide_damage: float = 10.0
## The wet streak the slide leaves for a moment: colour and how long it stays (seconds).
@export var belly_slide_trail_color: Color = Color(0.7, 0.86, 0.95, 0.55)
@export var belly_slide_trail_seconds: float = 0.5

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
