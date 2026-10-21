class_name PinProjectile
extends Projectile
## One flying sewing pin: straight and fast, hurts every zombie it passes through until its
## pierce is used up or it reaches its range.

## From this many zombies on one pin, the hit feels heavy (a tiny hit-stop).
const BIG_HIT: int = 3

## Zombies hit so far.
var hits: int = 0

var _numbers: WeaponLevel
var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _already_hit: Dictionary[int, bool] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.PIN)


func reset() -> void:
	super()
	hits = 0
	_travelled = 0.0
	_already_hit.clear()


func launch(from: Weapon, direction: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_direction = direction
	global_position = from.player.global_position
	size_to(from.area_scale())
	rotation = direction.angle()


## How many zombies one pin may hit (it passes through `pierce` of them).
func max_hits() -> int:
	return _numbers.pierce + 1


func advance(delta: float) -> bool:
	var step: float = _numbers.speed * delta
	# Check halfway too, so a fast pin can't skip over a zombie between two frames.
	for part: float in [0.5, 1.0]:
		_hit_zombies(global_position + _direction * step * part)
		if hits >= max_hits():
			return false
	global_position += _direction * step
	_travelled += step
	return _travelled < _numbers.reach


func _hit_zombies(point: Vector2) -> void:
	var push: Vector2 = _direction * weapon.stats.knockback
	for zombie: Zombie in manager.enemies.query_circle(point, weapon.hit_radius()):
		var id: int = zombie.get_instance_id()
		if _already_hit.has(id) or hits >= max_hits():
			continue
		_already_hit[id] = true
		hits += 1
		manager.enemies.damage(zombie, _numbers.damage, push)
		if hits == BIG_HIT:
			var run: Run = get_tree().get_first_node_in_group(Run.GROUP) as Run
			if run != null:
				run.hit_stop()
