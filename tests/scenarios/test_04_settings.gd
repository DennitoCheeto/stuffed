extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §6.1-6.2, issue #135): the Settings page opens from the town's Esc menu, the
## title screen and the run's pause menu. A changed volume and "Reduced menu animations" take
## effect at once and are saved (save -> reload -> compare); Back or Esc returns to the menu.

var _volumes: Dictionary[StringName, float] = {}


func before_each() -> void:
	await super.before_each()
	_volumes.clear()
	for bus: StringName in GameSettings.BUSES:
		_volumes[bus] = GameSettings.volume(bus)


func after_each() -> void:
	for bus: StringName in _volumes:
		GameSettings.set_volume(bus, _volumes[bus])
	GameSettings.reduced_motion = false
	GameSettings.damage_numbers = true
	super.after_each()


## Changes Effects volume and reduced animations on `page`, then checks effect and save.
func _change_and_check_saved(page: SettingsPanel) -> void:
	assert_true(page.is_open(), "the Settings page is open")
	assert_true(page.back_button.is_visible_in_tree(), "Back is on screen")
	page.effects_slider.value = 0.4
	assert_almost_eq(GameSettings.volume(&"Effects"), 0.4, 0.01, "Effects volume right away")
	page.reduced_motion_check.button_pressed = true
	assert_true(GameSettings.reduced_motion, "reduced animations right away")
	assert_true(UiFeel.reduced(), "the menus use it")
	assert_true(FileAccess.file_exists(TEST_SETTINGS), "saved to the settings file")
	GameSettings.reduced_motion = false
	GameSettings.set_volume(&"Effects", 1.0)
	GameSettings.load_saved()
	assert_true(GameSettings.reduced_motion, "reload gives the saved switch")
	assert_almost_eq(GameSettings.volume(&"Effects"), 0.4, 0.01, "reload gives the saved volume")


func test_settings_from_the_town_menu_take_effect_are_saved_and_back_returns() -> void:
	var town: Town = await go_to_town()
	town.open_menu()
	var menu: TownMenu = town.menu
	assert_true(menu.is_open(), "the town menu is open")
	assert_eq(menu.settings_button.text, "Settings")
	menu.settings_button.pressed.emit()
	await wait_process_frames(2)
	assert_false(menu.resume_button.is_visible_in_tree(), "the menu steps aside")
	await _change_and_check_saved(menu.settings)
	menu.settings.back_button.pressed.emit()
	await wait_process_frames(2)
	assert_false(menu.settings.is_open(), "Back closes Settings")
	assert_true(menu.is_open(), "the town menu is still open")
	assert_true(menu.resume_button.is_visible_in_tree(), "the town menu is back")
	menu.settings_button.pressed.emit()
	await wait_process_frames(2)
	await tap_action("pause")
	assert_false(menu.settings.is_open(), "Esc closes Settings")
	assert_true(menu.is_open(), "Esc only closes Settings, not the town menu")


func test_settings_from_the_title_screen_take_effect_are_saved_and_back_returns() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_not_null(title, "starts on the title")
	if title == null:
		return
	assert_true(title.settings_button.is_visible_in_tree(), "Settings is on the title screen")
	title.settings_button.pressed.emit()
	await wait_process_frames(2)
	assert_false(title.start_button.is_visible_in_tree(), "the title menu steps aside")
	await _change_and_check_saved(title.settings)
	title.settings.back_button.pressed.emit()
	await wait_process_frames(2)
	assert_false(title.settings.is_open(), "Back closes Settings")
	assert_true(title.start_button.is_visible_in_tree(), "the title menu is back")
	title.settings_button.pressed.emit()
	await wait_process_frames(2)
	await tap_action("pause")
	assert_false(title.settings.is_open(), "Esc closes Settings")
	assert_true(title.start_button.is_visible_in_tree(), "the title menu is back after Esc")


func test_settings_from_the_pause_menu_and_back_to_the_pause_menu() -> void:
	var run: Run = await start_run()
	await tap_action("pause")
	var menu: PauseMenu = run.pause_menu
	assert_true(menu.is_open(), "pause menu open")
	menu.settings_button.pressed.emit()
	await wait_process_frames(2)
	assert_false(menu.panel.visible, "the pause menu steps aside")
	await _change_and_check_saved(menu.settings)
	await tap_action("pause")
	assert_false(menu.settings.is_open(), "Esc closes Settings")
	assert_true(menu.is_open(), "still paused")
	assert_true(menu.panel.visible, "the pause menu is back")
	assert_true(run.is_frozen(), "the run stays frozen")
