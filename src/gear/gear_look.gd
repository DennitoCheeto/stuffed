class_name GearLook
extends RefCounted
## How a piece of sewn-on gear looks (spec 09 §7): a small felt shape by slot (a cap, a vest, a
## charm on a loop) in the piece's own calm colour, with the ink outline and a stitched seam.
## Each stitch level adds one detail: Lv 2 a second stitch row (cap, charm) or buttons (vest),
## Lv 3 a pom-pom (cap), a pocket (vest) or a tassel (charm). Drawn on the sewing table tiles,
## in the photos and baked once onto the heroes (HeroGear).

const OUTLINE: Color = UiColors.INK
const SEAM: Color = Color(1.0, 1.0, 1.0, 0.55)
## How much darker the buttons and tassel are, and how much lighter the pom-pom and pocket.
const DARKER: float = 0.4
const LIGHTER: float = 0.3
## The Patch Vest's patch (spec 09 §3): where it sits and how big it is, in half-sides of the vest.
const PATCH_VEST: StringName = &"patch_vest"
const PATCH_OFFSET: Vector2 = Vector2(-0.18, -0.05)
const PATCH_SIZE: float = 0.38
const PATCH_TILT: float = -0.2


## True for the piece that wears a felt patch (the Patch Vest).
static func has_patch(piece: GearDef) -> bool:
	return piece.id == PATCH_VEST


## The Patch Vest's patch: a small tilted square on the vest (`u` = half the side), `shrink`
## times its size around its own middle (its seam runs at 0.7).
static func patch_shape(middle: Vector2, u: float, shrink: float = 1.0) -> PackedVector2Array:
	var corners: PackedVector2Array = []
	var center: Vector2 = middle + PATCH_OFFSET * u
	var half: float = PATCH_SIZE * u / 2.0 * shrink
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		corners.append(center + (corner * half).rotated(PATCH_TILT))
	return corners


## Draws `piece` at stitch level `level` (0 = just the shape, no seams: a silhouette) on `canvas`,
## fitted in a square of `side` around `middle`, filled with `fill`. The Patch Vest wears its
## patch unless `patch` is false (the hero's vest after the patch caught a hit).
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
	for shape: PackedVector2Array in shapes(piece.slot, middle, side):
		_patch(canvas, shape, fill, outline_width)
	if level <= 0:
		return
	var dash: float = side / 18.0
	var seam_width: float = maxf(side / 48.0, 1.0)
	for line: PackedVector2Array in seams(piece.slot, level, middle, side):
		var dashes: PackedVector2Array = stitches(line, dash, dash * 0.75)
		if not dashes.is_empty():
			canvas.draw_multiline(dashes, SEAM, seam_width)
	var u: float = side / 2.0
	if patch and has_patch(piece):
		var corners: PackedVector2Array = patch_shape(middle, u)
		_patch(canvas, corners, piece.effect_color, outline_width)
		var inset: PackedVector2Array = patch_shape(middle, u, 0.7)
		inset.append(inset[0])
		canvas.draw_multiline(stitches(inset, dash, dash * 0.75), SEAM, seam_width)
	match piece.slot:
		GearDef.Slot.HEAD:
			if level >= 3:
				var pom: PackedVector2Array = FeltDraw.circle(
					middle + Vector2(0.0, -0.5) * u, 0.16 * u
				)
				_patch(canvas, pom, fill.lightened(LIGHTER), outline_width)
		GearDef.Slot.BODY:
			if level >= 2:
				for y: float in [-0.12, 0.28]:
					var button: Vector2 = middle + Vector2(0.14, y) * u
					canvas.draw_circle(button, 0.07 * u, fill.darkened(DARKER))
			if level >= 3:
				var pocket: Rect2 = Rect2(middle + Vector2(-0.46, 0.2) * u, Vector2(0.3, 0.3) * u)
				_patch(
					canvas,
					FeltDraw.rounded(pocket, 0.05 * u),
					fill.lightened(LIGHTER),
					outline_width
				)
		GearDef.Slot.CHARM:
			if level >= 3:
				for x: float in [-0.1, 0.0, 0.1]:
					var top: Vector2 = middle + Vector2(x * 0.5, 0.74) * u
					canvas.draw_line(
						top, middle + Vector2(x, 0.98) * u, fill.darkened(DARKER), 0.07 * u
					)


