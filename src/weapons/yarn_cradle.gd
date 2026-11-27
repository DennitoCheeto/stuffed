class_name YarnCradle
extends Resource
## Cat's Cradle's unwinding ball (spec 11 §4.1): every bounce stretches a yarn thread from the last
## bounce point to the new one; threads hurt the zombies touching them for a while. The ball also
## snags XP buttons it rolls over and sends them to its hero. Tune it in data/weapons/cats_cradle.tres.

## How long one thread stays on the floor, in seconds.
@export var thread_seconds: float = 2.5
## Damage to every zombie touching a thread, every `thread_interval` seconds.
@export var thread_damage: float = 4.0
@export var thread_interval: float = 0.5
## At most this many threads per Cat's Cradle (the oldest one goes).
@export var max_threads: int = 20
## A zombie this close to a thread (plus its own radius) touches it, in pixels.
@export var thread_reach: float = 6.0
## How a thread looks (soft and see-through: the player's own effects stay quiet).
@export var thread_width: float = 3.0
@export var thread_color: Color = Color(0.86, 0.74, 0.95, 0.6)
## Threads fade out over their last this many seconds.
@export var fade_seconds: float = 0.4
## XP buttons within this many pixels of the ball fly to its hero.
@export var snag_radius: float = 28.0
