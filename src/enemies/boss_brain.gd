class_name BossBrain
extends RefCounted
## How a boss fights, one frame at a time. The EnemyManager asks it each frame where the boss
## walks; the brain starts patterns, shows their telegraph and fires them. This base brain only
## walks towards its target; each boss subclasses it (BigTedBrain).

var def: BossDef
## The boss's telegraph on the floor (set by the Zombie).
var telegraph: BossTelegraph
## Seconds until it may start its next pattern.
var pattern_cooldown: float = 0.0
## Seconds left in the current part of a pattern (not used while walking).
var state_left: float = 0.0


func _init(boss_def: BossDef) -> void:
	def = boss_def
	pattern_cooldown = def.first_pattern_delay


## Where the boss walks this frame (pixels per second) towards `target` (the nearest player,
## may be null).
func step(zombie: Zombie, target: Player, _manager: EnemyManager, _delta: float) -> Vector2:
	if target == null:
		return Vector2.ZERO
	return zombie.position.direction_to(target.global_position) * zombie.current_speed()


## Stops whatever pattern is going on (the run calms down).
func calm_down() -> void:
	if telegraph != null:
		telegraph.clear()


## How puffed up it looks: 0 = normal, 1 = about to fire.
func puff_amount() -> float:
	return 0.0


## True while it is in the middle of a pattern (telegraph or attack).
func is_busy() -> bool:
	return false


## True while it flies (it can't touch anyone then).
func is_airborne() -> bool:
	return false


## True when `target` is close enough to start a pattern (not from off-screen).
func _in_range(zombie: Zombie, target: Player) -> bool:
	if target == null:
		return false
	var reach: float = def.pattern_range
	return zombie.position.distance_squared_to(target.global_position) <= reach * reach


## How far the current telegraph is: 0 = just shown, 1 = the attack comes now.
func _progress(windup: float) -> float:
	return clampf(1.0 - state_left / maxf(windup, 0.001), 0.0, 1.0)
