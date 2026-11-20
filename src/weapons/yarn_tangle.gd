class_name YarnTangle
extends Resource
## Yarn Bomb's tangle (spec 10 §3): a while after the sticky yarn lands, the web yanks every
## zombie inside it to its middle and pops (a second burst). Tune it in data/weapons/yarn_bomb.tres.

## Seconds after landing until the web yanks (it is gone after the pop).
@export var delay: float = 2.0
## How far the yank drags a zombie towards the middle (1 = all the way; bosses resist).
@export var pull_share: float = 0.9
## Seconds from the yank to the pop (the web knots up meanwhile).
@export var knot_seconds: float = 0.25
## The pop: damage to every zombie within `pop_share` of the web's radius, and how it pushes them.
@export var pop_damage: float = 40.0
@export var pop_share: float = 0.7
@export var pop_push: float = 160.0
## How the pop looks: seconds and opacity of the fading puff, and its size as a share of the web.
@export var pop_seconds: float = 0.3
@export var pop_opacity: float = 0.4
@export var pop_size: float = 1.1
## Pitch of the pop (the Yarn Cannon's "pop", lower).
@export var pop_pitch: float = 0.5
