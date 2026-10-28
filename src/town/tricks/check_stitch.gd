class_name CheckStitch
extends Control
## The check mark sewn onto a bought trick patch (spec 06 §2): a row of teal stitches in the
## patch's top-right corner. `progress` runs 0 → 1 while it is being sewn on.

const STITCH_COLOR: Color = UiColors.TEAL
const MARK_SIZE: Vector2 = Vector2(54, 42)
const MARGIN: Vector2 = Vector2(18, 16)
const WIDTH: float = 5.0

## How much of the check is sewn (0 = nothing, 1 = done).
var progress: float = 1.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## The check's corner points, left to right (for tests and drawing).
func points() -> PackedVector2Array:
	var corner: Vector2 = Vector2(size.x - MARGIN.x - MARK_SIZE.x, MARGIN.y)
	return PackedVector2Array(
		[
			corner + Vector2(0.0, MARK_SIZE.y * 0.55),
			corner + Vector2(MARK_SIZE.x * 0.36, MARK_SIZE.y),
			corner + Vector2(MARK_SIZE.x, 0.0),
		]
	)


func _draw() -> void:
	if progress <= 0.0:
		return
	var corners: PackedVector2Array = points()
	var first: float = corners[0].distance_to(corners[1])
	var total: float = first + corners[1].distance_to(corners[2])
	var reach: float = total * progress
	var path: PackedVector2Array = [corners[0]]
	if reach <= first:
		path.append(corners[0].lerp(corners[1], reach / first))
	else:
		path.append(corners[1])
		path.append(corners[1].lerp(corners[2], (reach - first) / (total - first)))
	for index: int in range(1, path.size()):
		var from: Vector2 = path[index - 1]
		var to: Vector2 = path[index]
		var length: float = from.distance_to(to)
		var walked: float = 0.0
		while walked < length:
			var end: float = minf(walked + 9.0, length)
			var start: Vector2 = from.lerp(to, walked / length)
			draw_line(start, from.lerp(to, end / length), STITCH_COLOR, WIDTH)
			walked = end + 4.0
