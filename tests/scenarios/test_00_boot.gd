extends "res://tests/scenarios/run_scenario.gd"
## Scenario: the player starts the game and sees the title screen.


func test_start_screen_shows_title_and_version() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_not_null(title, "the game opens on the title screen")
	assert_eq(title.title_label.text, "Stuffed")
	assert_eq(title.version_label.text, GameInfo.version_label())


func test_start_run_button_has_keyboard_focus() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_true(title.start_button.has_focus())


func test_quit_button_quits() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	watch_signals(main)
	title.quit_button.pressed.emit()
	assert_signal_emitted(main, "quit_requested")
