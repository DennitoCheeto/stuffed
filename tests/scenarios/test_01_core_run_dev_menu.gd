extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §9, AC-32): the developer menu (F1).

var run: Run


func _run_with_menu() -> Run:
	run = await start_run()
	run.spawner.active = false
	sender.key_down(KEY_F1)
	await wait_process_frames(2)
	sender.key_up(KEY_F1)
	await wait_process_frames(1)
	return run


func test_ac32_f1_opens_the_developer_menu() -> void:
	await _run_with_menu()
	assert_true(run.dev_menu.visible, "F1 opens it")
	assert_false(run.is_frozen(), "the game keeps running")


func test_ac32_spawn_100_shamblers() -> void:
	await _run_with_menu()
	run.dev_menu.press("100 shamblers")
	assert_eq(run.enemies.alive_count(), 100)
	for zombie: Zombie in run.enemies.zombies:
		assert_eq(zombie.stats.display_name, "Shambler")


func test_ac32_level_up_now() -> void:
	await _run_with_menu()
	run.dev_menu.press("Level up now")
	assert_eq(first_player().progress.level, 2)
	assert_true(run.level_up_screen.is_open(), "the card screen comes up")


func test_ac32_kill_all() -> void:
	await _run_with_menu()
	run.dev_menu.press("10 runners")
	assert_eq(run.enemies.alive_count(), 10)
	run.dev_menu.press("Kill all")
	assert_eq(run.enemies.alive_count(), 0)


func test_ac32_jump_to_half_a_minute_before_the_goal() -> void:
	await _run_with_menu()
	run.dev_menu.press("Jump to 7:30")
	await wait_physics_frames(2)
	assert_string_starts_with(run.hud.timer_label.text, "7:30 / 8:00")
	run.dev_menu.press("+30 s")
	assert_gt(run.elapsed, 479.0)


func test_invincible_pause_and_speed() -> void:
	await _run_with_menu()
	run.dev_menu.press("Invincible")
	assert_false(first_player().take_hit(50.0, "Shambler"), "invincible")
	run.dev_menu.press("Pause")
	assert_true(run.is_frozen(), "paused")
	run.dev_menu.press("Pause")
	assert_false(run.is_frozen())
	run.dev_menu.press("2x")
	assert_eq(Engine.time_scale, 2.0)
	run.dev_menu.press("1x")
	assert_eq(Engine.time_scale, 1.0)


func test_restart_with_the_same_seed() -> void:
	await _run_with_menu()
	var seed_value: int = run.seed_value
	run.dev_menu.press("Restart same seed")
	await wait_process_frames(2)
	var fresh: Run = main.current_screen as Run
	assert_not_null(fresh)
	assert_ne(fresh, run, "a new run")
	assert_eq(fresh.seed_value, seed_value, "same seed")
