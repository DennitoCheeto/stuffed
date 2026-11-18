extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §3, AC-87, AC-88, AC-89): Pip starts with Snowball Toss; her snowballs burst
## and slow the zombies they hit; Chilly Hug slows zombies close to her (bosses less), and
## leaves zombies farther away alone.

const PIP: HeroStats = preload("res://data/heroes/pip.tres")


func _start_as_pip() -> Run:
	main.town.plushies["pip"] = "in_town"
	main.town.set_hero(0, "pip")
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	return run


func _zombie(run: Run, at: Vector2) -> Zombie:
	var stats: EnemyStats = run.spawner.schedule.entries[0].enemy
	return run.enemies.spawn(stats, at)


func test_ac87_pip_starts_with_snowball_toss() -> void:
	await _start_as_pip()
	var pip: Player = first_player()
	assert_eq(pip.stats, PIP)
	assert_not_null(pip.weapon(&"snowball_toss"), "her own weapon")
	assert_null(pip.weapon(&"peel_boomerang"))


func test_ac88_chilly_hug_slows_zombies_close_to_pip() -> void:
	var run: Run = await _start_as_pip()
	var pip: Player = first_player()
	disarm(pip)
	var near: Zombie = _zombie(run, pip.global_position + Vector2(60, 0))
	var far: Zombie = _zombie(run, pip.global_position + Vector2(400, 0))
	var boss: Zombie = run.spawner.spawn_boss(run.spawner.schedule.boss)
	boss.position = pip.global_position + Vector2(-60, 0)
	await wait_physics_frames(3)
	assert_almost_eq(near.slow_amount, PIP.chilly_slow, 0.001, "near: slower")
	assert_eq(far.slow_amount, 0.0, "far away: normal speed")
	assert_almost_eq(boss.slow_amount, PIP.chilly_boss_slow, 0.001, "bosses: a bit slower")
	assert_true((pip.get_node("ChillyHug") as ChillyHug).visible, "frost ring shows")
	var ring: ChillyHug = pip.get_node("ChillyHug") as ChillyHug
	assert_eq(WorldLayers.absolute_z(ring), WorldLayers.FLOOR_MARKS, "on the floor")


func test_ac89_a_snowball_bursts_and_slows_the_group() -> void:
	var run: Run = await _start_as_pip()
	var pip: Player = first_player()
	Sfx.history.clear()
	var spot: Vector2 = pip.global_position + Vector2(250, 0)
	var group: Array[Zombie] = []
	for offset: Vector2 in [Vector2.ZERO, Vector2(15, 10), Vector2(-12, 14)]:
		group.append(_zombie(run, spot + offset))
	for zombie: Zombie in group:
		zombie.max_health = 1000.0
		zombie.health = 1000.0
	var hit: bool = false
	for i: int in 240:
		await wait_physics_frames(1)
		if group[0].slow_amount > 0.0 and group[1].slow_amount > 0.0:
			hit = true
			break
	assert_true(hit, "the snowball landed on the group and slowed it")
	assert_almost_eq(group[0].slow_amount, PIP.starting_weapon.slow, 0.001)
	assert_lt(group[0].health, 1000.0, "and hurt it a little")
	assert_true(Sfx.history.has(&"snowball"), "its own sound")
