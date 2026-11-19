class_name WorkshopLook
extends RefCounted
## The Sewing Workshop in the art kit's style (spec 09 §5): a wooden sewing table with a giant
## spool on it. Ruin: the table lies tipped over, the spool rolled off, thread unwound across the
## floor and the pincushion squashed flat. Lv 1: the table, the giant spool and a pincushion.
## Lv 2: two big sewing pins hold up a pin cushion roof with thread bunting under it.
## Lv 3: a sewing machine on the table stitching a fluttering cloth, scissors leaning on a leg
## and a pin flag on the roof.

## The table: front edge of the top (x from, x to), its height and thickness, and how far its
## top goes back (3/4 view: up and right by `RISE` per unit of depth).
const TABLE_LEFT: float = -88.0
const TABLE_RIGHT: float = 64.0
const TABLE_HEIGHT: float = 52.0
const TABLE_THICK: float = 9.0
const DEPTH: float = 22.0
const RISE: float = 0.6
const LEG_INSET: float = 8.0
const LEG_WIDTH: float = 7.0
## The giant spool on the table: its thread half width and height, the flange thickness.
const SPOOL_X: float = 32.0
const SPOOL_HALF_WIDTH: float = 17.0
const SPOOL_HEIGHT: float = 38.0
const SPOOL_FLANGE: float = 7.0
## The thread colour of the giant spool and the cloth (index into the palette's toy colours).
const SPOOL_THREAD: int = 2
const CLOTH_COLOR: int = 3
## The two big pins holding the roof (x), how high their heads sit, the roof's half width,
## how high it bulges and how many pins stick out of it.
const POLE_X: Array[float] = [-100.0, 80.0]
const POLE_HEIGHT: float = 166.0
const ROOF_HALF_WIDTH: float = 104.0
const ROOF_BULGE: float = 40.0
const ROOF_PINS: int = 5
## Lv 3: the pin flag on top of the roof.
const FLAG_HEIGHT: float = 34.0


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	var width: float = TABLE_RIGHT - TABLE_LEFT
	LookParts.box_shadow(sketch, TABLE_LEFT, width, depth)
	if level >= 2:
		_pole(sketch, palette, POLE_X[0])
		_pole(sketch, palette, POLE_X[1])
	_table(sketch, palette, Vector2.ZERO)
	var top: float = -TABLE_HEIGHT - TABLE_THICK
	var on_table: float = top + depth.y / 2.0
	var spool_foot: Vector2 = Vector2(SPOOL_X + depth.x / 2.0, on_table)
	_spool(sketch, palette, spool_foot)
	if level >= 3:
		_sewing_machine(sketch, palette, Vector2(TABLE_LEFT + 38.0 + depth.x / 2.0, on_table))
		_scissors(sketch, palette, Vector2(TABLE_RIGHT + 18.0, 0.0))
	else:
		_pincushion(sketch, palette, Vector2(TABLE_LEFT + 34.0 + depth.x / 2.0, on_table), 14.0)
	if level >= 2:
		_roof(sketch, palette)
		var low: float = -POLE_HEIGHT + 12.0
		var from: Vector2 = Vector2(POLE_X[0] + 4.0, low)
		LookParts.bunting(sketch, &"bunting", from, Vector2(POLE_X[1] - 4.0, low), 10.0, 8)
	if level >= 3:
		var peak: Vector2 = Vector2(_roof_middle(), -POLE_HEIGHT - ROOF_BULGE + 6.0)
		LookParts.pin_flag(sketch, &"pin_flag", peak, FLAG_HEIGHT, palette.ribbon)


## The middle of the roof (between the two pins).
static func _roof_middle() -> float:
	return (POLE_X[0] + POLE_X[1]) / 2.0


