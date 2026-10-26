class_name SnackBarLook
extends RefCounted
## The Snack Bar in the art kit's style (spec 05 §3.2): a blue cookie tin with a striped awning.
## Ruin: the tin is dented and open, its lid lies on the floor, cookie crumbs around it.
## Lv 1: the closed tin with a big cookie on top. Lv 2: a striped awning on poles, a spool stool
## and a button table. Lv 3: a cupcake tower, fairy lights on the awning and two tables.

## Front width, front height and depth of the tin per level (design units).
const FRONT_WIDTHS: Array[float] = [100.0, 106.0, 112.0]
const FRONT_HEIGHTS: Array[float] = [54.0, 60.0, 64.0]
const DEPTH: float = 24.0
## How far the side and top lean up for every unit of depth (3/4 view).
const RISE: float = 0.6
const LID: float = 12.0
## The awning's front edge height above the floor (Lv 2, Lv 3), its back edge sits higher.
const AWNING_HEIGHTS: Array[float] = [128.0, 160.0]
const AWNING_SLOPE: float = 32.0
const AWNING_FRONT: float = 84.0
const AWNING_BACK: float = 68.0
const POLE_X: float = 80.0
## Where the button tables and spool stools stand (x, and y for the ones in front).
const TABLE_X: float = 104.0
const STOOL_X: float = 100.0
const FRONT_STOOL: Vector2 = Vector2(82.0, 10.0)


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var tin: Rect2 = _front(level)
	LookParts.box_shadow(sketch, tin.position.x, tin.size.x, Vector2(DEPTH, -DEPTH * RISE))
	if level >= 2:
		for x: float in [-POLE_X, POLE_X]:
			var pole: PackedVector2Array = [Vector2(x, 0.0), Vector2(x, -_awning_low(level))]
			sketch.rod(&"awning", pole, palette.wood_side, 5.0)
	_lid(sketch, palette, tin)
	_body(sketch, palette, tin)
	var top: Vector2 = _lid_top(tin)
	if level >= 3:
		_cupcake_tower(sketch, palette, top)
	else:
		_cookie(sketch, palette, top + Vector2(0.0, 2.0), 22.0)
	if level == 2:
		_stool(sketch, palette, Vector2(-STOOL_X, 0.0))
		_table(sketch, palette, Vector2(TABLE_X, 0.0), 0, &"button_table")
	elif level >= 3:
		_table(sketch, palette, Vector2(-TABLE_X, 0.0), 1, &"second_table")
		_table(sketch, palette, Vector2(TABLE_X, 0.0), 0, &"button_table")
		_stool(sketch, palette, Vector2(-FRONT_STOOL.x, FRONT_STOOL.y))
		_stool(sketch, palette, FRONT_STOOL)
	if level >= 2:
		_awning(sketch, palette, _awning_low(level))
	if level >= 3:
		var low: float = -_awning_low(level) + 3.0
		var from: Vector2 = Vector2(-AWNING_FRONT + 4.0, low)
		LookParts.fairy_lights(sketch, &"fairy_lights", from, Vector2(-from.x, low), 12.0, 9)


static func _awning_low(level: int) -> float:
	return AWNING_HEIGHTS[clampi(level - 2, 0, 1)]


## The tin's front face (x placed so front + side sit around the middle).
static func _front(level: int) -> Rect2:
	var width: float = FRONT_WIDTHS[level - 1]
	var height: float = FRONT_HEIGHTS[level - 1]
	return Rect2(-(width + DEPTH) / 2.0, -height, width, height)


## The middle of the lid's top face (where things stand on the tin).
static func _lid_top(tin: Rect2) -> Vector2:
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	return Vector2(tin.get_center().x, tin.position.y - LID) + depth / 2.0


## The tin's front with painted dots and a band, and its darker side face.
static func _body(sketch: BuildingSketch, palette: WorldPalette, tin: Rect2) -> void:
	sketch.block(&"tin", tin, palette.tin, true)
	var band: Rect2 = Rect2(tin.position.x, tin.end.y - 12.0, tin.size.x, 7.0)
	sketch.shade(BuildingSketch.corners(band), palette.tin_lid)
	for row: int in 2:
		var y: float = tin.position.y + 12.0 + row * 14.0
		var x: float = tin.position.x + 12.0 + (row % 2) * 10.0
		while x < tin.end.x - 8.0:
			sketch.dot(Vector2(x, y), 3.0, palette.tag)
			x += 20.0
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	var top: Vector2 = Vector2(tin.end.x, tin.position.y)
	var side: PackedVector2Array = [tin.end, tin.end + depth, top + depth, top]
	sketch.piece(&"tin", side, palette.tin_side)
	var side_band: PackedVector2Array = [
		band.end, band.end + depth, Vector2(band.end.x, band.position.y) + depth
	]
	side_band.append(Vector2(band.end.x, band.position.y))
	sketch.shade(side_band, Color(palette.tin_lid, 0.6))