## Every colour `piece` is drawn with at stitch level `level` (readability tests).
static func colors(piece: GearDef, level: int) -> Array[Color]:
	var result: Array[Color] = [piece.color, OUTLINE, SEAM]
	if has_patch(piece) and level >= 1:
		result.append(piece.effect_color)
	if level >= 2:
		result.append(piece.color.darkened(DARKER))
	if level >= 3:
		result.append(piece.color.lightened(LIGHTER))
	return result


## The felt parts of a piece in `slot`, fitted in a square of `side` around `middle`.
static func shapes(slot: GearDef.Slot, middle: Vector2, side: float) -> Array[PackedVector2Array]:
	var u: float = side / 2.0
	match slot:
		GearDef.Slot.HEAD:
			var dome: PackedVector2Array = []
			for i: int in 17:
				var angle: float = PI + PI * i / 16.0
				dome.append(middle + Vector2(cos(angle) * 0.62, 0.15 + sin(angle) * 0.6) * u)
			var brim: PackedVector2Array = FeltDraw.rounded(
				Rect2(middle + Vector2(-0.85, 0.12) * u, Vector2(1.5, 0.22) * u), 0.1 * u
			)
			return [dome, brim]
		GearDef.Slot.BODY:
			var vest: PackedVector2Array = [
				middle + Vector2(-0.45, -0.7) * u,
				middle + Vector2(-0.12, -0.45) * u,
				middle + Vector2(0.12, -0.45) * u,
				middle + Vector2(0.45, -0.7) * u,
				middle + Vector2(0.8, -0.35) * u,
				middle + Vector2(0.6, -0.15) * u,
				middle + Vector2(0.58, 0.75) * u,
				middle + Vector2(-0.58, 0.75) * u,
				middle + Vector2(-0.6, -0.15) * u,
				middle + Vector2(-0.8, -0.35) * u,
			]
			return [vest]
	var loop: PackedVector2Array = FeltDraw.circle(middle + Vector2(0.0, -0.62) * u, 0.18 * u, 16)
	var charm: PackedVector2Array = FeltDraw.circle(middle + Vector2(0.0, 0.18) * u, 0.58 * u)
	return [loop, charm]


## The stitch rows on a piece at stitch level `level`: one row at Lv 1, a second from Lv 2 on
## (the vest gets buttons instead).
static func seams(
	slot: GearDef.Slot, level: int, middle: Vector2, side: float
) -> Array[PackedVector2Array]:
	var u: float = side / 2.0
	var rows: Array[PackedVector2Array] = []
	match slot:
		GearDef.Slot.HEAD:
			rows.append(
				PackedVector2Array(
					[middle + Vector2(-0.5, 0.0) * u, middle + Vector2(0.5, 0.0) * u]
				)
			)
			if level >= 2:
				var arc: PackedVector2Array = []
				for i: int in 9:
					var angle: float = PI * 1.15 + PI * 0.7 * i / 8.0
					arc.append(middle + Vector2(cos(angle) * 0.36, 0.15 + sin(angle) * 0.36) * u)
				rows.append(arc)
		GearDef.Slot.BODY:
			rows.append(
				PackedVector2Array(
					[middle + Vector2(0.0, -0.4) * u, middle + Vector2(0.0, 0.68) * u]
				)
			)
		_:
			var ring: PackedVector2Array = FeltDraw.circle(
				middle + Vector2(0.0, 0.18) * u, 0.42 * u, 24
			)
			ring.append(ring[0])
			rows.append(ring)
			if level >= 2:
				var at: Vector2 = middle + Vector2(0.0, 0.18) * u
				rows.append(
					PackedVector2Array(
						[at + Vector2(-0.18, -0.18) * u, at + Vector2(0.18, 0.18) * u]
					)
				)
				rows.append(
					PackedVector2Array(
						[at + Vector2(0.18, -0.18) * u, at + Vector2(-0.18, 0.18) * u]
					)
				)
	return rows


## One felt shape with its ink outline.
static func _patch(
	canvas: CanvasItem, shape: PackedVector2Array, fill: Color, outline_width: float
) -> void:
	if shape.size() < 3:
		return
	FeltDraw.fill(canvas, shape, fill)
	if outline_width <= 0.0:
		return
	var ring: PackedVector2Array = shape.duplicate()
	ring.append(shape[0])
	canvas.draw_polyline(ring, OUTLINE, outline_width, true)


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
