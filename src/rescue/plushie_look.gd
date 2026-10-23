class_name PlushieLook
extends RefCounted
## Felt looks of the rescued plushies (spec 03 §7), drawn from the product owner's photos of the
## girlfriend's real plushies: Pip (round polar bear with a scarf), Böbö (big teddy), BamBam
## (long bear with a bowtie and a heart) and Robbar (smol chonky seal). Colours come from each
## PlushieDef; the shapes live here. A plushie stands on `at` (its feet) and is about 3.2 x
## `size` tall (times its `height`).

const EYE_COLOR: Color = Color("#2a2230")
const SHINE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.25)
const CHEEK_COLOR: Color = Color(0.96, 0.62, 0.66, 0.55)
const EAR_PINK: Color = Color("#f3b9c4")
## Outlines are the body colour this much darker.
const OUTLINE_DARKEN: float = 0.45
## How far a waving arm swings (radians) at the top of a wave.
const WAVE_SWING: float = 1.9


## Draws `plushie` on `canvas`, standing on `at`. `wave` (0..1) lifts its right arm (or
## flipper) to wave.
static func draw(
	canvas: CanvasItem, plushie: PlushieDef, at: Vector2, size: float, wave: float = 0.0
) -> void:
	var u: float = size * plushie.height
	canvas.draw_colored_polygon(ellipse(at, u * 1.1, u * 0.3), SHADOW_COLOR)
	match plushie.shape:
		PlushieDef.Shape.ROUND_BEAR:
			_draw_round_bear(canvas, plushie, at, u, wave)
		PlushieDef.Shape.LONG:
			_draw_long(canvas, plushie, at, u, wave)
		PlushieDef.Shape.SEAL:
			_draw_seal(canvas, plushie, at, u, wave)
		_:
			_draw_teddy(canvas, plushie, at, u, wave)


## Points of an ellipse around `center` with radii `rx` and `ry`, turned by `angle`.
static func ellipse(
	center: Vector2, rx: float, ry: float, angle: float = 0.0
) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in 24:
		var turn: float = TAU * i / 24.0
		points.append(center + Vector2(cos(turn) * rx, sin(turn) * ry).rotated(angle))
	return points


## How high the top of the plushie's head is above its feet (pixels, for name tags).
static func top(plushie: PlushieDef, size: float) -> float:
	var u: float = size * plushie.height
	match plushie.shape:
		PlushieDef.Shape.ROUND_BEAR:
			return u * 3.5
		PlushieDef.Shape.LONG:
			return u * 3.9
		PlushieDef.Shape.SEAL:
			return u * 1.8
		_:
			return u * 3.0


## Pip: a huge round white body, a tiny head on top, a knitted scarf, stubby arms with dark
## pads and three toe dots on each foot.
static func _draw_round_bear(
	canvas: CanvasItem, p: PlushieDef, at: Vector2, u: float, wave: float
) -> void:
	var line: Color = p.body_color.darkened(0.25)
	for side: float in [-1.0, 1.0]:
		var foot: Vector2 = at + Vector2(side * u * 0.55, -u * 0.25)
		_oval(canvas, foot, u * 0.45, u * 0.3, p.body_color, line)
		for toe: int in 3:
			var dot: Vector2 = foot + Vector2((toe - 1) * u * 0.17, u * 0.1)
			canvas.draw_circle(dot, u * 0.06, p.patch_color)
	var body: Vector2 = at + Vector2(0.0, -u * 1.55)
	for side: float in [-1.0, 1.0]:
		var swing: float = WAVE_SWING * wave if side > 0.0 else 0.0
		var shoulder: Vector2 = body + Vector2(side * u * 1.15, -u * 0.45)
		var turn: float = -side * 0.35 - side * swing
		var hand: Vector2 = shoulder + Vector2(0.0, u * 0.6).rotated(turn)
		_oval(canvas, (shoulder + hand) / 2.0, u * 0.3, u * 0.55, p.body_color, line, turn)
		canvas.draw_circle(hand, u * 0.08, p.patch_color)
	_oval(canvas, body, u * 1.3, u * 1.4, p.body_color, line)
	canvas.draw_arc(body + Vector2(0.0, u * 0.1), u * 0.95, 0.0, TAU, 32, Color(line, 0.25), 2.0)
	var head: Vector2 = at + Vector2(0.0, -u * 3.1)
	for side: float in [-1.0, 1.0]:
		var ear: Vector2 = head + Vector2(side * u * 0.3, -u * 0.32)
		_oval(canvas, ear, u * 0.14, u * 0.13, p.body_color, line)
	_oval(canvas, head, u * 0.42, u * 0.38, p.body_color, line)
	_face(canvas, head + Vector2(0.0, u * 0.02), u * 0.3, u * 0.05)
	var neck: Vector2 = at + Vector2(0.0, -u * 2.78)
	_oval(canvas, neck, u * 0.55, u * 0.16, p.detail_color, p.detail_color.darkened(0.35))
	var tail: PackedVector2Array = [
		neck + Vector2(-u * 0.4, -u * 0.05),
		neck + Vector2(-u * 0.15, u * 0.05),
		neck + Vector2(-u * 0.55, u * 0.95),
		neck + Vector2(-u * 0.82, u * 0.85),
	]
	canvas.draw_colored_polygon(tail, p.detail_color)
	_outline(canvas, tail, p.detail_color.darkened(0.35))


