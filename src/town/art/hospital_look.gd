class_name HospitalLook
extends RefCounted
## The Plush Hospital in the art kit's style (spec 05 §3.2, PO pick H2): a dollhouse hospital
## with a mint roof. Ruin: the walls collapsed to a jagged stump with an empty doorway, the roof
## fallen off onto the floor. Lv 1: a one-storey house with a mint roof, a round attic window, a
## door and a front step. Lv 2: an upstairs ward, plushies asleep in bed seen through its windows.
## Lv 3: windows downstairs, a cross on the roof and flower bushes by the walls.

## The front wall's width, one storey's height and how far the side goes back (3/4 view).
const WALL_WIDTH: float = 176.0
const STOREY: float = 76.0
const DEPTH: Vector2 = Vector2(22.0, -12.0)
## How far the roof reaches past the walls, and how high its gable rises.
const ROOF_OVERHANG: float = 14.0
const ROOF_HEIGHT: float = 74.0
## The door (width, height) and the step it stands on.
const DOOR: Vector2 = Vector2(36.0, 52.0)
const STEP: Vector2 = Vector2(52.0, 6.0)
## Upstairs ward windows and downstairs windows: size, and where they sit (share of the width).
const WARD_WINDOW: Vector2 = Vector2(58.0, 44.0)
const LOW_WINDOW: Vector2 = Vector2(40.0, 34.0)
const WINDOW_SHARES: Array[float] = [0.24, 0.76]
## The flower bushes (Lv 3): one clump of three felt balls each side (offset, radius).
const BUSH_BALLS: Array[Vector3] = [
	Vector3(-12.0, -10.0, 11.0), Vector3(0.0, -16.0, 13.0), Vector3(12.0, -9.0, 11.0)
]


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var storeys: int = 2 if level >= 2 else 1
	var height: float = STOREY * storeys
	var front: Rect2 = Rect2(-(WALL_WIDTH + DEPTH.x) / 2.0, -height, WALL_WIDTH, height)
	LookParts.box_shadow(sketch, front.position.x, front.size.x, DEPTH)
	_walls(sketch, palette, front)
	var gable: Vector2 = _roof(sketch, palette, front)
	_door(sketch, palette, front)
	if level >= 2:
		_upstairs(sketch, palette, front)
	if level >= 3:
		_low_windows(sketch, palette, front)
		_roof_cross(sketch, palette, gable)
		sketch.mark(&"flower_bushes")
		_bush(sketch, palette, Vector2(front.position.x - 4.0, 0.0), 0)
		_bush(sketch, palette, Vector2(front.end.x + 12.0, 0.0), 1)
	else:
		_attic_window(sketch, palette, gable)


