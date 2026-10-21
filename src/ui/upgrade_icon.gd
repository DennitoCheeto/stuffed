class_name UpgradeIcon
extends Control
## A small felt-style icon for an upgrade card, drawn in code.

const BACK_COLOR: Color = Color("#2a2633")
const RING_COLOR: Color = Color("#4a4358")

## Which icon to draw: boomerang, pin, needles, buttons, feet, stuffing, magnet, hands, scissors, thread, spool,
## felt, snack. "" draws only the empty round back (an empty HUD slot).
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
		&"needles":
			_needles()
		&"buttons":
			_buttons()
		&"scissors":
			_scissors()
		&"thread":
			_thread()
		&"spool":
			_spool()
		&"felt":
			_felt()


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


func _scissors() -> void:
	var blade: Color = Color("#d9d6e3")
	var handle: Color = Color("#4fc3a1")
	draw_line(Vector2(-6, 6), Vector2(20, -22), blade, 5.0)
	draw_line(Vector2(6, 6), Vector2(-20, -22), blade, 5.0)
	draw_arc(Vector2(-11, 15), 8.0, 0.0, TAU, 16, handle, 4.0)
	draw_arc(Vector2(11, 15), 8.0, 0.0, TAU, 16, handle, 4.0)
	draw_circle(Vector2(0, -1), 2.5, Color("#4a4358"))


func _thread() -> void:
	var color: Color = Color("#e0475b")
	var points: PackedVector2Array = []
	for i: int in 25:
		var t: float = i / 24.0
		points.append(Vector2(lerpf(-24, 24, t), sin(t * TAU * 1.5) * 10.0))
	draw_polyline(points, color, 4.0, true)
	draw_line(Vector2(24, 0), Vector2(30, -6), Color("#d9d6e3"), 3.0)


func _spool() -> void:
	var wood: Color = Color("#c98a4b")
	draw_rect(Rect2(-18, -22, 36, 7), wood)
	draw_rect(Rect2(-18, 15, 36, 7), wood)
	draw_rect(Rect2(-13, -15, 26, 30), Color("#9b6ad6"))
	for y: float in [-9.0, -2.0, 5.0, 12.0]:
		draw_line(Vector2(-13, y), Vector2(13, y - 3.0), Color("#c6a3f0"), 2.0)


func _felt() -> void:
	var shape: PackedVector2Array = FeltShapes.points(
		PackedFloat32Array([-20, -16, 0, -22, 20, -16, 18, 8, 0, 24, -18, 8])
	)
	draw_colored_polygon(shape, Color("#7aa5d9"))
	var stitch: Color = Color("#f4f1e8")
	for i: int in 5:
		var y: float = -12.0 + i * 7.0
		draw_line(Vector2(-6, y), Vector2(6, y), stitch, 2.0)


func _needles() -> void:
	draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 32, Color("#6f6a80"), 2.0)
	for angle: float in [0.3, 2.4, 4.5]:
		var at: Vector2 = Vector2.from_angle(angle) * 20.0
		var along: Vector2 = Vector2.from_angle(angle + PI / 2.0) * 11.0
		draw_line(at - along, at + along, Color("#cfd3e0"), 3.0)


func _buttons() -> void:
	for spot: Vector3 in [Vector3(-12, 8, 11), Vector3(10, -4, 13), Vector3(-6, -14, 8)]:
		var center: Vector2 = Vector2(spot.x, spot.y)
		draw_circle(center, spot.z, Color("#8fc9b9"))
		for hole: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			draw_circle(center + hole * spot.z * 0.3, spot.z * 0.15, Color("#4f7f73"))
