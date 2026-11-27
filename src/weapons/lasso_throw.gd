class_name LassoThrow
extends Resource
## Lasso Lash's lasso (spec 11 §4.5): every few lashes the front lash ropes the toughest zombie in
## its arc (an elite first, never a boss), swings it once around the hero, hurting every zombie it
## passes, then flings it towards the hero's cursor, where the snipped thread hurts it. With no
## elite to rope, a boss in the arc takes the lash twice instead. Tune it in
## data/weapons/lasso_lash.tres.

## Every this many lashes (one attack = front + back lash) the front one ropes.
@export var every_lashes: int = 3
## Seconds for the one swing around the hero.
@export var swing_seconds: float = 0.5
## How far from the hero the roped zombie swings.
@export var swing_radius: float = 95.0
## What it does to each zombie it passes (once per swing), and how far past its body that counts.
@export var swing_damage: float = 20.0
@export var swing_push: float = 240.0
@export var swing_reach: float = 10.0
## Seconds the throw is in the air, and how far it can go at most.
@export var throw_seconds: float = 0.3
@export var throw_reach: float = 360.0
## Where it lands, the thread is snipped: this many times the lash's damage.
@export var snip_factor: float = 3.0
## Sounds (names in SfxBank).
@export var rope_sound: StringName = &"lasso_rope"
@export var snip_sound: StringName = &"lasso_snip"
## The rope from the hero to the swung zombie, and the calm streak behind a thrown one (the
## zombie keeps its normal look: it is still a danger).
@export var rope_color: Color = Color(0.93, 0.9, 0.98, 0.75)
@export var rope_width: float = 3.0
@export var streak_length: float = 50.0
@export var streak_width: float = 8.0
@export var streak_color: Color = Color(0.95, 0.93, 0.99, 0.45)
