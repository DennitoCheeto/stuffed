class_name GearLook
extends RefCounted
## How a piece of sewn-on gear looks in the menus (spec 09 §7, #331): every piece has its own felt
## picture (a cap with a visor, a propeller cap, a pin cushion with pins, a vest with its patch, a
## raincoat with toggles, a gingham apron, a bell, a four-hole button, a wind-up key) with the ink
## outline and a stitched seam; each stitch level adds one detail (Lv 2 in a darker shade, Lv 3
## in a lighter one). Gear is not drawn on the heroes. Drawn on the sewing table tiles and slots,
## under the Wardrobe photos and in the Scrapbook, laid out in a square tile (`GearFit.tile`).

const OUTLINE: Color = UiColors.INK
const SEAM: Color = Color(1.0, 1.0, 1.0, 0.55)
## The cuff, bill, toggles and straps (a little darker than the piece) and the pale parts
## (propeller blades, gingham, the button's thread).
const CUFF: float = 0.2
const PALE: float = 0.45
## How much darker the Lv 2 detail is and how much lighter the Lv 3 detail.
const DARKER: float = 0.4
const LIGHTER: float = 0.3
## The string charms hang on, the pins' steel and their heads.
const STRING: Color = Color("#6b5f52")
const METAL: Color = Color("#8a8a96")
const PIN_HEADS: Array[Color] = [Color("#f0d36a"), Color("#8fb0de"), Color("#a9c48f")]
## The Patch Vest's patch (spec 09 §3) and the wind-up key (no string).
const PATCH_VEST: StringName = &"patch_vest"
const BEHIND: StringName = &"wind_up_key"
const PATCH_TILT: float = -0.2
## Which way the wind-up key's shaft points (up and to the left).
const KEY_DIRECTION: Vector2 = Vector2(-0.8, -0.6)
## Points on a curve or an oval side.
const STEPS: int = 10
## How far a body piece's shoulders drop at the sides (share of its height).
const SHOULDER_DROP: float = 0.16


## True for the piece that wears a felt patch (the Patch Vest).
static func has_patch(piece: GearDef) -> bool:
	return piece.id == PATCH_VEST


## Draws `piece` at stitch level `level` (0 = just the shape, no seams: a silhouette) filling a
## square tile of `side` around `middle`. See `draw_fitted`.
static func draw(
	canvas: CanvasItem,
	piece: GearDef,
	level: int,
	middle: Vector2,
	side: float,
	fill: Color,
	outline_width: float,
	patch: bool = true
) -> void:
	if side < 2.0:
		return
	draw_fitted(canvas, piece, level, GearFit.tile(middle, side), fill, outline_width, patch)


## Draws `piece` at stitch level `level` cut to `fit`, filled with `fill`. The Patch Vest wears its
## patch unless `patch` is false.
static func draw_fitted(
	canvas: CanvasItem,
	piece: GearDef,
	level: int,
	fit: GearFit,
	fill: Color,
	outline_width: float,
	patch: bool = true
) -> void:
	var pen: Pen = Pen.new(canvas, fill, outline_width, level)
	match piece.slot:
		GearDef.Slot.HEAD:
			_draw_head(pen, piece.id, fit)
		GearDef.Slot.BODY:
			_draw_body(pen, piece.id, fit, patch, piece.effect_color)
		_:
			_draw_charm(pen, piece.id, fit)


## Every colour `piece` is drawn with at stitch level `level` (readability tests).
static func colors(piece: GearDef, level: int) -> Array[Color]:
	var base: Color = piece.color
	var result: Array[Color] = [base, OUTLINE, SEAM, base.darkened(CUFF), base.lightened(PALE)]
	if has_patch(piece) and level >= 1:
		result.append(piece.effect_color)
	if piece.slot == GearDef.Slot.CHARM and piece.id != BEHIND:
		result.append(STRING)
	if piece.id == &"pin_cushion_hat":
		result.append(METAL)
		result.append_array(PIN_HEADS)
	if level >= 2:
		result.append(base.darkened(DARKER))
	if level >= 3:
		result.append(base.lightened(LIGHTER))
	return result