## The wooden sewing table standing on `at` (front left leg ... front right leg), with a drawer.
static func _table(sketch: BuildingSketch, palette: WorldPalette, at: Vector2) -> void:
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	var top_y: float = at.y - TABLE_HEIGHT
	for x: float in [TABLE_LEFT + LEG_INSET, TABLE_RIGHT - LEG_INSET]:
		var back: PackedVector2Array = [Vector2(at.x + x, at.y) + depth, Vector2(at.x + x, top_y)]
		back[1] += depth
		sketch.rod(&"sewing_table", back, palette.wood_side, LEG_WIDTH)
	for x: float in [TABLE_LEFT + LEG_INSET, TABLE_RIGHT - LEG_INSET]:
		var leg: PackedVector2Array = [Vector2(at.x + x, at.y), Vector2(at.x + x, top_y)]
		sketch.rod(&"sewing_table", leg, palette.wood, LEG_WIDTH)
	var width: float = TABLE_RIGHT - TABLE_LEFT
	var front: Rect2 = Rect2(at.x + TABLE_LEFT, top_y - TABLE_THICK, width, TABLE_THICK)
	var top_left: Vector2 = front.position
	var top_right: Vector2 = Vector2(front.end.x, front.position.y)
	var top: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(&"sewing_table", top, palette.wood_top, true)
	sketch.block(&"sewing_table", front, palette.wood)
	var side: PackedVector2Array = [front.end, front.end + depth, top_right + depth, top_right]
	sketch.piece(&"sewing_table", side, palette.wood_side)
	var drawer: Rect2 = Rect2(front.position.x + 26.0, front.end.y, 64.0, 12.0)
	sketch.block(&"sewing_table", drawer, palette.wood, true)
	sketch.dot(drawer.get_center(), 2.6, palette.brass)
	var grain: PackedVector2Array = [
		top_left + Vector2(14.0, -5.0), top_right + Vector2(-20.0, -6.0) + depth * 0.4
	]
	sketch.line(grain, palette.wood_grain, 1.2)


## The giant spool standing on the table, its thread end hanging over the table's front.
static func _spool(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2) -> void:
	var thread: Color = WorldPalette.pick(palette.toys, SPOOL_THREAD)
	LookParts.reel(
		sketch, &"giant_spool", foot, SPOOL_HALF_WIDTH, SPOOL_HEIGHT, SPOOL_FLANGE, thread
	)
	var start: Vector2 = foot + Vector2(SPOOL_HALF_WIDTH, -SPOOL_FLANGE - SPOOL_HEIGHT * 0.4)
	var hanging: PackedVector2Array = [
		start, start + Vector2(10.0, 8.0), Vector2(TABLE_RIGHT + 4.0, -TABLE_HEIGHT - 4.0)
	]
	hanging.append(Vector2(TABLE_RIGHT + 10.0, -TABLE_HEIGHT + 16.0))
	sketch.line(hanging, thread, 2.2)


## A round felt pincushion with a few pins in it.
static func _pincushion(
	sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, r: float
) -> void:
	var center: Vector2 = foot - Vector2(0.0, r * 0.7)
	sketch.piece(&"pincushion", LookParts.oval(center, r, r * 0.75), palette.pincushion)
	var seam: PackedVector2Array = [center + Vector2(0.0, -r * 0.7), center + Vector2(0.0, r * 0.7)]
	sketch.line(seam, palette.pincushion_dark, 1.4)
	for i: int in 3:
		var base: Vector2 = center + Vector2((i - 1) * r * 0.5, -r * 0.45)
		var head: Vector2 = base + Vector2((i - 1) * 3.0, -9.0)
		sketch.line([base, head], palette.metal_dark, 1.4)
		sketch.dot(head, 2.6, WorldPalette.pick(palette.buttons, i))


## One big sewing pin standing on the floor as a roof pole, its round head under the roof.
static func _pole(sketch: BuildingSketch, palette: WorldPalette, x: float) -> void:
	var pin: PackedVector2Array = [Vector2(x, 0.0), Vector2(x, -POLE_HEIGHT)]
	sketch.rod(&"pin_poles", pin, palette.metal, 5.0)
	var shine: Rect2 = Rect2(x + 0.5, -POLE_HEIGHT, 1.5, POLE_HEIGHT - 6.0)
	sketch.shade(BuildingSketch.corners(shine), palette.metal_dark)


