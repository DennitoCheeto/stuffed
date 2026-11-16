extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §2, §3, §8, §10, AC-74, AC-81): the moon calendar by the fort door appears
## once 2 buildings are built, every finished expedition ticks it down by one (the end screen
## says it too), and the town developer menu calls the siege, damages and repairs buildings.

var town: Town


func _settle() -> void:
	for i: int in roundi(6.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func _building(id: StringName) -> TownBuilding:
	return town.buildings[id]


## Gives up a run the way the player does (pause menu) and returns the end screen.
func _give_up() -> EndScreen:
	var run: Run = main.current_screen as Run
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	return main.current_screen as EndScreen


func test_ac74_the_calendar_appears_once_two_buildings_stand() -> void:
	town = await go_to_town()
	assert_false(town.calendar.visible, "no warning in a fresh town")
	town.dev_menu.press(TownDevMenu.build_label(_building(&"toy_box_armory")))
	await _settle()
	assert_false(town.calendar.visible, "one building: nothing to defend yet")
	town.dev_menu.press(TownDevMenu.build_label(_building(&"lucky_jar")))
	await _settle()
	assert_true(town.calendar.visible, "two buildings: the horde is on its way")
	assert_eq(town.calendar.nights, 2)
	assert_eq(town.calendar.shown_text(), "The horde arrives in 2 nights.")
	assert_true(town.is_banner_showing(), "with a banner")
	assert_eq(town.banner_title.text, "A horde is on its way!")
	assert_eq(SaveStore.read().siege_nights, 2, "saved at once")


func test_ac74_every_expedition_ticks_one_night_and_the_end_screen_says_it() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 2
	town = await go_to_town()
	assert_eq(town.calendar.shown_text(), "The horde arrives in 2 nights.")
	await start_run()
	var end: EndScreen = await _give_up()
	assert_not_null(end)
	if end == null:
		return
	assert_eq(main.town.siege_nights, 1, "one night went by")
	assert_true(end.brought_home.horde_label.visible)
	assert_eq(end.brought_home.horde_label.text, "1 night until the horde!")
	assert_eq(SaveStore.read().siege_nights, 1, "saved with the haul")
	town = await go_to_town()
	assert_eq(town.calendar.nights, 1)
	assert_eq(town.calendar.shown_text(), "The horde arrives in 1 night.")
	await start_run()
	end = await _give_up()
	assert_eq(end.brought_home.horde_label.text, "The horde is coming tonight!")
	town = await go_to_town()
	assert_eq(town.calendar.nights, 0)
	assert_eq(town.calendar.shown_text(), "The horde arrives tonight!")


func test_ac74_no_line_on_the_end_screen_before_the_warning() -> void:
	await start_run()
	var end: EndScreen = await _give_up()
	assert_not_null(end)
	if end != null:
		assert_false(end.brought_home.horde_label.visible)
	assert_eq(main.town.siege_nights, -1)


func test_ac81_the_countdown_comes_back_after_reopening_the_game() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 2
	await start_run()
	main.save_now()
	# The game closes during the run: on the next start it counts as given up (one night).
	main.load_town()
	assert_eq(main.town.siege_nights, 1, "the unfinished run was a night too")
	var before: Dictionary = main.town.to_dict()
	main.load_town()
	assert_eq(main.town.to_dict(), before, "same town after loading it again")


func test_dev_menu_calls_the_siege_and_damages_and_repairs_buildings() -> void:
	main.town.building_levels = {"toy_box_armory": 2, "lucky_jar": 1}
	town = await go_to_town()
	await _settle()
	town.dev_menu.press(TownDevMenu.SIEGE_NOW)
	assert_eq(main.town.siege_nights, 0)
	assert_eq(town.calendar.shown_text(), "The horde arrives tonight!")
	assert_eq(SaveStore.read().siege_nights, 0, "saved")
	assert_eq(town.dev_menu.damage_one(), "toy_box_armory")
	assert_eq(town.dev_menu.damage_one(), "lucky_jar")
	assert_eq(town.dev_menu.damage_one(), "", "ruins can't be damaged")
	assert_true(SaveStore.read().is_damaged("lucky_jar"), "saved")
	town.dev_menu.press(TownDevMenu.REPAIR_ALL)
	assert_eq(main.town.damaged.size(), 0)
	assert_eq(SaveStore.read().damaged.size(), 0, "saved")
