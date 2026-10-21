class_name UpgradeIcon
extends Control
## A small felt-style icon for an upgrade card, drawn in code.

const BACK_COLOR: Color = Color("#2a2633")
const RING_COLOR: Color = Color("#4a4358")
## Evolved weapons get a gold ring.
const EVOLVED_RING_COLOR: Color = Color("#f2c230")
const EVOLVED: Array[StringName] = [&"split", &"storm", &"volley", &"bomb"]

## Which icon to draw: boomerang, pin, needles, buttons, cloud, yarn, thimble, cannon, whip,
## zipper, feet, stuffing, magnet, hands, scissors, thread, spool, felt, snack. "" draws only the
## empty round back (an empty HUD slot).
var icon: StringName = &"":
	set(value):
		icon = value
		queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0
	draw_circle(center, radius, EVOLVED_RING_COLOR if EVOLVED.has(icon) else RING_COLOR)
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
		&"cloud":
			_cloud()
		&"yarn":
			_yarn()
		&"thimble":
			_thimble()
		&"cannon":
			_cannon()
		&"whip":
			_whip()
		&"zipper":
			_zipper()
		&"scissors":
			_scissors()
		&"thread":
			_thread()
		&"spool":
			_spool()
		&"felt":
			_felt()
		&"split":
			_split()
		&"storm":
			_storm()
		&"volley":
			_volley()
		&"bomb":
			_bomb()


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


func _cloud() -> void:
	for puff: Vector3 in [Vector3(-14, 4, 12), Vector3(14, 4, 12), Vector3(0, -6, 16)]:
		draw_circle(Vector2(puff.x, puff.y), puff.z, Color("#e9e2f2"))
	draw_rect(Rect2(-14, 4, 28, 12), Color("#e9e2f2"))
	for spot: Vector2 in [Vector2(-22, 24), Vector2(0, 26), Vector2(22, 24)]:
		draw_circle(spot, 3.0, Color("#b9aecb"))


func _yarn() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color("#e98aa8"))
	for x: float in [-9.0, 0.0, 9.0]:
		draw_arc(Vector2(x * 2.4, 0), 20.0, PI - 0.9, PI + 0.9, 10, Color("#b65a7c"), 2.5)
	draw_line(Vector2(16, 12), Vector2(28, 26), Color("#e98aa8"), 3.0)


func _thimble() -> void:
	var body: PackedVector2Array = [Vector2(-16, 18), Vector2(-12, -14), Vector2(0, -20)]
	body.append_array([Vector2(12, -14), Vector2(16, 18)])
	draw_colored_polygon(body, Color("#c9c3b4"))
	for y: float in [-8.0, 2.0]:
		for x: float in [-6.0, 0.0, 6.0]:
			draw_circle(Vector2(x, y), 2.0, Color("#8d8676"))
	draw_rect(Rect2(-18, 14, 36, 6), Color("#aaa395"))


func _cannon() -> void:
	draw_rect(Rect2(-24, -6, 30, 18), Color("#8d8676"))
	draw_circle(Vector2(-24, 3), 9.0, Color("#6f6a80"))
	draw_circle(Vector2(18, -6), 13.0, Color("#e98aa8"))
	draw_arc(Vector2(14, -6), 13.0, -0.9, 0.9, 10, Color("#b65a7c"), 2.5)


func _whip() -> void:
	draw_arc(Vector2(-14, 6), 30.0, -1.3, 0.5, 20, Color("#f0d78c"), 5.0)
	draw_line(Vector2(-22, 26), Vector2(-14, 6), Color("#8d6a4f"), 6.0)


func _zipper() -> void:
	draw_line(Vector2(-26, 20), Vector2(22, -20), Color("#8fc4d9"), 9.0)
	for i: int in 6:
		var at: Vector2 = Vector2(-22, 17).lerp(Vector2(18, -17), i / 5.0)
		draw_line(at + Vector2(-4, -4), at + Vector2(4, 4), Color("#dfeef4"), 2.5)
	draw_circle(Vector2(24, -22), 6.0, Color("#dfeef4"))


## Banana Split: three peels fanning out.
func _split() -> void:
	var shape: PackedVector2Array = FeltShapes.svg_path(
		PackedFloat32Array([-14, 6, -8, -10, 8, -10, 14, 6, 6, -2, -6, -2, -14, 6])
	)
	for tilt: float in [-0.7, 0.0, 0.7]:
		var points: PackedVector2Array = []
		for point: Vector2 in shape:
			points.append((point * 1.2 + Vector2(0, -20)).rotated(tilt) + Vector2(0, 14))
		draw_colored_polygon(points, Color("#f2d34a"))


## Sewing Storm: a whirl of needles.
func _storm() -> void:
	for ring: float in [12.0, 22.0]:
		draw_arc(Vector2.ZERO, ring, 0.0, TAU, 32, Color("#6f6a80"), 2.0)
	for i: int in 8:
		var angle: float = TAU * i / 8.0
		var at: Vector2 = Vector2.from_angle(angle) * (14.0 if i % 2 == 0 else 24.0)
		var along: Vector2 = Vector2.from_angle(angle + PI / 2.0) * 7.0
		draw_line(at - along, at + along, Color("#e6eaf5"), 3.0)


## Pincushion Volley: a fan of pins.
func _volley() -> void:
	for i: int in 5:
		var direction: Vector2 = Vector2.from_angle(-PI / 2.0 + (i - 2) * 0.32)
		var tail: Vector2 = Vector2(0, 22) + direction * 4.0
		var tip: Vector2 = tail + direction * 40.0
		draw_line(tail, tip, Color("#d9d6e3"), 3.0)
		draw_circle(tail, 4.5, Color("#e0475b"))


## Yarn Bomb: a yarn ball with sticky strands around it.
func _bomb() -> void:
	for i: int in 6:
		var angle: float = TAU * i / 6.0 + 0.3
		draw_line(Vector2.ZERO, Vector2.from_angle(angle) * 28.0, Color("#f0a8c0"), 2.0)
	draw_circle(Vector2.ZERO, 17.0, Color("#e98aa8"))
	for x: float in [-7.0, 0.0, 7.0]:
		draw_arc(Vector2(x * 2.4, 0), 17.0, PI - 0.9, PI + 0.9, 10, Color("#b65a7c"), 2.5)
