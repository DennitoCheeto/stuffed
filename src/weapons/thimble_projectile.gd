class_name ThimbleProjectile
extends Projectile
## One lobbed thimble. The shot itself sits at the landing spot and shows the shadow there, which
## grows as the thimble comes down; the thimble is a child sprite flying in an arc from the
## player. On landing it hurts every zombie within the weapon's area, then the shadow puffs out.

## Shortest flight, so even a close target shows its shadow for a moment.
const MIN_FLIGHT: float = 0.35
## Highest point of the arc above the straight line, per pixel of distance.
const ARC_HEIGHT: float = 0.35
const SHADOW_START: float = 0.4
const SHADOW_OPACITY: float = 0.55
## After landing, the shadow grows and fades for this long.
const IMPACT_TIME: float = 0.2
const IMPACT_GROWTH: float = 0.4
const SPIN_SPEED: float = 7.0

## True from the moment it lands.
var landed: bool = false

var _numbers: WeaponLevel
var _from: Vector2 = Vector2.ZERO
var _flight_time: float = 0.0
var _elapsed: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _thimble: Sprite2D


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.SHADOW)
	_base_scale = scale
	_thimble = Sprite2D.new()
	_thimble.top_level = true
	ProjectileLook.apply(_thimble, ProjectileLook.THIMBLE)
	add_child(_thimble)


func reset() -> void:
	super()
	landed = false
	_elapsed = 0.0
	_thimble.visible = true


## Throws the thimble from the player to `target` (a point in the world).
func launch(from: Weapon, target: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_from = from.player.global_position
	global_position = target
	_flight_time = maxf(_from.distance_to(target) / maxf(_numbers.speed, 1.0), MIN_FLIGHT)
	_place(0.0)


## Seconds until it lands (0 once it has).
func time_to_land() -> float:
	return maxf(_flight_time - _elapsed, 0.0)


## On-screen radius of the landing hit (Big Spool included).
func blast_radius() -> float:
	return _numbers.area


func advance(delta: float) -> bool:
	_elapsed += delta
	if not landed:
		if _elapsed < _flight_time:
			_place(_elapsed / _flight_time)
			return true
		_land()
	var after: float = (_elapsed - _flight_time) / IMPACT_TIME
	scale = _shadow_scale() * (1.0 + IMPACT_GROWTH * after)
	self_modulate.a = SHADOW_OPACITY * (1.0 - after)
	return after < 1.0


func _land() -> void:
	landed = true
	_thimble.visible = false
	Sfx.play(&"hit", 0.7)
	for zombie: Zombie in manager.enemies.query_circle(global_position, _numbers.area):
		var push: Vector2 = global_position.direction_to(zombie.position) * weapon.stats.knockback
		manager.enemies.damage(zombie, _numbers.damage, push)


## Thimble and shadow at `progress` (0 = thrown, 1 = landed) of the flight.
func _place(progress: float) -> void:
	var height: float = _from.distance_to(global_position) * ARC_HEIGHT * sin(PI * progress)
	_thimble.global_position = _from.lerp(global_position, progress) + Vector2(0.0, -height)
	_thimble.rotation = SPIN_SPEED * _elapsed
	scale = _shadow_scale() * lerpf(SHADOW_START, 1.0, progress)
	self_modulate.a = SHADOW_OPACITY * lerpf(0.5, 1.0, progress)


func _shadow_scale() -> Vector2:
	return _base_scale * _numbers.area / ProjectileLook.SHADOW_RADIUS