## Stitch dashes along the open line `path`: pairs of points (start, end) for a multiline.
static func stitches(path: PackedVector2Array, dash: float, gap: float) -> PackedVector2Array:
	var result: PackedVector2Array = []
	var on: bool = true
	var left: float = dash
	for i: int in path.size() - 1:
		var from: Vector2 = path[i]
		var to: Vector2 = path[i + 1]
		while from.distance_to(to) > 0.001:
			var step: float = minf(left, from.distance_to(to))
			var next: Vector2 = from.move_toward(to, step)
			if on:
				result.append(from)
				result.append(next)
			from = next
			left -= step
			if left <= 0.001:
				on = not on
				left = dash if on else gap
	return result


# --- Caps and hats -------------------------------------------------------------------------


static func _draw_head(pen: Pen, id: StringName, fit: GearFit) -> void:
	var box: Rect2 = fit.head
	var brow: Vector2 = Vector2(box.get_center().x, box.end.y)
	var rx: float = box.size.x / 2.0 + pen.out()
	var h: float = box.size.y
	var sag: float = h * 0.12
	if id == &"pin_cushion_hat":
		_draw_cushion(pen, brow, rx, h)
		return
	pen.shape(_dome(brow, rx, h + pen.out(), sag), pen.fill)
	var band: float = maxf(h * 0.3, 2.0)
	pen.shape(_cuff(brow, rx, h + pen.out(), sag, band), pen.fill.darkened(CUFF))
	pen.seam(_smile(brow + Vector2(0.0, -band / 2.0), rx * 0.92, sag))
	if pen.level >= 1:
		var top: PackedVector2Array = []
		for i: int in STEPS + 1:
			var turn: float = PI * (1.2 + 0.6 * i / STEPS)
			top.append(brow + Vector2(cos(turn) * rx * 0.6, sin(turn) * h * 0.62))
		pen.seam(top)
	var crown: Vector2 = brow + Vector2(0.0, -h - pen.out())
	if id == &"propeller_cap":
		_draw_propeller(pen, crown, rx, h)
		return
	var bill: PackedVector2Array = _smile(brow, rx * 0.72, sag)
	var depth: float = maxf(h * 0.18, 1.2)
	for i: int in STEPS + 1:
		var turn: float = PI * i / STEPS
		bill.append(brow + Vector2(cos(turn) * rx * 0.72, sag * 0.5 + sin(turn) * depth))
	pen.shape(bill, pen.fill.darkened(CUFF))
	if pen.level >= 2:
		var lens: Vector2 = brow + Vector2(-rx * 0.45, -h * 0.55)
		pen.shape(FeltDraw.circle(lens, maxf(h * 0.18, 1.5), 12), pen.fill.darkened(DARKER))
	if pen.level >= 3:
		var radius: float = maxf(box.size.x * 0.13, 2.0)
		pen.shape(FeltDraw.circle(crown, radius, 14), pen.fill.lightened(LIGHTER))


