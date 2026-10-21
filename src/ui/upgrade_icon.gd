class_name UpgradeIcon
extends Control
## A small felt-style icon for an upgrade card, drawn in code.

const BACK_COLOR: Color = Color("#2a2633")
const RING_COLOR: Color = Color("#4a4358")

## Which icon to draw: boomerang, pin, feet, stuffing, magnet, hands, snack.
var icon: StringName = &"":
	set(value):
		icon = value
		queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0
	draw_circle(center, radius, RING_COLOR)
	draw_circle(center, radius - 4.0, BACK_COLOR)
	draw_set_transform(center, 0.0, Vector2.ONE * radius / 40.0)
	match icon:
		&"boomerang":
			_peel(Color("#efe3a0"), 0.0)
		&"snack":
			_peel(Color("#f2b52e"), 0.5)
		&"pin":
			draw_line(Vector2(-22, 22), Vector2(18, -18), Color("#d9d6e3"), 4.0)
			draw_circle(Vector2(20, -20), 7.0, Color("#e0475b"))
		&"feet":
			_ellipse(Vector2(-10, 4), Vector2(8, 14), Color("#f08a3c"))
			_ellipse(Vector2(10, -4), Vector2(8, 14), Color("#f08a3c"))
		&"stuffing":
			for puff: Vector3 in [Vector3(-10, 4, 12), Vector3(8, 6, 11), Vector3(0, -8, 13)]:
				draw_circle(Vector2(puff.x, puff.y), puff.z, Color("#f4f1e8"))
		&"magnet":
			draw_arc(Vector2(0, 2), 16.0, 0.0, PI, 16, Color("#e0475b"), 10.0)
			draw_rect(Rect2(-21, -16, 10, 18), Color("#e0475b"))
			draw_rect(Rect2(11, -16, 10, 18), Color("#e0475b"))
			draw_rect(Rect2(-21, -22, 10, 7), Color("#d9d6e3"))
			draw_rect(Rect2(11, -22, 10, 7), Color("#d9d6e3"))
		&"hands":
			draw_circle(Vector2(4, 0), 15.0, Color("#f2b52e"))
			for y: float in [-10.0, 0.0, 10.0]:
				draw_line(Vector2(-28, y), Vector2(-14, y), Color("#f2b52e"), 3.0)


func _peel(color: Color, tilt: float) -> void:
	var shape: PackedVector2Array = FeltShapes.svg_path(
		PackedFloat32Array([-14, 6, -8, -10, 8, -10, 14, 6, 6, -2, -6, -2, -14, 6])
	)
	var points: PackedVector2Array = []
	for point: Vector2 in shape:
		points.append(point.rotated(tilt) * 1.8)
	draw_colored_polygon(points, color)


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	draw_colored_polygon(FeltShapes.ellipse(center, radii, 16), color)
