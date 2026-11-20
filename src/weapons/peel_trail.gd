class_name PeelTrail
extends Resource
## Banana Split's peel trail (spec 10 §3): a split peel that hits a zombie drops a slippery peel
## there; zombies that step on it slip and are stunned, like Banane's Slippery. Tune it in
## data/weapons/banana_split.tres.

## At most this many of one hero's peels lie on the floor; a new one takes the oldest one's place.
@export var max_peels: int = 6
## Seconds a peel stays on the floor if nobody steps on it.
@export var lifetime: float = 5.0
## Seconds after landing before it gets slippery (so it lands first, then trips the next zombie).
@export var arm_seconds: float = 0.3
## Seconds a zombie is stunned after slipping.
@export var stun: float = 1.0
## Radius of the slippery area, in pixels (grows with Big Spool).
@export var radius: float = 20.0
## The peel is drawn this many times the size of a thrown peel.
@export var size: float = 1.0
## How see-through it is on the floor (1 = solid).
@export var alpha: float = 0.85
