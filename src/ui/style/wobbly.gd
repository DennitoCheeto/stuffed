class_name Wobbly
extends Container
## Base of the UI pieces that tilt, lift, grow and fade (spec 04 §2-3).
## Godot's containers reset the rotation and scale of their children, so a Wobbly takes the
## place in the layout and moves only its `body` inside it: the layout never notices the motion.

## The part that shows (and moves). Subclasses create it in `_init` with `set_body`.
var body: Control
## Resting tilt in degrees.
var tilt: float = 0.0:
	set(value):
		tilt = value
		_place()
## Extra motion on top of the rest pose (animated by ScreenMotion, stickers and buttons).
## lift: px up (negative = down); grow: scale; spin: extra degrees; fade: 0 = invisible.
var lift: float = 0.0:
	set(value):
		lift = value
		_place()
var grow: float = 1.0:
	set(value):
		grow = value
		_place()
var spin: float = 0.0:
	set(value):
		spin = value
		_place()
var fade: float = 1.0:
	set(value):
		fade = value
		_place()


func set_body(part: Control) -> void:
	body = part
	add_child(part)
	part.minimum_size_changed.connect(update_minimum_size)
	update_minimum_size()


func _get_minimum_size() -> Vector2:
	return body.get_combined_minimum_size() if body != null else Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_place()


## Back to the rest pose (no lift, normal size, only the resting tilt, fully visible).
func rest() -> void:
	lift = 0.0
	grow = 1.0
	spin = 0.0
	fade = 1.0


func _place() -> void:
	if body == null:
		return
	body.size = size
	body.pivot_offset = size / 2.0
	body.position = Vector2(0, -lift)
	body.scale = Vector2.ONE * grow
	body.rotation = deg_to_rad(tilt + spin)
	body.modulate.a = fade
