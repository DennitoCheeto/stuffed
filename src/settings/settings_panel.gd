class_name SettingsPanel
extends CanvasLayer
## The one Settings page (spec 04 §6.2, spec 10 §5), opened from the run's pause menu, the
## town's Esc menu and the title screen. Four sewn tabs: Sound (Master / Effects / Music),
## Screen (window mode, V-Sync), Controls (key changing, `ControlsPage`) and Readability
## (damage numbers, flashes, screen shake, own effects, reduced menu animations, hints).
## Changes take effect at once and are saved (GameSettings). Q / E or a click switch tabs; Back
## or Esc closes it and the menu that opened it comes back (`closed`). Works while frozen.

signal closed
## "Show hints again" was pressed: whoever keeps the seen hints (the save) forgets them.
signal hints_again_requested

enum Tab { SOUND, SCREEN, CONTROLS, READABILITY }

## Every open Settings page is in this group: F11 / Alt+Enter tell it the window mode changed.
const GROUP: StringName = &"settings_panels"
## Nodes in this group forget the seen hints on "Show hints again" (`show_hints_again()`).
const HINT_KEEPERS: StringName = &"hint_keepers"
const TAB_NAMES: PackedStringArray = ["Sound", "Screen", "Controls", "Readability"]
const WINDOW_MODE_NAMES: PackedStringArray = ["Windowed", "Fullscreen", "Borderless"]
const VOLUMES: Array[StringName] = [&"Master", &"Effects", &"Music"]
const LABEL_WIDTH: float = 170.0
const SLIDER_WIDTH: float = 360.0
const FONT_SIZE: int = 26
const TAB_FONT_SIZE: int = 22
## Every tab's page takes this much room at least, so the panel doesn't jump between tabs.
const PAGE_SIZE: Vector2 = Vector2(640, 470)
## Fabric-tag tabs and choice buttons: plain, and the chosen one.
const TAG_COLOR: Color = UiColors.TAG
const TAG_ON_COLOR: Color = UiColors.STICKER_TEAL
const HINTS_AGAIN: String = "Show hints again"
const HINTS_AGAIN_NOTE: String = "Every hint will show again."
## Width of the "40%" next to a slider.
const PERCENT_WIDTH: float = 70.0

## Which tab is showing (`Tab`).
var tab_index: int = Tab.SOUND
var tabs: Array[SewnButton] = []
## One page per tab, same order as `tabs`.
var pages: Array[VBoxContainer] = []
var damage_numbers_check: FeltSwitch
var reduced_motion_check: FeltSwitch
var master_slider: ThreadSlider
var effects_slider: ThreadSlider
var music_slider: ThreadSlider
## Windowed / Fullscreen / Borderless (index = `GameSettings.WindowMode`).
var window_buttons: Array[SewnButton] = []
var vsync_check: FeltSwitch
var flashes_check: FeltSwitch
var shake_slider: ThreadSlider
var own_effects_slider: ThreadSlider
var hints_check: FeltSwitch
var hints_again_button: SewnButton
var hints_note: Label
## The Controls tab (key changing).
var controls: ControlsPage
var back_button: SewnButton
var panel: FeltPanel = FeltPanel.new(-1.5)
var motion: ScreenMotion = ScreenMotion.new()


func _init() -> void:
	layer = 40
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	add_child(motion)
	# The menu that opens the page already lays its cloth behind it: this one only dims a little.
	add_child(MenuCloth.new(0.35, 0.5, true))
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel.add_tape(0.5, -3.0).add_tape(0.94, 7.0, UiColors.TAPE_TEAL)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.content.add_child(column)
	column.add_child(HandTitle.new("Settings", 56))
	var tab_row: HBoxContainer = HBoxContainer.new()
	tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_row.add_theme_constant_override(&"separation", 10)
	column.add_child(tab_row)
	var holder: MarginContainer = MarginContainer.new()
	holder.custom_minimum_size = PAGE_SIZE
	column.add_child(holder)
	for i: int in TAB_NAMES.size():
		var tab: SewnButton = _tag_button(TAB_NAMES[i])
		tab.focus_mode = Control.FOCUS_NONE
		tab.pressed.connect(show_tab.bind(i))
		tab_row.add_child(tab)
		tabs.append(tab)
		var page: VBoxContainer = VBoxContainer.new()
		page.add_theme_constant_override("separation", 16)
		holder.add_child(page)
		pages.append(page)
	_build_sound(pages[Tab.SOUND])
	_build_screen(pages[Tab.SCREEN])
	_build_controls(pages[Tab.CONTROLS])
	_build_readability(pages[Tab.READABILITY])
	back_button = SewnButton.new("Back", true)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	column.add_child(back_button)
	show_tab(Tab.SOUND)


