class_name HospitalLook
extends RefCounted
## The Plush Hospital in the art kit's style (spec 05 §3.2): a tissue box with a plaster cross.
## Ruin: the box is squashed flat with a torn flap, crumpled tissues and a loose plaster around it.
## Lv 1: the box with a plaster cross. Lv 2: windows and a tissue puffing out of the top.
## Lv 3: a bigger box and a little bed outside with a napping plushie.

## Front width, front height and depth of the box per level (design units).
const FRONT_WIDTHS: Array[float] = [104.0, 116.0, 122.0]
const FRONT_HEIGHTS: Array[float] = [62.0, 72.0, 78.0]
const DEPTH: float = 30.0
## How far the side and top lean up for every unit of depth (3/4 view).
const RISE: float = 0.6
## Lv 3 moves the box left to make room for the bed.
const SHIFTS: Array[float] = [0.0, 0.0, -46.0]
const BED_GAP: float = 14.0
const BED_WIDTH: float = 80.0


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var box: Rect2 = _front(level)
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	LookParts.box_shadow(sketch, box.position.x, box.size.x, depth)
	var slot: Vector2 = _top_face(sketch, palette, box, depth)
	if level >= 2:
		_tissue_puff(sketch, palette, slot)
	_front_face(sketch, palette, box, level)
	_side_face(sketch, palette, box, depth)
	if level >= 3:
		_bed(sketch, palette, box.end.x + DEPTH + BED_GAP)


static func _front(level: int) -> Rect2:
	var width: float = FRONT_WIDTHS[level - 1]
	var height: float = FRONT_HEIGHTS[level - 1]
	return Rect2(-(width + DEPTH) / 2.0 + SHIFTS[level - 1], -height, width, height)


## The light top face with the oval tissue slot; returns the slot's middle.
static func _top_face(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, depth: Vector2
) -> Vector2:
	var top_left: Vector2 = box.position
	var top_right: Vector2 = Vector2(box.end.x, box.position.y)
	var top: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(&"box", top, palette.tissue)
	var slot: Vector2 = Vector2(box.get_center().x, box.position.y) + depth / 2.0
	sketch.shade(LookParts.oval(slot, box.size.x * 0.28, 4.0), palette.box_inside)
	return slot


## The front: a teal band, the plaster cross and (Lv 2+) two little windows.
static func _front_face(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, level: int
) -> void:
	sketch.block(&"box", box, palette.tissue_box, true)
	var band: Rect2 = Rect2(box.position.x, box.position.y + 7.0, box.size.x, 7.0)
	sketch.shade(BuildingSketch.corners(band), palette.paint_trim)
	var middle: Vector2 = Vector2(box.get_center().x, box.position.y + box.size.y * 0.58)
	_plaster_cross(sketch, palette, middle)
	if level < 2:
		return
	for share: float in [0.17, 0.83]:
		var at: Vector2 = Vector2(box.position.x + box.size.x * share, middle.y - 2.0)
		var pane: Rect2 = Rect2(at - Vector2(10.0, 10.0), Vector2(20.0, 20.0))
		sketch.block(&"windows", pane.grow(3.0), palette.paint_trim)
		sketch.shade(BuildingSketch.corners(pane), palette.glass)
		sketch.line([at - Vector2(0.0, 10.0), at + Vector2(0.0, 10.0)], palette.paint_trim, 2.0)
		sketch.line([at - Vector2(10.0, 0.0), at + Vector2(10.0, 0.0)], palette.paint_trim, 2.0)
		var shine: Rect2 = Rect2(pane.position + Vector2(3.0, 3.0), Vector2(4.0, 6.0))
		sketch.shade(BuildingSketch.corners(shine), palette.glass_shine)


## Two plasters crossed, each with its soft pad and little holes.
static func _plaster_cross(sketch: BuildingSketch, palette: WorldPalette, at: Vector2) -> void:
	var arm: float = 22.0
	var thick: float = 9.0
	var upright: Rect2 = Rect2(at.x - thick, at.y - arm, thick * 2.0, arm * 2.0)
	sketch.block(&"plaster_cross", upright, palette.plaster)
	var across_bar: Rect2 = Rect2(at.x - arm, at.y - thick, arm * 2.0, thick * 2.0)
	sketch.block(&"plaster_cross", across_bar, palette.plaster)
	var pad: Rect2 = Rect2(at - Vector2(7.0, 7.0), Vector2(14.0, 14.0))
	sketch.shade(BuildingSketch.corners(pad), palette.tissue)
	var hole: Color = palette.plaster.darkened(0.2)
	for end: Vector2 in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		var tip: Vector2 = at + end * (arm - 6.0)
		var across: Vector2 = end.orthogonal() * 3.5
		sketch.dot(tip + across, 1.3, hole)
		sketch.dot(tip - across, 1.3, hole)


static func _side_face(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, depth: Vector2
) -> void:
	var top: Vector2 = Vector2(box.end.x, box.position.y)
	var side: PackedVector2Array = [box.end, box.end + depth, top + depth, top]
	sketch.piece(&"box", side, palette.tissue_box_side)
	var band_top: Vector2 = top + Vector2(0.0, 7.0)
	var down: Vector2 = Vector2(0.0, 7.0)
	var band: PackedVector2Array = [
		band_top, band_top + depth, band_top + depth + down, band_top + down
	]
	sketch.shade(band, Color(palette.paint_trim, 0.7))