## Böbö: a big classic teddy bear with a light muzzle, round ears and paw pads.
static func _draw_teddy(
	canvas: CanvasItem, p: PlushieDef, at: Vector2, u: float, wave: float
) -> void:
	var line: Color = p.body_color.darkened(OUTLINE_DARKEN)
	for side: float in [-1.0, 1.0]:
		var foot: Vector2 = at + Vector2(side * u * 0.5, -u * 0.25)
		_oval(canvas, foot, u * 0.38, u * 0.3, p.body_color, line)
		_patch(canvas, foot + Vector2(0.0, u * 0.05), u * 0.2, u * 0.15, p.accent_color)
	var body: Vector2 = at + Vector2(0.0, -u * 0.95)
	_arms(canvas, p, body + Vector2(0.0, -u * 0.35), u * 0.8, u, wave, line)
	_oval(canvas, body, u * 0.9, u * 0.85, p.body_color, line)
	var belly: Color = p.accent_color.darkened(0.08)
	_patch(canvas, body + Vector2(0.0, u * 0.1), u * 0.5, u * 0.5, belly)
	var head: Vector2 = at + Vector2(0.0, -u * 2.05)
	for side: float in [-1.0, 1.0]:
		var ear: Vector2 = head + Vector2(side * u * 0.7, -u * 0.68)
		_oval(canvas, ear, u * 0.33, u * 0.33, p.body_color, line)
		canvas.draw_circle(ear, u * 0.16, p.accent_color)
	_oval(canvas, head, u * 0.95, u * 0.9, p.body_color, line)
	var muzzle: Vector2 = head + Vector2(0.0, u * 0.3)
	_patch(canvas, muzzle, u * 0.42, u * 0.3, p.accent_color)
	_patch(canvas, muzzle + Vector2(0.0, -u * 0.1), u * 0.16, u * 0.11, p.patch_color)
	_eyes(canvas, head + Vector2(0.0, -u * 0.12), u * 0.38, u * 0.12)


