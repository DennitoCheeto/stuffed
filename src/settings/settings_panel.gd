class_name SettingsPanel
extends CanvasLayer
## The one Settings page (spec 04 §6.2), opened from the run's pause menu, the town's Esc menu
## and the title screen: damage numbers, reduced menu animations and the Master / Effects /
## Music volume. Changes take effect at once and are saved (GameSettings). Back or Esc closes
## it and the menu that opened it comes back (`closed`). Works while the game is frozen.

signal closed

const VOLUMES: Array[StringName] = [&"Master", &"Effects", &"Music"]
const LABEL_WIDTH: float = 170.0
const SLIDER_WIDTH: float = 360.0
const FONT_SIZE: int = 26

var damage_numbers_check: CheckButton
var reduced_motion_check: CheckButton
var master_slider: HSlider
var effects_slider: HSlider
var music_slider: HSlider
var back_button: SewnButton
var panel: FeltPanel = FeltPanel.new(-1.5)


func _init() -> void:
	layer = 40
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(UiColors.CLOTH.darkened(0.55), 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel.add_tape(0.5, -3.0)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.content.add_child(column)
	column.add_child(HandTitle.new("Settings", 56))
	damage_numbers_check = _switch(column, "Damage numbers")
	damage_numbers_check.toggled.connect(_on_damage_numbers_toggled)
	reduced_motion_check = _switch(column, "Reduced menu animations")
	reduced_motion_check.toggled.connect(_on_reduced_motion_toggled)
	master_slider = _slider(column, &"Master")
	effects_slider = _slider(column, &"Effects")
	music_slider = _slider(column, &"Music")
	back_button = SewnButton.new("Back", true)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	column.add_child(back_button)


func is_open() -> bool:
	return visible


## Shows the page with the current settings.
func open() -> void:
	damage_numbers_check.set_pressed_no_signal(GameSettings.damage_numbers)
	reduced_motion_check.set_pressed_no_signal(GameSettings.reduced_motion)
	for bus: StringName in VOLUMES:
		slider_for(bus).set_value_no_signal(GameSettings.volume(bus))
	visible = true
	panel.rest()
	back_button.grab_focus()


## Saves and hides the page; the menu underneath takes over again.
func close() -> void:
	if not visible:
		return
	visible = false
	GameSettings.save()
	closed.emit()


func slider_for(bus: StringName) -> HSlider:
	match bus:
		&"Master":
			return master_slider
		&"Effects":
			return effects_slider
	return music_slider


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _on_damage_numbers_toggled(on: bool) -> void:
	GameSettings.damage_numbers = on
	GameSettings.save()


func _on_reduced_motion_toggled(on: bool) -> void:
	GameSettings.reduced_motion = on
	GameSettings.save()


func _on_volume_changed(value: float, bus: StringName) -> void:
	GameSettings.set_volume(bus, value)


func _switch(column: VBoxContainer, words: String) -> CheckButton:
	var check: CheckButton = CheckButton.new()
	check.text = words
	check.add_theme_font_override("font", UiFonts.body())
	check.add_theme_font_size_override("font_size", FONT_SIZE)
	for color: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
		check.add_theme_color_override(color, UiColors.INK)
	check.add_theme_color_override(&"font_focus_color", UiColors.PURPLE)
	check.add_theme_color_override(&"font_hover_pressed_color", UiColors.PURPLE)
	column.add_child(check)
	return check


func _slider(column: VBoxContainer, bus: StringName) -> HSlider:
	var row: HBoxContainer = HBoxContainer.new()
	column.add_child(row)
	var label: Label = Label.new()
	label.text = String(bus)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	label.add_theme_font_override("font", UiFonts.body())
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", UiColors.INK)
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = 1.0
	slider.custom_minimum_size = Vector2(SLIDER_WIDTH, 0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_changed.bind(bus))
	row.add_child(slider)
	return slider
