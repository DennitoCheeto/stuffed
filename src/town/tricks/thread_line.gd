class_name ThreadLine
extends Control
## A loose thread joining the trick patches on their strip of cloth (spec 06 §2): a little wavy
## piece in each gap between two neighbouring patches, tucked under their edges.

const WIDTH: float = 4.0
const WAVE_PIXELS: float = 6.0
## How far each piece reaches under the patches next to it.
const TUCK: float = 6.0

var color: Color = UiColors.PURPLE
## The controls the thread joins, left to right (sizes are read when drawing).
var links: Array[Control] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The thread follows the patches when they move or resize.
func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


## The thread pieces as (from, to) pairs in this control's coordinates.
func pieces() -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var to_local: Transform2D = get_global_transform().affine_inverse()
	for index: int in range(1, links.size()):
		var left: Rect2 = links[index - 1].get_global_rect()
		var right: Rect2 = links[index].get_global_rect()
		var from: Vector2 = Vector2(left.end.x - TUCK, left.get_center().y)
		var to: Vector2 = Vector2(right.position.x + TUCK, right.get_center().y)
		result.append(PackedVector2Array([to_local * from, to_local * to]))
	return result


func _draw() -> void:
	for piece: PackedVector2Array in pieces():
		var line: PackedVector2Array = []
		var steps: int = 12
		for index: int in steps + 1:
			var share: float = float(index) / steps
			var wave: float = sin(share * TAU) * WAVE_PIXELS
			line.append(piece[0].lerp(piece[1], share) + Vector2(0.0, wave))
		draw_polyline(line, color, WIDTH, true)
