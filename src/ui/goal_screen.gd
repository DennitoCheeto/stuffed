class_name GoalScreen
extends CanvasLayer
## Shown when the run goal is reached (the boss is beaten): "You beat the Bedroom!" and the
## choice to end the run with a win or keep going endlessly. Keys 1 / 2, a click, or arrows +
## Enter. Keeps running while the run is frozen.

signal end_chosen
signal endless_chosen

## Picks are ignored this long after opening, so a key held from playing doesn't pick.
const INPUT_DELAY: float = 0.3

var _accepting: bool = false

@onready var end_button: Button = %EndButton
@onready var endless_button: Button = %EndlessButton


func _ready() -> void:
	visible = false
	end_button.pressed.connect(choose_end)
	endless_button.pressed.connect(choose_endless)


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	_accepting = false
	end_button.grab_focus()
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_accepting = true


func choose_end() -> void:
	if _accept():
		end_chosen.emit()


func choose_endless() -> void:
	if _accept():
		endless_chosen.emit()


func _accept() -> bool:
	if not visible or not _accepting:
		return false
	visible = false
	_accepting = false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pick_card_1"):
		get_viewport().set_input_as_handled()
		choose_end()
	elif event.is_action_pressed(&"pick_card_2"):
		get_viewport().set_input_as_handled()
		choose_endless()
