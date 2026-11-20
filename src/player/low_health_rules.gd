class_name LowHealthRules
extends Resource
## Numbers of the low-health warning (spec 10 §7, AC-115): when it starts, how fast the heart
## beats and how big the heart patch pulses. No red screen edge: red is the zombies' colour.

## The warning runs while health is below this share of max health (and the hero still stands).
@export_range(0.05, 0.9) var threshold: float = 0.25
## Seconds from one heartbeat to the next.
@export var beat_seconds: float = 0.85
## The pulse of the heart patch fades out over this many seconds after each beat.
@export var pulse_seconds: float = 0.35
## How much bigger the heart patch grows on a beat (0.3 = 30% bigger).
@export var pulse_grow: float = 0.3
## How much lighter the heart's rose gets on a beat (never towards red).
@export var pulse_lighten: float = 0.35
## The heartbeat sound (`SfxBank`).
@export var sound: StringName = &"heartbeat"
