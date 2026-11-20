class_name SlamRingProjectile
extends Projectile
## Bear Slam's ground slam (spec 10 §3): the moment it is launched every zombie inside the ring is
## hurt, pushed away and knocked down (a short stun); then the ring spreads out on the floor and
## fades. Drawn with the mortar's felt ring, tinted by `GroundSlam.ring_color`.

## Zombies the slam hit (for tests).
var hit: int = 0

var _rules: GroundSlam
var _radius: float = 0.0
var _age: float = 0.0
var _base_scale: Vector2 = Vector2.ONE


func _init() -> void:
	# On the floor: under the zombies (like the mortar's ring).
	z_index = -1
	ProjectileLook.apply(self, ProjectileLook.RING)
	_base_scale = scale


func reset() -> void:
	super()
	hit = 0
	_age = 0.0


func slam(from: Weapon) -> void:
	weapon = from
	_rules = from.stats.ground_slam
	_radius = _rules.radius * from.area_scale()
	global_position = from.origin()
	modulate = _rules.ring_color
	scale = _base_scale * 0.3 * _radius / ProjectileLook.RING_RADIUS
	Sfx.play(&"slam")
	var damage: float = _rules.damage * from.damage_scale()
	for zombie: Zombie in manager.enemies.query_circle(global_position, _radius):
		var push: Vector2 = global_position.direction_to(zombie.position) * _rules.push
		zombie.stun(_rules.stun)
		hit += 1
		manager.enemies.damage(zombie, damage, push, weapon)


## Radius the slam hits (Big Spool included).
func radius() -> float:
	return _radius


func advance(delta: float) -> bool:
	_age += delta
	var done: float = clampf(_age / maxf(_rules.ring_seconds, 0.001), 0.0, 1.0)
	var spread: float = lerpf(0.3, 1.0, ease(done, 0.4))
	scale = _base_scale * spread * _radius / ProjectileLook.RING_RADIUS
	modulate.a = _rules.ring_color.a * (1.0 - done)
	return done < 1.0
