class_name Snowmen
extends Resource
## Snow Day's snowmen (spec 10 §3): every snowball landing builds a snowman; zombies nearby walk to
## it and crowd around it, then it bursts and freezes them. Tune it in data/weapons/snow_day.tres.

## At most this many of one hero's snowmen stand at once (a landing builds none while full).
@export var max_snowmen: int = 3
## Seconds a snowman stands before it bursts.
@export var lifetime: float = 4.0
## Zombies within this many pixels walk to it instead of the heroes (bosses don't).
@export var lure_reach: float = 220.0
## They stop this far from its middle (plus their own size), crowding around it.
@export var stand_off: float = 18.0
## The burst: radius, damage, how long it freezes zombies, and the share of that for bosses.
@export var burst_radius: float = 95.0
@export var burst_damage: float = 20.0
@export var freeze_seconds: float = 1.5
@export var boss_freeze_share: float = 0.3
## Seconds it takes to pop up (it grows from the ground) and to wobble before it bursts.
@export var build_seconds: float = 0.25
@export var wobble_seconds: float = 0.5
## Pitch of the burst sound.
@export var burst_pitch: float = 1.0
