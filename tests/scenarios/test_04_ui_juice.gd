extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §3, M3.5-01): menu juice. Buttons lift, grow and "pat" on hover and focus,
## squish and "boop" on press, a disabled one says "nope"; screens drop in, and a key pressed
## during the motion works at once. "Reduced menu animations" is saved.

## A spring is done after its length plus a little margin.
const SETTLE: float = 0.1

var layer: CanvasLayer
var column: VBoxContainer
var presses: Array[String] = []


func before_each() -> void:
	await super.before_each()
	presses.clear()
	layer = CanvasLayer.new()
	layer.layer = 50
	main.add_child(layer)
	column = VBoxContainer.new()
	column.position = Vector2(200, 200)
	column.add_theme_constant_override("separation", 40)
	layer.add_child(column)


func after_each() -> void:
	GameSettings.reduced_motion = false
	super.after_each()


func _button(words: String, main_button: bool = false) -> SewnButton:
	var button: SewnButton = SewnButton.new(words, main_button)
	column.add_child(button)
	button.pressed.connect(func() -> void: presses.append(words))
	return button


## Moves the mouse onto the middle of `control` (canvas → window coordinates).
func _point_at(control: Control) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * (control.size / 2.0)
	sender.mouse_motion(control.get_viewport().get_screen_transform() * canvas)
	await wait_process_frames(2)


func _mouse_down(control: Control) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * (control.size / 2.0)
	sender.mouse_left_button_down(control.get_viewport().get_screen_transform() * canvas)
	await wait_process_frames(2)


func _mouse_up(control: Control) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * (control.size / 2.0)
	sender.mouse_left_button_up(control.get_viewport().get_screen_transform() * canvas)
	await wait_process_frames(2)


func _settle() -> void:
	await wait_seconds(UiFeel.STYLE.spring_seconds + SETTLE)


func test_ac50_hover_lifts_and_grows_the_button_with_a_felt_pat() -> void:
	var button: SewnButton = _button("Back to the fort", true)
	var other: SewnButton = _button("Try again")
	await wait_process_frames(2)
	Sfx.history.clear()
	await _point_at(button)
	await _settle()
	var style: UiStyle = UiFeel.STYLE
	assert_almost_eq(button.lift_amount(), style.hover_lift, 0.5, "lifted")
	assert_almost_eq(button.grow_amount(), style.hover_grow, 0.01, "grown")
	assert_true(Sfx.history.has(&"ui_hover"), "felt pat on hover")
	assert_eq(other.lift_amount(), 0.0, "the other button stays down")
	await _point_at(other)
	await _settle()
	assert_almost_eq(button.lift_amount(), 0.0, 0.5, "back down when the mouse leaves")
	assert_almost_eq(other.lift_amount(), style.hover_lift, 0.5, "the new one lifts")


func test_ac50_press_squishes_with_a_boop_and_still_presses() -> void:
	var button: SewnButton = _button("Back to the fort", true)
	await wait_process_frames(2)
	await _point_at(button)
	Sfx.history.clear()
	await _mouse_down(button)
	await _settle()
	assert_true(Sfx.history.has(&"ui_press"), "boop on press")
	assert_almost_eq(button.grow_amount(), UiFeel.STYLE.press_squish, 0.01, "squished")
	assert_almost_eq(button.box.press, 1.0, 0.01, "pressed into its thick edge")
	await _mouse_up(button)
	assert_eq(presses, ["Back to the fort"], "the press went through")
	await _settle()
	assert_true(button.is_raised(), "springs back up under the mouse")


func test_ac50_a_disabled_button_does_not_lift_and_says_nope() -> void:
	var button: SewnButton = _button("Rebuild")
	button.disabled = true
	await wait_process_frames(2)
	Sfx.history.clear()
	await _point_at(button)
	await _settle()
	assert_eq(button.lift_amount(), 0.0, "no lift")
	assert_false(Sfx.history.has(&"ui_hover"), "no hover sound")
	assert_almost_eq(button.face.modulate.a, UiFeel.STYLE.disabled_fade, 0.01, "faded")
	await _mouse_down(button)
	assert_true(Sfx.history.has(&"ui_nope"), "nope sound")
	assert_true(button.is_wiggling(), "nope wiggle")
	await _mouse_up(button)
	assert_eq(presses, [], "nothing happened")


