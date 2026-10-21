extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §8, AC-14, AC-16): killed zombies drop XP buttons, Banane collects them.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


func test_ac14_killed_zombie_disappears_and_drops_an_xp_button() -> void:
	await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(400, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	await wait_physics_frames(1)
	var where: Vector2 = zombie.position
	run.enemies.damage(zombie, 999.0)
	await wait_physics_frames(2)
	assert_false(is_instance_valid(zombie), "the zombie is gone")
	assert_eq(run.pickups.buttons.size(), 1, "one button dropped")
	var button: XpButton = run.pickups.buttons[0]
	assert_eq(button.position, where, "where the zombie died")
	assert_eq(button.size, SHAMBLER.xp_button, "small button for a shambler")
	assert_eq(button.value, 1)


func test_ac16_button_in_range_flies_to_banane_and_adds_xp() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var button: XpButton = run.pickups.drop(
		EnemyStats.XpSize.MEDIUM, banane.global_position + Vector2(banane.pickup_range - 10.0, 0)
	)
	watch_signals(run.pickups)
	await wait_physics_frames(3)
	assert_lt(button.position.x, banane.global_position.x + banane.pickup_range - 10.0, "moving")
	await wait_physics_frames(30)
	assert_signal_emitted(run.pickups, "collected")
	assert_eq(run.pickups.buttons.size(), 0)
	assert_eq(banane.progress.xp, 3, "a medium button is worth 3")


func test_ac16_button_out_of_range_stays_put() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var spot: Vector2 = banane.global_position + Vector2(banane.pickup_range + 30.0, 0)
	var button: XpButton = run.pickups.drop(EnemyStats.XpSize.SMALL, spot)
	await wait_physics_frames(60)
	assert_eq(button.position, spot)
	assert_eq(banane.progress.xp, 0)


func test_ac16_walking_close_picks_it_up() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var spot: Vector2 = banane.global_position + Vector2(banane.pickup_range + 60.0, 0)
	run.pickups.drop(EnemyStats.XpSize.BIG, spot)
	await hold_action("p1_move_right", 40)
	await wait_physics_frames(20)
	assert_eq(run.pickups.buttons.size(), 0, "collected after walking towards it")
	assert_eq(banane.progress.level, 2, "10 XP is a level-up from level 1")


func test_hud_shows_xp_and_level() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.add_xp(3)
	assert_eq(run.hud.xp_bar.value, 3.0)
	assert_eq(run.hud.xp_bar.max_value, 5.0)
	banane.add_xp(2)
	assert_eq(run.hud.level_label.text, "Lv 2")


func test_chained_pickups_count_up() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	for i: int in 3:
		run.pickups.drop(EnemyStats.XpSize.SMALL, banane.global_position + Vector2(20 + i * 6, 0))
	watch_signals(run.pickups)
	await wait_physics_frames(20)
	assert_signal_emit_count(run.pickups, "collected", 3)
	var last: Array = get_signal_parameters(run.pickups, "collected")
	assert_eq(last[2], 3, "third pickup in a row has chain 3 (rising plip)")
