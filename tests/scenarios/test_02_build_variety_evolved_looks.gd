extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §20, AC-30): an evolved weapon's shots look clearly different from its base
## weapon's (own part, bigger, glitter trail), each hit makes a sparkle pop, and its HUD slot
## gets the golden evolved frame.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const TOUGH: float = 100000.0
const EVOLVED_IDS: Array[StringName] = [
	&"banana_split", &"pincushion_volley", &"sewing_storm", &"yarn_bomb"
]

var run: Run


func before_each() -> void:
	RecipeBook.seen.clear()
	await super()


func after_each() -> void:
	RecipeBook.seen.clear()
	super()


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	first_player().invincible = true
	return run


func _tough_zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.health = TOUGH
	zombie.move_speed = 0.0
	return zombie


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


## The first shot `weapon` has in flight that is a real shot (not a sparkle or sticky yarn).
func _shot_of(weapon: Weapon) -> Projectile:
	for shot: Projectile in run.projectiles.fired_by(weapon):
		if not shot is SparkleProjectile and not shot is StickyYarnProjectile:
			return shot
	return null


func _sparkle_of(weapon: Weapon) -> SparkleProjectile:
	for shot: Projectile in run.projectiles.fired_by(weapon):
		if shot is SparkleProjectile:
			return shot as SparkleProjectile
	return null


func _drop(weapon: Weapon) -> void:
	weapon.get_parent().remove_child(weapon)
	weapon.free()
	first_player().loadout_changed.emit()


## Fresh zombies all around player 1 at `distance` (earlier hits may have pushed others away).
func _ring_of_zombies(distance: float) -> void:
	for i: int in 8:
		var at: Vector2 = Vector2.from_angle(TAU * i / 8.0) * distance
		_tough_zombie(first_player().global_position + at)


func _slot_of(weapon: Weapon) -> LoadoutSlot:
	return run.hud.weapon_slots[first_player().weapons().find(weapon)]


func test_ac30_evolved_shots_look_different_from_the_base_weapon() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	for evolved_id: StringName in EVOLVED_IDS:
		var evolution: EvolutionDef = run.upgrade_pool.evolution_into(evolved_id)
		var base_def: UpgradeDef = run.upgrade_pool.find(evolution.weapon)
		_ring_of_zombies(160.0)
		var base: Weapon = banane.add_weapon(base_def.weapon)
		base.level = base_def.top_level()
		banane.loadout_changed.emit()
		assert_true(await _wait_until(func() -> bool: return _shot_of(base) != null, 4.0))
		var base_shot: Projectile = _shot_of(base)
		var base_region: Rect2 = base_shot.region_rect
		var base_size: float = base_shot.scale.x
		assert_null(base_shot.look, "%s: the normal look" % base_def.id)
		assert_false(_slot_of(base).evolved, "%s: plain HUD slot" % base_def.id)
		var evolved: Weapon = banane.evolve(evolution)
		_ring_of_zombies(evolved.current().reach)
		await wait_physics_frames(1)
		assert_true(await _wait_until(func() -> bool: return _shot_of(evolved) != null, 4.0))
		var shot: Projectile = _shot_of(evolved)
		assert_not_null(shot.look, "%s: wears its own look" % evolved_id)
		assert_ne(shot.region_rect, base_region, "%s: another felt part" % evolved_id)
		assert_gt(shot.scale.x, base_size * 1.15, "%s: bigger shots" % evolved_id)
		assert_not_null(shot.trail, "%s: a glitter trail" % evolved_id)
		if shot.trail != null:
			assert_true(shot.trail.emitting, "%s: the trail is on" % evolved_id)
			assert_eq(shot.trail.color, evolved.stats.shot_look.trail_color)
		var slot: LoadoutSlot = _slot_of(evolved)
		assert_true(slot.evolved, "%s: evolved HUD slot" % evolved_id)
		assert_true(slot.frame.visible, "%s: golden frame + star" % evolved_id)
		var has_sparkle: Callable = func() -> bool: return _sparkle_of(evolved) != null
		var popped: bool = await _wait_until(has_sparkle, 4.0)
		assert_true(popped, "%s: a sparkle pop on a hit" % evolved_id)
		if popped:
			var sparkle: SparkleProjectile = _sparkle_of(evolved)
			assert_gt(sparkle.radius(), 0.0)
			assert_lte(sparkle.radius(), evolved.stats.shot_look.flash_radius + 0.01)
		_drop(evolved)
		await wait_physics_frames(2)


func test_ac30_a_pooled_shot_loses_the_evolved_look_for_the_base_weapon() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_tough_zombie(banane.global_position + Vector2(160, 0))
	var evolution: EvolutionDef = run.upgrade_pool.evolution_into(&"pincushion_volley")
	banane.add_weapon(evolution.evolved)
	var volley: Weapon = banane.weapon(&"pincushion_volley")
	assert_true(await _wait_until(func() -> bool: return _shot_of(volley) != null, 4.0))
	_drop(volley)
	await wait_physics_frames(2)
	var sniper_def: UpgradeDef = run.upgrade_pool.find(evolution.weapon)
	var sniper: Weapon = banane.add_weapon(sniper_def.weapon)
	assert_true(await _wait_until(func() -> bool: return _shot_of(sniper) != null, 4.0))
	var pin: Projectile = _shot_of(sniper)
	assert_null(pin.look, "a reused pin is a plain pin again")
	assert_false(pin.trail != null and pin.trail.emitting, "no trail")
