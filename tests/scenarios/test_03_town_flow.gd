extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §2, §5, §11, AC-37, AC-38): title -> the Pillow Fort -> E at the Bedroom
## door -> a run -> "Brought home" counts the haul into the jars -> "Back to the fort".

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const OPEN_FROM_START: Array[StringName] = [&"toy_box_armory", &"lucky_jar"]


func _town() -> Town:
	return main.current_screen as Town


func _end() -> EndScreen:
	return main.current_screen as EndScreen


## A quiet run from the town: no spawns, no weapons, so the test decides what happens.
func _quiet_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


func _wait_for_count(end: EndScreen) -> void:
	for i: int in roundi(3.0 * FPS):
		if end.brought_home.is_done():
			return
		await wait_physics_frames(1)


func _die(run: Run) -> void:
	var banane: Player = first_player()
	banane.health = 1.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_seconds(Run.DEATH_PAUSE + 0.3)


func _restart_game() -> void:
	remove_child(main)
	main.free()
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	await wait_physics_frames(1)


func test_title_offers_new_game_first_then_continue() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_eq(title.start_button.text, "New game")
	await go_to_town()
	assert_not_null(_town(), "New game opens the town")
	await _restart_game()
	title = main.current_screen as TitleScreen
	assert_eq(title.start_button.text, "Continue", "the town was saved")
	await go_to_town()
	assert_not_null(_town(), "Continue goes straight to the town")


func test_ac37_new_game_opens_the_town_with_fort_door_scrapbook_and_6_ruins() -> void:
	var town: Town = await go_to_town()
	assert_not_null(town)
	if town == null:
		return
	assert_not_null(town.fort, "the fort in the middle")
	assert_true(town.layout.fort_rect.encloses(town.layout.door_rect), "the door is in the fort")
	assert_not_null(town.scrapbook, "the Scrapbook stand")
	assert_eq(town.ruins.size(), 6, "6 ruins")
	var open_ids: Array[StringName] = []
	for ruin: TownRuin in town.open_ruins():
		open_ids.append(ruin.spot.id)
	open_ids.sort()
	var expected: Array[StringName] = OPEN_FROM_START.duplicate()
	expected.sort()
	assert_eq(open_ids, expected, "exactly the Armory and the Lucky Jar can be rebuilt")
	assert_eq(town.ruins[&"watchtower"].status_label.text, "Rebuild 1 building first")
	assert_eq(main.music.track, &"town", "the town's own music")
	assert_eq(first_player().weapons().size(), 0, "no weapons at home")


func test_ac37_banane_walks_with_wasd_and_the_camera_follows() -> void:
	var town: Town = await go_to_town()
	var banane: Player = first_player()
	var start: Vector2 = banane.global_position
	await hold_action("p1_move_left", 60)
	assert_lt(banane.global_position.x, start.x - 100.0, "A walks left")
	await hold_action("p1_move_down", 40)
	assert_gt(banane.global_position.y, start.y + 50.0, "S walks down")
	await wait_physics_frames(40)
	# Sideways only: the headless test window is square, so the view stops at the bottom wall.
	var gap: float = absf(town.camera.get_screen_center_position().x - banane.global_position.x)
	assert_lt(gap, 20.0, "the camera follows")


func test_ac37_ruins_block_walking() -> void:
	var town: Town = await go_to_town()
	var banane: Player = first_player()
	var ruin: Rect2 = town.layout.spot(&"toy_box_armory").rect
	banane.global_position = Vector2(ruin.position.x - 60.0, ruin.get_center().y)
	await hold_action("p1_move_right", 40)
	assert_lt(banane.global_position.x, ruin.position.x, "stops at the ruin")


func test_ac37_the_fort_and_the_scrapbook_block_walking() -> void:
	var town: Town = await go_to_town()
	var banane: Player = first_player()
	var fort: Rect2 = town.layout.fort_rect
	banane.global_position = Vector2(fort.position.x + 60.0, fort.end.y + 60.0)
	await hold_action("p1_move_up", 40)
	assert_gt(banane.global_position.y, fort.end.y, "stops at the fort")
	var stand: Rect2 = town.layout.scrapbook_rect
	banane.global_position = Vector2(stand.get_center().x, stand.end.y + 60.0)
	await hold_action("p1_move_up", 40)
	assert_gt(banane.global_position.y, stand.end.y, "stops at the Scrapbook stand")


