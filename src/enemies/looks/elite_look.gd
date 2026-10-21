class_name EliteLook
extends RefCounted
## The marks of an elite, sewn onto any zombie look: a gold patch on the belly and a crown of
## stitches on the head. Drawn once into the FeltAtlas.

const PATCH: StringName = &"elite/patch"
const CROWN: StringName = &"elite/crown"
const GOLD: Color = Color("#f2c230")
const GOLD_DARK: Color = Color("#9c6b12")
const STITCH_COLOR: Color = Color("#fff3c4")
const OUTLINE: float = 5.0


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	return {PATCH: _patch(), CROWN: _crown()}


## A slightly crooked gold square with a stitched edge, centred on its pivot.
static func _patch() -> FeltPiece:
	var square: PackedVector2Array = FeltShapes.points([-20, -18, 21, -20, 19, 19, -21, 18])
	var patch: FeltPiece = ZombieLook.part(Vector2.ZERO, square, GOLD)
	patch.outline_width = OUTLINE
	patch.outline_color = GOLD_DARK.darkened(0.4)
	var stitch: PackedVector2Array = FeltShapes.points(
		[-15, -13, 16, -15, 14, 14, -16, 13, -15, -13]
	)
	patch.add_line(stitch, STITCH_COLOR, 2.5)
	return patch


## A three-pointed crown; its pivot is the middle of its bottom edge.
static func _crown() -> FeltPiece:
	var outline: PackedVector2Array = FeltShapes.points(
		[-34, 0, -38, -38, -18, -18, 0, -46, 18, -18, 38, -38, 34, 0]
	)
	var crown: FeltPiece = ZombieLook.part(Vector2.ZERO, outline, GOLD)
	crown.outline_width = OUTLINE
	crown.outline_color = GOLD_DARK.darkened(0.4)
	crown.add_line(FeltShapes.points([-32, -8, 32, -8]), GOLD_DARK, 3.0)
	for x: float in [-24.0, -12.0, 0.0, 12.0, 24.0]:
		crown.add_line(FeltShapes.points([x, -12, x, -4]), STITCH_COLOR, 2.0)
	return crown
