class_name BoomerangProjectile
extends Projectile
## One thrown banana peel. Out to its reach, then back to its player; every zombie it touches is
## hurt once on the way out and once on the way back.

const SPIN_SPEED: float = 16.0
const CATCH_DISTANCE: float = 10.0

var returning: bool = false

var _boomerang: PeelBoomerang
var _numbers: WeaponLevel
var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _hit_out: Dictionary[int, bool] = {}
var _hit_back: Dictionary[int, bool] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.PEEL)


func reset() -> void:
	super()
	returning = false
	_travelled = 0.0
	_hit_out.clear()
	_hit_back.clear()


func launch(from: PeelBoomerang, direction: Vector2) -> void:
	weapon = from
	_boomerang = from
	_numbers = from.current()
	_direction = direction
	global_position = from.player.global_position
	size_to(from.area_scale())
	dress(from)


func advance(delta: float) -> bool:
	var step: float = _numbers.speed * delta
	if returning:
		var target: Vector2 = _boomerang.player.global_position
		if global_position.distance_to(target) <= step + CATCH_DISTANCE:
			_boomerang.peel_caught.emit()
			Sfx.play(&"throw", 0.8)
			return false
		_direction = global_position.direction_to(target)
	global_position += _direction * step
	_travelled += step
	if not returning and _travelled >= _numbers.reach:
		returning = true
	_hit_zombies()
	rotation += SPIN_SPEED * delta
	return true


func _hit_zombies() -> void:
	var already_hit: Dictionary[int, bool] = _hit_back if returning else _hit_out
	var push: Vector2 = _direction * _boomerang.stats.knockback
	var radius: float = _boomerang.hit_radius()
	for zombie: Zombie in manager.enemies.query_circle(global_position, radius):
		var id: int = zombie.get_instance_id()
		if already_hit.has(id):
			continue
		already_hit[id] = true
		hurt(zombie, _numbers.damage, push)
