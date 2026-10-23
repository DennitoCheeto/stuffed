class_name PlushieLook
extends RefCounted
## Placeholder felt look of a rescued plushie (spec 03 §7): a round head with ears, a body with a
## belly patch and button eyes, in the plushie's colours. Replaced by the real plushies' looks
## once the product owner sends photos (M3-10).

const EYE_COLOR: Color = Color("#2a2230")
const SHINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.25)
## Outlines are the body colour this much darker.
const OUTLINE_DARKEN: float = 0.45


## Draws `plushie` on `canvas`, standing on `at` (its feet), `size` pixels = the head's radius.
static func draw(canvas: CanvasItem, plushie: PlushieDef, at: Vector2, size: float) -> void:
	var outline: Color = plushie.body_color.darkened(OUTLINE_DARKEN)
	var body_at: Vector2 = at + Vector2(0.0, -size * 0.75)
	var head_at: Vector2 = at + Vector2(0.0, -size * 1.95)
	canvas.draw_colored_polygon(ellipse(at, size * 0.95, size * 0.3), SHADOW_COLOR)
	_draw_ears(canvas, plushie, head_at, size, outline)
	_disc(canvas, body_at, size * 0.8, plushie.body_color, outline)
	canvas.draw_circle(body_at + Vector2(0.0, size * 0.1), size * 0.45, plushie.accent_color)
	_disc(canvas, head_at, size, plushie.body_color, outline)
	canvas.draw_colored_polygon(
		ellipse(head_at + Vector2(0.0, size * 0.35), size * 0.42, size * 0.3), plushie.accent_color
	)
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = head_at + Vector2(side * size * 0.38, -size * 0.08)
		canvas.draw_circle(eye, size * 0.14, EYE_COLOR)
		canvas.draw_circle(eye + Vector2(-size * 0.04, -size * 0.05), size * 0.05, SHINE_COLOR)
	canvas.draw_circle(head_at + Vector2(0.0, size * 0.25), size * 0.08, EYE_COLOR)


## Points of an ellipse around `center` with radii `rx` and `ry`.
static func ellipse(center: Vector2, rx: float, ry: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in 20:
		var angle: float = TAU * i / 20.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


static func _disc(
	canvas: CanvasItem, center: Vector2, radius: float, fill: Color, outline: Color
) -> void:
	canvas.draw_circle(center, radius, fill)
	canvas.draw_arc(center, radius, 0.0, TAU, 28, outline, 2.0, true)


static func _draw_ears(
	canvas: CanvasItem, plushie: PlushieDef, head_at: Vector2, size: float, outline: Color
) -> void:
	for side: float in [-1.0, 1.0]:
		match plushie.ears:
			PlushieDef.Ears.ROUND:
				var ear: Vector2 = head_at + Vector2(side * size * 0.72, -size * 0.72)
				_disc(canvas, ear, size * 0.36, plushie.body_color, outline)
				canvas.draw_circle(ear, size * 0.18, plushie.accent_color)
			PlushieDef.Ears.LONG:
				var tip: Vector2 = head_at + Vector2(side * size * 0.45, -size * 1.75)
				var middle: Vector2 = (head_at + tip) / 2.0 + Vector2(side * size * 0.05, 0.0)
				var outer: PackedVector2Array = ellipse(Vector2.ZERO, size * 0.28, size * 0.75)
				var inner: PackedVector2Array = ellipse(Vector2.ZERO, size * 0.13, size * 0.55)
				var turn: Transform2D = Transform2D(side * 0.25, middle)
				canvas.draw_colored_polygon(turn * outer, plushie.body_color)
				var closed: PackedVector2Array = turn * outer
				closed.append(closed[0])
				canvas.draw_polyline(closed, outline, 2.0, true)
				canvas.draw_colored_polygon(turn * inner, plushie.accent_color)
			PlushieDef.Ears.POINTY:
				var base: Vector2 = head_at + Vector2(side * size * 0.55, -size * 0.6)
				var ear: PackedVector2Array = [
					base + Vector2(-side * size * 0.4, size * 0.1),
					base + Vector2(side * size * 0.25, -size * 0.75),
					base + Vector2(side * size * 0.4, size * 0.3),
				]
				canvas.draw_colored_polygon(ear, plushie.body_color)
				var closed: PackedVector2Array = ear.duplicate()
				closed.append(ear[0])
				canvas.draw_polyline(closed, outline, 2.0, true)
			_:
				# No ears (a frog): big eye bumps on top instead.
				var bump: Vector2 = head_at + Vector2(side * size * 0.5, -size * 0.75)
				_disc(canvas, bump, size * 0.32, plushie.body_color, outline)