## The closed lid: a slab a little wider than the tin, with its top face and side.
static func _lid(sketch: BuildingSketch, palette: WorldPalette, tin: Rect2) -> void:
	var front: Rect2 = Rect2(tin.position.x - 4.0, tin.position.y - LID, tin.size.x + 8.0, LID)
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	var top_left: Vector2 = front.position
	var top_right: Vector2 = Vector2(front.end.x, front.position.y)
	var top: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(&"tin_lid", top, palette.tin_lid.lightened(0.12))
	sketch.seam([top_left + Vector2(10.0, -4.0), top_right + Vector2(4.0, -4.0)])
	sketch.block(&"tin_lid", front, palette.tin_lid)
	var side: PackedVector2Array = [front.end, front.end + depth, top_right + depth, top_right]
	sketch.piece(&"tin_lid", side, palette.tin)


## A big felt cookie standing on the tin, with chocolate chips.
static func _cookie(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, r: float) -> void:
	var center: Vector2 = foot - Vector2(0.0, r)
	sketch.disc(&"cookie", center, r, palette.cookie)
	sketch.seam(FeltDraw.circle(center, r - 5.0, 16), true)
	var chips: Array[Vector2] = [
		Vector2(-0.45, -0.3), Vector2(0.2, -0.5), Vector2(0.5, 0.1), Vector2(-0.1, 0.15)
	]
	chips.append(Vector2(-0.4, 0.45))
	chips.append(Vector2(0.25, 0.5))
	for chip: Vector2 in chips:
		sketch.dot(center + chip * r, r * 0.11, palette.box_inside)


## A spool stool: a small cotton reel with a button cushion on top.
static func _stool(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2) -> void:
	var thread: Color = WorldPalette.pick(palette.toys, 3)
	var top: float = LookParts.reel(sketch, &"spool_stool", foot, 9.0, 12.0, 5.0, thread)
	var seat: Vector2 = Vector2(foot.x, top + 1.0)
	LookParts.flange(sketch, &"spool_stool", seat, 14.0, 6.0, palette.pincushion, palette.ribbon)


## A table: a big sewing button lying on a spool leg, with its four holes.
static func _table(
	sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, index: int, part: StringName
) -> void:
	var leg: Color = palette.wood_top
	var top: float = LookParts.reel(sketch, part, foot, 5.0, 18.0, 4.0, leg)
	var color: Color = WorldPalette.pick(palette.buttons, index)
	var center: Vector2 = Vector2(foot.x, top - 6.0)
	sketch.piece(part, LookParts.oval(center + Vector2(0.0, 4.0), 26.0, 8.0), color.darkened(0.15))
	sketch.piece(part, LookParts.oval(center, 26.0, 8.0), color)
	for hole: Vector2 in [Vector2(-5, -2), Vector2(5, -2), Vector2(-5, 2), Vector2(5, 2)]:
		sketch.dot(center + hole, 1.8, palette.button_hole)


## The striped awning in front of the tin: a slanted roof with a scalloped front edge.
static func _awning(sketch: BuildingSketch, palette: WorldPalette, low: float) -> void:
	var front: float = -low
	var back: float = front - AWNING_SLOPE
	var shape: PackedVector2Array = [
		Vector2(-AWNING_BACK, back), Vector2(AWNING_BACK, back), Vector2(AWNING_FRONT, front)
	]
	var bumps: int = 8
	var step: float = AWNING_FRONT * 2.0 / bumps
	for i: int in bumps:
		var x: float = AWNING_FRONT - i * step
		shape.append(Vector2(x - step * 0.25, front + 6.0))
		shape.append(Vector2(x - step * 0.5, front + 8.0))
		shape.append(Vector2(x - step * 0.75, front + 6.0))
		shape.append(Vector2(x - step, front))
	sketch.piece(&"awning", shape, palette.tag)
	sketch.stripes(shape, palette.ribbon, step, step / 2.0, true)
	var hem: PackedVector2Array = [
		Vector2(-AWNING_FRONT, front - 6.0), Vector2(AWNING_FRONT, front - 6.0)
	]
	sketch.line(hem, Color(palette.ribbon_dark, 0.6), 2.0)
	sketch.seam([Vector2(-AWNING_BACK + 8.0, back + 5.0), Vector2(AWNING_BACK - 8.0, back + 5.0)])