## The pin cushion roof: a plump pink cushion lying on the two pins, tied into segments, with
## pins sticking out of its top.
static func _roof(sketch: BuildingSketch, palette: WorldPalette) -> void:
	var middle: float = _roof_middle()
	var base: float = -POLE_HEIGHT + 4.0
	var shape: PackedVector2Array = []
	var steps: int = 16
	for i: int in steps + 1:
		var t: float = float(i) / steps
		var x: float = middle - ROOF_HALF_WIDTH + t * ROOF_HALF_WIDTH * 2.0
		shape.append(Vector2(x, base - sin(t * PI) * ROOF_BULGE))
	for i: int in range(steps - 1, 0, -1):
		var t: float = float(i) / steps
		var x: float = middle - ROOF_HALF_WIDTH + t * ROOF_HALF_WIDTH * 2.0
		shape.append(Vector2(x, base + 8.0 + sin(t * PI) * 4.0))
	sketch.piece(&"pincushion_roof", shape, palette.pincushion, true)
	var belly: PackedVector2Array = []
	for i: int in range(steps - 1, 0, -1):
		belly.append(shape[steps + (steps - i)])
	for i: int in range(1, steps):
		var t: float = float(i) / steps
		var x: float = middle - ROOF_HALF_WIDTH + t * ROOF_HALF_WIDTH * 2.0
		belly.append(Vector2(x, base - sin(t * PI) * ROOF_BULGE * 0.25))
	sketch.shade(belly, Color(palette.pincushion_dark, 0.55))
	for i: int in [-2, -1, 1, 2]:
		var x: float = middle + i * ROOF_HALF_WIDTH * 0.38
		var t: float = (x - middle + ROOF_HALF_WIDTH) / (ROOF_HALF_WIDTH * 2.0)
		var tie: PackedVector2Array = [
			Vector2(x, base - sin(t * PI) * ROOF_BULGE + 2.0), Vector2(x * 1.02, base + 6.0)
		]
		sketch.line(tie, palette.pincushion_dark, 1.6)
	sketch.dot(Vector2(middle, base - ROOF_BULGE * 0.45), 5.0, palette.brass)
	sketch.parts.append(&"roof_pins")
	for i: int in ROOF_PINS:
		var t: float = 0.18 + 0.64 * i / maxf(ROOF_PINS - 1, 1)
		if absf(t - 0.5) < 0.05:
			continue
		var x: float = middle - ROOF_HALF_WIDTH + t * ROOF_HALF_WIDTH * 2.0
		var root: Vector2 = Vector2(x, base - sin(t * PI) * ROOF_BULGE + 3.0)
		var head: Vector2 = root + Vector2((t - 0.5) * 22.0, -14.0)
		sketch.line([root, head], palette.metal_dark, 1.6)
		sketch.dot(head, 3.4, WorldPalette.pick(palette.buttons, i))


## Lv 3: a little felt sewing machine on the table, stitching a fluttering cloth.
static func _sewing_machine(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2) -> void:
	var body: Color = palette.tag
	var cloth: PackedVector2Array = [
		foot + Vector2(-34.0, 1.0),
		foot + Vector2(-12.0, -3.0),
		foot + Vector2(-16.0, 14.0),
		foot + Vector2(-38.0, 20.0),
	]
	sketch.sway(foot + Vector2(-12.0, 0.0), Vector2(-26.0, 20.0))
	sketch.piece(&"fabric", cloth, WorldPalette.pick(palette.toys, CLOTH_COLOR))
	sketch.still()
	var base: Rect2 = Rect2(foot.x - 30.0, foot.y - 8.0, 56.0, 8.0)
	sketch.block(&"sewing_machine", base, palette.wood_side)
	var arm: PackedVector2Array = [
		foot + Vector2(10.0, -8.0),
		foot + Vector2(24.0, -8.0),
		foot + Vector2(24.0, -40.0),
		foot + Vector2(-24.0, -40.0),
		foot + Vector2(-24.0, -24.0),
		foot + Vector2(-14.0, -24.0),
		foot + Vector2(-14.0, -30.0),
		foot + Vector2(10.0, -30.0),
	]
	sketch.piece(&"sewing_machine", arm, body, true)
	sketch.dot(foot + Vector2(0.0, -35.0), 2.0, palette.brass)
	var needle: PackedVector2Array = [foot + Vector2(-20.0, -24.0), foot + Vector2(-20.0, -11.0)]
	sketch.rod(&"sewing_machine", needle, palette.metal, 2.0)
	var wheel: Vector2 = foot + Vector2(28.0, -30.0)
	sketch.disc(&"sewing_machine", wheel, 8.0, palette.metal)
	sketch.dot(wheel, 3.0, palette.metal_dark)
	var stitch: PackedVector2Array = [foot + Vector2(-20.0, -10.0), foot + Vector2(-30.0, -2.0)]
	sketch.line(stitch, WorldPalette.pick(palette.toys, SPOOL_THREAD), 1.4)