func is_open() -> bool:
	return visible


## Shows the page with the current settings, on the Sound tab.
func open() -> void:
	damage_numbers_check.show_pressed(GameSettings.damage_numbers)
	reduced_motion_check.show_pressed(GameSettings.reduced_motion)
	flashes_check.show_pressed(GameSettings.flashes)
	hints_check.show_pressed(GameSettings.hints)
	shake_slider.value = GameSettings.screen_shake
	own_effects_slider.value = GameSettings.own_effects
	hints_note.visible = false
	for bus: StringName in VOLUMES:
		slider_for(bus).set_value_no_signal(GameSettings.volume(bus))
	controls.open()
	sync_screen()
	show_tab(Tab.SOUND)
	visible = true
	motion.open([panel])
	back_button.grab_focus()


## Saves and hides the page; the menu underneath takes over again.
func close() -> void:
	if not visible:
		return
	controls.stop_listening()
	visible = false
	GameSettings.save()
	closed.emit()


## Shows tab `index` (wraps around).
func show_tab(index: int) -> void:
	tab_index = wrapi(index, 0, TAB_NAMES.size())
	controls.stop_listening()
	for i: int in pages.size():
		pages[i].visible = i == tab_index
		_mark(tabs[i], i == tab_index)


## The Screen tab follows the settings (after F11 / Alt+Enter too).
func sync_screen() -> void:
	for i: int in window_buttons.size():
		_mark(window_buttons[i], i == GameSettings.window_mode)
	vsync_check.show_pressed(GameSettings.vsync)


## Picks a window mode: applied at once and saved.
func choose_window_mode(mode: GameSettings.WindowMode) -> void:
	GameSettings.window_mode = mode
	GameSettings.apply_screen()
	GameSettings.save()
	sync_screen()


## Turns hints back on and asks the save to forget which hints were seen (used from M6-10).
func show_hints_again() -> void:
	GameSettings.hints = true
	hints_check.show_pressed(true)
	GameSettings.save()
	hints_again_requested.emit()
	if is_inside_tree():
		get_tree().call_group(HINT_KEEPERS, &"forget_hints")
	hints_note.visible = true


func slider_for(bus: StringName) -> ThreadSlider:
	match bus:
		&"Master":
			return master_slider
		&"Effects":
			return effects_slider
	return music_slider


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_Q or key.keycode == KEY_PAGEUP:
		get_viewport().set_input_as_handled()
		show_tab(tab_index - 1)
	elif key.keycode == KEY_E or key.keycode == KEY_PAGEDOWN:
		get_viewport().set_input_as_handled()
		show_tab(tab_index + 1)


func _build_sound(page: VBoxContainer) -> void:
	master_slider = _slider(page, &"Master")
	effects_slider = _slider(page, &"Effects")
	music_slider = _slider(page, &"Music")


func _build_screen(page: VBoxContainer) -> void:
	page.add_child(UiFonts.label("Window", FONT_SIZE, UiColors.INK))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	page.add_child(row)
	for i: int in WINDOW_MODE_NAMES.size():
		var choice: SewnButton = _tag_button(WINDOW_MODE_NAMES[i])
		choice.pressed.connect(choose_window_mode.bind(i))
		row.add_child(choice)
		window_buttons.append(choice)
	vsync_check = _switch(page, "V-Sync (no tearing)")
	vsync_check.toggled.connect(_on_vsync_toggled)


func _build_controls(page: VBoxContainer) -> void:
	controls = ControlsPage.new(_tag_button)
	controls.changed.connect(_on_controls_changed)
	page.add_child(controls)


