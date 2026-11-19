extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §5, §9, AC-110): Settings has 4 sewn tabs (Sound, Screen, Controls,
## Readability) that a click or Q / E switch. The Screen tab's window mode and V-Sync apply at
## once, are saved and come back after a restart; F11 / Alt+Enter update the window switch.


func after_each() -> void:
	GameSettings.reset()
	super.after_each()


func _open_settings() -> SettingsPanel:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	return title.settings


func _shown_pages(page: SettingsPanel) -> Array[int]:
	var shown: Array[int] = []
	for i: int in page.pages.size():
		if page.pages[i].is_visible_in_tree():
			shown.append(i)
	return shown


func test_ac110_four_tabs_and_each_shows_its_own_page() -> void:
	var page: SettingsPanel = await _open_settings()
	var names: PackedStringArray = []
	for tab: SewnButton in page.tabs:
		names.append(tab.text)
		assert_true(tab.is_visible_in_tree(), "%s tab on screen" % tab.text)
	assert_eq(names, PackedStringArray(["Sound", "Screen", "Controls", "Readability"]))
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.SOUND], "opens on Sound")
	assert_true(page.master_slider.is_visible_in_tree(), "Sound has the volume sliders")
	assert_false(page.vsync_check.is_visible_in_tree(), "other tabs hidden")
	page.tabs[SettingsPanel.Tab.SCREEN].pressed.emit()
	await wait_process_frames(1)
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.SCREEN], "a click shows Screen")
	assert_true(page.window_buttons[0].is_visible_in_tree(), "window mode on Screen")
	assert_true(page.vsync_check.is_visible_in_tree(), "V-Sync on Screen")
	assert_false(page.master_slider.is_visible_in_tree(), "Sound hidden")
	sender.key_down(KEY_E)
	await wait_process_frames(1)
	sender.key_up(KEY_E)
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.CONTROLS], "E: next tab")
	assert_true(page.controls.is_visible_in_tree(), "Controls shows the key list")
	sender.key_down(KEY_E)
	await wait_process_frames(1)
	sender.key_up(KEY_E)
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.READABILITY], "E: Readability")
	assert_true(page.damage_numbers_check.is_visible_in_tree(), "damage numbers here")
	assert_true(page.reduced_motion_check.is_visible_in_tree(), "reduced animations here")
	assert_true(page.tabs[SettingsPanel.Tab.READABILITY].button_pressed, "its tab is marked")
	assert_false(page.tabs[SettingsPanel.Tab.SOUND].button_pressed, "the others are not")
	sender.key_down(KEY_E)
	await wait_process_frames(1)
	sender.key_up(KEY_E)
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.SOUND], "E wraps around")
	sender.key_down(KEY_Q)
	await wait_process_frames(1)
	sender.key_up(KEY_Q)
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.READABILITY], "Q goes back")
	page.close()
	page.open()
	assert_eq(_shown_pages(page), [SettingsPanel.Tab.SOUND], "opens on Sound again")


func test_ac110_window_mode_and_vsync_apply_at_once_and_survive_a_restart() -> void:
	var page: SettingsPanel = await _open_settings()
	page.show_tab(SettingsPanel.Tab.SCREEN)
	assert_true(page.window_buttons[GameSettings.WindowMode.WINDOWED].button_pressed, "windowed")
	page.window_buttons[GameSettings.WindowMode.BORDERLESS].pressed.emit()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.BORDERLESS, "chosen")
	assert_eq(GameSettings.applied_window, DisplayServer.WINDOW_MODE_FULLSCREEN, "applied at once")
	assert_true(page.window_buttons[GameSettings.WindowMode.BORDERLESS].button_pressed, "marked")
	assert_false(page.window_buttons[GameSettings.WindowMode.WINDOWED].button_pressed, "unmarked")
	page.vsync_check.button_pressed = false
	assert_false(GameSettings.vsync, "V-Sync off")
	assert_false(GameSettings.applied_vsync, "applied at once")
	assert_true(FileAccess.file_exists(TEST_SETTINGS), "saved")
	# Restart: forget everything, boot the game again from the saved file.
	remove_child(main)
	main.queue_free()
	await wait_process_frames(1)
	GameSettings.reset()
	GameSettings.apply_screen()
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	await wait_physics_frames(1)
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.BORDERLESS, "loaded on boot")
	assert_eq(GameSettings.applied_window, DisplayServer.WINDOW_MODE_FULLSCREEN, "applied on boot")
	assert_false(GameSettings.applied_vsync, "V-Sync off on boot")
	page = await _open_settings()
	page.show_tab(SettingsPanel.Tab.SCREEN)
	assert_true(page.window_buttons[GameSettings.WindowMode.BORDERLESS].button_pressed, "shown")
	assert_false(page.vsync_check.button_pressed, "V-Sync switch shows off")


func test_ac110_f11_updates_the_window_switch() -> void:
	var page: SettingsPanel = await _open_settings()
	page.show_tab(SettingsPanel.Tab.SCREEN)
	await tap_action("toggle_fullscreen")
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.FULLSCREEN, "F11: fullscreen")
	assert_eq(GameSettings.applied_window, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	assert_true(page.window_buttons[GameSettings.WindowMode.FULLSCREEN].button_pressed, "marked")
	assert_false(page.window_buttons[GameSettings.WindowMode.WINDOWED].button_pressed)
	assert_true(page.is_open(), "Settings stays open")
	GameSettings.window_mode = GameSettings.WindowMode.WINDOWED
	GameSettings.load_saved()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.FULLSCREEN, "F11 saves it")
	await tap_action("toggle_fullscreen")
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED, "F11: back to a window")
	assert_true(page.window_buttons[GameSettings.WindowMode.WINDOWED].button_pressed, "marked")
