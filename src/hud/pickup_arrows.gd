class_name PickupArrows
extends Control
## Small arrows at the screen edge that point to floor pickups out of sight (spec 02b §4).

## Arrows sit this far inside the screen edge, in pixels.
const MARGIN: float = 44.0
## Arrow length and half width, in pixels.
const LENGTH: float = 22.0
const HALF_WIDTH: float = 13.0
const OUTLINE_COLOR: Color = Color("#1d3a52")
## The arrow nudges towards its pickup this far and back, in pixels.
const NUDGE: float = 4.0
const NUDGE_SPEED: float = 1.5

## Where the pickups lie (the run's floor items).
var floor_items: Node2D
## Each arrow's tip (screen pixels) and the direction it points, rebuilt every frame.
var points: PackedVector2Array = []
var directions: PackedVector2Array = []

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	points.clear()
	directions.clear()
	if floor_items == null:
		return
	var view: Rect2 = get_viewport_rect()
	var to_screen: Transform2D = get_viewport().get_canvas_transform()
	for child: Node in floor_items.get_children():
		var pickup: FloorPickup = child as FloorPickup
		if pickup == null or pickup.taken or pickup.is_queued_for_deletion():
			continue
		var at: Vector2 = to_screen * pickup.global_position
		if view.has_point(at):
			continue
		var direction: Vector2 = view.get_center().direction_to(at)
		points.append(_edge_point(view.grow(-MARGIN), direction))
		directions.append(direction)
	queue_redraw()


## Where a line from the middle of `area` in `direction` leaves it.
func _edge_point(area: Rect2, direction: Vector2) -> Vector2:
	var half: Vector2 = area.size / 2.0
	var reach: float = INF
	if absf(direction.x) > 0.001:
		reach = minf(reach, half.x / absf(direction.x))
	if absf(direction.y) > 0.001:
		reach = minf(reach, half.y / absf(direction.y))
	return area.get_center() + direction * reach


func _draw() -> void:
	var nudge: float = NUDGE * (0.5 + 0.5 * sin(_time * TAU * NUDGE_SPEED))
	for i: int in points.size():
		var forward: Vector2 = directions[i]
		var side: Vector2 = forward.orthogonal() * HALF_WIDTH
		var tip: Vector2 = points[i] + forward * nudge
		var back: Vector2 = tip - forward * LENGTH
		var shape: PackedVector2Array = [tip, back + side, back - side]
		draw_colored_polygon(shape, FloorPickupLook.GLOW_COLOR)
		shape.append(tip)
		draw_polyline(shape, OUTLINE_COLOR, 3.0, true)
