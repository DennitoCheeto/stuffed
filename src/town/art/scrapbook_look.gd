class_name ScrapbookLook
extends RefCounted
## The Scrapbook stand in the art kit's style (spec 05 §3.2): a big open book on a wooden stand,
## a photo taped on one page, a sticker on the other and a ribbon bookmark. Built around the
## stand's bottom middle.

const BOARD_HALF: float = 62.0
const BOARD_HEIGHT: float = 44.0


static func build() -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new()
	var palette: WorldPalette = WorldPalette.current()
	LookParts.footprint_shadow(sketch, Rect2(-40.0, -8.0, 80.0, 8.0))
	LookParts.flange(sketch, &"stand", Vector2.ZERO, 34.0, 9.0, palette.wood_top, palette.wood)
	sketch.rod(&"stand", [Vector2(0.0, -8.0), Vector2(0.0, -BOARD_HEIGHT)], palette.wood_side, 9.0)
	var y: float = -BOARD_HEIGHT
	var board: PackedVector2Array = [
		Vector2(-BOARD_HALF, y), Vector2(BOARD_HALF, y), Vector2(BOARD_HALF - 8.0, y - 14.0)
	]
	board.append(Vector2(-BOARD_HALF + 8.0, y - 14.0))
	sketch.piece(&"stand", board, palette.wood_top)
	_book(sketch, palette, y - 4.0)
	var edge: Rect2 = Rect2(-BOARD_HALF - 2.0, y - 2.0, BOARD_HALF * 2.0 + 4.0, 7.0)
	sketch.block(&"stand", edge, palette.wood_side)
	var ribbon: PackedVector2Array = [
		Vector2(10.0, y - 8.0), Vector2(12.0, y + 8.0), Vector2(16.0, y + 20.0)
	]
	sketch.rod(&"bookmark", ribbon, palette.ribbon, 4.0)
	return sketch


## The open book: a lavender cover, two cream pages with a photo, lines and a sticker.
static func _book(sketch: BuildingSketch, palette: WorldPalette, bottom: float) -> void:
	var top: float = bottom - 46.0
	var cover: PackedVector2Array = [
		Vector2(-66.0, bottom), Vector2(66.0, bottom), Vector2(60.0, top), Vector2(-60.0, top)
	]
	sketch.piece(&"book", cover, palette.paint)
	for side: float in [-1.0, 1.0]:
		var page: PackedVector2Array = [
			Vector2(side * 2.0, bottom - 2.0),
			Vector2(side * 60.0, bottom - 5.0),
			Vector2(side * 55.0, top + 2.0),
			Vector2(side * 2.0, top + 5.0),
		]
		sketch.piece(&"book", page, palette.tag)
	sketch.line([Vector2(0.0, bottom - 2.0), Vector2(0.0, top + 5.0)], Color(palette.ink, 0.3), 2.0)
	var photo: Rect2 = Rect2(-46.0, top + 9.0, 28.0, 24.0)
	sketch.shade(BuildingSketch.corners(photo), palette.tissue)
	sketch.shade(BuildingSketch.corners(photo.grow(-3.0)), palette.glass_side)
	sketch.dot(photo.get_center() + Vector2(2.0, 3.0), 5.0, palette.teddy)
	var tape: Rect2 = Rect2(photo.position + Vector2(8.0, -3.0), Vector2(12.0, 6.0))
	sketch.shade(BuildingSketch.corners(tape), Color(palette.gingham_check, 0.8))
	for i: int in 4:
		var line_y: float = top + 12.0 + i * 8.0
		var row: PackedVector2Array = [Vector2(8.0, line_y), Vector2(40.0 - (i % 2) * 8.0, line_y)]
		sketch.line(row, Color(palette.ink, 0.22), 1.5)
	sketch.shade(BuildingSketch.star(Vector2(46.0, top + 14.0), 8.0), palette.sparkle)
