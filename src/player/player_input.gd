class_name PlayerInput
extends RefCounted
## Reads the controls of one player. Player N uses the input actions named "pN_<action>"
## (p1 = keyboard + mouse), so local co-op only needs a second set of actions.

var player_index: int = 0


func _init(index: int) -> void:
	player_index = index


## The input action name for this player, e.g. action("dash") -> "p1_dash".
func action(action_name: String) -> StringName:
	return StringName("p%d_%s" % [player_index + 1, action_name])


func has_controls() -> bool:
	return InputMap.has_action(action("move_left"))


## Move direction, never longer than 1 (diagonals are not faster than straight lines).
func move_vector() -> Vector2:
	if not has_controls():
		return Vector2.ZERO
	var left: StringName = action("move_left")
	var right: StringName = action("move_right")
	var up: StringName = action("move_up")
	var down: StringName = action("move_down")
	return Input.get_vector(left, right, up, down)


func is_just_pressed(action_name: String) -> bool:
	var full_name: StringName = action(action_name)
	return InputMap.has_action(full_name) and Input.is_action_just_pressed(full_name)
