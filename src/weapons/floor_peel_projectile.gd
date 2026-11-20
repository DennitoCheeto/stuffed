class_name FloorPeelProjectile
extends Projectile
## A slippery peel on the floor from Banana Split's peel trail (spec 10 §3). It lies still; once
## armed, the zombies standing on it slip and are stunned, then it is used up. A pooled sprite like
## every other shot (own-shots layer, under the zombies), so a floor full of them costs nothing.

## Seconds since it landed.
var age: float = 0.0
## True once someone slipped on it or a newer peel took its place.
var used: bool = false
## Zombies that slipped on it (for tests).
var slipped: int = 0

var _trail: PeelTrail


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.SPLIT_PEEL)


func reset() -> void:
	super()
	age = 0.0
	used = false
	slipped = 0
	modulate.a = 1.0


func drop(from: Weapon, at: Vector2) -> void:
	weapon = from
	_trail = from.stats.peel_trail
	global_position = at
	rotation = randf_range(-0.6, 0.6)
	size_to(from.area_scale() * _trail.size)


## Radius of its slippery area right now (Big Spool makes it bigger).
func slip_radius() -> float:
	return _trail.radius * weapon.area_scale()


func is_armed() -> bool:
	return age >= _trail.arm_seconds


func advance(delta: float) -> bool:
	if used:
		return false
	age += delta
	if age >= _trail.lifetime:
		return false
	modulate.a = _trail.alpha * clampf((_trail.lifetime - age) / 0.4, 0.0, 1.0)
	if not is_armed():
		return true
	var victims: Array[Zombie] = manager.enemies.query_circle(global_position, slip_radius())
	if victims.is_empty():
		return true
	for zombie: Zombie in victims:
		zombie.stun(_trail.stun)
	slipped = victims.size()
	Sfx.play(&"slip")
	used = true
	return false
