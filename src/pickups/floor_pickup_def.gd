class_name FloorPickupDef
extends Resource
## One kind of floor pickup (spec 02b §3): its name, banner, sound and how often it drops.
## Lives inside data/floor_pickup_rules.tres.

## What the run does when it is grabbed (e.g. &"magnet"); also picks its felt look.
@export var id: StringName = &""
@export var display_name: String = ""
## Big banner text when grabbed, e.g. "BIG MAGNET!".
@export var banner: String = ""
## Small line under the banner that says what just happened.
@export var banner_subtitle: String = ""
## How likely this kind is compared to the others (40 vs 30 = a bit more often).
@export var weight: float = 1.0
## Sound from SfxBank played when it is grabbed.
@export var sound: StringName = &""
