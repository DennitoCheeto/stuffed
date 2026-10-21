class_name StickyYarnProjectile
extends Projectile
## A patch of sticky yarn left by a Yarn Bomb burst. For the weapon's duration, zombies inside
## its area are slowed (`WeaponStats.slow`) and hurt every hit interval
## (`WeaponStats.linger_damage`). Soft and see-through: the player's own effects stay quiet.

const TINT: Color = Color(1.0, 0.78, 0.88, 0.22)
## Zombies stay slowed this long after leaving the patch.
const SLOW_AFTER: float = 0.2
## It fades out over its last this many seconds.
const FADE_TIME: float = 0.4

var _numbers: WeaponLevel
var _time_left: float = 0.0
## Zombie instance id → seconds until the patch may hurt it again.
var _cooldowns: Dictionary[int, float] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.BURST)


func reset() -> void:
	super()
	_cooldowns.clear()


func launch(from: Weapon, at: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_time_left = _numbers.duration
	global_position = at
	ProjectileLook.apply(self, ProjectileLook.BURST, radius() / ProjectileLook.BURST_RADIUS)
	modulate = TINT


## On-screen radius of the patch (Big Spool included).
func radius() -> float:
	return _numbers.area


func time_left() -> float:
	return _time_left


func advance(delta: float) -> bool:
	_time_left -= delta
	if _time_left <= 0.0:
		return false
	modulate.a = TINT.a * minf(_time_left / FADE_TIME, 1.0)
	rotation += 0.3 * delta
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	var hurt: float = weapon.stats.linger_damage * weapon.player.damage_multiplier
	for zombie: Zombie in manager.enemies.query_circle(global_position, radius()):
		zombie.slow(weapon.stats.slow, SLOW_AFTER)
		var id: int = zombie.get_instance_id()
		if _cooldowns.has(id):
			continue
		_cooldowns[id] = weapon.stats.hit_interval
		manager.enemies.damage(zombie, hurt, Vector2.ZERO)
	return true
