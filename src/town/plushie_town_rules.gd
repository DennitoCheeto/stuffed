class_name PlushieTownRules
extends Resource
## Rescued plushies at home (spec 03 §7): how they walk, sit and wave in the Pillow Fort, the
## stitch-up moment when they move in, and the coins they add to every run. Tune it in
## data/town/plushie_town_rules.tres, not in code. Hospital beds per level live on the Plush
## Hospital's BuildingLevel.plushie_beds.

## Extra share of coins brought home per plushie living in town (0.05 = +5%; 4 = +20%).
@export var coin_bonus_per_plushie: float = 0.05
## Drawing size in town (PlushieLook `size`, pixels; a plushie is about 3.2x this tall).
@export var size: float = 24.0
## Walking speed (pixels per second).
@export var walk_speed: float = 70.0
## How far a walk goes at most (pixels).
@export var walk_distance: float = 520.0
## A standing pause between walks lasts this long (seconds, picked at random in between).
@export var idle_min_seconds: float = 1.2
@export var idle_max_seconds: float = 3.5
## How likely the next walk goes to a cushion to sit on it.
@export var sit_chance: float = 0.3
## Sitting on a cushion lasts this long (seconds, picked at random in between).
@export var sit_min_seconds: float = 4.0
@export var sit_max_seconds: float = 9.0
## A player closer than this makes it stop and wave (pixels).
@export var wave_radius: float = 170.0
## One wave lasts this long (seconds), then it waits this long before it waves again.
@export var wave_seconds: float = 1.6
@export var wave_cooldown: float = 6.0
## Walks keep at least this far from buildings and walls (pixels).
@export var keep_clear: float = 40.0
## How many pixels it bobs up and down while walking.
@export var bob_pixels: float = 4.0
## How likely the next walk goes to a free hangout spot (reading, table, nap, lookout).
@export var spot_chance: float = 0.35
## Hanging out at a spot lasts this long (seconds, picked at random in between).
@export var spot_min_seconds: float = 6.0
@export var spot_max_seconds: float = 14.0
## Climbing up to (or down from) a spot like the Watchtower lookout (pixels per second).
@export var climb_speed: float = 160.0
## The stitch-up moment when a plushie moves in (seconds).
@export var stitch_seconds: float = 1.3
## Banner when plushies move in ("%s" = the names) and its subtitle ("%d" = coin bonus in %).
@export var moved_in_banner: String = "%s moved in!"
@export var moved_in_subtitle: String = "Stitched up at the Plush Hospital: +%d%% coins per plushie"
## The tent's sign while plushies wait in it.
@export var waiting_text: String = "Waiting for a Hospital bed"
@export var moved_in_sound: StringName = &"rescued"
## A small squeak when a plushie waves at a player.
@export var wave_sound: StringName = &"hello"
