class_name WardrobeLook
extends RefCounted
## The Wardrobe in the art kit's style (spec 08 §5): a little painted toy wardrobe with a curved
## top, two sewn doors with brass knobs, one door a crack open with a scarf peeking out, a heart
## cut into the top and two stubby feet. Built around its bottom middle (y up is negative).

const HALF: float = 34.0
const HEIGHT: float = 84.0


static func build(unit: float = 1.0) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit)
	var palette: WorldPalette = WorldPalette.current()
	LookParts.footprint_shadow(sketch, Rect2(-HALF - 4.0, -8.0, HALF * 2.0 + 8.0, 8.0))
	for side: float in [-1.0, 1.0]:
		var foot: Rect2 = Rect2(side * (HALF - 9.0) - 5.0, -7.0, 10.0, 7.0)
		sketch.block(&"feet", foot, palette.wood_side)
	var body: PackedVector2Array = [
		Vector2(-HALF, -6.0),
		Vector2(HALF, -6.0),
		Vector2(HALF, -HEIGHT + 16.0),
		Vector2(HALF * 0.6, -HEIGHT + 4.0),
		Vector2(0.0, -HEIGHT),
		Vector2(-HALF * 0.6, -HEIGHT + 4.0),
		Vector2(-HALF, -HEIGHT + 16.0),
	]
	sketch.piece(&"body", body, palette.paint, true)
	var side_shade: PackedVector2Array = [
		Vector2(HALF - 6.0, -6.0),
		Vector2(HALF, -6.0),
		Vector2(HALF, -HEIGHT + 16.0),
		Vector2(HALF - 6.0, -HEIGHT + 13.0),
	]
	sketch.shade(side_shade, Color(palette.ink, 0.12))
	_doors(sketch, palette)
	var heart: Vector2 = Vector2(0.0, -HEIGHT + 14.0)
	sketch.dot(heart + Vector2(-3.0, -1.0), 3.6, palette.paint_trim)
	sketch.dot(heart + Vector2(3.0, -1.0), 3.6, palette.paint_trim)
	var tip: PackedVector2Array = [
		heart + Vector2(-6.4, 0.0), heart + Vector2(6.4, 0.0), heart + Vector2(0.0, 7.0)
	]
	sketch.shade(tip, palette.paint_trim)
	return sketch


## Two doors with seams and brass knobs; the right one stands a crack open and a striped scarf
## hangs out of it.
static func _doors(sketch: BuildingSketch, palette: WorldPalette) -> void:
	var top: float = -HEIGHT + 22.0
	var bottom: float = -10.0
	var left: Rect2 = Rect2(-HALF + 5.0, top, HALF - 6.0, bottom - top)
	sketch.block(&"doors", left, palette.paint_trim, true)
	var right: PackedVector2Array = [
		Vector2(3.0, top + 1.0),
		Vector2(HALF - 2.0, top - 2.0),
		Vector2(HALF - 2.0, bottom + 2.0),
		Vector2(3.0, bottom),
	]
	var gap: Rect2 = Rect2(1.0, top, 3.0, bottom - top)
	sketch.shade(BuildingSketch.corners(gap), palette.box_inside)
	var scarf: PackedVector2Array = [
		Vector2(2.0, top + 14.0), Vector2(-2.0, top + 30.0), Vector2(0.0, top + 44.0)
	]
	sketch.rod(&"scarf", scarf, palette.ribbon, 6.0)
	sketch.piece(&"doors", right, palette.paint_trim, true)
	sketch.dot(Vector2(-4.0, (top + bottom) / 2.0), 2.6, palette.brass)
	sketch.dot(Vector2(8.0, (top + bottom) / 2.0), 2.6, palette.brass)