## Lv 2+: a soft tissue puffing up out of the slot.
static func _tissue_puff(sketch: BuildingSketch, palette: WorldPalette, slot: Vector2) -> void:
	var puff: PackedVector2Array = [
		slot + Vector2(-14.0, 1.0),
		slot + Vector2(-20.0, -14.0),
		slot + Vector2(-9.0, -30.0),
		slot + Vector2(1.0, -22.0),
		slot + Vector2(10.0, -38.0),
		slot + Vector2(20.0, -18.0),
		slot + Vector2(14.0, 1.0),
	]
	sketch.piece(&"tissue_puff", puff, palette.tissue)
	var fold: PackedVector2Array = [slot + Vector2(-2.0, -2.0), slot + Vector2(6.0, -26.0)]
	sketch.line(fold, palette.tissue_box_side, 1.5)


## Lv 3: a little bed outside with a teddy napping under a striped blanket.
static func _bed(sketch: BuildingSketch, palette: WorldPalette, left: float) -> void:
	LookParts.footprint_shadow(sketch, Rect2(left, -8.0, BED_WIDTH, 8.0))
	for x: float in [left + 5.0, left + BED_WIDTH - 5.0]:
		sketch.rod(&"bed", [Vector2(x, 0.0), Vector2(x, -12.0)], palette.wood_side, 4.0)
	sketch.block(&"bed", Rect2(left, -42.0, 10.0, 42.0), palette.wood_top)
	sketch.block(&"bed", Rect2(left + BED_WIDTH - 9.0, -28.0, 9.0, 28.0), palette.wood_top)
	sketch.block(&"bed", Rect2(left, -16.0, BED_WIDTH, 8.0), palette.wood)
	sketch.block(&"bed", Rect2(left + 6.0, -25.0, BED_WIDTH - 12.0, 10.0), palette.tissue)
	sketch.block(&"bed", Rect2(left + 10.0, -36.0, 22.0, 12.0), palette.bed_pillow)
	var head: Vector2 = Vector2(left + 22.0, -38.0)
	LookParts.teddy_head(sketch, &"napping_plushie", head, 10.0, true)
	var blanket: PackedVector2Array = [
		Vector2(left + 28.0, -14.0),
		Vector2(left + BED_WIDTH - 6.0, -14.0),
		Vector2(left + BED_WIDTH - 6.0, -28.0),
		Vector2(left + 56.0, -33.0),
		Vector2(left + 34.0, -31.0),
		Vector2(left + 28.0, -26.0),
	]
	sketch.piece(&"blanket", blanket, palette.bed_blanket, true)
	sketch.stripes(blanket, Color(palette.bed_fold, 0.8), 12.0, 5.0, true)
	sketch.parts.append(&"zzz")
	for i: int in 3:
		var at: Vector2 = head + Vector2(12.0 + i * 10.0, -18.0 - i * 13.0)
		var size: float = 5.0 + i * 1.5
		var z: PackedVector2Array = [
			at + Vector2(-size, -size), at + Vector2(size, -size), at + Vector2(-size, size)
		]
		z.append(at + Vector2(size, size))
		sketch.line(z, palette.sign_effect, 1.8)


## Ruin: the box is squashed flat and tilted with a torn flap, crumpled tissues and a loose
## plaster lie on the floor.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var box: Rect2 = Rect2(-70.0, -36.0, 114.0, 36.0)
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE * 0.6)
	LookParts.box_shadow(sketch, box.position.x, box.size.x, depth)
	sketch.turn(0.06, Vector2(box.end.x, 0.0))
	var top_left: Vector2 = box.position
	var top_right: Vector2 = Vector2(box.end.x, box.position.y)
	var flap: PackedVector2Array = [
		top_left + Vector2(8.0, 0.0), top_left + Vector2(40.0, 0.0), top_left + Vector2(14.0, -26.0)
	]
	sketch.piece(&"squashed_box", flap, palette.tissue_box)
	var top: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(&"squashed_box", top, palette.tissue_box_side)
	var fold: PackedVector2Array = [
		top_left + Vector2(30.0, -4.0), top_right + Vector2(-20.0, -6.0)
	]
	sketch.line(fold, palette.ink, 1.6)
	sketch.block(&"squashed_box", box, palette.tissue_box)
	var corner: Vector2 = box.position
	var crease: PackedVector2Array = [
		corner + Vector2(20.0, 8.0), corner + Vector2(52.0, 20.0), corner + Vector2(90.0, 10.0)
	]
	sketch.line(crease, Color(palette.ink, 0.6), 1.6)
	var band: Rect2 = Rect2(box.position.x, box.position.y + 6.0, box.size.x, 6.0)
	sketch.shade(BuildingSketch.corners(band), palette.paint_trim)
	var side: PackedVector2Array = [box.end, box.end + depth, top_right + depth, top_right]
	sketch.piece(&"squashed_box", side, palette.tissue_box_side)
	sketch.straighten()
	for at: Vector2 in [Vector2(-96.0, 2.0), Vector2(box.end.x + DEPTH + 26.0, 4.0)]:
		var lump: PackedVector2Array = [
			at + Vector2(-14.0, 0.0),
			at + Vector2(-16.0, -10.0),
			at + Vector2(-6.0, -18.0),
			at + Vector2(4.0, -12.0),
			at + Vector2(14.0, -16.0),
			at + Vector2(16.0, -2.0),
		]
		sketch.piece(&"crumpled_tissues", lump, palette.tissue)
		var wrinkle: PackedVector2Array = [at + Vector2(-8.0, -6.0), at + Vector2(6.0, -10.0)]
		sketch.line(wrinkle, palette.tissue_box_side, 1.4)
	sketch.turn(-0.3, Vector2.ZERO, Vector2(-36.0, 2.0))
	sketch.block(&"loose_plaster", Rect2(-20.0, -6.0, 40.0, 12.0), palette.plaster)
	sketch.shade(BuildingSketch.corners(Rect2(-6.0, -4.0, 12.0, 8.0)), palette.tissue)
	sketch.straighten()
