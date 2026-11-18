class_name DamageLook
extends RefCounted
## A building a lost siege damaged (spec 07 §6): a few felt patches sewn over it, each with a
## dashed seam and a loose thread hanging off a corner. Drawn on top of the building's look in
## its own coordinates (bottom middle = 0, up = negative y). Colours from the world palette.

## A patch's size as a share of the building's width, and how far it may tilt (radians).
const PATCH_SHARE: Vector2 = Vector2(0.15, 0.24)
const PATCH_TILT: float = 0.35
## Patches stay inside this share of the look's box (away from its outline).
const INSET: float = 0.18
## The loose thread: how long (px) and how far it curls sideways.
const THREAD_LENGTH: float = 22.0
const THREAD_CURL: float = 7.0
## A patch's corners on a 1 x 1 square around its middle, clockwise.
const UNIT_CORNERS: Array[Vector2] = [
	Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)
]


## Draws `count` patches over a look whose box is `bounds`, placed by `seed_value` (the same
## building always gets the same patches).
static func draw(canvas: CanvasItem, bounds: Rect2, count: int, seed_value: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	if palette.damage_patches.is_empty() or count <= 0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var margin: Vector2 = bounds.size * INSET
	var inner: Rect2 = bounds.grow_individual(-margin.x, -margin.y, -margin.x, -margin.y)
	for i: int in count:
		var side: float = bounds.size.x * rng.randf_range(PATCH_SHARE.x, PATCH_SHARE.y)
		var middle: Vector2 = Vector2(
			rng.randf_range(inner.position.x, inner.end.x),
			rng.randf_range(inner.position.y, inner.end.y)
		)
		var corners: PackedVector2Array = patch_corners(
			middle, Vector2(side, side * 0.8), rng.randf_range(-PATCH_TILT, PATCH_TILT)
		)
		_draw_patch(canvas, corners, WorldPalette.pick(palette.damage_patches, i), palette)


## The four corners of a patch `size` big around `middle`, turned by `tilt` radians.
static func patch_corners(middle: Vector2, size: Vector2, tilt: float) -> PackedVector2Array:
	var corners: PackedVector2Array = []
	for corner: Vector2 in UNIT_CORNERS:
		corners.append(middle + (corner * size).rotated(tilt))
	return corners


static func _draw_patch(
	canvas: CanvasItem, corners: PackedVector2Array, fill: Color, palette: WorldPalette
) -> void:
	var closed: PackedVector2Array = corners.duplicate()
	closed.append(corners[0])
	FeltDraw.fill(canvas, corners, fill)
	canvas.draw_polyline(closed, palette.ink, palette.building_outline, true)
	var middle: Vector2 = (corners[0] + corners[2]) / 2.0
	var inset: float = palette.seam_inset
	for i: int in 4:
		var from: Vector2 = corners[i].move_toward(middle, inset)
		var to: Vector2 = corners[(i + 1) % 4].move_toward(middle, inset)
		canvas.draw_dashed_line(
			from, to, palette.loose_thread, palette.seam_width, palette.seam_dash, true
		)
	var start: Vector2 = corners[2]
	var thread: PackedVector2Array = [
		start,
		start + Vector2(THREAD_CURL, THREAD_LENGTH * 0.4),
		start + Vector2(-THREAD_CURL * 0.5, THREAD_LENGTH * 0.75),
		start + Vector2(THREAD_CURL * 0.3, THREAD_LENGTH),
	]
	canvas.draw_polyline(thread, palette.loose_thread, palette.seam_width, true)
