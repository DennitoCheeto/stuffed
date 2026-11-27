class_name LassoRope
extends Node2D
## Lasso Lash's lasso (spec 11 §4.5). `rope_in(direction)` picks the toughest zombie in the front
## arc (an elite first, never a boss) and holds it (`Zombie.held`): it swings once around the hero,
## hurting and pushing every zombie it passes (once each), then flies towards the hero's own
## cursor, and where it lands the snipped thread hurts it (`LassoThrow.snip_factor` × the lash).
## With no elite to rope, a boss in the arc takes the lash a second time instead (bosses are never
## moved). Draws the rope (swing) or a calm streak (throw) with one line, above the floor.

enum Phase { IDLE, SWING, THROW }

const NAME: StringName = &"LassoRope"

## The weapon whose lasso this is (its numbers, its hero and its tally row).
var weapon: Weapon
var phase: Phase = Phase.IDLE
## The zombie on the rope right now (null while idle).
var roped: Zombie
## Counts for tests: zombies roped, zombies the swing hit, snips that landed, double boss hits.
var ropes: int = 0
var swing_hits: int = 0
var snips: int = 0
var boss_doubles: int = 0

var _time: float = 0.0
var _start_angle: float = 0.0
var _start_distance: float = 0.0
var _throw_from: Vector2 = Vector2.ZERO
var _throw_to: Vector2 = Vector2.ZERO
var _passed: Dictionary[int, bool] = {}
var _drawn: bool = false


func _init() -> void:
	name = NAME
	top_level = true
	z_as_relative = false
	z_index = WorldLayers.OWN_SHOTS


func is_busy() -> bool:
	return phase != Phase.IDLE


## The front lash went towards `direction`: rope its toughest zombie, or hit a boss twice.
## Returns true if it did either.
func rope_in(direction: Vector2) -> bool:
	var lasso: LassoThrow = _lasso()
	var manager: EnemyManager = weapon.enemies() if weapon != null else null
	if lasso == null or manager == null or is_busy():
		return false
	var best: Zombie = null
	var boss: Zombie = null
	for zombie: Zombie in _in_arc(direction, manager):
		if zombie.is_boss():
			boss = zombie
		elif best == null or _tougher(zombie, best):
			best = zombie
	if boss != null and (best == null or not best.is_elite()):
		boss_doubles += 1
		manager.damage(boss, weapon.current().damage, Vector2.ZERO, weapon)
		return true
	if best == null:
		return false
	_hold(best)
	return true


## Lets go of the roped zombie (it walks on where it is).
func release() -> void:
	if roped != null and is_instance_valid(roped):
		roped.held = false
	roped = null
	phase = Phase.IDLE
	_passed.clear()


## Where the swing is right now (`share` 0..1 of the way round), around the hero.
func swing_point(share: float) -> Vector2:
	var lasso: LassoThrow = _lasso()
	var grow: float = clampf(share * 4.0, 0.0, 1.0)
	var distance: float = lerpf(_start_distance, lasso.swing_radius, grow)
	return weapon.origin() + Vector2.from_angle(_start_angle + TAU * share) * distance


## Where a throw from `from` comes down: towards the cursor, at most `throw_reach` away, inside
## the walls.
func landing_from(from: Vector2) -> Vector2:
	var lasso: LassoThrow = _lasso()
	var aim: Vector2 = weapon.aim_point()
	var to: Vector2 = aim
	if from.distance_to(aim) > lasso.throw_reach:
		to = from + from.direction_to(aim) * lasso.throw_reach
	var manager: EnemyManager = weapon.enemies()
	if manager != null and manager.play_rect.size != Vector2.ZERO:
		var inside: Rect2 = manager.play_rect.grow(-roped.radius())
		to = to.clamp(inside.position, inside.end)
	return to


func _exit_tree() -> void:
	release()


func _lasso() -> LassoThrow:
	return weapon.stats.lasso_throw if weapon != null and weapon.stats != null else null


