extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §8, §10, AC-14, AC-15): a killed bloater bursts into a clearly shown cloud
## that hurts Banane while he stands in it and then disappears; tanks are big, slow and tough;
## the new zombie types show up in a real run.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const BLOATER: EnemyStats = preload("res://data/enemies/bloater.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")

var run: Run
var bursts: Array[EnemyCloud] = []


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	bursts.clear()
	run.enemies.zombie_burst.connect(
		func(_zombie: Zombie, cloud: EnemyCloud) -> void: bursts.append(cloud)
	)
	return run


## A bloater standing still at `offset` from Banane, killed right away.
func _pop_bloater(offset: Vector2) -> EnemyCloud:
	var bloater: Zombie = run.enemies.spawn(BLOATER, first_player().global_position + offset)
	bloater.move_speed = 0.0
	assert_true(run.enemies.damage(bloater, 1000.0), "the bloater is killed")
	return bursts[-1] if not bursts.is_empty() else null


func test_ac14_killed_bloater_leaves_a_cloud_that_hurts_then_disappears() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var health: float = banane.health
	var cloud: EnemyCloud = _pop_bloater(Vector2(50, 0))
	assert_not_null(cloud, "it burst into a cloud")
	assert_eq(run.projectiles.hostile_count(), 1)
	await wait_physics_frames(10)
	assert_lt(banane.health, health, "standing in the cloud hurts")
	assert_eq(banane.last_hit_by, "Bloater", "you know what hit you")
	await wait_seconds(BLOATER.death_cloud.duration)
	assert_eq(run.projectiles.hostile_count(), 0, "the cloud is gone")
	var after: float = banane.health
	await wait_seconds(1.0)
	assert_eq(banane.health, after, "and stops hurting")


func test_ac14_it_keeps_hurting_while_banane_stays_inside() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var hits: Array[float] = []
	banane.hurt.connect(func(amount: float) -> void: hits.append(amount))
	_pop_bloater(Vector2(30, 20))
	await wait_seconds(BLOATER.death_cloud.duration)
	assert_gte(hits.size(), 3, "several hits over the cloud's life")
	assert_eq(hits[0], BLOATER.death_cloud.damage)


func test_ac14_outside_the_cloud_is_safe() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var health: float = banane.health
	var cloud: EnemyCloud = _pop_bloater(Vector2(BLOATER.death_cloud.radius + 40.0, 0))
	await wait_seconds(BLOATER.death_cloud.duration)
	assert_eq(banane.health, health, "killed from a distance, no damage")
	assert_eq(cloud.radius, BLOATER.death_cloud.radius)


func test_ac14_walking_out_of_the_cloud_stops_the_damage() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var health: float = banane.health
	_pop_bloater(Vector2(-20, 0))
	await wait_physics_frames(5)
	assert_lt(banane.health, health, "hit once")
	await hold_action("p1_move_right", roundi(0.8 * FPS))
	var outside: float = banane.health
	await wait_seconds(1.0)
	assert_eq(banane.health, outside, "no more hits outside")


func test_ac14_the_cloud_is_drawn_on_the_danger_layer_at_its_real_size() -> void:
	await _quiet_run()
	var cloud: EnemyCloud = _pop_bloater(Vector2(300, 0))
	await wait_seconds(0.3)
	assert_eq(cloud.get_parent().z_index, ProjectileManager.HOSTILE_Z, "above everything")
	var probe: Sprite2D = Sprite2D.new()
	ProjectileLook.apply(probe, ProjectileLook.HAZARD)
	var drawn_radius: float = ProjectileLook.HAZARD_RADIUS * cloud.scale.x / probe.scale.x
	probe.free()
	assert_almost_eq(drawn_radius, cloud.radius, 2.0, "its edge is where it hurts")


func test_goal_pops_make_no_clouds() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	for i: int in 5:
		run.enemies.spawn(BLOATER, banane.global_position + Vector2.from_angle(i * 1.2) * 60.0)
	run.elapsed = run.rules.goal_seconds - 0.05
	await wait_seconds(Run.POP_CHAIN_TIME + 0.2)
	assert_eq(run.enemies.alive_count(), 0)
	assert_eq(run.projectiles.hostile_count(), 0, "celebrating is safe")


func test_bloater_is_a_balloon_pig_and_tank_an_elephant() -> void:
	await _quiet_run()
	var at: Vector2 = first_player().global_position + Vector2(400, 0)
	assert_eq(run.enemies.spawn(BLOATER, at).puppet.look.prefix, "pig")
	assert_eq(run.enemies.spawn(TANK, at + Vector2(0, 100)).puppet.look.prefix, "elephant")


func test_ac15_tank_is_slower_and_survives_what_kills_a_shambler() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var tank: Zombie = run.enemies.spawn(TANK, banane.global_position + Vector2(400, 0))
	var shambler: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(-400, 0))
	await wait_physics_frames(roundi(2.0 * FPS))
	var tank_walked: float = 400.0 - tank.position.distance_to(banane.global_position)
	var shambler_walked: float = 400.0 - shambler.position.distance_to(banane.global_position)
	assert_lt(tank_walked, shambler_walked, "the tank walks slower")
	assert_true(run.enemies.damage(shambler, SHAMBLER.max_health), "this kills a shambler")
	assert_false(run.enemies.damage(tank, SHAMBLER.max_health), "but not a tank")


func test_ac16_new_types_join_a_real_run() -> void:
	await _quiet_run()
	first_player().invincible = true
	run.spawner.active = true
	run.rng.seed = 5
	var kinds: Array[String] = ["Shambler", "Runner", "Spitter", "Bloater", "Tank"]
	var seen: Dictionary[String, bool] = {}
	run.elapsed = 205.0
	for i: int in roundi(25.0 * FPS):
		for zombie: Zombie in run.enemies.zombies:
			seen[zombie.stats.display_name] = true
		if seen.size() == kinds.size():
			break
		await wait_physics_frames(1)
	for kind: String in kinds:
		assert_true(seen.has(kind), "%s after 3:25" % kind)
