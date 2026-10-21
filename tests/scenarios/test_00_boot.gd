extends GutTest
## Scenario: the player starts the game.

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")

var _main: Control
var _sender: GutInputSender


func before_each() -> void:
	_main = MAIN_SCENE.instantiate()
	_main.set("quit_on_cancel", false)
	add_child_autofree(_main)
	_sender = GutInputSender.new(Input)
	await wait_physics_frames(2)


func after_each() -> void:
	_sender.release_all()
	_sender.clear()


func test_start_screen_shows_title_and_version() -> void:
	var title: Label = _main.get_node("%TitleLabel")
	var version: Label = _main.get_node("%VersionLabel")
	assert_eq(title.text, "STUFFED")
	assert_eq(version.text, GameInfo.version_label())


func test_pressing_esc_asks_to_quit() -> void:
	watch_signals(_main)
	_sender.action_down("ui_cancel").hold_for(0.05)
	await wait_for_signal(_sender.idle, 1)
	assert_signal_emitted(_main, "quit_requested")
