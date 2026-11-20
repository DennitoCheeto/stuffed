class_name StitchUp
extends Resource
## Sewing Storm's stitch-up (spec 10 §3): flung needles trail thread; a moment later the threads
## pull tight, dragging every zombie a needle passed through towards the hero and hitting it
## again when they snap. Tune it in data/weapons/sewing_storm.tres.

## Seconds after the fling starts until the threads pull tight.
@export var pull_delay: float = 0.6
## Push towards the hero on the snap, in pixels per second (like knockback).
@export var pull: float = 520.0
## Damage of the snap hit (times the hero's damage bonus).
@export var snap_damage: float = 14.0
## The thread: colour (soft, never a danger colour), width in pixels, and how far apart the
## recorded points of a needle's path are.
@export var thread_color: Color = Color(0.776, 0.914, 1, 0.7)
@export var thread_width: float = 2.0
@export var point_gap: float = 12.0
## Seconds the pulled-tight thread takes to whip back to the hero and vanish.
@export var snap_seconds: float = 0.15
## Pitch of the snap sound (the storm's own sound, higher).
@export var snap_pitch: float = 1.7
