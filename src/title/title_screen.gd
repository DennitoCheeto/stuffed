class_name TitleScreen
extends Control
## The first screen: "Stuffed", Continue (or New game the first time) and Quit. Continue and
## New game open the town. Works with mouse and keyboard. With a saved town it also offers
## "Start over", which asks twice before the town is deleted.

signal start_requested
signal quit_requested
## The player confirmed "Start over" twice: the saved town should be deleted.
signal start_over_requested

const ASKS: PackedStringArray = [
	"Start over with a new town?",
	"Really? Your whole town will be gone.",
]

## Main sets this before the screen is shown: a saved town exists.
var has_save: bool = false
var start_over_button: Button
## The confirm box (question + Yes / No), hidden until "Start over" is pressed.
var confirm_box: VBoxContainer
var confirm_label: Label
var yes_button: Button
var no_button: Button
## 0 = not asking, 1 = first question shown, 2 = second question shown.
var confirm_step: int = 0

@onready var title_label: Label = %TitleLabel
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	version_label.text = GameInfo.version_label()
	start_button.text = start_text()
	# Built first: the copies of the Quit button must not carry its connection.
	_build_start_over()
	start_button.pressed.connect(start_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
	start_button.grab_focus()


## "Continue" with a saved town, else "New game".
func start_text() -> String:
	return "Continue" if has_save else "New game"


## Pressing "Start over", then Yes twice, deletes the town. No (or Esc) backs out at any step.
func press_start_over() -> void:
	confirm_step = 1
	_show_confirm()


func _on_yes() -> void:
	if confirm_step < ASKS.size():
		confirm_step += 1
		_show_confirm()
		return
	_close_confirm()
	has_save = false
	start_over_button.visible = false
	start_button.text = start_text()
	start_over_requested.emit()


func _close_confirm() -> void:
	confirm_step = 0
	confirm_box.visible = false
	start_button.get_parent().visible = true
	start_button.grab_focus()


func _show_confirm() -> void:
	confirm_label.text = ASKS[confirm_step - 1]
	yes_button.text = "Yes, start over" if confirm_step == ASKS.size() else "Yes"
	start_button.get_parent().visible = false
	confirm_box.visible = true
	no_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if confirm_step > 0 and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_close_confirm()


## A small "Start over" button under Quit and the confirm box in the same spot.
func _build_start_over() -> void:
	var menu: Control = start_button.get_parent()
	start_over_button = quit_button.duplicate() as Button
	start_over_button.text = "Start over"
	start_over_button.custom_minimum_size = Vector2(240, 48)
	start_over_button.add_theme_font_size_override(&"font_size", 24)
	start_over_button.visible = has_save
	menu.add_child(start_over_button)
	start_over_button.pressed.connect(press_start_over)
	confirm_box = VBoxContainer.new()
	confirm_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	confirm_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	confirm_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	confirm_box.add_theme_constant_override(&"separation", 20)
	confirm_box.visible = false
	add_child(confirm_box)
	confirm_label = Label.new()
	confirm_label.add_theme_font_size_override(&"font_size", 40)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_box.add_child(confirm_label)
	yes_button = quit_button.duplicate() as Button
	confirm_box.add_child(yes_button)
	yes_button.pressed.connect(_on_yes)
	no_button = quit_button.duplicate() as Button
	no_button.text = "No, keep my town"
	confirm_box.add_child(no_button)
	no_button.pressed.connect(_close_confirm)
