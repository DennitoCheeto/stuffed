class_name BossDef
extends Resource
## A mini-boss or boss (spec 02 §9): a huge zombie with its own patterns, announced with a banner
## and a big health bar at the top of the screen. While it is on the field, normal spawning is
## lighter. It drops a gift box. Each boss type subclasses this and makes its own BossBrain.
## Tune it in data/bosses/*.tres, not in code.

## Its body: health, walking speed, touching damage, XP button, radius before `size`.
@export var enemy: EnemyStats
## Drawn and touching this much bigger than `enemy.radius` says.
@export var size: float = 3.0
## When it arrives, in seconds into the run (the mini-boss; the boss comes at the run goal).
@export var at_seconds: float = 240.0
## Big text of the arrival banner, e.g. "Big Ted!".
@export var banner: String = "Boss!"
## Small text under it, e.g. "Mini-boss".
@export var banner_subtitle: String = ""
@export var banner_seconds: float = 2.5
## Normal spawning runs at this share while it is alive (0.4 = 40 %).
@export var spawn_rate_scale: float = 0.4
## It starts its first pattern this long after it appears.
@export var first_pattern_delay: float = 2.0
## Seconds of walking between two patterns.
@export var pattern_gap_seconds: float = 2.5
## It only starts a pattern when its target is at most this far away (not from off-screen).
@export var pattern_range: float = 520.0


## A fresh brain for one boss on the field.
func make_brain() -> BossBrain:
	return BossBrain.new(self)
