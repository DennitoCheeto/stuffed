class_name PinProjectile
extends Node2D
## One flying sewing pin: straight and fast, hurts every zombie it passes through until its
## pierce is used up or it reaches its range.

const LENGTH: float = 30.0
const SHAFT_COLOR: Color = Color("#d9d6e3")
const HEAD_COLOR: Color = Color("#e0475b")

## Zombies hit so far.
var hits: int = 0

var _weapon: Weapon
var _enemies: EnemyManager
var _numbers: WeaponLevel
var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _already_hit: Dictionary[int, bool] = {}


func launch(weapon: Weapon, manager: EnemyManager, direction: Vector2) -> void:
	_weapon = weapon
	_enemies = manager
	_numbers = weapon.current()
	_direction = direction
	global_position = weapon.player.global_position
	rotation = direction.angle()


## How many zombies one pin may hit (it passes through `pierce` of them).
func max_hits() -> int:
	return _numbers.pierce + 1


func _physics_process(delta: float) -> void:
	var step: float = _numbers.speed * delta
	# Check halfway too, so a fast pin can't skip over a zombie between two frames.
	for part: float in [0.5, 1.0]:
		_hit_zombies(global_position + _direction * step * part)
		if hits >= max_hits():
			queue_free()
			return
	global_position += _direction * step
	_travelled += step
	if _travelled >= _numbers.reach:
		queue_free()


func _hit_zombies(point: Vector2) -> void:
	var push: Vector2 = _direction * _weapon.stats.knockback
	for zombie: Zombie in _enemies.query_circle(point, _weapon.stats.hit_radius):
		var id: int = zombie.get_instance_id()
		if _already_hit.has(id) or hits >= max_hits():
			continue
		_already_hit[id] = true
		hits += 1
		_enemies.damage(zombie, _numbers.damage, push)


func _draw() -> void:
	draw_line(Vector2(-LENGTH, 0.0), Vector2(0.0, 0.0), SHAFT_COLOR, 3.0)
	draw_colored_polygon([Vector2(0, -1.5), Vector2(7, 0), Vector2(0, 1.5)], SHAFT_COLOR)
	draw_circle(Vector2(-LENGTH, 0.0), 4.0, HEAD_COLOR)
