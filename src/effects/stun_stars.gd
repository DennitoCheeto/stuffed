class_name StunStars
extends Node2D
## Little stars circling above a stunned zombie's head.

const STAR_COLOR: Color = Color("#ffe27a")
const EDGE_COLOR: Color = Color("#5a4a1a")
const COUNT: int = 3
const ORBIT: Vector2 = Vector2(16.0, 5.0)
const SPEED: float = 7.0

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	for i: int in COUNT:
		var angle: float = _time * SPEED + TAU * i / COUNT
		var center: Vector2 = Vector2(cos(angle) * ORBIT.x, sin(angle) * ORBIT.y)
		_star(center, 4.5)


func _star(center: Vector2, size: float) -> void:
	var points: PackedVector2Array = []
	for i: int in 10:
		var reach: float = size if i % 2 == 0 else size * 0.45
		points.append(center + Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * reach)
	var edge: PackedVector2Array = points.duplicate()
	edge.append(points[0])
	draw_colored_polygon(points, STAR_COLOR)
	draw_polyline(edge, EDGE_COLOR, 1.0)
