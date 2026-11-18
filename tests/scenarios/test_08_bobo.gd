extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §3, AC-87, AC-88, AC-89): Böbö starts with Paw Swat, a wide swipe where he
## faces; his dash is a shoulder charge that shoves zombies and hurts them a little (Bear Hug);
## and he takes less damage than Banane.

const BOBO: HeroStats = preload("res://data/heroes/bobo.tres")


func _start_as_bobo() -> Run:
	main.town.plushies["bobo"] = "in_town"
	main.town.set_hero(0, "bobo")
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	return run


func _zombie(run: Run, at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(run.spawner.schedule.entries[0].enemy, at)
	zombie.max_health = 1000.0
	zombie.health = 1000.0
	return zombie


func test_ac87_bobo_starts_with_paw_swat() -> void:
	await _start_as_bobo()
	var bobo: Player = first_player()
	assert_eq(bobo.stats, BOBO)
	assert_eq(bobo.max_health, BOBO.max_health)
	assert_not_null(bobo.weapon(&"paw_swat"), "his own weapon")


func test_ac89_paw_swat_hits_in_front_not_behind() -> void:
	var run: Run = await _start_as_bobo()
	var bobo: Player = first_player()
	Sfx.history.clear()
	bobo.facing = Vector2.RIGHT
	var front: Zombie = _zombie(run, bobo.global_position + Vector2(50, 0))
	var behind: Zombie = _zombie(run, bobo.global_position + Vector2(-50, 0))
	for i: int in 120:
		await wait_physics_frames(1)
		bobo.facing = Vector2.RIGHT
		if front.health < 1000.0:
			break
	assert_lt(front.health, 1000.0, "the swipe hits in front")
	assert_eq(behind.health, 1000.0, "not behind him at level 1")
	assert_true(Sfx.history.has(&"paw"), "its own sound")


func test_ac88_the_dash_shoves_zombies_and_he_takes_less_damage() -> void:
	var run: Run = await _start_as_bobo()
	var bobo: Player = first_player()
	disarm(bobo)
	var hug: BearHug = bobo.get_node("BearHug") as BearHug
	var in_the_way: Zombie = _zombie(run, bobo.global_position + Vector2(70, 6))
	await wait_physics_frames(2)
	sender.action_down("p1_move_right")
	await wait_physics_frames(2)
	await tap_action("p1_dash")
	sender.action_up("p1_move_right")
	var shove: float = 0.0
	for i: int in 12:
		await wait_physics_frames(1)
		shove = maxf(shove, in_the_way.knockback.length())
	assert_eq(hug.shoves, 1, "the charge hit the zombie in its way once")
	assert_lt(in_the_way.health, 1000.0, "and hurt it a little")
	assert_gt(shove, 0.0, "and shoved it away")
	run.enemies.damage(in_the_way, 10000.0)
	while bobo.is_invulnerable():
		await wait_physics_frames(1)
	var before: float = bobo.health
	assert_true(bobo.take_hit(10.0, "test"))
	assert_almost_eq(before - bobo.health, 10.0 * BOBO.damage_taken, 0.01, "Bear Hug: less damage")
