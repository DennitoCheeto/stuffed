class_name TownMenu
extends CanvasLayer
## The Esc menu in town: back to the fort, the title screen, or quit the game.
## Keeps working while the town is paused.

signal resumed
signal title_requested
signal quit_requested

var resume_button: Button
var title_button: Button
var quit_button: Button


func _init() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.08, 0.6)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override(&"separation", 18)
	add_child(box)
	var heading: Label = TownArt.label("The Pillow Fort", 56)
	box.add_child(heading)
	resume_button = _button(box, "Back to the fort")
	resume_button.pressed.connect(close)
	title_button = _button(box, "Title screen")
	title_button.pressed.connect(title_requested.emit)
	quit_button = _button(box, "Quit game")
	quit_button.pressed.connect(quit_requested.emit)


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _button(box: VBoxContainer, text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380, 68)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override(&"font_size", 32)
	box.add_child(button)
	return button