## The white walls with their shaded side, stitched along the sides and the top.
static func _walls(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	var top_right: Vector2 = Vector2(front.end.x, front.position.y)
	var side: PackedVector2Array = [front.end, front.end + DEPTH, top_right + DEPTH, top_right]
	sketch.piece(&"house", side, palette.hospital_wall_side)
	sketch.block(&"house", front, palette.hospital_wall)
	var inner: Rect2 = front.grow(-palette.seam_inset)
	var path: PackedVector2Array = [
		Vector2(inner.position.x, front.end.y - palette.seam_inset * 2.0),
		inner.position,
		Vector2(inner.end.x, inner.position.y),
		Vector2(inner.end.x, front.end.y - palette.seam_inset * 2.0),
	]
	sketch.seam(path)


## The mint roof: a sewn gable over the front and its slope going back. Returns the gable's
## middle (for the attic window or the cross).
static func _roof(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> Vector2:
	var base: float = front.position.y + 2.0
	var left: Vector2 = Vector2(front.position.x - ROOF_OVERHANG, base)
	var right: Vector2 = Vector2(front.end.x + ROOF_OVERHANG, base)
	var apex: Vector2 = Vector2(front.get_center().x, base - ROOF_HEIGHT)
	var slope: PackedVector2Array = [right, right + DEPTH, apex + DEPTH, apex]
	sketch.piece(&"roof", slope, palette.hospital_roof_dark)
	sketch.piece(&"roof", [left, right, apex], palette.hospital_roof, true)
	return Vector2(apex.x, base - ROOF_HEIGHT * 0.38)


## Lv 1 and 2: a little round window in the gable.
static func _attic_window(sketch: BuildingSketch, palette: WorldPalette, at: Vector2) -> void:
	sketch.disc(&"attic_window", at, 11.0, palette.hospital_wall)
	sketch.dot(at, 7.0, palette.glass)
	sketch.line([at - Vector2(7.0, 0.0), at + Vector2(7.0, 0.0)], palette.hospital_wall, 2.0)
	sketch.dot(at + Vector2(-3.0, -3.0), 1.8, palette.glass_shine)


## The mint door with a round window and a knob, on a wooden front step.
static func _door(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	var middle: float = front.get_center().x
	var step: Rect2 = Rect2(middle - STEP.x / 2.0, -STEP.y, STEP.x, STEP.y)
	var door: Rect2 = Rect2(middle - DOOR.x / 2.0, -STEP.y - DOOR.y, DOOR.x, DOOR.y)
	sketch.block(&"door", door, palette.hospital_roof, true)
	sketch.dot(door.get_center() + Vector2(0.0, -11.0), 6.5, palette.glass)
	sketch.dot(Vector2(door.end.x - 8.0, door.get_center().y + 6.0), 3.0, palette.brass)
	sketch.block(&"front_step", step, palette.wood_top)


## Lv 2: the upstairs ward: a floor band between the storeys and two windows, each with a
## plushie asleep in bed.
static func _upstairs(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	sketch.mark(&"upstairs")
	var floor_band: Rect2 = Rect2(front.position.x, -STOREY - 4.0, front.size.x, 8.0)
	sketch.shade(BuildingSketch.corners(floor_band), palette.hospital_wall_side)
	var side: Vector2 = Vector2(front.end.x, -STOREY - 4.0)
	var down: Vector2 = Vector2(0.0, 8.0)
	var band: PackedVector2Array = [side, side + DEPTH, side + DEPTH + down, side + down]
	sketch.shade(band, palette.hospital_wall_side.darkened(0.1))
	for i: int in WINDOW_SHARES.size():
		var middle: float = front.position.x + front.size.x * WINDOW_SHARES[i]
		var top_left: Vector2 = Vector2(middle - WARD_WINDOW.x / 2.0, front.position.y + 16.0)
		var pane: Rect2 = Rect2(top_left, WARD_WINDOW)
		sketch.block(&"ward_windows", pane.grow(4.0), palette.hospital_wall_side)
		sketch.shade(BuildingSketch.corners(pane), palette.glass)
		_ward_bed(sketch, palette, pane, i)
		for corner: float in [pane.position.x, pane.end.x]:
			var reach: float = 12.0 if corner == pane.position.x else -12.0
			var curtain: PackedVector2Array = [
				Vector2(corner, pane.position.y),
				Vector2(corner + reach, pane.position.y),
				Vector2(corner, pane.position.y + 20.0),
			]
			sketch.shade(curtain, palette.bed_blanket)


## A bed inside a ward window with a plushie asleep under the blanket (a teddy, then a seal).
static func _ward_bed(
	sketch: BuildingSketch, palette: WorldPalette, pane: Rect2, index: int
) -> void:
	sketch.mark(&"ward_beds")
	var bed: Rect2 = Rect2(pane.position.x + 5.0, pane.end.y - 14.0, pane.size.x - 10.0, 8.0)
	var head: Vector2 = Vector2(bed.position.x + 11.0, bed.position.y - 5.0)
	var pillow: Rect2 = Rect2(bed.position.x + 1.0, bed.position.y - 9.0, 20.0, 9.0)
	LookParts.outlined(sketch, BuildingSketch.corners(pillow), palette.bed_pillow)
	sketch.mark(&"plushies_in_bed")
	sketch.dot(head, 9.5, palette.ink)
	if index % 2 == 0:
		for x: float in [-6.0, 6.0]:
			sketch.dot(head + Vector2(x, -6.5), 4.5, palette.ink)
		LookParts.teddy_head(sketch, &"", head, 8.0, true)
	else:
		sketch.dot(head, 8.0, palette.metal)
		for x: float in [-3.0, 3.0]:
			var eye: Vector2 = head + Vector2(x, -1.0)
			sketch.line([eye - Vector2(1.5, 0.0), eye + Vector2(1.5, 0.0)], palette.ink, 1.2)
		sketch.dot(head + Vector2(0.0, 2.5), 1.4, palette.ink)
	var blanket: Rect2 = Rect2(bed.position + Vector2(16.0, -6.0), Vector2(bed.size.x - 16.0, 8.0))
	var cover: Color = palette.bed_blanket
	if index % 2 == 1:
		cover = WorldPalette.pick(palette.gift_box_tops, 2)
	LookParts.outlined(sketch, BuildingSketch.corners(blanket), cover)
	LookParts.outlined(sketch, BuildingSketch.corners(bed), palette.wood)


## Lv 3: a window each side of the door, with a cross of window bars.
static func _low_windows(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	for share: float in WINDOW_SHARES:
		var middle: Vector2 = Vector2(front.position.x + front.size.x * share, -43.0)
		var pane: Rect2 = Rect2(middle - LOW_WINDOW / 2.0, LOW_WINDOW)
		sketch.block(&"downstairs_windows", pane.grow(4.0), palette.hospital_wall_side)
		sketch.shade(BuildingSketch.corners(pane), palette.glass)
		var bar: Color = palette.hospital_wall_side
		sketch.line([Vector2(middle.x, pane.position.y), Vector2(middle.x, pane.end.y)], bar, 3.0)
		sketch.line([Vector2(pane.position.x, middle.y), Vector2(pane.end.x, middle.y)], bar, 3.0)
		var shine: Rect2 = Rect2(pane.position + Vector2(3.0, 3.0), Vector2(4.0, 10.0))
		sketch.shade(BuildingSketch.corners(shine), palette.glass_shine)


## Lv 3: a white felt disc with a teal cross in the gable.
static func _roof_cross(sketch: BuildingSketch, palette: WorldPalette, at: Vector2) -> void:
	sketch.disc(&"roof_cross", at, 16.0, palette.hospital_wall)
	var teal: Color = WorldPalette.pick(palette.toys, 2)
	sketch.shade(BuildingSketch.corners(Rect2(at.x - 4.5, at.y - 11.0, 9.0, 22.0)), teal)
	sketch.shade(BuildingSketch.corners(Rect2(at.x - 11.0, at.y - 4.5, 22.0, 9.0)), teal)


## Lv 3: a round felt bush with little flowers, standing on `foot`.
static func _bush(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, index: int) -> void:
	for ball: Vector3 in BUSH_BALLS:
		sketch.disc(&"flower_bushes", foot + Vector2(ball.x, ball.y), ball.z, palette.bush)
	for i: int in BUSH_BALLS.size():
		var ball: Vector3 = BUSH_BALLS[i]
		var flower: Vector2 = foot + Vector2(ball.x + 3.0, ball.y - ball.z * 0.4)
		sketch.dot(flower, 3.2, WorldPalette.pick(palette.flower_petals, i + index))
		sketch.dot(flower, 1.3, palette.flower_middle)


## Ruin: the walls collapsed to a jagged stump with an empty doorway and cracks, rubble on the
## floor, and the roof fallen off, lying tipped against the wall.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var left: float = -(WALL_WIDTH + DEPTH.x) / 2.0
	var right: float = left + WALL_WIDTH
	LookParts.box_shadow(sketch, left, WALL_WIDTH, DEPTH)
	var side: PackedVector2Array = [
		Vector2(right, 0.0),
		Vector2(right, 0.0) + DEPTH,
		Vector2(right, -50.0) + DEPTH,
		Vector2(right, -50.0),
	]
	sketch.piece(&"collapsed_walls", side, palette.hospital_wall_side)
	var stump: PackedVector2Array = [
		Vector2(left, 0.0),
		Vector2(right, 0.0),
		Vector2(right, -50.0),
		Vector2(52.0, -60.0),
		Vector2(26.0, -42.0),
		Vector2(-6.0, -64.0),
		Vector2(-44.0, -46.0),
		Vector2(-72.0, -58.0),
		Vector2(left, -50.0),
	]
	sketch.piece(&"collapsed_walls", stump, palette.hospital_wall)
	var middle: float = left + WALL_WIDTH / 2.0
	var doorway: Rect2 = Rect2(middle - DOOR.x / 2.0, -DOOR.y + 6.0, DOOR.x, DOOR.y - 6.0)
	sketch.block(&"door_hole", doorway, palette.box_inside)
	var crack: PackedVector2Array = [
		Vector2(36.0, -40.0), Vector2(44.0, -28.0), Vector2(38.0, -16.0)
	]
	sketch.line(crack, palette.ink, 1.5)
	sketch.line([Vector2(-56.0, -44.0), Vector2(-62.0, -30.0)], palette.ink, 1.5)
	for bit: Rect2 in [Rect2(right + 14.0, -8.0, 14.0, 9.0), Rect2(30.0, -6.0, 12.0, 8.0)]:
		sketch.block(&"rubble", bit, palette.hospital_wall_side)
	sketch.turn(-0.1, Vector2(left - 34.0, 0.0))
	var roof: PackedVector2Array = [
		Vector2(left - 34.0, 0.0), Vector2(left + 74.0, 0.0), Vector2(left + 20.0, -50.0)
	]
	sketch.piece(&"fallen_roof", roof, palette.hospital_roof, true)
	sketch.straighten()
