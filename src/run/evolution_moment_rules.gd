class_name EvolutionMomentRules
extends Resource
## Numbers for the evolution moment (spec 10 §3): the sewing reveal on the gift box screen and
## what happens back in the run. Tune them in data/ui/evolution_moment.tres.

@export_group("Sewing reveal (gift box screen)")
## Seconds of "weapon + item → sewn together → evolved weapon → EVOLVED!" (any key skips).
@export var reveal_seconds: float = 1.5
@export var stamp_text: String = "EVOLVED!"
## How far apart the two icons start (pixels from the middle) and where they meet.
@export var icon_start_x: float = 280.0
@export var icon_meet_x: float = 70.0
## How many stitches the needle sews between them.
@export var stitches: int = 5

@export_group("Back in the run (first time per evolution kind per run)")
## Real seconds of slow motion and how slow (0.3 = 30% speed). Reduced motion skips it.
@export var slow_seconds: float = 0.4
@export var slow_scale: float = 0.3
## The ring that pulses out from the hero.
@export var pulse_seconds: float = 0.6
@export var pulse_radius: float = 260.0
@export var pulse_width: float = 8.0
@export var pulse_color: Color = Color("#f2c230")
## The first attack is drawn this much bigger, easing back to normal over `big_attack_seconds`.
@export var big_attack_scale: float = 1.5
@export var big_attack_seconds: float = 0.5
