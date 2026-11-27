class_name BowlingLane
extends Node2D
## The zombies one Bowling Buttons knocked over (spec 11 §4.2). Each tumbles for
## `ZombieBowling.tumble_seconds`; while it tumbles it hurts and pushes every zombie it bumps into,
## once each. Bumped zombies don't tumble themselves, so it can't run forever. Bosses never tumble.
## Draws a calm streak behind every tumbler in one `draw_multiline` (one draw call), under the
## zombies.

const NAME: StringName = &"BowlingLane"

## The weapon whose lane this is (its numbers and its tally row).
var weapon: Weapon
## Zombies knocked over by tumblers so far, and tumbles that knocked over `strike_count` or more.
var bumps: int = 0
var strikes: int = 0

## One entry per tumbling zombie: the zombie, which way it tumbles, seconds left, how long it
## tumbles in all, and the ids of the zombies it already bumped.
var _zombies: Array[Zombie] = []
var _directions: PackedVector2Array = []
var _left: PackedFloat32Array = []
var _length: PackedFloat32Array = []
var _bumped: Array[Dictionary] = []
var _drawn: bool = false


func _init() -> void:
	name = NAME
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


## `zombie` was knocked back towards `direction`: it starts (or keeps) tumbling. Bosses don't.
func tumble(zombie: Zombie, direction: Vector2) -> void:
	var bowling: ZombieBowling = _bowling()
	if bowling == null or zombie.dead or zombie.is_boss() or direction == Vector2.ZERO:
		return
	var seconds: float = bowling.tumble_seconds
	if zombie.is_elite():
		seconds *= bowling.elite_share
	zombie.tumble_left = maxf(zombie.tumble_left, seconds)
	var index: int = _zombies.find(zombie)
	if index >= 0:
		_directions[index] = direction.normalized()
		_left[index] = maxf(_left[index], seconds)
		return
	_zombies.append(zombie)
	_directions.append(direction.normalized())
	_left.append(seconds)
	_length.append(seconds)
	var own: Dictionary[int, bool] = {zombie.get_instance_id(): true}
	_bumped.append(own)


## The zombies tumbling right now.
func tumbling() -> Array[Zombie]:
	var result: Array[Zombie] = []
	for zombie: Zombie in _zombies:
		if is_instance_valid(zombie) and not zombie.dead:
			result.append(zombie)
	return result


func is_tumbling(zombie: Zombie) -> bool:
	return tumbling().has(zombie)


func _bowling() -> ZombieBowling:
	return weapon.stats.zombie_bowling if weapon != null and weapon.stats != null else null


func _drop(index: int) -> void:
	_zombies.remove_at(index)
	_directions.remove_at(index)
	_left.remove_at(index)
	_length.remove_at(index)
	_bumped.remove_at(index)


func _physics_process(delta: float) -> void:
	var bowling: ZombieBowling = _bowling()
	if bowling == null or _zombies.is_empty():
		return
	var manager: EnemyManager = weapon.enemies()
	for i: int in range(_zombies.size() - 1, -1, -1):
		var zombie: Zombie = _zombies[i]
		_left[i] -= delta
		if not is_instance_valid(zombie) or zombie.dead or _left[i] <= 0.0 or manager == null:
			_drop(i)
			continue
		_bump_from(i, bowling, manager)


## Knocks over every zombie tumbler `i` touches that it hasn't bumped yet.
func _bump_from(i: int, bowling: ZombieBowling, manager: EnemyManager) -> void:
	var tumbler: Zombie = _zombies[i]
	var bumped: Dictionary = _bumped[i]
	var before: int = bumped.size()
	var damage: float = bowling.bump_damage * weapon.damage_scale()
	var push: Vector2 = _directions[i] * bowling.bump_push
	var reach: float = tumbler.radius() + bowling.bump_reach
	for other: Zombie in manager.query_circle(tumbler.position, reach):
		var id: int = other.get_instance_id()
		if bumped.has(id) or other.is_boss():
			continue
		bumped[id] = true
		bumps += 1
		manager.damage(other, damage, push, weapon)
	# The tumbler itself is in its own list, so "knocked over" = size - 1.
	var strike: int = bowling.strike_count + 1
	if before < strike and bumped.size() >= strike:
		strikes += 1
		Sfx.play(bowling.strike_sound)


func _process(_delta: float) -> void:
	if not _zombies.is_empty() or _drawn:
		modulate.a = GameSettings.own_effects
		queue_redraw()
	_drawn = not _zombies.is_empty()


func _draw() -> void:
	var bowling: ZombieBowling = _bowling()
	if bowling == null:
		return
	var points: PackedVector2Array = []
	for i: int in _zombies.size():
		var zombie: Zombie = _zombies[i]
		if not is_instance_valid(zombie) or zombie.dead:
			continue
		var share: float = clampf(_left[i] / maxf(_length[i], 0.001), 0.0, 1.0)
		var back: Vector2 = -_directions[i] * (zombie.radius() + bowling.streak_length * share)
		points.append(zombie.position - _directions[i] * zombie.radius() * 0.5)
		points.append(zombie.position + back)
	if not points.is_empty():
		draw_multiline(points, bowling.streak_color, bowling.streak_width)