## A beanie dome over the brow: the top of an oval `rx` wide and `ry` tall, closed by the brim
## curving down a little in the middle (`sag`) as it wraps round the head.
static func _dome(brow: Vector2, rx: float, ry: float, sag: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in STEPS * 2 + 1:
		var turn: float = PI + PI * i / (STEPS * 2)
		points.append(brow + Vector2(cos(turn) * rx, sin(turn) * ry))
	for i: int in range(STEPS - 1, 0, -1):
		var x: float = -rx + 2.0 * rx * i / STEPS
		points.append(brow + Vector2(x, sag * (1.0 - pow(x / rx, 2.0))))
	return points


## The turned-up cuff along the brim, `band` tall.
static func _cuff(
	brow: Vector2, rx: float, ry: float, sag: float, band: float
) -> PackedVector2Array:
	var inner: float = rx * sqrt(maxf(1.0 - pow(band / ry, 2.0), 0.0))
	var points: PackedVector2Array = []
	for i: int in STEPS + 1:
		var x: float = -inner + 2.0 * inner * i / STEPS
		points.append(brow + Vector2(x, -band + sag * (1.0 - pow(x / rx, 2.0))))
	for i: int in STEPS + 1:
		var x: float = rx - 2.0 * rx * i / STEPS
		points.append(brow + Vector2(x * 1.02, sag * (1.0 - pow(x / rx, 2.0))))
	return points


## The brim's curve from left to right, `rx` wide.
static func _smile(brow: Vector2, rx: float, sag: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in STEPS + 1:
		var x: float = -rx + 2.0 * rx * i / STEPS
		points.append(brow + Vector2(x, sag * (1.0 - pow(x / rx, 2.0))))
	return points


static func _draw_propeller(pen: Pen, crown: Vector2, rx: float, h: float) -> void:
	var tall: float = maxf(h * 0.55, 3.0)
	var hub: Vector2 = crown + Vector2(0.0, -tall)
	pen.canvas.draw_line(crown, hub, OUTLINE, maxf(h * 0.12, 1.2), true)
	var blade: float = rx * 0.5
	var thick: float = maxf(h * 0.16, 1.3)
	var tip: Color = pen.fill.lightened(LIGHTER) if pen.level >= 3 else pen.fill.lightened(PALE)
	for side: float in [-1.0, 1.0]:
		var middle: Vector2 = hub + Vector2(side * blade, 0.0)
		pen.shape(PlushieLook.ellipse(middle, blade, thick), pen.fill.lightened(PALE))
		if pen.level >= 3:
			var end: Vector2 = hub + Vector2(side * blade * 1.55, 0.0)
			pen.canvas.draw_circle(end, thick * 0.7, tip)
	var center: PackedVector2Array = FeltDraw.circle(hub, thick * 1.2, 12)
	pen.shape(center, pen.fill.darkened(DARKER) if pen.level >= 2 else pen.fill.darkened(CUFF))


## The Pin Cushion Hat: a squashy cushion sitting on the head with pins poking out of the top.
static func _draw_cushion(pen: Pen, brow: Vector2, rx: float, h: float) -> void:
	var middle: Vector2 = brow + Vector2(0.0, -h * 0.55)
	var ry: float = h * 0.62 + pen.out()
	var pins: Array[float] = [-0.3, 0.32]
	if pen.level >= 3:
		pins = [-0.42, 0.08, 0.46]
	var pin_length: float = maxf(h * 0.75, 4.0)
	for i: int in pins.size():
		var base: Vector2 = middle + Vector2(pins[i] * rx, -ry * 0.7)
		var head: Vector2 = base + Vector2(pins[i] * pin_length * 0.6, -pin_length)
		pen.canvas.draw_line(base, head, METAL, maxf(h * 0.07, 1.0), true)
		pen.shape(FeltDraw.circle(head, maxf(h * 0.13, 1.6), 10), PIN_HEADS[i])
	var cushion: PackedVector2Array = PlushieLook.ellipse(middle, rx * 1.02, ry)
	pen.shape(cushion, pen.fill)
	var ridge: Color = pen.fill.darkened(DARKER) if pen.level >= 2 else pen.fill.darkened(CUFF)
	for x: float in [-0.45, 0.0, 0.45]:
		var line: PackedVector2Array = []
		for i: int in STEPS + 1:
			var y: float = -ry * 0.85 + 1.7 * ry * i / STEPS
			var bulge: float = x * rx * sqrt(maxf(1.0 - pow(y / ry, 2.0), 0.0))
			line.append(middle + Vector2(bulge, y))
		pen.canvas.draw_polyline(line, ridge, maxf(h * 0.08, 1.0), true)
	pen.seam(_smile(brow + Vector2(0.0, -h * 0.22), rx * 0.8, -h * 0.12))
	if pen.level >= 3:
		var bow: Vector2 = middle + Vector2(0.0, -ry)
		pen.shape(PlushieLook.ellipse(bow, rx * 0.22, h * 0.14), pen.fill.lightened(LIGHTER))


# --- Vests, coats, aprons ------------------------------------------------------------------


static func _draw_body(
	pen: Pen, id: StringName, fit: GearFit, patch: bool, patch_color: Color
) -> void:
	match id:
		&"raincoat":
			_draw_raincoat(pen, fit)
		&"picnic_apron":
			_draw_apron(pen, fit)
		_:
			_draw_vest(pen, fit, patch, patch_color)


static func _draw_vest(pen: Pen, fit: GearFit, patch: bool, patch_color: Color) -> void:
	var span: Vector2 = fit.band_y()
	var oval: Rect2 = fit.body.grow(pen.out())
	pen.shape(_wrap(oval, span, fit.opening, true), pen.fill)
	var middle: float = oval.get_center().x
	var w: float = fit.body.size.x
	pen.seam(_hem(oval, span.y - maxf(w * 0.05, 1.5), 0.9))
	var open_bottom: float = span.x + fit.opening.y
	if pen.level >= 1 and patch and patch_color.a > 0.0:
		var at: Vector2 = Vector2(middle - _half(oval, lerpf(span.x, span.y, 0.55)) * 0.5, 0.0)
		at.y = lerpf(open_bottom, span.y, 0.45)
		pen.shape(patch_shape(at, w * 0.13), patch_color)
		var inset: PackedVector2Array = patch_shape(at, w * 0.09)
		inset.append(inset[0])
		pen.seam(inset)
	if pen.level >= 2:
		for share: float in [0.3, 0.65]:
			var button: Vector2 = Vector2(middle + w * 0.06, lerpf(open_bottom, span.y, share))
			pen.canvas.draw_circle(button, maxf(w * 0.035, 1.0), pen.fill.darkened(DARKER))
	if pen.level >= 3:
		var y: float = lerpf(open_bottom, span.y, 0.5)
		var pocket: Rect2 = Rect2(Vector2(middle + w * 0.14, y), Vector2(w * 0.2, w * 0.15))
		pen.shape(FeltDraw.rounded(pocket, w * 0.03), pen.fill.lightened(LIGHTER))


## The Patch Vest's patch: a small tilted square around `middle`, `half` the side.
static func patch_shape(middle: Vector2, half: float) -> PackedVector2Array:
	var corners: PackedVector2Array = []
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(middle + (corner * half).rotated(PATCH_TILT))
	return corners


static func _draw_raincoat(pen: Pen, fit: GearFit) -> void:
	var span: Vector2 = fit.band_y(0.14)
	var oval: Rect2 = fit.body.grow(pen.out())
	pen.shape(_wrap(oval, span, fit.opening, false), pen.fill)
	var middle: float = oval.get_center().x
	var w: float = fit.body.size.x
	var open_bottom: float = span.x + fit.opening.y
	var closure: PackedVector2Array = [Vector2(middle, open_bottom), Vector2(middle, span.y)]
	pen.canvas.draw_polyline(closure, OUTLINE, maxf(pen.line * 0.8, 0.8), true)
	pen.seam(_hem(oval, span.y - maxf(w * 0.05, 1.5), 0.9))
	var toggles: int = 3 if pen.level >= 2 else 2
	for i: int in toggles:
		var y: float = lerpf(open_bottom, span.y, (i + 0.7) / (toggles + 0.6))
		var toggle: Rect2 = Rect2(Vector2(middle + w * 0.03, y), Vector2(w * 0.12, w * 0.05))
		var shade: Color = pen.fill.darkened(DARKER if i == 2 else CUFF)
		pen.shape(FeltDraw.rounded(toggle, w * 0.025), shade)
	if pen.level >= 3:
		var y: float = lerpf(open_bottom, span.y, 0.55)
		var pocket: Rect2 = Rect2(Vector2(middle - w * 0.33, y), Vector2(w * 0.2, w * 0.13))
		pen.shape(FeltDraw.rounded(pocket, w * 0.03), pen.fill.lightened(LIGHTER))


static func _draw_apron(pen: Pen, fit: GearFit) -> void:
	var span: Vector2 = fit.band_y(0.06)
	var oval: Rect2 = fit.body.grow(pen.out())
	var middle: float = oval.get_center().x
	var w: float = fit.body.size.x
	var top: float = span.x + fit.opening.y * 0.85
	var waist: float = lerpf(top, span.y, 0.42)
	var bib: float = minf(_half(oval, top) * 0.75, w * 0.24)
	bib = maxf(bib, fit.opening.x * 0.8)
	var skirt: float = _half(oval, waist) * 0.86
	var strap: Color = pen.fill.darkened(CUFF)
	for side: float in [-1.0, 1.0]:
		var from: Vector2 = Vector2(middle + side * bib * 0.85, top + 1.0)
		var to: Vector2 = Vector2(middle + side * (fit.opening.x + w * 0.05), span.x - w * 0.04)
		pen.canvas.draw_line(from, to, OUTLINE, maxf(w * 0.07, 2.0), true)
		pen.canvas.draw_line(from, to, strap, maxf(w * 0.04, 1.2), true)
	var shape: PackedVector2Array = [
		Vector2(middle - bib, top),
		Vector2(middle + bib, top),
		Vector2(middle + bib, waist),
		Vector2(middle + skirt, waist),
	]
	for i: int in STEPS + 1:
		var y: float = lerpf(waist, span.y, float(i) / STEPS)
		shape.append(Vector2(middle + minf(skirt * 1.04, _half(oval, y) * 0.96), y))
	for i: int in STEPS + 1:
		var y: float = lerpf(span.y, waist, float(i) / STEPS)
		shape.append(Vector2(middle - minf(skirt * 1.04, _half(oval, y) * 0.96), y))
	shape.append(Vector2(middle - bib, waist))
	pen.shape(shape, pen.fill)
	var check: Color = pen.fill.lightened(PALE)
	var thick: float = maxf(w * 0.05, 1.2)
	for x: float in [-0.5, 0.5]:
		var at: float = middle + x * bib
		pen.canvas.draw_line(Vector2(at, top + 1.0), Vector2(at, span.y - 1.0), check, thick)
	for share: float in [0.3, 0.7]:
		var y: float = lerpf(waist, span.y, share)
		var reach: float = skirt * 0.9
		pen.canvas.draw_line(Vector2(middle - reach, y), Vector2(middle + reach, y), check, thick)
	pen.seam(
		PackedVector2Array(
			[Vector2(middle - skirt * 0.9, waist), Vector2(middle + skirt * 0.9, waist)]
		)
	)
	if pen.level >= 2:
		var trim: PackedVector2Array = _hem(oval, span.y - maxf(w * 0.03, 1.0), 0.84)
		pen.canvas.draw_polyline(trim, pen.fill.darkened(DARKER), maxf(w * 0.05, 1.2), true)
	if pen.level >= 3:
		var y: float = lerpf(waist, span.y, 0.35)
		var pocket: Rect2 = Rect2(Vector2(middle - w * 0.12, y), Vector2(w * 0.24, w * 0.15))
		pen.shape(FeltDraw.rounded(pocket, w * 0.03), pen.fill.lightened(LIGHTER))


## Half the width of `oval` at height `y`.
static func _half(oval: Rect2, y: float) -> float:
	var ry: float = oval.size.y / 2.0
	var t: float = clampf((y - oval.get_center().y) / ry, -1.0, 1.0)
	return oval.size.x / 2.0 * sqrt(1.0 - t * t)


## A piece wrapped round the body: the part of `oval` between `span.x` and `span.y` (top and
## bottom y), with round shoulders and a neck opening (`opening`: half width, depth) cut into the
## top, a V (`v`) or a round U.
static func _wrap(oval: Rect2, span: Vector2, opening: Vector2, v: bool) -> PackedVector2Array:
	var middle: float = oval.get_center().x
	var shoulder: float = span.x + (span.y - span.x) * SHOULDER_DROP
	var points: PackedVector2Array = []
	for i: int in STEPS + 1:
		var y: float = lerpf(shoulder, span.y, float(i) / STEPS)
		points.append(Vector2(middle + _half(oval, y), y))
	var hem: PackedVector2Array = _hem(oval, span.y, 1.0)
	for i: int in range(hem.size() - 2, 0, -1):
		points.append(hem[i])
	for i: int in STEPS + 1:
		var y: float = lerpf(span.y, shoulder, float(i) / STEPS)
		points.append(Vector2(middle - _half(oval, y), y))
	var edge: float = _half(oval, shoulder)
	var half: float = minf(opening.x, edge * 0.8)
	for i: int in range(1, STEPS):
		var s: float = float(i) / STEPS
		var y: float = span.x + (shoulder - span.x) * (1.0 - sin(s * PI / 2.0))
		points.append(Vector2(middle - lerpf(edge, half, s), y))
	if v:
		points.append(Vector2(middle - half, span.x))
		points.append(Vector2(middle, span.x + opening.y))
		points.append(Vector2(middle + half, span.x))
	else:
		for i: int in STEPS + 1:
			var turn: float = PI - PI * i / STEPS
			points.append(Vector2(middle + cos(turn) * half, span.x + sin(turn) * opening.y))
	for i: int in range(STEPS - 1, 0, -1):
		var s: float = float(i) / STEPS
		var y: float = span.x + (shoulder - span.x) * (1.0 - sin(s * PI / 2.0))
		points.append(Vector2(middle + lerpf(edge, half, s), y))
	return points


## The hem at height `y`: a gentle curve across `share` of the oval's width there.
static func _hem(oval: Rect2, y: float, share: float) -> PackedVector2Array:
	var half: float = _half(oval, y) * share
	var sag: float = oval.size.y * 0.03
	var points: PackedVector2Array = []
	for i: int in STEPS + 1:
		var x: float = -half + 2.0 * half * i / STEPS
		var dip: float = sag * (1.0 - pow(x / half, 2.0)) if half > 0.0 else 0.0
		points.append(Vector2(oval.get_center().x + x, y + dip))
	return points


# --- Charms --------------------------------------------------------------------------------


static func _draw_charm(pen: Pen, id: StringName, fit: GearFit) -> void:
	var size: float = _charm_size(fit)
	if id == BEHIND:
		_draw_key(pen, fit.key, size)
		return
	var at: Vector2 = fit.charm
	var hook: Vector2 = at + Vector2(0.0, -size * 0.62)
	var neck: PackedVector2Array = _neck(fit)
	var thread: float = maxf(size * 0.1, 1.0)
	for end: Vector2 in neck:
		var sag: Vector2 = (end + hook) / 2.0 + Vector2(0.0, size * 0.12)
		pen.canvas.draw_polyline(PackedVector2Array([end, sag, hook]), STRING, thread, true)
	if id == &"lucky_button":
		_draw_button(pen, at, size)
	else:
		_draw_bell(pen, at, size)
	if pen.level >= 3:
		var bow: Vector2 = hook + Vector2(0.0, -size * 0.05)
		for side: float in [-1.0, 1.0]:
			var loop: Vector2 = bow + Vector2(side * size * 0.2, 0.0)
			pen.shape(
				PlushieLook.ellipse(loop, size * 0.17, size * 0.11), pen.fill.lightened(LIGHTER)
			)


## Where the string goes round the neck: the two top corners of the neck opening.
static func _neck(fit: GearFit) -> PackedVector2Array:
	var top: float = fit.band_y().x
	var middle: float = fit.body.get_center().x
	var half: float = maxf(fit.opening.x, fit.body.size.x * 0.18)
	return PackedVector2Array([Vector2(middle - half, top), Vector2(middle + half, top)])


static func _charm_size(fit: GearFit) -> float:
	return maxf(fit.charm_size, 4.0)


static func _draw_bell(pen: Pen, at: Vector2, size: float) -> void:
	var half: float = size * 0.5
	var bell: PackedVector2Array = []
	for i: int in STEPS + 1:
		var turn: float = PI + PI * i / STEPS
		bell.append(at + Vector2(cos(turn) * half * 0.8, -size * 0.12 + sin(turn) * size * 0.5))
	bell.append(at + Vector2(half * 0.8, size * 0.28))
	bell.append(at + Vector2(half * 1.05, size * 0.42))
	bell.append(at + Vector2(-half * 1.05, size * 0.42))
	bell.append(at + Vector2(-half * 0.8, size * 0.28))
	var clapper: PackedVector2Array = FeltDraw.circle(
		at + Vector2(0.0, size * 0.5), size * 0.14, 10
	)
	pen.shape(clapper, pen.fill.darkened(CUFF))
	pen.shape(bell, pen.fill)
	pen.seam(
		PackedVector2Array(
			[at + Vector2(-half * 0.65, size * 0.12), at + Vector2(half * 0.65, size * 0.12)]
		)
	)
	if pen.level >= 2:
		var band: Rect2 = Rect2(
			at + Vector2(-half * 0.78, -size * 0.1), Vector2(half * 1.56, size * 0.12)
		)
		pen.shape(FeltDraw.rounded(band, size * 0.04), pen.fill.darkened(DARKER))


static func _draw_button(pen: Pen, at: Vector2, size: float) -> void:
	var radius: float = size * 0.5
	pen.shape(FeltDraw.circle(at, radius, 20), pen.fill)
	var rim: PackedVector2Array = FeltDraw.circle(at, radius * 0.72, 20)
	rim.append(rim[0])
	var rim_color: Color = pen.fill.darkened(DARKER) if pen.level >= 2 else pen.fill.darkened(CUFF)
	pen.canvas.draw_polyline(rim, rim_color, maxf(size * 0.08, 1.0), true)
	var gap: float = radius * 0.28
	var holes: Array[Vector2] = []
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		holes.append(at + corner * gap)
	var thread: Color = pen.fill.lightened(PALE)
	pen.canvas.draw_line(holes[0], holes[3], thread, maxf(size * 0.07, 1.0), true)
	pen.canvas.draw_line(holes[1], holes[2], thread, maxf(size * 0.07, 1.0), true)
	for hole: Vector2 in holes:
		pen.canvas.draw_circle(hole, maxf(size * 0.07, 0.8), OUTLINE)


## The wind-up key coming out of the back at `root`: a shaft and a two-loop bow.
static func _draw_key(pen: Pen, root: Vector2, size: float) -> void:
	var tip: Vector2 = root + KEY_DIRECTION * size * 1.15
	var across: Vector2 = KEY_DIRECTION.orthogonal()
	var shaft: float = maxf(size * 0.2, 1.6)
	pen.canvas.draw_line(root, tip, OUTLINE, shaft + pen.line * 2.0, true)
	pen.canvas.draw_line(root, tip, pen.fill, shaft, true)
	if pen.level >= 2:
		for share: float in [0.35, 0.6]:
			var at: Vector2 = root.lerp(tip, share)
			var notch: Vector2 = across * shaft * 0.6
			pen.canvas.draw_line(
				at - notch, at + notch, pen.fill.darkened(DARKER), maxf(shaft * 0.3, 0.8)
			)
	for side: float in [-1.0, 1.0]:
		var loop: Vector2 = tip + KEY_DIRECTION * size * 0.12 + across * side * size * 0.32
		var angle: float = across.angle()
		pen.shape(PlushieLook.ellipse(loop, size * 0.34, size * 0.22, angle), pen.fill)
		var hole: Color = (
			pen.fill.lightened(LIGHTER) if pen.level >= 3 else pen.fill.lightened(PALE)
		)
		pen.shape(PlushieLook.ellipse(loop, size * 0.13, size * 0.08, angle), hole)
	pen.shape(FeltDraw.circle(tip, size * 0.16, 10), pen.fill.darkened(CUFF))
	pen.seam(PackedVector2Array([root.lerp(tip, 0.15), root.lerp(tip, 0.85)]))


## What one piece is drawn with: the canvas, its fill, the inner ink line and the stitch level.
class Pen:
	var canvas: CanvasItem
	var fill: Color
	var line: float
	var level: int

	func _init(on: CanvasItem, color: Color, width: float, stitch_level: int) -> void:
		canvas = on
		fill = color
		line = width
		level = stitch_level

	## How far a piece stands out of the hero's outline (felt has a thickness).
	func out() -> float:
		return maxf(line, 0.8)

	## One felt shape with its ink outline.
	func shape(points: PackedVector2Array, color: Color) -> void:
		if points.size() < 3:
			return
		FeltDraw.fill(canvas, points, color)
		if line <= 0.0:
			return
		var ring: PackedVector2Array = points.duplicate()
		ring.append(points[0])
		canvas.draw_polyline(ring, OUTLINE, line, true)

	## A stitched seam along the open line `path` (from stitch level 1 on).
	func seam(path: PackedVector2Array) -> void:
		if level <= 0 or path.size() < 2:
			return
		var length: float = 0.0
		for i: int in path.size() - 1:
			length += path[i].distance_to(path[i + 1])
		var dash: float = clampf(length / 9.0, 1.2, 4.0)
		var dashes: PackedVector2Array = GearLook.stitches(path, dash, dash * 0.75)
		if not dashes.is_empty():
			canvas.draw_multiline(dashes, SEAM, maxf(dash * 0.4, 0.8))