func test_ac38_e_at_the_bedroom_door_starts_a_run() -> void:
	var town: Town = await go_to_town()
	var banane: Player = first_player()
	banane.global_position = town.layout.spawn_position + Vector2(-500, 0)
	await wait_physics_frames(2)
	assert_false(town.prompt_label.visible, "no prompt away from the door")
	await tap_action("p1_interact")
	await wait_physics_frames(2)
	assert_true(main.current_screen is Town, "E away from the door does nothing")
	banane.global_position = town.layout.spawn_position
	await wait_physics_frames(2)
	assert_true(town.prompt_label.visible, "the door shows a prompt")
	assert_string_contains(town.prompt_label.text, "Bedroom")
	await tap_action("p1_interact")
	await wait_physics_frames(2)
	assert_true(main.current_screen is Run, "E at the door starts a run")
	assert_eq(main.town.runs_started, 1)


func test_ac38_after_getting_stuffed_half_is_brought_home_and_back_to_the_fort() -> void:
	main.town.materials["coins"] = 100
	var run: Run = await _quiet_run()
	run.haul.add("coins", 31)
	run.haul.add("stuffing", 3)
	Sfx.history.clear()
	await _die(run)
	var end: EndScreen = _end()
	assert_not_null(end, "the end screen")
	if end == null:
		return
	assert_eq(end.brought_home.amount("coins"), 16, "half of 31, rounded up")
	assert_eq(end.brought_home.amount("stuffing"), 2)
	assert_eq(end.brought_home.amount("thread"), 0)
	await _wait_for_count(end)
	assert_true(end.brought_home.is_done(), "the count ends")
	assert_eq(end.brought_home.shown_gain("coins"), 16)
	assert_eq(end.brought_home.shown_total("coins"), 116, "counted into the jars")
	assert_true(Sfx.history.has(&"pickup"), "with a plip")
	assert_true(end.fort_button.has_focus(), "Back to the fort is ready on the keyboard")
	end.fort_button.pressed.emit()
	await wait_physics_frames(2)
	var town: Town = _town()
	assert_not_null(town, "back in the town")
	if town != null:
		assert_eq(town.jars["coins"].shown, 116, "the jars show the haul")
		assert_eq(town.jars["stuffing"].shown, 2)


func test_ac38_beating_the_king_brings_everything_home() -> void:
	var run: Run = await _quiet_run()
	run.haul.add("coins", 31)
	run.haul.add("thread", 2)
	beat_the_boss(run)
	await wait_for_goal_screen(run)
	run.goal_screen.end_button.pressed.emit()
	await wait_physics_frames(2)
	var end: EndScreen = _end()
	assert_not_null(end)
	if end == null:
		return
	assert_eq(end.brought_home.amount("coins"), 31)
	assert_eq(end.brought_home.amount("thread"), 2)
	assert_eq(end.brought_home.note_label.text, "You kept everything!")
	end.brought_home.finish()
	assert_eq(end.brought_home.shown_total("coins"), 31)
	await go_to_town()
	assert_not_null(_town(), "Back to the fort")


func test_ac38_giving_up_brings_half_home() -> void:
	var run: Run = await _quiet_run()
	run.haul.add("coins", 10)
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	var end: EndScreen = _end()
	assert_not_null(end, "the Brought home screen after giving up too")
	if end == null:
		return
	assert_eq(end.title_label.text, "You gave up")
	assert_eq(end.brought_home.amount("coins"), 5)
	await go_to_town()
	assert_eq(_town().jars["coins"].shown, 5)


func test_esc_in_town_opens_a_menu_with_the_title_screen() -> void:
	var town: Town = await go_to_town()
	await tap_action("pause")
	assert_true(town.menu.is_open(), "Esc opens the town menu")
	town.menu.resume_button.pressed.emit()
	assert_false(town.menu.is_open())
	town.open_menu()
	town.menu.title_button.pressed.emit()
	await wait_physics_frames(2)
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_not_null(title, "back at the title")
	if title != null:
		assert_eq(title.start_button.text, "Continue")