## Lv 3: a two-tier cake stand with cupcakes on the tin.
static func _cupcake_tower(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2) -> void:
	var stem_top: Vector2 = foot - Vector2(0.0, 32.0)
	sketch.rod(&"cupcake_tower", [foot, stem_top], palette.metal, 4.0)
	var china: Color = palette.tag
	var china_side: Color = palette.tissue_box_side
	LookParts.flange(sketch, &"cupcake_tower", stem_top, 20.0, 5.0, china, china_side)
	_cupcake(sketch, palette, stem_top - Vector2(0.0, 5.0), 1)
	LookParts.flange(sketch, &"cupcake_tower", foot, 36.0, 6.0, china, china_side)
	for i: int in 3:
		var at: Vector2 = foot + Vector2((i - 1) * 22.0, -6.0)
		_cupcake(sketch, palette, at, i + 2)


## One cupcake standing on `foot`: a pleated paper cup, frosting and a berry.
static func _cupcake(
	sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, index: int
) -> void:
	var cup: PackedVector2Array = [
		foot + Vector2(-7.0, 0.0),
		foot + Vector2(7.0, 0.0),
		foot + Vector2(10.0, -10.0),
		foot + Vector2(-10.0, -10.0),
	]
	sketch.piece(&"cupcake_tower", cup, WorldPalette.pick(palette.toys, 2 + index % 2))
	for dx: float in [-4.0, 0.0, 4.0]:
		var pleat: PackedVector2Array = [foot + Vector2(dx, -1.0), foot + Vector2(dx * 1.3, -9.0)]
		sketch.line(pleat, Color(palette.ink, 0.25), 1.2)
	var frosting: PackedVector2Array = [
		foot + Vector2(-11.0, -9.0),
		foot + Vector2(11.0, -9.0),
		foot + Vector2(10.0, -14.0),
		foot + Vector2(5.0, -17.0),
		foot + Vector2(2.0, -21.0),
		foot + Vector2(-2.0, -21.0),
		foot + Vector2(-5.0, -17.0),
		foot + Vector2(-10.0, -14.0),
	]
	var cream: Color = palette.tag if index % 2 == 0 else palette.gingham_check
	sketch.piece(&"cupcake_tower", frosting, cream)
	sketch.dot(foot + Vector2(0.0, -22.0), 3.5, palette.ribbon_dark)


## Ruin: the tin lies dented and open with no lid, the lid lies on the floor, crumbs around.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var tin: Rect2 = _front(1)
	var depth: Vector2 = Vector2(DEPTH, -DEPTH * RISE)
	LookParts.footprint_shadow(sketch, Rect2(tin.position.x, -10.0, tin.size.x + 130.0, 10.0))
	sketch.turn(-0.1, Vector2(tin.position.x, 0.0))
	var top_left: Vector2 = tin.position
	var top_right: Vector2 = Vector2(tin.end.x, tin.position.y)
	var hole: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(&"dented_tin", hole, palette.box_inside)
	sketch.block(&"dented_tin", tin, palette.tin)
	var dent: PackedVector2Array = [
		top_right + Vector2(-34.0, 0.0),
		top_right + Vector2(-8.0, 0.0),
		top_right + Vector2(-14.0, 22.0),
		top_right + Vector2(-30.0, 16.0),
	]
	sketch.shade(dent, palette.tin_side)
	sketch.line([dent[0], dent[3], dent[2]], palette.ink, 1.6)
	var side: PackedVector2Array = [tin.end, tin.end + depth, top_right + depth, top_right]
	sketch.piece(&"dented_tin", side, palette.tin_side)
	sketch.straighten()
	var lid_at: Vector2 = Vector2(tin.end.x + DEPTH + 46.0, 4.0)
	LookParts.flange(sketch, &"fallen_lid", lid_at, 38.0, 9.0, palette.tin_lid, palette.tin)
	var half: PackedVector2Array = [
		Vector2(-6.0, 0.0), Vector2(-14.0, -8.0), Vector2(-16.0, -18.0), Vector2(-6.0, -12.0)
	]
	half.append_array([Vector2(0.0, -18.0), Vector2(4.0, -8.0)])
	var at: Vector2 = Vector2(tin.position.x - 6.0, 2.0)
	var crumb_shape: PackedVector2Array = []
	for point: Vector2 in half:
		crumb_shape.append(at + point * 1.4)
	sketch.piece(&"crumbs", crumb_shape, palette.cookie)
	for i: int in 5:
		var crumb: Vector2 = Vector2(tin.position.x + 20.0 + i * 26.0, 6.0 - (i % 2) * 3.0)
		sketch.dot(crumb, 3.0 - (i % 2), palette.cookie)
