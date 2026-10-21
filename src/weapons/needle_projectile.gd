class_name NeedleProjectile
extends Projectile
## One orbiting needle: circles its player at the weapon's reach until its duration is over.
## Hurts each zombie it touches, and the same zombie again only after the weapon's hit interval.

## Angle around the player, in radians.
var angle: float = 0.0

var _numbers: WeaponLevel
var _time_left: float = 0.0
## Zombie instance id → seconds until this needle may hurt it again.
var _cooldowns: Dictionary[int, float] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.NEEDLE)


func reset() -> void:
	super()
	_cooldowns.clear()


func launch(from: Weapon, start_angle: float) -> void:
	weapon = from
	_numbers = from.current()
	angle = start_angle
	_time_left = _numbers.duration
	size_to(from.area_scale())
	_place()


func advance(delta: float) -> bool:
	_time_left -= delta
	if _time_left <= 0.0:
		return false
	angle = wrapf(angle + _numbers.speed / maxf(_numbers.reach, 1.0) * delta, 0.0, TAU)
	_place()
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	var push: Vector2 = Vector2.from_angle(angle) * weapon.stats.knockback
	for zombie: Zombie in manager.enemies.query_circle(global_position, weapon.hit_radius()):
		var id: int = zombie.get_instance_id()
		if _cooldowns.has(id):
			continue
		_cooldowns[id] = weapon.stats.hit_interval
		manager.enemies.damage(zombie, _numbers.damage, push)
	return true


## Seconds until this circle of needles is gone.
func time_left() -> float:
	return _time_left


func _place() -> void:
	global_position = weapon.player.global_position + Vector2.from_angle(angle) * _numbers.reach
	# Point along the circle, the way the needle travels.
	rotation = angle + PI / 2.0
