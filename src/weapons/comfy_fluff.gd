class_name ComfyFluff
extends Resource
## Comfy Cloud's fluff trail and mend (spec 11 §4.3): while the hero walks, a puff of fluff drops
## behind them; puffs hurt the zombies inside on the cloud's beat. Each zombie the cloud or a puff
## pops mends the cloud's own hero a little. Tune it in data/weapons/comfy_cloud.tres.

## A puff drops every this many seconds of walking.
@export var drop_every: float = 0.4
## The hero counts as walking above this speed, in pixels per second.
@export var walk_speed: float = 20.0
## How long one puff stays on the floor, in seconds.
@export var puff_seconds: float = 3.0
## On-screen radius of a puff (60 px wide = 30).
@export var puff_radius: float = 30.0
## Damage to every zombie inside a puff, on each of the cloud's puffs (its beat).
@export var puff_damage: float = 5.0
## At most this many puffs per Comfy Cloud (the oldest one goes).
@export var max_puffs: int = 8
## How a puff looks: see-through (the player's own effects stay quiet), fading out at the end,
## growing in from this share of its size when it drops.
@export var puff_opacity: float = 0.45
@export var fade_seconds: float = 0.5
@export var grow_from: float = 0.6
@export var grow_seconds: float = 0.15
## Health mended per zombie popped inside the cloud or a puff, and at most this much per second.
@export var mend_per_kill: float = 1.0
@export var mend_per_second: float = 4.0
## The little stitch sparkle that floats up from the hero on a mend.
@export var mend_color: Color = Color(0.78, 0.93, 0.8, 0.8)
@export var mend_seconds: float = 0.6
@export var mend_rise: float = 30.0
@export var mend_size: float = 5.0
