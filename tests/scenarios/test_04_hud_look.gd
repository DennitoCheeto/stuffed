extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 04 §2.3, AC-51, M3.5-08): during a run the HUD keeps its quiet style. It only
## gets the new fonts, colours and small dark felt backings: nothing in it tilts, wobbles or is
## taped on, and only the boss's own health bar uses the danger red (enemy things, vision §6).

const FONT_FILES: Array[FontFile] = [UiFonts.FREDOKA, UiFonts.PATRICK_HAND, UiFonts.NUNITO]
## The style boxes a HUD control can draw with.
const BOXES: Array[StringName] = [&"normal", &"panel", &"background", &"fill"]
## Frames to watch for any tilt or wobble.
const WATCH_FRAMES: int = 20


## A busy run: a full loadout, the boss bar and a banner all showing.
func _busy_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	run.dev_menu.max_everything()
	var boss: Zombie = run.spawner.spawn_boss(run.spawner.schedule.boss)
	run.hud.show_boss(boss)
	run.hud.show_banner("Snow Globe!", "The horde freezes", 5.0)
	await wait_process_frames(3)
	return run


## Every visible Control under `node` (the boss bar and its label left out if `skip_boss`).
func _controls(node: Node, hud: Hud, skip_boss: bool, found: Array[Control]) -> void:
	if skip_boss and node == hud.boss_bar:
		return
	var control: Control = node as Control
	if control != null:
		if not control.visible:
			return
		found.append(control)
	for child: Node in node.get_children():
		_controls(child, hud, skip_boss, found)


func _all(hud: Hud, skip_boss: bool = false) -> Array[Control]:
	var found: Array[Control] = []
	_controls(hud, hud, skip_boss, found)
	return found


## The colours `control` draws its text and boxes with.
func _colors(control: Control) -> Array[Color]:
	var result: Array[Color] = []
	if control is Label:
		result.append(control.get_theme_color(&"font_color"))
	for box_name: StringName in BOXES:
		if not control.has_theme_stylebox(box_name):
			continue
		var box: StyleBox = control.get_theme_stylebox(box_name)
		if box is StyleBoxFlat:
			result.append((box as StyleBoxFlat).bg_color)
		elif box is StyleBoxFelt:
			result.append((box as StyleBoxFelt).fill)
			result.append((box as StyleBoxFelt).stitch)
	return result


func _is_ui_font(font: Font) -> bool:
	var variation: FontVariation = font as FontVariation
	if variation != null:
		return FONT_FILES.has(variation.base_font)
	return FONT_FILES.has(font)


func test_ac51_nothing_in_the_hud_tilts_wobbles_or_is_taped_on() -> void:
	var run: Run = await _busy_run()
	var problems: PackedStringArray = []
	for i: int in WATCH_FRAMES:
		for control: Control in _all(run.hud):
			if control is Wobbly or control is TapeStrip:
				problems.append("%s moves like a menu piece" % control.name)
			if not is_zero_approx(control.rotation):
				problems.append("%s tilts" % control.name)
			for box_name: StringName in BOXES:
				var box: StyleBoxFelt = control.get_theme_stylebox(box_name) as StyleBoxFelt
				if box != null and not box.tape_spots.is_empty():
					problems.append("%s is taped on" % control.name)
		await wait_process_frames(1)
	assert_eq(problems, PackedStringArray(), "the HUD stays still")


func test_ac51_the_hud_uses_the_new_fonts_and_felt_backings() -> void:
	var run: Run = await _busy_run()
	var hud: Hud = run.hud
	var labels: int = 0
	for control: Control in _all(hud):
		var label: Label = control as Label
		if label == null:
			continue
		labels += 1
		var font: Font = label.get_theme_font(&"font")
		assert_true(_is_ui_font(font), "%s '%s' uses a game font" % [label.name, label.text])
	assert_gt(labels, 5, "timer, level, health, banner, boss name, jars")
	assert_true(hud.timer_label.get_theme_stylebox(&"normal") is StyleBoxFelt, "timer on felt")
	assert_true(hud.level_label.get_theme_stylebox(&"normal") is StyleBoxFelt, "level on felt")
	var back: StyleBox = hud.health_bar.get_theme_stylebox(&"background")
	assert_true(back is StyleBoxFelt, "the health bar sits in felt")
	var xp: StyleBoxFlat = hud.xp_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	assert_eq(xp.bg_color, UiColors.XP, "XP is green")


func test_ac51_only_the_boss_bar_uses_danger_colours() -> void:
	var run: Run = await _busy_run()
	var hud: Hud = run.hud
	var problems: PackedStringArray = []
	for control: Control in _all(hud, true):
		for color: Color in _colors(control):
			if UiColors.is_danger(color):
				problems.append("%s uses %s" % [control.name, color.to_html()])
	assert_eq(problems, PackedStringArray(), "no danger colours in the hero's HUD")
	assert_true(hud.boss_bar.visible)
	var boss_fill: StyleBoxFlat = hud.boss_bar.get_theme_stylebox(&"fill") as StyleBoxFlat
	assert_true(UiColors.is_danger(boss_fill.bg_color), "the boss (an enemy) keeps its red")
