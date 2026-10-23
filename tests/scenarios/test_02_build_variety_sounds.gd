extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §12): every weapon has its own sound when it attacks; elites, gift boxes,
## evolutions and bosses have their own sounds, and an evolution sounds bigger than a gift box.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const WEAPONS_DIR: String = "res://data/weapons/"
const TOUGH: float = 100000.0

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
	Sfx.history.clear()
	return run


func _all_weapons() -> Array[WeaponStats]:
	var result: Array[WeaponStats] = []
	for file: String in DirAccess.get_files_at(WEAPONS_DIR):
		if file.ends_with(".tres"):
			result.append(load(WEAPONS_DIR + file) as WeaponStats)
	return result


func _tough_zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.health = TOUGH
	zombie.max_health = TOUGH
	zombie.move_speed = 0.0
	return zombie


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _played(sound: StringName) -> Callable:
	return func() -> bool: return Sfx.history.has(sound)


func test_every_weapon_plays_its_own_sound_when_it_attacks() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_tough_zombie(banane.global_position + Vector2(120, 0))
	var silent: PackedStringArray = []
	for stats: WeaponStats in _all_weapons():
		disarm(banane)
		Sfx.history.clear()
		var weapon: Weapon = banane.add_weapon(stats)
		var shots: Array[bool] = []
		weapon.fired.connect(func() -> void: shots.append(true))
		await _wait_until(func() -> bool: return not shots.is_empty(), 4.0)
		if shots.is_empty() or not Sfx.history.has(stats.sound):
			silent.append("%s (fired: %s)" % [stats.id, not shots.is_empty()])
	assert_eq(silent, PackedStringArray(), "weapons without their sound")


func test_the_stuffing_cloud_puffs_often_but_its_sound_comes_rarely() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_tough_zombie(banane.global_position + Vector2(50, 0))
	var cloud: WeaponStats = load(WEAPONS_DIR + "stuffing_cloud.tres")
	assert_gt(cloud.sound_gap, 1.0, "a gap in data")
	var weapon: Weapon = banane.add_weapon(cloud)
	var shots: Array[bool] = []
	weapon.fired.connect(func() -> void: shots.append(true))
	Sfx.history.clear()
	await wait_seconds(3.2)
	assert_gt(shots.size(), 5, "it attacks several times a second")
	assert_between(Sfx.history.count(&"fluff"), 1, 3, "but its sound plays at most every 1.5 s")


func test_an_elite_arriving_has_its_own_sound() -> void:
	await _quiet_run()
	run.spawner.spawn_elite(SHAMBLER)
	assert_true(await _wait_until(_played(&"elite"), 0.5), "the elite bell rings")


func test_bosses_sound_heavier_when_hit_and_beaten() -> void:
	await _quiet_run()
	var ted: Zombie = run.spawner.spawn_boss(run.spawner.schedule.mini_boss)
	Sfx.history.clear()
	run.enemies.damage(ted, 1.0)
	assert_true(Sfx.history.has(&"boss_hit"), "a boss hit is a heavy thud")
	assert_false(Sfx.history.has(&"hit"), "not the normal hit")
	var shambler: Zombie = _tough_zombie(first_player().global_position + Vector2(300, 0))
	run.enemies.damage(shambler, 1.0)
	assert_true(Sfx.history.has(&"hit"), "normal zombies keep the normal hit")
	Sfx.history.clear()
	run.enemies.damage(ted, TOUGH * 100.0)
	assert_true(Sfx.history.has(&"boss_down"), "beating a boss has its own sound")
	assert_false(Sfx.history.has(&"pop"), "not just a pop")


func test_a_gift_box_opens_with_its_own_sound() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.add_weapon(banane.stats.starting_weapon)
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0), "the box opens")
	assert_true(await _wait_until(_played(&"gift_open"), 1.0), "with a pop and a sparkle")
	assert_false(Sfx.history.has(&"evolution"))


func test_an_evolution_has_a_bigger_sound_than_a_gift_box() -> void:
	await _quiet_run()
	var pool: UpgradePool = run.upgrade_pool
	var evolution: EvolutionDef = pool.evolution_into(&"banana_split")
	var banane: Player = first_player()
	var base: UpgradeDef = pool.find(evolution.weapon)
	banane.add_weapon(base.weapon).level = base.top_level()
	banane.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0), "the box opens")
	assert_true(await _wait_until(_played(&"evolution"), 1.0), "the evolution fanfare plays")
	assert_false(Sfx.history.has(&"gift_open"), "instead of the normal gift sound")
