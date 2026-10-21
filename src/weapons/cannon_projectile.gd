class_name CannonProjectile
extends Projectile
## One Yarn Cannon ball: big and slow. Flies straight until it touches a zombie or reaches its
## range, then bursts: every zombie within the weapon's area is hurt and pushed away. The burst
## shows as a quick, fading puff of yarn.

const SPIN_SPEED: float = 4.0
## The ball is drawn this many times the size of a Bouncy Yarn Ball.
const BALL_SIZE: float = 1.8
const BURST_TIME: float = 0.25
const BURST_OPACITY: float = 0.45

## True from the moment it bursts.
var burst: bool = false

var _numbers: WeaponLevel
var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0
var _burst_left: float = 0.0
var _ball_scale: Vector2 = Vector2.ONE
var _burst_scale: Vector2 = Vector2.ONE


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.BURST)
	_burst_scale = scale
	ProjectileLook.apply(self, ProjectileLook.YARN, BALL_SIZE)
	_ball_scale = scale


func reset() -> void:
	super()
	burst = false
	_travelled = 0.0
	ProjectileLook.apply(self, ProjectileLook.YARN, BALL_SIZE)
	modulate.a = 1.0


func launch(from: Weapon, direction: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_direction = direction
	global_position = from.player.global_position
	scale = _ball_scale * from.area_scale()


## On-screen radius of the burst (Big Spool included).
func burst_radius() -> float:
	return _numbers.area


func advance(delta: float) -> bool:
	if burst:
		_burst_left -= delta
		var done: float = 1.0 - _burst_left / BURST_TIME
		scale = _burst_scale * burst_radius() / ProjectileLook.BURST_RADIUS * (0.7 + 0.3 * done)
		modulate.a = BURST_OPACITY * (1.0 - done)
		return _burst_left > 0.0
	var step: float = _numbers.speed * delta
	global_position += _direction * step
	_travelled += step
	rotation += SPIN_SPEED * delta
	var touching: Array[Zombie] = manager.enemies.query_circle(global_position, weapon.hit_radius())
	if not touching.is_empty() or _travelled >= _numbers.reach:
		_burst()
	return true


func _burst() -> void:
	burst = true
	_burst_left = BURST_TIME
	Sfx.play(&"pop", 0.6)
	for zombie: Zombie in manager.enemies.query_circle(global_position, _numbers.area):
		var push: Vector2 = global_position.direction_to(zombie.position) * weapon.stats.knockback
		manager.enemies.damage(zombie, _numbers.damage, push)
	ProjectileLook.apply(self, ProjectileLook.BURST)
	rotation = 0.0
	scale = _burst_scale * burst_radius() / ProjectileLook.BURST_RADIUS * 0.7
	modulate.a = BURST_OPACITY
