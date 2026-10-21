class_name BeamProjectile
extends Projectile
## The Zipper Ray's beam: a straight zipper from the player, `reach` long, pointing at the
## cursor. While it lasts it hurts every zombie touching the line, each one again only after the
## weapon's hit interval. Big Spool makes it thicker.

var _numbers: WeaponLevel
var _time_left: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
## Zombie instance id → seconds until the beam may hurt it again.
var _cooldowns: Dictionary[int, float] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.ZIPPER)
	_base_scale = scale


func reset() -> void:
	super()
	_cooldowns.clear()


func launch(from: Weapon) -> void:
	weapon = from
	_numbers = from.current()
	_time_left = _numbers.duration
	scale = _base_scale * Vector2(_numbers.reach / ProjectileLook.ZIPPER_LENGTH, from.area_scale())
	_aim()


## Seconds until the beam is gone.
func time_left() -> float:
	return _time_left


## Where the beam ends (its start is the player).
func end_point() -> Vector2:
	return global_position + Vector2.from_angle(rotation) * _numbers.reach


func advance(delta: float) -> bool:
	_time_left -= delta
	if _time_left <= 0.0:
		return false
	_aim()
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	var start: Vector2 = global_position
	var end: Vector2 = end_point()
	var push: Vector2 = Vector2.from_angle(rotation) * weapon.stats.knockback
	var width: float = weapon.hit_radius()
	for zombie: Zombie in manager.enemies.zombies:
		if zombie.dead:
			continue
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(zombie.position, start, end)
		var reach: float = width + zombie.radius()
		if closest.distance_squared_to(zombie.position) > reach * reach:
			continue
		var id: int = zombie.get_instance_id()
		if _cooldowns.has(id):
			continue
		_cooldowns[id] = weapon.stats.hit_interval
		manager.enemies.damage(zombie, _numbers.damage, push)
	return true


func _aim() -> void:
	var player: Player = weapon.player
	global_position = player.global_position
	var aim: Vector2 = player.global_position.direction_to(player.aim_point())
	rotation = (aim if aim != Vector2.ZERO else player.facing).angle()