func _build_readability(page: VBoxContainer) -> void:
	damage_numbers_check = _switch(page, "Damage numbers")
	damage_numbers_check.toggled.connect(_on_damage_numbers_toggled)
	flashes_check = _switch(page, "Flashes")
	flashes_check.toggled.connect(_on_flashes_toggled)
	var rules: ReadabilityRules = GameSettings.READABILITY
	shake_slider = _percent_slider(page, "Screen shake", 0.0, rules.shake_step)
	shake_slider.value_changed.connect(_on_shake_changed)
	own_effects_slider = _percent_slider(
		page, "Own effects", rules.own_effects_min, rules.own_effects_step
	)
	own_effects_slider.value_changed.connect(_on_own_effects_changed)
	reduced_motion_check = _switch(page, "Reduced menu animations")
	reduced_motion_check.toggled.connect(_on_reduced_motion_toggled)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	page.add_child(row)
	hints_check = FeltSwitch.new("Hints", FONT_SIZE)
	hints_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_check.toggled.connect(_on_hints_toggled)
	row.add_child(hints_check)
	hints_again_button = _tag_button(HINTS_AGAIN)
	hints_again_button.toggle_mode = false
	hints_again_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hints_again_button.pressed.connect(show_hints_again)
	row.add_child(hints_again_button)
	hints_note = UiFonts.label(HINTS_AGAIN_NOTE, TAB_FONT_SIZE, UiColors.TEAL)
	hints_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hints_note.visible = false
	page.add_child(hints_note)


func _on_controls_changed() -> void:
	GameSettings.save()


func _on_damage_numbers_toggled(on: bool) -> void:
	GameSettings.damage_numbers = on
	GameSettings.save()


func _on_reduced_motion_toggled(on: bool) -> void:
	GameSettings.reduced_motion = on
	GameSettings.save()


func _on_flashes_toggled(on: bool) -> void:
	GameSettings.flashes = on
	GameSettings.save()


func _on_hints_toggled(on: bool) -> void:
	GameSettings.hints = on
	GameSettings.save()


func _on_shake_changed(value: float) -> void:
	GameSettings.screen_shake = value


func _on_own_effects_changed(value: float) -> void:
	GameSettings.own_effects = value


func _on_vsync_toggled(on: bool) -> void:
	GameSettings.vsync = on
	GameSettings.apply_screen()
	GameSettings.save()


func _on_volume_changed(value: float, bus: StringName) -> void:
	GameSettings.set_volume(bus, value)


func _switch(page: VBoxContainer, words: String) -> FeltSwitch:
	var check: FeltSwitch = FeltSwitch.new(words, FONT_SIZE)
	page.add_child(check)
	return check


func _slider(page: VBoxContainer, bus: StringName) -> ThreadSlider:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	page.add_child(row)
	var label: Label = UiFonts.label(String(bus), FONT_SIZE, UiColors.INK)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	row.add_child(label)
	var slider: ThreadSlider = ThreadSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 1.0
	slider.custom_minimum_size.x = SLIDER_WIDTH
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	row.add_child(slider)
	return slider


## A small fabric tag you can press (a tab or a choice); it lifts like every sewn button.
func _tag_button(words: String) -> SewnButton:
	var tag: SewnButton = SewnButton.new(words, false, TAB_FONT_SIZE)
	tag.toggle_mode = true
	tag.box.fill = TAG_COLOR
	tag.box.radius = 10.0
	tag.box.stitch_inset = 4.0
	tag.box.stitch_width = 2.0
	tag.box.stitch_dash = 6.0
	tag.box.stitch_gap = 4.0
	tag.box.depth = 4.0
	tag.box.pad(18, 6)
	tag.set_stitch(UiColors.TAG_STITCH)
	return tag


## Shows a tag as the chosen one (teal) or a plain one.
func _mark(tag: SewnButton, on: bool) -> void:
	tag.set_pressed_no_signal(on)
	tag.box.fill = TAG_ON_COLOR if on else TAG_COLOR
	tag.queue_redraw()


## A labelled thread slider from `low` to 100% with its value as "40%" next to it.
func _percent_slider(page: VBoxContainer, words: String, low: float, step: float) -> ThreadSlider:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	page.add_child(row)
	var label: Label = UiFonts.label(words, FONT_SIZE, UiColors.INK)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	row.add_child(label)
	var slider: ThreadSlider = ThreadSlider.new()
	slider.min_value = low
	slider.max_value = 1.0
	slider.step = step
	slider.value = 1.0
	slider.custom_minimum_size.x = SLIDER_WIDTH - PERCENT_WIDTH
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var amount: Label = UiFonts.label("100%", FONT_SIZE, UiColors.INK_SOFT)
	amount.custom_minimum_size = Vector2(PERCENT_WIDTH, 0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(amount)
	slider.value_changed.connect(_show_percent.bind(amount))
	return slider


func _show_percent(value: float, amount: Label) -> void:
	amount.text = "%d%%" % roundi(value * 100.0)
