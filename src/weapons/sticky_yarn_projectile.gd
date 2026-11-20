class_name StickyYarnProjectile
extends Projectile
## A patch of sticky yarn left by a Yarn Bomb burst. For the weapon's duration, zombies inside
## its area are slowed (`WeaponStats.slow`) and hurt every hit interval
## (`WeaponStats.linger_damage`). Soft and see-through: the player's own effects stay quiet.
## Tangle (spec 10 §3, `WeaponStats.yarn_tangle`): after `delay` the web yanks every zombie inside
## to its middle, knots up, and pops (a second burst); then it is gone.

enum Stage { WEB, KNOT, POP }

const TINT: Color = Color(1.0, 0.78, 0.88, 0.22)
## Zombies stay slowed this long after leaving the patch.
const SLOW_AFTER: float = 0.2
## It fades out over its last this many seconds.
const FADE_TIME: float = 0.4

var stage: Stage = Stage.WEB
## Zombies the pop hit (for tests).
var popped: int = 0

var _numbers: WeaponLevel
var _time_left: float = 0.0
## Seconds since it landed.
var _age: float = 0.0
## Seconds left of the knot or the pop.
var _stage_left: float = 0.0
## Zombie instance id → seconds until the patch may hurt it again.
var _cooldowns: Dictionary[int, float] = {}


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.BURST)


func reset() -> void:
	super()
	_cooldowns.clear()
	stage = Stage.WEB
	popped = 0
	_age = 0.0
	_stage_left = 0.0


func launch(from: Weapon, at: Vector2) -> void:
	weapon = from
	_numbers = from.current()
	_time_left = _numbers.duration
	global_position = at
	_show_size(1.0)
	modulate = TINT


## On-screen radius of the patch (Big Spool included).
func radius() -> float:
	return _numbers.area


func time_left() -> float:
	return _time_left


## Seconds until the web yanks (INF without a tangle, 0 once it did).
func tangle_in() -> float:
	var tangle: YarnTangle = weapon.stats.yarn_tangle
	if tangle == null:
		return INF
	return maxf(tangle.delay - _age, 0.0)


func advance(delta: float) -> bool:
	_age += delta
	match stage:
		Stage.KNOT:
			return _knot(delta)
		Stage.POP:
			return _pop_fading(delta)
	_time_left -= delta
	if _time_left <= 0.0:
		return false
	if tangle_in() <= 0.0:
		_yank()
		return true
	modulate.a = TINT.a * minf(_time_left / FADE_TIME, 1.0)
	rotation += 0.3 * delta
	for id: int in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)
	var hurt: float = weapon.stats.linger_damage * weapon.damage_scale()
	for zombie: Zombie in manager.enemies.query_circle(global_position, radius()):
		zombie.slow(weapon.stats.slow, SLOW_AFTER)
		var id: int = zombie.get_instance_id()
		if _cooldowns.has(id):
			continue
		_cooldowns[id] = weapon.stats.hit_interval
		manager.enemies.damage(zombie, hurt, Vector2.ZERO, weapon)
	return true


## Drags every zombie inside towards the middle (a push that slides them there).
func _yank() -> void:
	var tangle: YarnTangle = weapon.stats.yarn_tangle
	stage = Stage.KNOT
	_stage_left = tangle.knot_seconds
	for zombie: Zombie in manager.enemies.query_circle(global_position, radius()):
		var to_middle: Vector2 = global_position - zombie.position
		var push: Vector2 = to_middle * Zombie.KNOCKBACK_DECAY * tangle.pull_share
		zombie.knockback += push * zombie.knockback_taken()
		zombie.slow(weapon.stats.slow, tangle.knot_seconds + SLOW_AFTER)


## The web pulls into a knot, then pops.
func _knot(delta: float) -> bool:
	var tangle: YarnTangle = weapon.stats.yarn_tangle
	_stage_left -= delta
	var done: float = 1.0 - clampf(_stage_left / maxf(tangle.knot_seconds, 0.001), 0.0, 1.0)
	_show_size(lerpf(1.0, tangle.pop_share * 0.5, done))
	rotation += 4.0 * delta
	if _stage_left <= 0.0:
		_pop(tangle)
	return true


## The second burst: hurts everything near the middle and puffs out.
func _pop(tangle: YarnTangle) -> void:
	stage = Stage.POP
	_stage_left = tangle.pop_seconds
	Sfx.play(&"pop", tangle.pop_pitch)
	var damage: float = tangle.pop_damage * weapon.damage_scale()
	for zombie: Zombie in manager.enemies.query_circle(
		global_position, radius() * tangle.pop_share
	):
		var push: Vector2 = global_position.direction_to(zombie.position) * tangle.pop_push
		hurt(zombie, damage, push)
		popped += 1
	modulate.a = tangle.pop_opacity


func _pop_fading(delta: float) -> bool:
	var tangle: YarnTangle = weapon.stats.yarn_tangle
	_stage_left -= delta
	var done: float = 1.0 - clampf(_stage_left / maxf(tangle.pop_seconds, 0.001), 0.0, 1.0)
	_show_size(tangle.pop_size * (0.7 + 0.3 * done))
	modulate.a = tangle.pop_opacity * (1.0 - done)
	return _stage_left > 0.0


## Draws the patch at `share` of its radius.
func _show_size(share: float) -> void:
	ProjectileLook.apply(self, ProjectileLook.BURST, radius() * share / ProjectileLook.BURST_RADIUS)
