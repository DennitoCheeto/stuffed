extends GutTest
## Scenario (playtest M2 + M3): the end screen shows everything (stats, a long upgrade list, the
## haul, a rescue) and both buttons still fit on a 1920 x 1080 screen.

const END_SCENE: PackedScene = preload("res://src/ui/end_screen.tscn")
const SCREEN: Vector2 = Vector2(1920, 1080)

var frame: Control


func before_each() -> void:
	frame = Control.new()
	frame.size = SCREEN
	add_child_autofree(frame)


func _busy_result() -> RunResult:
	var result: RunResult = RunResult.new()
	result.survived_seconds = 520.0
	result.endless_seconds = 75.0
	result.level = 38
	result.kills = 4321
	result.killed_by = "Sock King"
	var upgrades: PackedStringArray = []
	for i: int in 24:
		upgrades.append("Some Long Upgrade Name %d (Lv 5)" % i)
	result.upgrades = upgrades
	return result


func test_buttons_fit_on_screen_with_everything_shown() -> void:
	var end: EndScreen = END_SCENE.instantiate()
	frame.add_child(end)
	end.show_result(_busy_result())
	var kept: Dictionary[String, int] = {"coins": 1234, "stuffing": 56, "thread": 7}
	var before: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 99}
	end.brought_home.show_haul(kept, before, 0.5, 0.1)
	end.brought_home.show_rescue("BamBam")
	await wait_process_frames(3)
	# The screen's resting layout (not mid drop-in) is what has to fit.
	end.motion.finish()
	await wait_process_frames(1)
	var screen: Rect2 = Rect2(Vector2.ZERO, SCREEN)
	for button: Button in [end.fort_button, end.try_again_button]:
		var rect: Rect2 = button.get_global_rect()
		assert_true(screen.encloses(rect), "%s fits on screen: %s" % [button.text, rect])
	var title: Rect2 = end.title_label.get_global_rect()
	assert_true(screen.encloses(title), "the title fits too: %s" % title)
