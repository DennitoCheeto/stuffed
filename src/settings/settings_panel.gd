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

var damage_numbers_check: FeltSwitch
var reduced_motion_check: FeltSwitch
var master_slider: ThreadSlider
var effects_slider: ThreadSlider
var music_slider: ThreadSlider
var back_button: SewnButton
var panel: FeltPanel = FeltPanel.new(-1.5)
var motion: ScreenMotion = ScreenMotion.new()


func _init() -> void:
	layer = 40
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	damage_numbers_check.show_pressed(GameSettings.damage_numbers)
	reduced_motion_check.show_pressed(GameSettings.reduced_motion)
	for bus: StringName in VOLUMES:
		slider_for(bus).set_value_no_signal(GameSettings.volume(bus))
	visible = true
	motion.open([panel])
	back_button.grab_focus()


## Saves and hides the page; the menu underneath takes over again.
func close() -> void:
	if not visible:
		return
	visible = false
	GameSettings.save()
	closed.emit()


func slider_for(bus: StringName) -> ThreadSlider:
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


func _switch(column: VBoxContainer, words: String) -> FeltSwitch:
	var check: FeltSwitch = FeltSwitch.new(words, FONT_SIZE)
	column.add_child(check)
	return check


func _slider(column: VBoxContainer, bus: StringName) -> ThreadSlider:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	column.add_child(row)
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
