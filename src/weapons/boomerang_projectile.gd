class_name BoomerangProjectile
extends Node2D
## One thrown banana peel. Out to its reach, then back to its player; every zombie it touches is
## hurt once on the way out and once on the way back.

const SPIN_SPEED: float = 16.0
const PEEL_COLOR: Color = Color("#efe3a0")
const PEEL_EDGE_COLOR: Color = Color("#b9a85a")
const CATCH_DISTANCE: float = 10.0

var returning: bool = false

var _weapon: PeelBoomerang
var _enemies: EnemyManager
var _numbers: WeaponLevel
var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _hit_out: Dictionary[int, bool] = {}
var _hit_back: Dictionary[int, bool] = {}
var _shape: PackedVector2Array = []


func launch(weapon: PeelBoomerang, manager: EnemyManager, direction: Vector2) -> void:
	_weapon = weapon
	_enemies = manager
	_numbers = weapon.current()
	_direction = direction
	global_position = weapon.player.global_position
	_shape = FeltShapes.svg_path(
		PackedFloat32Array([-14, 6, -8, -10, 8, -10, 14, 6, 6, -2, -6, -2, -14, 6])
	)
	scale = Vector2.ONE * 1.3


func _physics_process(delta: float) -> void:
	var step: float = _numbers.speed * delta
	if returning:
		var target: Vector2 = _weapon.player.global_position
		if global_position.distance_to(target) <= step + CATCH_DISTANCE:
			_weapon.peel_caught.emit()
			queue_free()
			return
		_direction = global_position.direction_to(target)
	global_position += _direction * step
	_travelled += step
	if not returning and _travelled >= _numbers.reach:
		returning = true
	_hit_zombies()
	rotation += SPIN_SPEED * delta


func _hit_zombies() -> void:
	var already_hit: Dictionary[int, bool] = _hit_back if returning else _hit_out
	var push: Vector2 = _direction * _weapon.stats.knockback
	for zombie: Zombie in _enemies.query_circle(global_position, _weapon.stats.hit_radius):
		var id: int = zombie.get_instance_id()
		if already_hit.has(id):
			continue
		already_hit[id] = true
		_enemies.damage(zombie, _numbers.damage, push)


func _draw() -> void:
	draw_colored_polygon(FeltShapes.shifted(_shape, Vector2(0.8, 1.6)), PEEL_EDGE_COLOR)
	draw_colored_polygon(_shape, PEEL_COLOR)
