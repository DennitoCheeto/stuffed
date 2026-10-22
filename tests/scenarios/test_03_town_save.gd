extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §3, §9, AC-47): the town is saved after every run, a running run is saved
## every few seconds, a closed game counts the run as given up, and "Start over" asks twice.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const RULES: MaterialRules = preload("res://data/town/material_rules.tres")


## A quiet run: no spawns, no weapons, so the test decides what happens.
func _quiet_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## Starts the game again, as after closing it (the old Main is gone without banking the run).
func _restart_game() -> void:
	remove_child(main)
	main.free()
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	await wait_physics_frames(1)


func _saved() -> TownSave:
	return SaveStore.read()


func test_ac47_a_running_run_is_saved_every_few_seconds() -> void:
	var run: Run = await _quiet_run()
	assert_eq(_saved().runs_started, 1, "starting a run is saved")
	run.haul.add("coins", 21)
	run.elapsed = Run.CHECKPOINT_SECONDS - 0.05
	await wait_physics_frames(5)
	var haul: RunHaul = RunHaul.from_dict(_saved().unfinished_run)
	assert_eq(haul.amount("coins"), 21, "the haul so far is on disk")


func test_ac47_closing_the_game_mid_run_counts_as_given_up() -> void:
	var run: Run = await _quiet_run()
	run.haul.add("coins", 21)
	run.haul.add("stuffing", 3)
	main.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await _restart_game()
	assert_eq(main.town.material("coins"), ceili(21 * RULES.keep_share_lost))
	assert_eq(main.town.material("stuffing"), ceili(3 * RULES.keep_share_lost))
	assert_true(main.town.unfinished_run.is_empty())
	assert_eq(_saved().material("coins"), main.town.material("coins"), "and saved right away")
	await _restart_game()
	assert_eq(main.town.material("coins"), 11, "settled only once")


func test_ac47_getting_stuffed_banks_the_lost_share() -> void:
	var run: Run = await _quiet_run()
	run.haul.add("coins", 31)
	var banane: Player = first_player()
	banane.health = 1.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	assert_true(main.current_screen is EndScreen, "end screen")
	assert_eq(_saved().material("coins"), 16, "half of 31, rounded up")
	assert_true(_saved().unfinished_run.is_empty())


func test_ac47_giving_up_from_the_pause_menu_banks_the_lost_share() -> void:
	var run: Run = await _quiet_run()
	run.haul.add("coins", 10)
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	assert_true(main.current_screen is TitleScreen)
	assert_eq(_saved().material("coins"), 5)


func test_ac47_beating_the_king_keeps_everything() -> void:
	var run: Run = await _quiet_run()
	run.haul.add("coins", 31)
	beat_the_boss(run)
	await wait_for_goal_screen(run)
	run.goal_screen.end_button.pressed.emit()
	await wait_physics_frames(2)
	assert_eq(_saved().material("coins"), 31)
	assert_eq(main.town.material("coins"), 31)


func test_ac47_start_over_asks_twice_then_deletes_the_town() -> void:
	var town: TownSave = TownSave.new()
	town.materials["coins"] = 500
	SaveStore.write(town)
	await _restart_game()
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_true(title.start_over_button.visible, "offered when there is a save")
	title.start_over_button.pressed.emit()
	assert_true(title.confirm_box.visible)
	title.no_button.pressed.emit()
	assert_false(title.confirm_box.visible, "No backs out")
	title.start_over_button.pressed.emit()
	title.yes_button.pressed.emit()
	assert_eq(title.confirm_label.text, "Really? Your whole town will be gone.")
	assert_true(SaveStore.exists(), "nothing deleted after the first Yes")
	title.yes_button.pressed.emit()
	assert_false(SaveStore.exists(), "deleted after the second Yes")
	assert_eq(main.town.material("coins"), 0)
	assert_false(title.start_over_button.visible)


func test_start_over_is_hidden_without_a_save() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_false(title.start_over_button.visible)


func test_ac47_quitting_from_the_title_saves() -> void:
	main.town.materials["coins"] = 77
	(main.current_screen as TitleScreen).quit_button.pressed.emit()
	assert_eq(_saved().material("coins"), 77)
