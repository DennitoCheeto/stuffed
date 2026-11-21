class_name SnowmanProjectile
extends Projectile
## A Snow Day snowman (spec 10 §3): built where a snowball lands. Zombies nearby walk to it and
## crowd around it (a `ZombieLure`); after its lifetime it bursts, hurting and freezing every
## zombie close by, and puffs away. A pooled sprite on the own-shots layer, under the zombies.

## Seconds the burst puff takes to fade.
const PUFF_SECONDS: float = 0.3
const PUFF_OPACITY: float = 0.45

## Seconds since it was built.
var age: float = 0.0
## True from the moment it bursts (then only the puff is left).
var burst: bool = false
## Zombies its burst froze (for tests).
var froze: int = 0
## Draws zombies to it while it stands (null before it is built).
var lure: ZombieLure

var _rules: Snowmen
var _base_scale: Vector2 = Vector2.ONE
var _puff_left: float = 0.0


func _init() -> void:
	ProjectileLook.apply(self, ProjectileLook.SNOWMAN)
	_base_scale = scale


func reset() -> void:
	super()
	_end_lure()
	age = 0.0
	burst = false
	froze = 0
	_puff_left = 0.0
	ProjectileLook.apply(self, ProjectileLook.SNOWMAN)
	modulate.a = 1.0


## Builds it at `at` for `from` (a Snow Day).
func build(from: Weapon, at: Vector2) -> void:
	weapon = from
	_rules = from.stats.snowmen
	global_position = at
	scale = Vector2.ZERO
	lure = ZombieLure.new(at, _rules.lure_reach, _rules.stand_off)
	manager.enemies.lures.append(lure)


## True while it stands (built, not burst yet).
func is_standing() -> bool:
	return not burst


## Seconds until it bursts.
func time_left() -> float:
	return maxf(_rules.lifetime - age, 0.0)


## Radius of its burst (Big Spool included).
func burst_radius() -> float:
	return _rules.burst_radius * weapon.area_scale()


func advance(delta: float) -> bool:
	age += delta
	if burst:
		_puff_left -= delta
		modulate.a = PUFF_OPACITY * clampf(_puff_left / PUFF_SECONDS, 0.0, 1.0)
		return _puff_left > 0.0
	var grown: float = clampf(age / maxf(_rules.build_seconds, 0.001), 0.0, 1.0)
	scale = _base_scale * weapon.area_scale() * ease(grown, 0.4)
	var wobble: float = 1.0 - time_left() / maxf(_rules.wobble_seconds, 0.001)
	rotation = 0.12 * sin(age * 40.0) * clampf(wobble, 0.0, 1.0)
	if age >= _rules.lifetime:
		_burst()
	return true


## Bursts: every zombie close by is hurt and frozen (bosses for a share of the time).
func _burst() -> void:
	burst = true
	_end_lure()
	_puff_left = PUFF_SECONDS
	Sfx.play(&"snowman_burst", _rules.burst_pitch)
	var damage: float = _rules.burst_damage * weapon.damage_scale()
	for zombie: Zombie in manager.enemies.query_circle(global_position, burst_radius()):
		var share: float = _rules.boss_freeze_share if zombie.is_boss() else 1.0
		zombie.freeze_for(_rules.freeze_seconds * share)
		froze += 1
		hurt(zombie, damage, Vector2.ZERO)
	rotation = 0.0
	var size: float = burst_radius() / ProjectileLook.SNOW_DAY_RADIUS
	ProjectileLook.apply(self, ProjectileLook.SNOW_DAY_BALL, size)
	modulate.a = PUFF_OPACITY


func _end_lure() -> void:
	if lure != null:
		lure.active = false
		lure = null


## The snowmen `weapon` (a Snow Day) has standing.
static func standing(weapon: Weapon) -> Array[SnowmanProjectile]:
	var result: Array[SnowmanProjectile] = []
	var shots: ProjectileManager = weapon.projectiles()
	if shots == null:
		return result
	for shot: Projectile in shots.fired_by(weapon):
		if shot is SnowmanProjectile and (shot as SnowmanProjectile).is_standing():
			result.append(shot as SnowmanProjectile)
	return result


## Builds a snowman for `weapon` at `at`, unless the most are already standing.
static func build_for(weapon: Weapon, at: Vector2) -> void:
	var rules: Snowmen = weapon.stats.snowmen
	var shots: ProjectileManager = weapon.projectiles()
	if rules == null or shots == null or standing(weapon).size() >= rules.max_snowmen:
		return
	var snowman: SnowmanProjectile = shots.spawn(SnowmanProjectile) as SnowmanProjectile
	snowman.build(weapon, at)
