class_name GearPicture
extends Control
## A piece of gear on its sewing table tile (spec 09 §6): a small felt shape by slot (a cap, a
## vest, a charm on a loop) in the piece's own calm colour with the ink outline. A piece whose
## pattern wasn't found yet is a dark silhouette. M4.5-05 puts the real pieces on the heroes.

const SILHOUETTE: Color = Color(0.2, 0.18, 0.26, 1.0)
const OUTLINE: Color = UiColors.INK
const OUTLINE_WIDTH: float = 2.5
const SEAM: Color = Color(1.0, 1.0, 1.0, 0.55)

var piece: GearDef
var locked: bool = false


func _init(shown: GearDef, is_locked: bool) -> void:
	piece = shown
	locked = is_locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(72, 72)


## The colour it is drawn in.
func fill_color() -> Color:
	return SILHOUETTE if locked else piece.color


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	var middle: Vector2 = size / 2.0
	for shape: PackedVector2Array in shapes(piece.slot, middle, side):
		FeltDraw.fill(self, shape, fill_color())
		var ring: PackedVector2Array = shape.duplicate()
		ring.append(shape[0])
		draw_polyline(ring, OUTLINE, OUTLINE_WIDTH, true)
	if not locked:
		var seam: PackedVector2Array = seam_line(piece.slot, middle, side)
		draw_polyline(FeltDraw.dashes(seam, 4.0, 3.0), SEAM, 1.5)


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


## A row of stitches across the piece (the sewn look).
static func seam_line(slot: GearDef.Slot, middle: Vector2, side: float) -> PackedVector2Array:
	var u: float = side / 2.0
	var line: PackedVector2Array = []
	match slot:
		GearDef.Slot.HEAD:
			line.append(middle + Vector2(-0.5, 0.0) * u)
			line.append(middle + Vector2(0.5, 0.0) * u)
			return line
		GearDef.Slot.BODY:
			line.append(middle + Vector2(0.0, -0.4) * u)
			line.append(middle + Vector2(0.0, 0.68) * u)
			return line
	var ring: PackedVector2Array = FeltDraw.circle(middle + Vector2(0.0, 0.18) * u, 0.42 * u, 24)
	ring.append(ring[0])
	return ring
