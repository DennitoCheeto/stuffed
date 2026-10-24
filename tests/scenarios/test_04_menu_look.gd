extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §6.1-6.2, AC-49, M3.5-06): the title screen, the pause menu (and its
## Recipes page), the town's Esc menu and Settings use the Stitched Scrapbook pieces: felt
## panels, sewn buttons, the three fonts, the felt cloth behind them; no old grey box, plain
## Button, plain slider or ColorRect is left. Settings' sliders are a thread with a sewing-button
## knob and its switches are felt switches; both react to mouse and keyboard.

const FONT_FILES: Array[FontFile] = [UiFonts.FREDOKA, UiFonts.PATRICK_HAND, UiFonts.NUNITO]
## A spring is done after its length plus a little margin.
const SETTLE: float = 0.1


func after_each() -> void:
	GameSettings.reduced_motion = false
	GameSettings.damage_numbers = true
	GameSettings.set_volume(&"Master", 1.0)
	super.after_each()


## Everything visible under `root` that isn't a themed piece, as readable lines (empty = all
## themed).
func unthemed(root: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	_walk(root, found)
	return found


func _walk(node: Node, found: PackedStringArray) -> void:
	var layer: CanvasLayer = node as CanvasLayer
	if layer != null and not layer.visible:
		return
	var control: Control = node as Control
	if control != null:
		if not control.visible:
			return
		var problem: String = _problem(control)
		if not problem.is_empty():
			found.append("%s (%s): %s" % [control.name, control.get_class(), problem])
	for child: Node in node.get_children():
		_walk(child, found)


func _problem(control: Control) -> String:
	if control is BaseButton and not (control is SewnButton or control is FeltSwitch):
		return "plain button"
	if control is Slider and not control is ThreadSlider:
		return "plain slider"
	if control is ColorRect:
		return "plain colour box (use MenuCloth)"
	if control is PanelContainer or control is Panel:
		var box: StyleBox = control.get_theme_stylebox(&"panel")
		if not (box is StyleBoxFelt or box is StyleBoxEmpty):
			return "panel drawn as %s" % box.get_class()
	if control is Label or control is Button:
		var font: Font = control.get_theme_font(&"font")
		if not _is_ui_font(font):
			return "font %s" % font
	return ""


func _is_ui_font(font: Font) -> bool:
	var variation: FontVariation = font as FontVariation
	if variation != null:
		return FONT_FILES.has(variation.base_font)
	return FONT_FILES.has(font)


## Asserts that `root` has only themed pieces and shows at least one sewn button and felt panel.
func _assert_themed(root: Node, screen: String) -> void:
	var found: PackedStringArray = unthemed(root)
	assert_eq(found.size(), 0, "%s is all felt: %s" % [screen, found])
	assert_gt(_count(root, SewnButton), 0, "%s has sewn buttons" % screen)
	assert_gt(_count(root, FeltPanel), 0, "%s has a felt panel" % screen)


func _count(node: Node, kind: Variant) -> int:
	var total: int = 0
	if is_instance_of(node, kind) and (node as CanvasItem).is_visible_in_tree():
		total += 1
	for child: Node in node.get_children():
		total += _count(child, kind)
	return total


## Moves the mouse onto `point` (local px) of `control` (canvas → window coordinates).
func _point_at(control: Control, point: Vector2) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * point
	sender.mouse_motion(control.get_viewport().get_screen_transform() * canvas)
	await wait_process_frames(2)


func _click_at(control: Control, point: Vector2) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * point
	var window: Vector2 = control.get_viewport().get_screen_transform() * canvas
	sender.mouse_left_button_down(window)
	await wait_process_frames(2)
	sender.mouse_left_button_up(window)
	await wait_process_frames(2)


func _settle() -> void:
	await wait_seconds(UiFeel.STYLE.spring_seconds + SETTLE)


func test_the_check_catches_an_old_grey_button() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child_autofree(layer)
	var old: Button = Button.new()
	old.text = "Give up"
	layer.add_child(old)
	var dim: ColorRect = ColorRect.new()
	layer.add_child(dim)
	layer.add_child(SewnButton.new("Resume"))
	await wait_process_frames(1)
	assert_eq(unthemed(layer).size(), 2, "plain button and plain box found: %s" % [unthemed(layer)])


func test_ac49_the_title_screen_is_felt_with_a_hand_written_name() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	await wait_process_frames(2)
	_assert_themed(title, "title (new game)")
	assert_eq(title.title_label.get_theme_font(&"font"), UiFonts.hand(), "hand-written name")
	assert_true(title.logo is HandTitle)
	assert_true(title.start_button.main, "New game is the gold button")
	assert_true(title.start_button.has_focus(), "keyboard ready")
	assert_true(title.start_button.get_parent().get_parent() == title.menu_panel.content)
	assert_true(title.cloth.is_visible_in_tree(), "the felt cloth is behind it")


func test_ac49_the_title_with_a_saved_town_and_the_start_over_question_are_felt() -> void:
	await go_to_town()
	main.show_title()
	await wait_process_frames(2)
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_eq(title.start_button.text, "Continue")
	assert_true(title.scrapbook_button.is_visible_in_tree(), "Scrapbook with a saved town")
	_assert_themed(title, "title (saved town)")
	title.start_over_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(title.confirm_box.is_visible_in_tree(), "the question is on a felt patch")
	assert_false(title.start_button.is_visible_in_tree(), "the menu steps aside")
	_assert_themed(title, "title (start over?)")
	assert_true(title.no_button.has_focus(), "the safe answer has the focus")


func test_ac49_settings_has_thread_sliders_and_felt_switches() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.settings_button.pressed.emit()
	await wait_process_frames(2)
	var page: SettingsPanel = title.settings
	assert_true(page.is_open())
	_assert_themed(page, "settings")
	assert_eq(_count(page, ThreadSlider), 3, "three thread sliders")
	assert_eq(_count(page, FeltSwitch), 2, "two felt switches")


func test_ac49_the_pause_menu_and_recipes_are_felt() -> void:
	var run: Run = await start_run()
	await tap_action("pause")
	var menu: PauseMenu = run.pause_menu
	assert_true(menu.is_open(), "Esc opens the pause menu")
	await wait_process_frames(2)
	_assert_themed(menu, "pause menu")
	assert_true(menu.resume_button.main, "Resume is the gold button")
	assert_true(menu.resume_button.has_focus(), "keyboard ready")
	assert_lt(menu.cloth.cloth_color().a, 1.0, "the run shows dimmed behind the cloth")
	menu.recipes_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(menu.recipes_page.is_visible_in_tree())
	_assert_themed(menu, "recipes")
	await tap_action("pause")
	assert_true(menu.recipes_button.has_focus(), "back on the menu, on Recipes")
	menu.settings_button.pressed.emit()
	await wait_process_frames(2)
	_assert_themed(menu, "settings (pause)")


func test_ac49_the_town_menu_is_felt() -> void:
	var town: Town = await go_to_town()
	town.open_menu()
	await wait_process_frames(2)
	_assert_themed(town.menu, "town menu")
	assert_true(town.menu.resume_button.main, "Back to the fort is the gold button")


func test_the_thread_slider_knob_grows_on_hover_and_follows_the_volume() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	var slider: ThreadSlider = title.settings.master_slider
	slider.value = 1.0
	var full: Vector2 = slider.knob_center()
	slider.value = 0.5
	assert_lt(slider.knob_center().x, full.x, "the knob moves left with a lower volume")
	Sfx.history.clear()
	await _point_at(slider, slider.knob_center())
	await _settle()
	assert_almost_eq(slider.knob_grow, UiFeel.STYLE.knob_grow, 0.02, "the knob grows on hover")
	assert_true(Sfx.history.has(&"ui_hover"), "felt pat on hover")
	await _point_at(title.settings.back_button, title.settings.back_button.size / 2.0)
	await _settle()
	assert_almost_eq(slider.knob_grow, 1.0, 0.02, "back to rest when the mouse leaves")


func test_the_thread_slider_works_with_the_keyboard_and_a_click() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	var slider: ThreadSlider = title.settings.master_slider
	slider.value = 0.5
	slider.grab_focus()
	await _settle()
	assert_true(slider.is_raised(), "focus raises the knob")
	await tap_action("ui_left")
	assert_almost_eq(GameSettings.volume(&"Master"), 0.45, 0.01, "left arrow turns it down")
	await _click_at(slider, Vector2(slider.size.x * 0.25, slider.size.y / 2.0))
	assert_lt(GameSettings.volume(&"Master"), 0.35, "a click on the thread moves the knob there")


func test_the_felt_switch_flips_with_a_click_or_enter_and_slides_its_knob() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	# Let the page finish dropping in, so the click lands where the switch rests.
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var switch: FeltSwitch = title.settings.reduced_motion_check
	assert_false(switch.button_pressed)
	var off_knob: Vector2 = switch.knob_center()
	Sfx.history.clear()
	await _click_at(switch, switch.size / 2.0)
	assert_true(GameSettings.reduced_motion, "a click turns it on")
	assert_true(Sfx.history.has(&"ui_press"), "boop")
	await _settle()
	assert_gt(switch.knob_center().x, off_knob.x, "the knob slid to the right")
	switch.grab_focus()
	await tap_action("ui_accept")
	await wait_process_frames(2)
	assert_false(GameSettings.reduced_motion, "Enter turns it off again")
	title.settings.close()
	GameSettings.reduced_motion = true
	title.open_settings()
	assert_true(switch.button_pressed, "opening shows the saved setting")
	assert_eq(switch.slide, 1.0, "the knob is already on the right side")