## BamBam: a long tube body (tan), round ears with pink insides, a light-blue bowtie, a
## lilac heart patch, pink cheeks and both arms up.
static func _draw_long(
	canvas: CanvasItem, p: PlushieDef, at: Vector2, u: float, wave: float
) -> void:
	var line: Color = p.body_color.darkened(OUTLINE_DARKEN)
	for side: float in [-1.0, 1.0]:
		var foot: Vector2 = at + Vector2(side * u * 0.38, -u * 0.15)
		_oval(canvas, foot, u * 0.3, u * 0.2, p.body_color, line)
	var top_y: float = -u * 3.55
	for side: float in [-1.0, 1.0]:
		var ear: Vector2 = at + Vector2(side * u * 0.42, top_y + u * 0.05)
		_oval(canvas, ear, u * 0.27, u * 0.25, p.body_color, line)
		canvas.draw_circle(ear + Vector2(0.0, u * 0.03), u * 0.14, EAR_PINK)
	for side: float in [-1.0, 1.0]:
		var lift: float = WAVE_SWING * 0.4 * wave * sin(wave * TAU * 2.0) if side > 0.0 else 0.0
		var shoulder: Vector2 = at + Vector2(side * u * 0.6, -u * 2.35)
		var turn: float = -side * 2.6 - lift
		var paw: Vector2 = shoulder + Vector2(0.0, u * 0.55).rotated(turn)
		_oval(canvas, (shoulder + paw) / 2.0, u * 0.22, u * 0.4, p.body_color, line, turn)
		canvas.draw_circle(paw, u * 0.07, CHEEK_COLOR)
	var tube: Rect2 = Rect2(at + Vector2(-u * 0.68, top_y), Vector2(u * 1.36, -top_y - u * 0.15))
	_capsule(canvas, tube, p.body_color, line)
	var face: Vector2 = at + Vector2(0.0, -u * 2.95)
	_eyes(canvas, face, u * 0.32, u * 0.09)
	var snout: Vector2 = face + Vector2(0.0, u * 0.17)
	_patch(canvas, snout, u * 0.2, u * 0.14, p.accent_color)
	_patch(canvas, snout + Vector2(0.0, -u * 0.06), u * 0.07, u * 0.04, EYE_COLOR)
	for side: float in [-1.0, 1.0]:
		canvas.draw_circle(face + Vector2(side * u * 0.47, u * 0.17), u * 0.09, CHEEK_COLOR)
	_bowtie(canvas, at + Vector2(0.0, -u * 2.45), u, p.detail_color)
	_heart(canvas, at + Vector2(-u * 0.2, -u * 0.95), u * 0.38, p.patch_color)


## Robbar: a smol chonky seal: a round spotted grey blob, a white face, flippers and a tail.
static func _draw_seal(
	canvas: CanvasItem, p: PlushieDef, at: Vector2, u: float, wave: float
) -> void:
	var line: Color = p.body_color.darkened(0.35)
	var body: Vector2 = at + Vector2(0.0, -u * 0.85)
	_oval(canvas, body + Vector2(u * 1.05, -u * 0.55), u * 0.22, u * 0.4, p.body_color, line, 0.7)
	_oval(canvas, body, u * 1.3, u * 0.88, p.body_color, line)
	var face: Vector2 = body + Vector2(-u * 0.25, u * 0.12)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in 40:
		var spread: Vector2 = Vector2(rng.randf_range(-1.15, 1.15), rng.randf_range(-0.8, 0.5))
		var inside: bool = Vector2(spread.x / 1.15, spread.y / 0.8).length() < 1.0
		var spot: Vector2 = body + spread * u
		if inside and (spot - face).length() > u * 0.66:
			canvas.draw_circle(spot, u * rng.randf_range(0.05, 0.1), p.detail_color)
	_patch(canvas, face, u * 0.62, u * 0.55, p.accent_color)
	_eyes(canvas, face + Vector2(0.0, -u * 0.12), u * 0.3, u * 0.09)
	for side: float in [-1.0, 1.0]:
		var cheek: Vector2 = face + Vector2(side * u * 0.08, u * 0.1)
		canvas.draw_circle(cheek, u * 0.1, p.accent_color.darkened(0.05))
	canvas.draw_circle(face + Vector2(0.0, u * 0.03), u * 0.04, EYE_COLOR)
	for side: float in [-1.0, 1.0]:
		var swing: float = -WAVE_SWING * 0.6 * wave if side > 0.0 else 0.0
		var flipper: Vector2 = at + Vector2(side * u * 0.75, -u * 0.18)
		_oval(canvas, flipper, u * 0.32, u * 0.14, p.body_color, line, side * 0.3 + swing)


