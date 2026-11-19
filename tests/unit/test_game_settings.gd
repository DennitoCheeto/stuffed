extends GutTest
## GameSettings (spec 10 §5, §9, AC-110): window mode and V-Sync are saved, reloaded and compared
## (hard rule 10); a broken, old or odd settings file loads defaults and never crashes.

const TEST_PATH: String = "user://test_unit_settings.json"

var _old_path: String


func before_each() -> void:
	_old_path = GameSettings.path
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.reset()


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.reset()
	GameSettings.path = _old_path


func _write(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_defaults_are_a_window_with_vsync() -> void:
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED)
	assert_true(GameSettings.vsync)


func test_window_mode_and_vsync_survive_save_and_reload() -> void:
	GameSettings.window_mode = GameSettings.WindowMode.BORDERLESS
	GameSettings.vsync = false
	GameSettings.reduced_motion = true
	assert_true(GameSettings.save(), "written")
	GameSettings.reset()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED, "reset in between")
	GameSettings.load_saved()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.BORDERLESS, "window mode back")
	assert_false(GameSettings.vsync, "V-Sync back")
	assert_true(GameSettings.reduced_motion, "older options still saved")


func test_every_window_mode_round_trips() -> void:
	for mode: int in GameSettings.WINDOW_MODE_IDS.size():
		GameSettings.window_mode = mode as GameSettings.WindowMode
		GameSettings.save()
		GameSettings.reset()
		GameSettings.load_saved()
		assert_eq(GameSettings.window_mode, mode, GameSettings.WINDOW_MODE_IDS[mode])


func test_a_broken_file_loads_defaults() -> void:
	GameSettings.window_mode = GameSettings.WindowMode.FULLSCREEN
	GameSettings.vsync = false
	_write("{ this is not json")
	GameSettings.load_saved()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED)
	assert_true(GameSettings.vsync)
	assert_true(GameSettings.damage_numbers)


func test_an_old_file_keeps_its_options_and_gets_screen_defaults() -> void:
	GameSettings.window_mode = GameSettings.WindowMode.FULLSCREEN
	_write('{"damage_numbers": false, "reduced_motion": true, "volumes": {"Music": 0.5}}')
	GameSettings.load_saved()
	assert_false(GameSettings.damage_numbers, "old option kept")
	assert_true(GameSettings.reduced_motion, "old option kept")
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED, "new option default")
	assert_true(GameSettings.vsync, "new option default")
	GameSettings.set_volume(&"Music", 1.0)


func test_odd_values_load_defaults_without_crashing() -> void:
	_write('{"window_mode": 7, "vsync": "yes", "damage_numbers": null, "volumes": 3}')
	GameSettings.load_saved()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED)
	assert_true(GameSettings.vsync)
	assert_true(GameSettings.damage_numbers)
	_write('{"window_mode": "huge"}')
	GameSettings.load_saved()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED)
	_write("[1, 2, 3]")
	GameSettings.load_saved()
	assert_eq(GameSettings.window_mode, GameSettings.WindowMode.WINDOWED)


func test_window_modes_map_to_the_display() -> void:
	assert_eq(
		GameSettings.display_mode(GameSettings.WindowMode.WINDOWED),
		DisplayServer.WINDOW_MODE_WINDOWED
	)
	assert_eq(
		GameSettings.display_mode(GameSettings.WindowMode.FULLSCREEN),
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	assert_eq(
		GameSettings.display_mode(GameSettings.WindowMode.BORDERLESS),
		DisplayServer.WINDOW_MODE_FULLSCREEN
	)


func test_f11_goes_full_screen_and_back_to_a_window() -> void:
	var windowed: GameSettings.WindowMode = GameSettings.WindowMode.WINDOWED
	var full: GameSettings.WindowMode = GameSettings.WindowMode.FULLSCREEN
	assert_eq(GameSettings.toggled_mode(windowed), full)
	assert_eq(GameSettings.toggled_mode(full), windowed)
	assert_eq(GameSettings.toggled_mode(GameSettings.WindowMode.BORDERLESS), windowed)


func test_apply_screen_asks_the_display_for_the_options() -> void:
	GameSettings.window_mode = GameSettings.WindowMode.BORDERLESS
	GameSettings.vsync = false
	GameSettings.apply_screen()
	assert_eq(GameSettings.applied_window, DisplayServer.WINDOW_MODE_FULLSCREEN)
	assert_false(GameSettings.applied_vsync)
	GameSettings.reset()
	GameSettings.apply_screen()
	assert_eq(GameSettings.applied_window, DisplayServer.WINDOW_MODE_WINDOWED)
	assert_true(GameSettings.applied_vsync)
