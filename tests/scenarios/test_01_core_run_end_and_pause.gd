extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §2, §3, §9, AC-22, AC-27 to AC-30): end screen, Try again, run log, pause.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


func _press(action: String) -> void:
	sender.action_down(action)
	await wait_process_frames(2)
	sender.action_up(action)
	await wait_process_frames(2)


## Banane picks a card, kills a zombie, then a shambler gets him.
func _die_before_the_goal() -> void:
	run = await start_run()
	run.spawner.active = false
	var banane: Player = first_player()
	run.upgrade_pool = run.upgrade_pool.duplicate()
	banane.apply_upgrade(UpgradeOffer.new(run.upgrade_pool.find(&"quick_feet"), 1))
	var target: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(500, 0))
	run.enemies.damage(target, 999.0)
	disarm(banane)
	banane.health = 1.0
	run.elapsed = 83.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_seconds(Run.DEATH_PAUSE + 0.3)


func test_ac22_dying_before_the_goal_shows_the_stats() -> void:
	await _die_before_the_goal()
	var end: EndScreen = main.current_screen as EndScreen
	assert_not_null(end, "end screen")
	if end == null:
		return
	assert_eq(end.title_label.text, "Banane got stuffed")
	assert_string_contains(end.stats_label.text, "Time survived: 1:23")
	assert_string_contains(end.stats_label.text, "Level: 1")
	assert_string_contains(end.stats_label.text, "Zombies stuffed: 1")
	assert_string_contains(end.stats_label.text, "Got stuffed by: Shambler")
	assert_eq(end.upgrades_label.text, "Upgrades: Quick Feet 1")
	assert_eq(end.seed_label.text, "Seed %d" % end.result.seed_value)


func test_ac27_try_again_starts_a_fresh_run() -> void:
	await _die_before_the_goal()
	(main.current_screen as EndScreen).try_again_button.grab_focus()
	await _press("ui_accept")
	await wait_physics_frames(3)
	var fresh: Run = main.current_screen as Run
	assert_not_null(fresh, "Enter on Try again starts a new run")
	if fresh == null:
		return
	var banane: Player = first_player()
	assert_eq(banane.health, banane.max_health, "full health")
	assert_eq(banane.max_health, banane.stats.max_health)
	assert_eq(banane.progress.level, 1)
	assert_string_starts_with(fresh.hud.timer_label.text, "0:0")
	assert_eq(banane.weapons().size(), 1, "only one weapon")
	assert_not_null(banane.weapon(&"peel_boomerang"), "the Peel Boomerang")
	assert_eq(banane.move_speed(), banane.stats.move_speed, "no boosts left over")


func test_ac28_a_finished_run_appends_one_line_to_the_run_log() -> void:
	await _die_before_the_goal()
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1, "one line")
	if entries.is_empty():
		return
	var entry: Dictionary = entries[0]
	for field: String in ["date", "seed", "time_survived", "goal_reached", "endless_time"]:
		assert_true(entry.has(field), field)
	for field: String in ["level", "kills", "killed_by", "upgrades"]:
		assert_true(entry.has(field), field)
	assert_eq(entry["goal_reached"], false)
	assert_eq(entry["killed_by"], "Shambler")
	assert_eq(entry["upgrades"], ["Quick Feet 1"])


func test_ac29_esc_pauses_and_esc_resumes() -> void:
	run = await start_run()
	var spot: Vector2 = first_player().global_position + Vector2(400, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	await wait_physics_frames(5)
	await _press("pause")
	assert_true(run.pause_menu.is_open(), "pause menu shown")
	var time_before: float = run.elapsed
	var zombie_before: Vector2 = zombie.position
	await wait_physics_frames(30)
	assert_eq(run.elapsed, time_before, "timer stopped")
	assert_eq(zombie.position, zombie_before, "zombies stopped")
	await _press("pause")
	assert_false(run.pause_menu.is_open())
	await wait_physics_frames(10)
	assert_gt(run.elapsed, time_before, "running again")


func test_ac29_resume_button_continues() -> void:
	run = await start_run()
	await _press("pause")
	assert_true(run.is_frozen())
	run.pause_menu.resume_button.pressed.emit()
	assert_false(run.is_frozen())


func test_ac29_give_up_shows_the_end_screen_and_logs_the_run() -> void:
	run = await start_run()
	await _press("pause")
	run.pause_menu.quit_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(main.current_screen is EndScreen, "the end screen (Brought home)")
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1)
	assert_eq(entries[0]["ending"], "quit")


func test_ac30_damage_numbers_toggle_takes_effect_immediately() -> void:
	run = await start_run()
	await _press("pause")
	var was: bool = GameSettings.damage_numbers
	run.pause_menu.damage_numbers_check.button_pressed = not was
	assert_eq(GameSettings.damage_numbers, not was)
	run.pause_menu.damage_numbers_check.button_pressed = was
	assert_eq(GameSettings.damage_numbers, was)


func test_ac30_volume_sliders_take_effect_immediately() -> void:
	run = await start_run()
	await _press("pause")
	var menu: PauseMenu = run.pause_menu
	var sliders: Dictionary[StringName, HSlider] = {
		&"Master": menu.master_slider, &"Effects": menu.effects_slider, &"Music": menu.music_slider
	}
	for bus: StringName in sliders:
		var before: float = GameSettings.volume(bus)
		sliders[bus].value = 0.5
		assert_almost_eq(GameSettings.volume(bus), 0.5, 0.01, "%s at half" % bus)
		sliders[bus].value = 0.0
		assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)), "%s off" % bus)
		sliders[bus].value = before
