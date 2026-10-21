class_name PlayersCamera
extends Camera2D
## Follows the group of players smoothly (with one player: Banane) and stops at the arena walls.
## Shakes a little when a player gets hurt.

## Strongest shake, in pixels.
const MAX_SHAKE: float = 10.0
## How fast a shake calms down (per second).
const SHAKE_DECAY: float = 3.0

## 0 = still, 1 = strongest shake.
var trauma: float = 0.0


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0


func _physics_process(_delta: float) -> void:
	if not Players.all(get_tree()).is_empty():
		global_position = Players.centroid(get_tree())


func _process(delta: float) -> void:
	trauma = maxf(trauma - SHAKE_DECAY * delta, 0.0)
	var strength: float = MAX_SHAKE * trauma * trauma
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength


## Adds some shake (0..1).
func shake(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


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
	force_update_scroll()
