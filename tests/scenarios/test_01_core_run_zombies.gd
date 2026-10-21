extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01, AC-10, AC-13, AC-15): shamblers spawn, chase and hurt Banane.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


## A run with the automatic spawner off, so each scenario places its own zombies.
func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	return run


func test_ac10_zombies_spawn_outside_the_visible_screen() -> void:
	await _quiet_run()
	var view: Rect2 = run.spawner.visible_rect()
	for i: int in 40:
		var zombie: Zombie = run.spawner.spawn_one(SHAMBLER)
		assert_not_null(zombie)
		assert_false(view.has_point(zombie.position), "outside the screen: %s" % zombie.position)
		assert_true(run.arena.play_rect().has_point(zombie.position), "inside the arena")


func test_ac10_spawner_brings_zombies_over_time() -> void:
	run = await start_run()
	assert_eq(run.enemies.alive_count(), 0, "nobody at 0:00")
	await wait_physics_frames(roundi(2.5 * FPS))
	assert_gt(run.enemies.alive_count(), 0, "zombies arrive in the first seconds")


func test_ac10_zombies_walk_towards_the_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(300, 0))
	var before: float = zombie.position.distance_to(banane.global_position)
	await wait_physics_frames(60)
	var after: float = zombie.position.distance_to(banane.global_position)
	assert_almost_eq(before - after, SHAMBLER.move_speed, 6.0, "about one second of walking")


func test_ac10_zombies_chase_the_nearest_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(1200, 0))
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, second.global_position + Vector2(0, 300))
	await wait_physics_frames(30)
	assert_lt(zombie.position.y, second.global_position.y + 300.0, "moves up to player 2")
	assert_almost_eq(zombie.position.x, second.global_position.x, 1.0, "not towards Banane")


func test_ac13_touching_hurts_once_per_invulnerability() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(10, 0))
	await wait_physics_frames(2)
	var once: float = banane.max_health - SHAMBLER.contact_damage
	assert_eq(banane.health, once, "one touch, one hit")
	await wait_physics_frames(roundi(banane.stats.hurt_invulnerability * FPS) - 6)
	assert_eq(banane.health, once, "no second hit while invulnerable")
	await wait_physics_frames(12)
	assert_eq(banane.health, once - SHAMBLER.contact_damage, "hurts again afterwards")
	assert_eq(banane.last_hit_by, "Shambler")


func test_ac13_zombies_do_not_hurt_during_dash() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	await tap_action("p1_dash")
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_physics_frames(2)
	assert_eq(banane.health, banane.max_health)


func test_ac15_never_more_than_the_maximum_alive() -> void:
	await _quiet_run()
	run.enemies.max_alive = 25
	for i: int in 60:
		run.spawner.spawn_one(SHAMBLER)
	assert_eq(run.enemies.alive_count(), 25)
	run.spawner.active = true
	await wait_physics_frames(30)
	assert_eq(run.enemies.alive_count(), 25, "the spawner respects it too")


func test_max_alive_comes_from_the_run_rules() -> void:
	await _quiet_run()
	assert_eq(run.enemies.max_alive, run.rules.max_enemies_alive)
	assert_eq(run.rules.max_enemies_alive, 500)


func test_crowd_spreads_out_instead_of_one_blob() -> void:
	await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(600, 0)
	var crowd: Array[Zombie] = []
	for i: int in 10:
		crowd.append(run.enemies.spawn(SHAMBLER, spot))
	await wait_physics_frames(20)
	var closest: float = INF
	for a: Zombie in crowd:
		for b: Zombie in crowd:
			if a != b:
				closest = minf(closest, a.position.distance_to(b.position))
	assert_gt(closest, SHAMBLER.radius * 0.5, "zombies pushed each other apart")


func test_hit_zombie_flashes_and_is_knocked_back() -> void:
	await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(600, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	await wait_physics_frames(1)
	assert_false(run.enemies.damage(zombie, 1.0, Vector2(200, 0)), "survives a small hit")
	await wait_physics_frames(1)
	assert_true(zombie.puppet.flash.visible, "white flash")
	assert_gt(zombie.knockback.x, 0.0, "pushed back")


func test_killed_zombie_bursts_and_disappears() -> void:
	await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(600, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	watch_signals(run.enemies)
	assert_true(run.enemies.damage(zombie, 999.0))
	assert_signal_emitted(run.enemies, "zombie_killed")
	assert_eq(run.enemies.alive_count(), 0)
	assert_eq(run.enemies.kills, 1)
	assert_eq(run.effects.get_child_count(), 1, "a burst of pieces and stuffing")
	await wait_physics_frames(2)
	assert_false(is_instance_valid(zombie), "the zombie node is gone")


func test_hud_shows_health() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	assert_eq(run.hud.health_label.text, "100 / 100")
	banane.take_hit(5.0, "Shambler")
	assert_eq(run.hud.health_label.text, "95 / 100")
	assert_eq(run.hud.health_bar.value, 95.0)
