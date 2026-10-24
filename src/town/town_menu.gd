class_name TownMenu
extends CanvasLayer
## The Esc menu in town (look from spec 04): back to the fort, Settings (the shared
## SettingsPanel), the title screen, or quit the game. Keeps working while the town is paused.

signal resumed
signal title_requested
signal quit_requested

const BUTTON_WIDTH: float = 380.0

var resume_button: SewnButton = SewnButton.new("Back to the fort", true, 32)
var settings_button: SewnButton = SewnButton.new("Settings")
var title_button: SewnButton = SewnButton.new("Title screen")
var quit_button: SewnButton = SewnButton.new("Quit game")
var settings: SettingsPanel = SettingsPanel.new()
## The felt patch with the buttons (hidden while Settings is open).
var panel: FeltPanel = FeltPanel.new(-1.5)
var motion: ScreenMotion = ScreenMotion.new()


func _init() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(motion)
	add_child(MenuCloth.new(0.8, 0.3))
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel.add_tape(0.5, -3.0, UiColors.TAPE_TEAL)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	panel.content.add_child(box)
	box.add_child(HandTitle.new("The Pillow Fort", 56, UiColors.PURPLE, -2.5))
	# Buttons fill the column: it sets their width.
	box.custom_minimum_size.x = BUTTON_WIDTH
	for button: SewnButton in [resume_button, settings_button, title_button, quit_button]:
		box.add_child(button)
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(show_settings)
	title_button.pressed.connect(title_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
	add_child(settings)
	settings.closed.connect(_on_settings_closed)


func is_open() -> bool:
	return visible


func open() -> void:
	settings.visible = false
	panel.visible = true
	visible = true
	motion.open([panel])
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not settings.visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


## Shows the Settings page instead of the menu.
func show_settings() -> void:
	panel.visible = false
	settings.open()


func _on_settings_closed() -> void:
	panel.visible = true
	settings_button.grab_focus()

