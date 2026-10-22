class_name ThimbleProjectile
extends Projectile
## One lobbed thimble (spec 02 §3, §20). The shot sits at the landing spot and shows a ring on the
## floor exactly as big as the hit area (Big Spool included); the ring fills in as the thimble
## comes down. The thimble flies in a high arc from the player with its small shadow under it.
## On landing it hurts every zombie inside the ring (they flash), the ring thumps and dust puffs.

## Shortest flight, so even a close target shows its ring for a moment.
const MIN_FLIGHT: float = 0.35
## Highest point of the arc above the straight line, per pixel of distance, and at least this.
const ARC_HEIGHT: float = 0.5
const MIN_ARC: float = 90.0
## The thimble looks this much bigger at the top of its arc (closer to the camera).
const APEX_GROWTH: float = 0.35
const RING_OPACITY: float = 0.7
## The fill grows from nothing to the full ring during the flight.
const FILL_OPACITY: float = 0.3
## Size of the moving shadow under the thimble (on-screen radius).
const SHADOW_SIZE: float = 12.0
const SHADOW_OPACITY: float = 0.45
## After landing: the ring thumps (bright, a bit bigger) and fades, dust puffs outwards.
const IMPACT_TIME: float = 0.35
const IMPACT_GROWTH: float = 0.12
const IMPACT_FILL_OPACITY: float = 0.5
const DUST_COUNT: int = 6
const DUST_SPREAD: float = 0.5
const SPIN_SPEED: float = 7.0

## True from the moment it lands.
var landed: bool = false

var _numbers: WeaponLevel
var _from: Vector2 = Vector2.ZERO
var _flight_time: float = 0.0
var _elapsed: float = 0.0
## The look's own scale (atlas units to screen); the ring is scaled on top of it.
var _base_scale: Vector2 = Vector2.ONE
var _thimble: Sprite2D
var _shadow: Sprite2D
var _fill: Sprite2D
var _dust: Array[Sprite2D] = []


func _init() -> void:
	# On the floor: under the zombies, above the arena (like boss telegraphs).
	z_index = -1
	ProjectileLook.apply(self, ProjectileLook.RING)
	_base_scale = scale
	_fill = Sprite2D.new()
	ProjectileLook.apply(_fill, ProjectileLook.DISC)
	add_child(_fill)
	_shadow = _floating(ProjectileLook.SHADOW)
	_shadow.scale *= SHADOW_SIZE / ProjectileLook.SHADOW_RADIUS
	for i: int in DUST_COUNT:
		_dust.append(_floating(ProjectileLook.DUST))
	_thimble = _floating(ProjectileLook.THIMBLE)
	# Flies above the zombies.
	_thimble.z_index = 2


func reset() -> void:
	super()
	landed = false
	_elapsed = 0.0
	_thimble.visible = true
	_shadow.visible = true
	for dust: Sprite2D in _dust:
		dust.visible = false


## Throws the thimble from the player to `target` (a point in the world).
func launch(from: Weapon, target: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_from = from.player.global_position
	global_position = target
	_flight_time = maxf(_from.distance_to(target) / maxf(_numbers.speed, 1.0), MIN_FLIGHT)
	scale = _ring_scale()
	self_modulate.a = RING_OPACITY
	_place(0.0)


## Seconds until it lands (0 once it has).
func time_to_land() -> float:
	return maxf(_flight_time - _elapsed, 0.0)


## Radius of the landing hit (Big Spool included).
func blast_radius() -> float:
	return _numbers.area


## On-screen radius of the ring on the floor, as drawn.
func ring_radius() -> float:
	return ProjectileLook.RING_RADIUS * scale.x / _base_scale.x


## How far the ring has filled in (0 = just thrown, 1 = landing now).
func fill_share() -> float:
	return _fill.scale.x


## Height of the thimble above its shadow on the floor.
func height() -> float:
	return _shadow.global_position.y - _thimble.global_position.y


func advance(delta: float) -> bool:
	_elapsed += delta
	if not landed:
		if _elapsed < _flight_time:
			_place(_elapsed / _flight_time)
			return true
		_land()
	var after: float = (_elapsed - _flight_time) / IMPACT_TIME
	_show_impact(minf(after, 1.0))
	return after < 1.0


func _land() -> void:
	landed = true
	_thimble.visible = false
	_shadow.visible = false
	Sfx.play(&"hit", 0.7)
	for zombie: Zombie in manager.enemies.query_circle(global_position, blast_radius()):
		var push: Vector2 = global_position.direction_to(zombie.position) * weapon.stats.knockback
		manager.enemies.damage(zombie, _numbers.damage, push)
	for dust: Sprite2D in _dust:
		dust.visible = true


## Thimble, its shadow and the ring's fill at `progress` (0 = thrown, 1 = landed).
func _place(progress: float) -> void:
	var arc: float = maxf(_from.distance_to(global_position) * ARC_HEIGHT, MIN_ARC)
	var ground: Vector2 = _from.lerp(global_position, progress)
	var lift: float = sin(PI * progress)
	_shadow.global_position = ground
	_shadow.self_modulate.a = SHADOW_OPACITY * lerpf(0.5, 1.0, 1.0 - lift)
	_thimble.global_position = ground + Vector2(0.0, -arc * lift)
	_thimble.rotation = SPIN_SPEED * _elapsed
	_thimble.scale = _base_scale * (1.0 + APEX_GROWTH * lift)
	# The fill hangs under the ring, so it is already scaled to the hit area.
	_fill.scale = Vector2.ONE * progress
	_fill.self_modulate.a = FILL_OPACITY


## The landing at `after` (0 = just landed, 1 = gone): the ring thumps and fades, dust puffs.
func _show_impact(after: float) -> void:
	var fade: float = 1.0 - after
	scale = _ring_scale() * (1.0 + IMPACT_GROWTH * after)
	self_modulate.a = fade
	_fill.scale = Vector2.ONE
	_fill.self_modulate.a = IMPACT_FILL_OPACITY * fade
	var radius: float = blast_radius()
	for i: int in _dust.size():
		var dust: Sprite2D = _dust[i]
		var out: Vector2 = Vector2.from_angle(TAU * i / _dust.size())
		dust.global_position = global_position + out * radius * (1.0 + DUST_SPREAD * after)
		dust.scale = _base_scale * (1.0 + after)
		dust.self_modulate.a = fade


## A sprite of `key` that moves on its own (not with the ring's scale).
func _floating(key: StringName) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.top_level = true
	ProjectileLook.apply(sprite, key)
	add_child(sprite)
	return sprite


## The ring's scale for the hit area (Big Spool included).
func _ring_scale() -> Vector2:
	return _base_scale * blast_radius() / ProjectileLook.RING_RADIUS
