class_name LoadoutBoardLook
extends RefCounted
## The "My loadout" corkboard by the door (spec 04b §3) in the art kit's style: a cork board in a
## wooden frame on two short legs, with three paper notes pinned on by sewing buttons (one for the
## hero, one for the weapon, one for the gear). Built around its bottom middle (y up is negative).

const HALF: float = 40.0
const BOARD_HEIGHT: float = 50.0
const LEG_HEIGHT: float = 30.0
## The notes on the board: rect relative to the board's top-left corner, tilt as a skew.
const NOTES: Array[Rect2] = [Rect2(8, 9, 20, 24), Rect2(31, 6, 19, 22), Rect2(53, 12, 20, 26)]
const NOTE_TILTS: PackedFloat32Array = [-2.0, 1.5, -1.0]
const SPECKLES: PackedVector2Array = [
	Vector2(6, 40), Vector2(40, 38), Vector2(70, 6), Vector2(27, 44)
]


static func build() -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new()
	var palette: WorldPalette = WorldPalette.current()
	LookParts.footprint_shadow(sketch, Rect2(-HALF - 2.0, -6.0, HALF * 2.0 + 4.0, 6.0))
	for side: float in [-1.0, 1.0]:
		var x: float = side * (HALF - 10.0)
		sketch.rod(
			&"legs", [Vector2(x, 0.0), Vector2(x, -LEG_HEIGHT - 4.0)], palette.wood_side, 7.0
		)
	var top: float = -LEG_HEIGHT - BOARD_HEIGHT
	var board: Rect2 = Rect2(-HALF, top, HALF * 2.0, BOARD_HEIGHT)
	sketch.block(&"frame", board.grow(5.0), palette.wood)
	sketch.block(&"cork", board, palette.cork, true)
	for speckle: Vector2 in SPECKLES:
		sketch.dot(board.position + speckle, 1.6, palette.cork_dark)
	for index: int in NOTES.size():
		var note: Rect2 = NOTES[index]
		note.position += board.position
		var lean: float = NOTE_TILTS[index]
		var paper: PackedVector2Array = [
			note.position + Vector2(lean, 0.0),
			Vector2(note.end.x + lean, note.position.y),
			note.end,
			Vector2(note.position.x, note.end.y),
		]
		sketch.piece(&"notes", paper, palette.tag)
		for row: int in 3:
			var y: float = note.position.y + 10.0 + row * 5.0
			var ruled: PackedVector2Array = [
				Vector2(note.position.x + 4.0, y), Vector2(note.end.x - 4.0, y)
			]
			sketch.line(ruled, Color(palette.ink, 0.25), 1.2)
		var pin: Vector2 = Vector2(note.get_center().x + lean / 2.0, note.position.y + 3.0)
		sketch.dot(pin, 3.2, palette.pick(palette.buttons, index))
	return sketch
