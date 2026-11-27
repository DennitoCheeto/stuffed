class_name CradleThreads
extends Node2D
## The yarn threads one Cat's Cradle leaves between its bounce points (spec 11 §4.1). Each thread
## hurts the zombies touching it every `YarnCradle.thread_interval` for its lifetime. All threads
## are drawn in one `draw_multiline_colors` (one draw call), on the own-shots layer under the
## zombies.

const NAME: StringName = &"CradleThreads"

## The weapon whose threads these are (its numbers and its tally row).
var weapon: Weapon
## Zombie hits from threads so far (for tests).
var hits: int = 0

## One entry per thread, oldest first: its two ends, its age and the seconds until it hurts again.
var _from: PackedVector2Array = []
var _to: PackedVector2Array = []
var _age: PackedFloat32Array = []
var _wait: PackedFloat32Array = []
var _drawn: bool = false


func _init() -> void:
	name = NAME
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


## Stretches a new thread from `from` to `to` (the oldest one goes when there are too many).
func add(from: Vector2, to: Vector2) -> void:
	var cradle: YarnCradle = _cradle()
	if cradle == null or from.distance_squared_to(to) < 1.0:
		return
	_from.append(from)
	_to.append(to)
	_age.append(0.0)
	_wait.append(cradle.thread_interval)
	while _from.size() > cradle.max_threads:
		_drop(0)
	queue_redraw()


func count() -> int:
	return _from.size()


## Pairs of points, one pair per thread (for tests).
func segments() -> PackedVector2Array:
	var result: PackedVector2Array = []
	for i: int in _from.size():
		result.append(_from[i])
		result.append(_to[i])
	return result


func _cradle() -> YarnCradle:
	return weapon.stats.yarn_cradle if weapon != null and weapon.stats != null else null


func _drop(index: int) -> void:
	_from.remove_at(index)
	_to.remove_at(index)
	_age.remove_at(index)
	_wait.remove_at(index)


func _physics_process(delta: float) -> void:
	var cradle: YarnCradle = _cradle()
	if cradle == null or _from.is_empty():
		return
	var manager: EnemyManager = weapon.enemies()
	for i: int in range(_from.size() - 1, -1, -1):
		_age[i] += delta
		if _age[i] >= cradle.thread_seconds:
			_drop(i)
			continue
		_wait[i] -= delta
		if _wait[i] <= 0.0 and manager != null:
			_wait[i] += cradle.thread_interval
			_hurt_along(_from[i], _to[i], cradle, manager)


func _hurt_along(from: Vector2, to: Vector2, cradle: YarnCradle, manager: EnemyManager) -> void:
	var middle: Vector2 = (from + to) / 2.0
	var half: float = from.distance_to(to) / 2.0
	var damage: float = cradle.thread_damage * weapon.damage_scale()
	for zombie: Zombie in manager.query_circle(middle, half + cradle.thread_reach):
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(zombie.position, from, to)
		var reach: float = cradle.thread_reach + zombie.radius()
		if closest.distance_squared_to(zombie.position) > reach * reach:
			continue
		hits += 1
		manager.damage(zombie, damage, Vector2.ZERO, weapon)


func _process(_delta: float) -> void:
	# One more redraw after the last thread went, so nothing is left behind.
	if not _from.is_empty() or _drawn:
		modulate.a = GameSettings.own_effects
		queue_redraw()
	_drawn = not _from.is_empty()


func _draw() -> void:
	var cradle: YarnCradle = _cradle()
	if cradle == null or _from.is_empty():
		return
	var points: PackedVector2Array = []
	var colors: PackedColorArray = []
	for i: int in _from.size():
		var color: Color = cradle.thread_color
		var left: float = cradle.thread_seconds - _age[i]
		color.a *= clampf(left / maxf(cradle.fade_seconds, 0.001), 0.0, 1.0)
		points.append(_from[i])
		points.append(_to[i])
		colors.append(color)
	draw_multiline_colors(points, colors, cradle.thread_width)
