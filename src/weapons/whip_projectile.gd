class_name WhipProjectile
extends Projectile
## One lash of the Thread Whip: hurts every zombie in its arc the moment it is launched, then
## shows the thread's arc for a blink, fading out, around the player.

const SHOW_TIME: float = 0.18

var _time_left: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func _init() -> void:
	ProjectileLook.apply(self, _part())
	_base_scale = scale


## The look (Paw Swat shows a paw swipe).
func _part() -> StringName:
	return ProjectileLook.WHIP


func launch(from: Weapon, direction: Vector2) -> void:
	weapon = from
	var numbers: WeaponLevel = from.current()
	_time_left = SHOW_TIME
	global_position = from.origin()
	rotation = direction.angle()
	scale = _base_scale * numbers.area / _part_radius()
	modulate.a = 1.0
	var half_width: float = deg_to_rad(numbers.spread_degrees) / 2.0
	var push_strength: float = from.stats.knockback
	for zombie: Zombie in manager.enemies.query_circle(global_position, numbers.area):
		var to_zombie: Vector2 = zombie.position - global_position
		if absf(direction.angle_to(to_zombie)) > half_width:
			continue
		var push: Vector2 = to_zombie.normalized() * push_strength
		manager.enemies.damage(zombie, numbers.damage, push, weapon)


## The look's radius at scale 1 (it is stretched to the weapon's area).
func _part_radius() -> float:
	return ProjectileLook.WHIP_RADIUS


func advance(delta: float) -> bool:
	_time_left -= delta
	global_position = weapon.origin()
	modulate.a = _time_left / SHOW_TIME
	return _time_left > 0.0