## The living zombies inside the front lash's arc.
func _in_arc(direction: Vector2, manager: EnemyManager) -> Array[Zombie]:
	var numbers: WeaponLevel = weapon.current()
	var half_width: float = deg_to_rad(numbers.spread_degrees) / 2.0
	var center: Vector2 = weapon.origin()
	var result: Array[Zombie] = []
	for zombie: Zombie in manager.query_circle(center, numbers.area):
		if zombie.dead or zombie.held:
			continue
		if absf(direction.angle_to(zombie.position - center)) <= half_width:
			result.append(zombie)
	return result


## Elites before normal zombies, then the one with the most health in all.
func _tougher(a: Zombie, b: Zombie) -> bool:
	if a.is_elite() != b.is_elite():
		return a.is_elite()
	return a.max_health > b.max_health


func _hold(zombie: Zombie) -> void:
	roped = zombie
	zombie.held = true
	ropes += 1
	phase = Phase.SWING
	_time = 0.0
	var offset: Vector2 = zombie.position - weapon.origin()
	_start_angle = offset.angle()
	_start_distance = offset.length()
	_passed = {zombie.get_instance_id(): true}
	Sfx.play(_lasso().rope_sound)


func _physics_process(delta: float) -> void:
	if phase == Phase.IDLE:
		return
	var lasso: LassoThrow = _lasso()
	var manager: EnemyManager = weapon.enemies() if weapon != null else null
	if lasso == null or manager == null or not is_instance_valid(roped) or roped.dead:
		release()
		return
	_time += delta
	if phase == Phase.SWING:
		_swing(lasso, manager)
	else:
		_fly(lasso, manager)


func _swing(lasso: LassoThrow, manager: EnemyManager) -> void:
	var share: float = minf(_time / maxf(lasso.swing_seconds, 0.001), 1.0)
	roped.position = swing_point(share)
	if manager.play_rect.size != Vector2.ZERO:
		var inside: Rect2 = manager.play_rect.grow(-roped.radius())
		roped.position = roped.position.clamp(inside.position, inside.end)
	var reach: float = roped.radius() + lasso.swing_reach
	var damage: float = lasso.swing_damage * weapon.damage_scale()
	for other: Zombie in manager.query_circle(roped.position, reach):
		var id: int = other.get_instance_id()
		if _passed.has(id) or other.dead or other.held:
			continue
		_passed[id] = true
		swing_hits += 1
		var push: Vector2 = Vector2.ZERO
		if not other.is_boss():
			push = weapon.origin().direction_to(other.position) * lasso.swing_push
		manager.damage(other, damage, push, weapon)
	if share >= 1.0:
		phase = Phase.THROW
		_time = 0.0
		_throw_from = roped.position
		_throw_to = landing_from(_throw_from)


func _fly(lasso: LassoThrow, manager: EnemyManager) -> void:
	var share: float = minf(_time / maxf(lasso.throw_seconds, 0.001), 1.0)
	roped.position = _throw_from.lerp(_throw_to, ease(share, 0.6))
	if share < 1.0:
		return
	var thrown: Zombie = roped
	release()
	snips += 1
	Sfx.play(lasso.snip_sound)
	manager.damage(thrown, weapon.current().damage * lasso.snip_factor, Vector2.ZERO, weapon)


func _process(_delta: float) -> void:
	if is_busy() or _drawn:
		modulate.a = GameSettings.own_effects
		queue_redraw()
	_drawn = is_busy()


func _draw() -> void:
	var lasso: LassoThrow = _lasso()
	if lasso == null or not is_busy() or not is_instance_valid(roped):
		return
	if phase == Phase.SWING:
		draw_line(weapon.origin(), roped.position, lasso.rope_color, lasso.rope_width)
		return
	var way: Vector2 = _throw_from.direction_to(_throw_to)
	var front: Vector2 = roped.position - way * roped.radius() * 0.5
	var back: Vector2 = roped.position - way * (roped.radius() + lasso.streak_length)
	draw_line(front, back, lasso.streak_color, lasso.streak_width)