## Lv 3: a pair of felt scissors leaning against the table's front right leg.
static func _scissors(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2) -> void:
	var pivot: Vector2 = foot + Vector2(-6.0, -30.0)
	for side: float in [-1.0, 1.0]:
		var blade: PackedVector2Array = [
			pivot + Vector2(side * 2.0, 0.0), pivot + Vector2(-8.0 + side * 3.0, -26.0)
		]
		sketch.rod(&"scissors", blade, palette.metal, 4.0)
		var ring: Vector2 = pivot + Vector2(side * 7.0, 14.0)
		sketch.rod(&"scissors", [pivot, ring], WorldPalette.pick(palette.toys, 1), 4.0)
		sketch.disc(&"scissors", ring + Vector2(0.0, 6.0), 6.0, WorldPalette.pick(palette.toys, 1))
		sketch.dot(ring + Vector2(0.0, 6.0), 3.0, palette.box_inside)
	sketch.dot(pivot, 2.4, palette.brass)


## Ruin: the table tipped over with a broken leg, leaning on the giant spool that rolled off,
## its thread unwound across the floor, the pincushion squashed flat with pins scattered around.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	LookParts.footprint_shadow(sketch, Rect2(-100.0, -14.0, 200.0, 14.0))
	sketch.parts.append(&"tipped_table")
	sketch.turn(-0.3, Vector2(TABLE_LEFT + LEG_INSET, 0.0), Vector2(-12.0, 0.0))
	_table(sketch, palette, Vector2.ZERO)
	sketch.straighten()
	var thread: Color = WorldPalette.pick(palette.toys, SPOOL_THREAD)
	sketch.parts.append(&"fallen_spool")
	var long: float = SPOOL_HEIGHT + SPOOL_FLANGE * 2.0
	sketch.turn(PI / 2.0, Vector2.ZERO, Vector2(80.0 - long, -SPOOL_HALF_WIDTH * 1.3))
	LookParts.reel(
		sketch, &"fallen_spool", Vector2.ZERO, SPOOL_HALF_WIDTH, SPOOL_HEIGHT, SPOOL_FLANGE, thread
	)
	sketch.straighten()
	var loose: PackedVector2Array = [
		Vector2(56.0, -6.0), Vector2(30.0, 4.0), Vector2(6.0, -2.0), Vector2(-26.0, 6.0)
	]
	sketch.line(loose, thread, 2.4)
	sketch.parts.append(&"loose_thread")
	var cushion: Vector2 = Vector2(-74.0, -4.0)
	sketch.piece(&"squashed_cushion", LookParts.oval(cushion, 16.0, 6.0), palette.pincushion)
	for i: int in 3:
		var at: Vector2 = Vector2(-52.0 + i * 16.0, 4.0 - (i % 2) * 4.0)
		var head: Vector2 = at + Vector2(9.0, -3.0 + i)
		sketch.line([at, head], palette.metal_dark, 1.4)
		sketch.dot(head, 2.6, WorldPalette.pick(palette.buttons, i))
