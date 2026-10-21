class_name GiftBoxLook
extends RefCounted
## The felt gift box on the floor (box and lid with a bow), drawn once into the FeltAtlas.
## Shapes are in "atlas units": three times the on-screen size, for a sharp bake. The glow (drawn
## by the GiftBox) is warm and soft, never as loud as enemy bullets (readability, vision §6).

const DRAW_SCALE: float = 1.0 / 3.0
const BOX: StringName = &"gift/box"
const LID: StringName = &"gift/lid"
const BOX_COLOR: Color = Color("#5fa8d3")
const LID_COLOR: Color = Color("#6fb6df")
const RIBBON_COLOR: Color = Color("#f2c230")
const OUTLINE_COLOR: Color = Color("#1d3a52")
const GLOW_COLOR: Color = Color(1.0, 0.85, 0.4)
## Half the box's width on screen, in pixels.
const HALF_WIDTH: float = 15.0


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	return {BOX: _box(), LID: _lid()}


## Box body; its pivot is the middle of its bottom edge.
static func _box() -> FeltPiece:
	var w: float = HALF_WIDTH / DRAW_SCALE
	var h: float = 26.0 / DRAW_SCALE
	var box: FeltPiece = FeltPiece.new()
	box.polygon = FeltShapes.points([-w, -h, w, -h, w, 0, -w, 0])
	box.color = BOX_COLOR
	box.outline_width = 5.0
	box.outline_color = OUTLINE_COLOR
	var band: float = w * 0.18
	box.add_layer(FeltShapes.points([-band, -h, band, -h, band, 0, -band, 0]), RIBBON_COLOR)
	return box


## Lid with a bow; its pivot is the middle of its bottom edge.
static func _lid() -> FeltPiece:
	var w: float = (HALF_WIDTH + 3.0) / DRAW_SCALE
	var h: float = 9.0 / DRAW_SCALE
	var lid: FeltPiece = FeltPiece.new()
	lid.polygon = FeltShapes.points([-w, -h, w, -h, w, 0, -w, 0])
	lid.color = LID_COLOR
	lid.outline_width = 5.0
	lid.outline_color = OUTLINE_COLOR
	var band: float = HALF_WIDTH / DRAW_SCALE * 0.18
	lid.add_layer(FeltShapes.points([-band, -h, band, -h, band, 0, -band, 0]), RIBBON_COLOR)
	var loop: Vector2 = Vector2(10.0, 6.0) / DRAW_SCALE
	for side: float in [-1.0, 1.0]:
		var center: Vector2 = Vector2(side * loop.x, -h - loop.y * 0.8)
		lid.add_layer(FeltShapes.ellipse(center, loop), RIBBON_COLOR)
	return lid
