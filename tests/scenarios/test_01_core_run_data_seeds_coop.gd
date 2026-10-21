extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §11, §12, AC-33, AC-34, AC-35): numbers come from data files, seeds replay
## runs, and nothing assumes a single player.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


func _quiet_run(seed_value: int = 0) -> Run:
	main.start_run(seed_value)
	await wait_physics_frames(3)
	run = main.current_screen as Run
	run.spawner.active = false
	disarm(first_player())
	return run


func test_ac33_hero_speed_comes_from_the_data() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.stats = banane.stats.duplicate()
	banane.stats.move_speed = 300.0
	var start: Vector2 = banane.global_position
	await hold_action("p1_move_right", 30)
	assert_almost_eq(banane.global_position.x - start.x, 300.0 * 30.0 / FPS, 8.0)


func test_ac33_zombie_numbers_come_from_the_data() -> void:
	await _quiet_run()
	var fast: EnemyStats = SHAMBLER.duplicate()
	fast.move_speed = 90.0
	fast.max_health = 33.0
	var banane: Player = first_player()
	var zombie: Zombie = run.enemies.spawn(fast, banane.global_position + Vector2(400, 0))
	assert_eq(zombie.max_health, 33.0)
	await wait_physics_frames(60)
	var walked: float = 400.0 - zombie.position.distance_to(banane.global_position)
	assert_almost_eq(walked, 90.0, 6.0)


func test_ac33_weapon_and_xp_numbers_come_from_the_data() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var custom_rules: XpRules = banane.xp_rules.duplicate()
	custom_rules.first_level_xp = 2
	banane.progress.rules = custom_rules
	banane.add_xp(2)
	assert_eq(banane.progress.level, 2, "the curve from the data decides")
	var weapon_stats: WeaponStats = load("res://data/weapons/peel_boomerang.tres").duplicate(true)
	weapon_stats.levels[0].damage = 4.0
	var weapon: Weapon = banane.add_weapon(weapon_stats)
	assert_eq(weapon.current().damage, 4.0)


## Spawns for 3 s of a surge and records what appeared where.
func _spawn_record(seed_value: int) -> Array[String]:
	await _quiet_run(seed_value)
	run.elapsed = 150.0
	run.spawner.active = true
	await wait_physics_frames(roundi(3.0 * FPS))
	var record: Array[String] = []
	for zombie: Zombie in run.enemies.zombies:
		var spot: Vector2i = Vector2i(zombie.position.round())
		record.append("%s@%s" % [zombie.stats.display_name, spot])
	return record


func _card_record() -> Array[String]:
	var record: Array[String] = []
	for i: int in 5:
		for offer: UpgradeOffer in run.upgrade_pool.roll({&"peel_boomerang": 1}, run.upgrade_rng):
			record.append(String(offer.upgrade.id))
	return record


func test_ac34_same_seed_same_spawns_and_cards() -> void:
	var first_spawns: Array[String] = await _spawn_record(4242)
	var first_cards: Array[String] = _card_record()
	var second_spawns: Array[String] = await _spawn_record(4242)
	var second_cards: Array[String] = _card_record()
	assert_gt(first_spawns.size(), 5, "enough spawns to compare")
	assert_eq(second_spawns, first_spawns, "same zombies at the same places")
	assert_eq(second_cards, first_cards, "same cards")
	var other_spawns: Array[String] = await _spawn_record(999)
	assert_ne(other_spawns, first_spawns, "another seed gives another run")


func test_ac35_zombies_chase_whichever_player_is_nearer() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(1000, 0))
	var near_second: Zombie = run.enemies.spawn(SHAMBLER, second.global_position + Vector2(200, 0))
	var near_banane: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(-200, 0))
	await wait_physics_frames(30)
	assert_lt(near_second.position.x, second.global_position.x + 200.0, "goes to player 2")
	assert_gt(near_banane.position.x, banane.global_position.x - 200.0, "goes to Banane")


func test_ac35_xp_flies_to_the_nearer_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(100, 0))
	run.pickups.drop(EnemyStats.XpSize.MEDIUM, second.global_position + Vector2(30, 0))
	await wait_physics_frames(30)
	assert_eq(second.progress.xp, 3, "player 2 got it")
	assert_eq(banane.progress.xp, 0)


func test_ac35_the_run_only_ends_when_both_are_down() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(800, 0))
	var finished: Array[RunResult] = []
	run.finished.connect(func(result: RunResult) -> void: finished.append(result))
	banane.take_hit(1000.0, "Shambler")
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	assert_eq(finished.size(), 0, "player 2 still stands")
	assert_false(run.over)
	second.take_hit(1000.0, "Runner")
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	assert_eq(finished.size(), 1, "now the run is over")