func test_ac50_keyboard_focus_lifts_the_button_with_a_felt_pat() -> void:
	var first: SewnButton = _button("Resume")
	var second: SewnButton = _button("Give up")
	await wait_process_frames(2)
	first.grab_focus()
	await _settle()
	assert_true(first.is_raised(), "the focused button is up")
	Sfx.history.clear()
	sender.action_down(&"ui_down")
	await wait_process_frames(2)
	sender.action_up(&"ui_down")
	await _settle()
	assert_true(second.has_focus(), "focus moved down")
	assert_true(Sfx.history.has(&"ui_hover"), "felt pat on keyboard focus")
	assert_almost_eq(second.lift_amount(), UiFeel.STYLE.hover_lift, 0.5, "focused = lifted")
	assert_almost_eq(first.lift_amount(), 0.0, 0.5, "the old one goes back down")


func test_ac50_a_key_pressed_while_a_screen_opens_works_at_once() -> void:
	var panel: FeltPanel = FeltPanel.new(-1.0)
	column.add_child(panel)
	var button: SewnButton = SewnButton.new("Back to the fort", true)
	button.pressed.connect(func() -> void: presses.append("fort"))
	panel.content.add_child(button)
	var title: HandTitle = HandTitle.new("You survived!")
	column.add_child(title)
	var motion: ScreenMotion = ScreenMotion.new()
	layer.add_child(motion)
	await wait_process_frames(2)
	button.grab_focus()
	Sfx.history.clear()
	var parts: Array[Wobbly] = [panel, title]
	motion.open(parts)
	assert_true(Sfx.history.has(&"ui_open"), "whoosh")
	await wait_process_frames(2)
	assert_true(motion.is_moving(), "still dropping in")
	assert_gt(panel.lift, 0.0, "the panel is still above its place")
	sender.key_down(KEY_ENTER)
	await wait_process_frames(2)
	sender.key_up(KEY_ENTER)
	await wait_process_frames(2)
	assert_false(motion.is_moving(), "the key ended the motion")
	assert_eq(panel.lift, 0.0, "the panel is in place")
	assert_eq(title.fade, 1.0, "the title is fully visible")
	assert_eq(presses, ["fort"], "the key press reached the button")


func test_ac50_a_closing_screen_is_quick() -> void:
	var panel: FeltPanel = FeltPanel.new()
	column.add_child(panel)
	var motion: ScreenMotion = ScreenMotion.new()
	layer.add_child(motion)
	await wait_process_frames(2)
	var closed: Array[float] = []
	var start: int = Time.get_ticks_msec()
	var parts: Array[Wobbly] = [panel]
	motion.close(parts, func() -> void: closed.append((Time.get_ticks_msec() - start) / 1000.0))
	await wait_seconds(UiFeel.STYLE.close_seconds + SETTLE)
	assert_eq(closed.size(), 1, "closed")
	assert_lt(panel.lift, 0.0, "slid down")
	assert_eq(panel.fade, 0.0, "faded out")


func test_ac56_reduced_menu_animations_is_saved_and_skips_the_motion() -> void:
	var run: Run = await start_run()
	sender.action_down(&"pause")
	await wait_process_frames(2)
	sender.action_up(&"pause")
	await wait_process_frames(2)
	var menu: PauseMenu = run.pause_menu
	assert_true(menu.is_open(), "pause menu open")
	assert_eq(menu.reduced_motion_check.text, "Reduced menu animations")
	menu.reduced_motion_check.button_pressed = true
	assert_true(GameSettings.reduced_motion, "on right away")
	assert_true(FileAccess.file_exists(TEST_SETTINGS), "saved to the test settings file")
	GameSettings.reduced_motion = false
	GameSettings.load_saved()
	assert_true(GameSettings.reduced_motion, "reload gives the saved choice")
	var sticker: Sticker = Sticker.new("Mortar Maniac")
	column.add_child(sticker)
	var panel: FeltPanel = FeltPanel.new(2.0)
	column.add_child(panel)
	var motion: ScreenMotion = ScreenMotion.new()
	layer.add_child(motion)
	await wait_process_frames(2)
	var parts: Array[Wobbly] = [panel]
	motion.open(parts)
	sticker.slap()
	assert_false(motion.is_moving(), "no drop-in")
	assert_eq(panel.lift, 0.0, "in place at once")
	assert_false(sticker.is_slapping(), "the sticker is simply there")
	assert_eq(sticker.grow, 1.0, "normal size")
