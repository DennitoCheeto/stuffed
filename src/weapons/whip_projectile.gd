class_name WhipProjectile
extends Projectile
## One lash of the Thread Whip: hurts every zombie in its arc the moment it is launched, then
## shows the thread's arc for a blink, fading out, around the player.

const SHOW_TIME: float = 0.18

var _time_left: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.WHIP)
	_base_scale = scale


func launch(from: Weapon, direction: Vector2) -> void:
	weapon = from
	var numbers: WeaponLevel = from.current()
	_time_left = SHOW_TIME
	global_position = from.player.global_position
	rotation = direction.angle()
	scale = _base_scale * numbers.area / ProjectileLook.WHIP_RADIUS
	modulate.a = 1.0
	var half_width: float = deg_to_rad(numbers.spread_degrees) / 2.0
	var push_strength: float = from.stats.knockback
	for zombie: Zombie in manager.enemies.query_circle(global_position, numbers.area):
		var to_zombie: Vector2 = zombie.position - global_position
		if absf(direction.angle_to(to_zombie)) > half_width:
			continue
		var push: Vector2 = to_zombie.normalized() * push_strength
		manager.enemies.damage(zombie, numbers.damage, push, weapon)


func advance(delta: float) -> bool:
	_time_left -= delta
	global_position = weapon.player.global_position
	modulate.a = _time_left / SHOW_TIME
	return _time_left > 0.0
