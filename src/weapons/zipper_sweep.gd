class_name ZipperSweep
extends Resource
## Unzipper's sweep (spec 11 §4.6): the beam splits into two halves that sweep apart to both sides
## over the beam's time, like a zipper opening, then snap shut back to the middle; every zombie a
## half swept over takes the zip-shut hit when they meet. Tune it in data/weapons/unzipper.tres.

## How far each half opens from the middle, in degrees.
@export var open_degrees: float = 50.0
## Share of the beam's time spent opening; the rest it snaps shut (fast).
@export var open_share: float = 0.8
## The zip-shut hit on every swept zombie.
@export var shut_damage: float = 25.0
@export var shut_push: float = 120.0
## Zip-shut sound (a name in SfxBank).
@export var shut_sound: StringName = &"zip_shut"
## The flash along the middle when the halves meet.
@export var seam_color: Color = Color(0.9, 0.97, 0.95, 0.6)
@export var seam_width: float = 10.0
@export var seam_seconds: float = 0.25
