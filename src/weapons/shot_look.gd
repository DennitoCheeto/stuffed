class_name ShotLook
extends Resource
## How an evolved weapon's shots look (spec 02 §20): their own felt part and colour, bigger, a
## soft glitter trail and a sparkle pop on each hit. Soft colours only, never the red/orange of
## enemy danger, and see-through, so enemy bullets always read first (hard rule 9).
## Tune it in the evolved weapon's .tres.

## The shot's felt part in ProjectileLook (drawn instead of the base weapon's part).
@export var part: StringName = &""
## The shot is drawn this many times its normal size.
@export var size: float = 1.3
## Glitter specks left behind: colour (alpha = how see-through), how many float at once per shot,
## and how long each one lasts.
@export var trail_color: Color = Color(1, 1, 1, 0.6)
@export var trail_amount: int = 12
@export var trail_seconds: float = 0.4
## The sparkle pop on a hit: colour, on-screen radius and how long it lasts.
@export var flash_color: Color = Color(1, 1, 1, 0.6)
@export var flash_radius: float = 26.0
@export var flash_seconds: float = 0.22