## Two arms hanging from `shoulders`, `spread` apart; the right one lifts by `wave`.
static func _arms(
	canvas: CanvasItem,
	p: PlushieDef,
	shoulders: Vector2,
	spread: float,
	u: float,
	wave: float,
	line: Color
) -> void:
	for side: float in [-1.0, 1.0]:
		var swing: float = WAVE_SWING * wave if side > 0.0 else 0.0
		var shoulder: Vector2 = shoulders + Vector2(side * spread, 0.0)
		var turn: float = -side * 0.45 - side * swing
		var paw: Vector2 = shoulder + Vector2(0.0, u * 0.6).rotated(turn)
		_oval(canvas, (shoulder + paw) / 2.0, u * 0.25, u * 0.45, p.body_color, line, turn)
		canvas.draw_circle(paw, u * 0.12, p.accent_color)


static func _eyes(canvas: CanvasItem, center: Vector2, apart: float, radius: float) -> void:
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = center + Vector2(side * apart, 0.0)
		canvas.draw_circle(eye, radius, EYE_COLOR)
		canvas.draw_circle(eye + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.35, SHINE_COLOR)


## Tiny dot eyes, a nose and a smile (Pip's small head).
static func _face(canvas: CanvasItem, center: Vector2, apart: float, radius: float) -> void:
	for side: float in [-1.0, 1.0]:
		canvas.draw_circle(center + Vector2(side * apart * 0.5, -radius), radius, EYE_COLOR)
	canvas.draw_circle(center + Vector2(0.0, radius * 1.4), radius * 1.1, EYE_COLOR)
	var smile: Vector2 = center + Vector2(0.0, radius * 1.6)
	canvas.draw_arc(smile, radius * 2.0, 0.4, PI - 0.4, 8, EYE_COLOR, 1.5)


static func _bowtie(canvas: CanvasItem, center: Vector2, u: float, color: Color) -> void:
	var line: Color = color.darkened(0.3)
	for side: float in [-1.0, 1.0]:
		var wing: PackedVector2Array = [
			center,
			center + Vector2(side * u * 0.5, -u * 0.25),
			center + Vector2(side * u * 0.55, u * 0.0),
			center + Vector2(side * u * 0.5, u * 0.25),
		]
		canvas.draw_colored_polygon(wing, color)
		_outline(canvas, wing, line)
	canvas.draw_circle(center, u * 0.1, color.darkened(0.08))


static func _heart(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 24:
		var t: float = TAU * i / 24.0
		var x: float = 16.0 * pow(sin(t), 3)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(center + Vector2(x, -y) * radius / 16.0)
	canvas.draw_colored_polygon(points, color)
	_outline(canvas, points, color.darkened(0.2))


## A plain felt patch (no outline).
static func _patch(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	canvas.draw_colored_polygon(ellipse(center, rx, ry), color)


## A felt oval with an outline, turned by `angle`.
static func _oval(
	canvas: CanvasItem,
	center: Vector2,
	rx: float,
	ry: float,
	fill: Color,
	line: Color,
	angle: float = 0.0
) -> void:
	var points: PackedVector2Array = ellipse(center, rx, ry, angle)
	canvas.draw_colored_polygon(points, fill)
	_outline(canvas, points, line)


## A rounded tube filling `rect` (round top and bottom).
static func _capsule(canvas: CanvasItem, rect: Rect2, fill: Color, line: Color) -> void:
	var r: float = rect.size.x / 2.0
	var points: PackedVector2Array = []
	var top_middle: Vector2 = Vector2(rect.get_center().x, rect.position.y + r)
	var bottom_middle: Vector2 = Vector2(rect.get_center().x, rect.end.y - r)
	for i: int in 13:
		points.append(top_middle + Vector2.from_angle(PI + PI * i / 12.0) * r)
	for i: int in 13:
		points.append(bottom_middle + Vector2.from_angle(PI * i / 12.0) * r)
	canvas.draw_colored_polygon(points, fill)
	_outline(canvas, points, line)


static func _outline(canvas: CanvasItem, points: PackedVector2Array, line: Color) -> void:
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	canvas.draw_polyline(closed, line, 2.0, true)
