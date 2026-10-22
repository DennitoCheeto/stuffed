class_name StormNeedleProjectile
extends Projectile
## One needle of the Sewing Storm: circles its player for as long as the weapon exists. When
## flung it swings out to the weapon's area and back within the weapon's duration. Hurts each
## zombie it touches, the same zombie again only after the weapon's hit interval.

## Angle around the player, in radians.
var angle: float = 0.0
## Distance from the player right now.
var radius: float = 0.0
## True while it swings outward and back.
var flinging: bool = false

var _fling_time: float = 0.0
## Zombie instance id → seconds until this needle may hurt it again.
var _cooldowns: Dictionary[int, float] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.NEEDLE)


func reset() -> void:
	super()
	flinging = false
	_fling_time = 0.0
	_cooldowns.clear()


func launch(from: Weapon, start_angle: float) -> void:
	weapon = from
	angle = start_angle
	radius = from.current().reach
	size_to(from.area_scale())
	_place()
	dress(from)


## Swings out to the weapon's area and back.
func fling() -> void:
	flinging = true
	_fling_time = 0.0


func advance(delta: float) -> bool:
	# The storm lasts all run: read the numbers every frame, so new items apply at once.
	var numbers: WeaponLevel = weapon.current()
	radius = numbers.reach
	if flinging:
		_fling_time += delta
		var progress: float = _fling_time / maxf(numbers.duration, 0.01)
		if progress >= 1.0:
			flinging = false
		else:
			radius = lerpf(numbers.reach, maxf(numbers.area, numbers.reach), sin(progress * PI))
	angle = wrapf(angle + numbers.speed / maxf(radius, 1.0) * delta, 0.0, TAU)
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
		hurt(zombie, numbers.damage, push)
	return true


func _place() -> void:
	global_position = weapon.player.global_position + Vector2.from_angle(angle) * radius
	rotation = angle + PI / 2.0
