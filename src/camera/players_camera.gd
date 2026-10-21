class_name PlayersCamera
extends Camera2D
## Follows the group of players smoothly (with one player: Banane) and stops at the arena walls.


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0


func _physics_process(_delta: float) -> void:
	if not Players.all(get_tree()).is_empty():
		global_position = Players.centroid(get_tree())


## Keeps the view inside `bounds` (world coordinates).
func set_bounds(bounds: Rect2) -> void:
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)


## Jumps straight to the players without smoothing (start of a run).
func snap_to_players() -> void:
	global_position = Players.centroid(get_tree())
	reset_smoothing()
