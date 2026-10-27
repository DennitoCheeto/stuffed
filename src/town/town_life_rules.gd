class_name TownLifeRules
extends Resource
## Small ambient motion in the Pillow Fort (spec 05 §3.4): soft sunbeams with dust sparkles
## drifting in them, and now and then a paper plane gliding over the town. Tune it in
## data/town/town_life_rules.tres. (Flags and bunting flutter in the building shader: numbers in
## data/art/world_palette.tres.)

@export_group("Sunbeams")
## Where each beam starts at the top of the quilt (x in town pixels); it slants down to the right.
@export var sunbeam_starts: PackedFloat32Array = [500.0, 1500.0]
@export var sunbeam_width: float = 240.0
## How far a beam moves right for every pixel it goes down.
@export var sunbeam_slant: float = 0.35
## Share of the palette's sunbeam strength used in town (the town is already bright).
@export_range(0.0, 1.0) var sunbeam_strength: float = 0.45

@export_group("Dust sparkles")
@export var sparkles_per_beam: int = 12
## Biggest sparkle (pixels, star radius).
@export var sparkle_size: float = 5.0
## How fast they drift up the beam (pixels per second) and how fast they twinkle (per second).
@export var sparkle_drift: float = 12.0
@export var sparkle_twinkle: float = 0.5

@export_group("Paper plane")
## The first plane comes this many seconds after arriving, then one every few seconds in between.
@export var plane_first_at: float = 8.0
@export var plane_min_gap: float = 20.0
@export var plane_max_gap: float = 40.0
@export var plane_speed: float = 280.0
## Its length (pixels), how high it flies over its shadow, and how far it bobs up and down.
@export var plane_size: float = 34.0
@export var plane_height: float = 80.0
@export var plane_bob: float = 22.0
