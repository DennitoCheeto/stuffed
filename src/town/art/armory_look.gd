class_name ArmoryLook
extends RefCounted
## The Toy Box Armory in the art kit's style (spec 05 §3.2): an open wooden sewing box with the
## weapons inside. Ruin: the box is knocked over with a broken plank, its lid lies on the floor.
## Lv 1: the box with a pencil and a ball. Lv 2: a sewing tray with spools, scissors, a needle and
## a clasp. Lv 3: painted with stars, brass corners and a weapon rack beside it.

## Front width, front height and depth of the box per level (design units).
const FRONT_WIDTHS: Array[float] = [128.0, 142.0, 150.0]
const FRONT_HEIGHTS: Array[float] = [74.0, 84.0, 90.0]
const DEPTHS: Array[float] = [30.0, 32.0, 34.0]
## How far the side and top lean up for every unit of depth (3/4 view).
const RISE: float = 0.6
## How far the floor shadow sits right and down of the box's footprint.
const SHADOW_NUDGE: Vector2 = Vector2(9.0, 5.0)


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
	var depth: Vector2 = _depth(level)
	sketch.shadow(_floor_shadow(box, depth))
	if level >= 3:
		_weapon_rack(sketch, palette, box)
	_lid(sketch, palette, box, depth, level)
	if level >= 2:
		_tray(sketch, palette, box, depth)
	_opening(sketch, palette, box, depth)
	_toys(sketch, palette, box, level)
	_front_face(sketch, palette, box, level)
	_side_face(sketch, palette, box, depth, level)


## The box's front face (x placed so front + side sit around the middle).
static func _front(level: int) -> Rect2:
	var width: float = FRONT_WIDTHS[level - 1]
	var height: float = FRONT_HEIGHTS[level - 1]
	var left: float = -(width + DEPTHS[level - 1]) / 2.0
	return Rect2(left, -height, width, height)


## Where the back edge sits from the front edge.
static func _depth(level: int) -> Vector2:
	var depth: float = DEPTHS[level - 1]
	return Vector2(depth, -depth * RISE)


## The box's footprint on the floor (front and side bottom edges), nudged right and down: the
## light comes from the top-left, so a thin shadow shows below the front and along the side.
static func _floor_shadow(box: Rect2, depth: Vector2) -> PackedVector2Array:
	return [
		Vector2(box.position.x, 0.0) + SHADOW_NUDGE,
		Vector2(box.end.x, 0.0) + SHADOW_NUDGE,
		Vector2(box.end.x, 0.0) + depth + SHADOW_NUDGE,
		Vector2(box.position.x, 0.0) + depth + SHADOW_NUDGE,
	]


## The open lid leaning back from the box's back edge: we see its inside.
static func _lid(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, depth: Vector2, level: int
) -> void:
	var hinge_left: Vector2 = box.position + depth
	var hinge_right: Vector2 = Vector2(box.end.x, box.position.y) + depth
	var lean: Vector2 = Vector2(12.0, -box.size.y * 0.85)
	var lid: PackedVector2Array = [hinge_left, hinge_right, hinge_right + lean, hinge_left + lean]
	sketch.piece(&"lid", lid, palette.wood_top)
	var inner: PackedVector2Array = [
		hinge_left + Vector2(10.0, -8.0),
		hinge_right + Vector2(-10.0, -8.0),
		hinge_right + lean + Vector2(-8.0, 10.0),
		hinge_left + lean + Vector2(12.0, 10.0),
	]
	sketch.shade(inner, palette.wood)
	sketch.seam(inner, true)
	var lip: Vector2 = Vector2(4.0, -6.0)
	var edge: PackedVector2Array = [
		hinge_left + lean, hinge_right + lean, hinge_right + lean + lip, hinge_left + lean + lip
	]
	sketch.shade(edge, palette.wood_side)
	if level < 2:
		return
	var needle_top: Vector2 = hinge_left + lean * 0.8 + Vector2(box.size.x * 0.25, 0.0)
	var needle: PackedVector2Array = [needle_top, needle_top + Vector2(18.0, 46.0)]
	sketch.rod(&"needle", needle, palette.metal, 3.0)
	var eye: Vector2 = needle_top + Vector2(1.5, 4.0)
	sketch.dot(eye, 1.4, palette.metal_dark)
	var thread: PackedVector2Array = [eye, needle_top + Vector2(-14.0, 22.0)]
	sketch.line(thread, WorldPalette.pick(palette.toys, 2), 1.5)


## Lv 2+: a lifted sewing tray at the back with spools of thread on it.
static func _tray(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, depth: Vector2
) -> void:
	var corner: Vector2 = box.position + Vector2(depth.x * 0.5 + 8.0, depth.y - 22.0)
	var front: Rect2 = Rect2(corner, Vector2(box.size.x * 0.5, 22.0))
	for i: int in 3:
		var spool: Vector2 = Vector2(front.position.x + 16.0 + i * 22.0, front.position.y - 8.0)
		var thread: Rect2 = Rect2(spool + Vector2(-7.0, -14.0), Vector2(14.0, 16.0))
		sketch.block(&"spools", thread, WorldPalette.pick(palette.toys, i + 1))
		var cap: Rect2 = Rect2(spool + Vector2(-9.0, -18.0), Vector2(18.0, 5.0))
		sketch.shade(BuildingSketch.corners(cap), palette.wood_top)
	sketch.block(&"tray", front, palette.wood_top, true)


## The dark inside of the open box.
static func _opening(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, depth: Vector2
) -> void:
	var top_left: Vector2 = box.position
	var top_right: Vector2 = Vector2(box.end.x, box.position.y)
	var hole: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(&"box", hole, palette.box_inside)


## Weapons and toys sticking up out of the box.
static func _toys(sketch: BuildingSketch, palette: WorldPalette, box: Rect2, level: int) -> void:
	var rim: float = box.position.y
	var left: float = box.position.x
	_pencil(sketch, palette, Vector2(left + 28.0, rim + 16.0), Vector2(left + 46.0, rim - 64.0))
	if level >= 2:
		_scissors(sketch, palette, Vector2(left + box.size.x * 0.62, rim - 16.0))
	if level >= 3:
		var wand_top: Vector2 = Vector2(left + 66.0, rim - 46.0)
		var wand: PackedVector2Array = [Vector2(left + 72.0, rim + 10.0), wand_top]
		sketch.rod(&"star_wand", wand, WorldPalette.pick(palette.toys, 3), 4.0)
		sketch.piece(&"star_wand", BuildingSketch.star(wand_top, 13.0), palette.sparkle)
	var ball: Vector2 = Vector2(box.end.x - 22.0, rim - 6.0)
	sketch.disc(&"ball", ball, 17.0, WorldPalette.pick(palette.toys, 1))
	var stripe: PackedVector2Array = [ball + Vector2(-17.0, -3.0), ball + Vector2(17.0, -3.0)]
	sketch.line(stripe, WorldPalette.pick(palette.toys, 4), 4.0)


static func _pencil(
	sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, tip: Vector2
) -> void:
	var along: Vector2 = (tip - foot).normalized()
	var wood_start: Vector2 = tip - along * 14.0
	var body: PackedVector2Array = [foot, wood_start]
	sketch.rod(&"pencil", body, WorldPalette.pick(palette.toys, 0), 11.0)
	var side: Vector2 = along.orthogonal() * 5.5
	var cone: PackedVector2Array = [wood_start + side, tip, wood_start - side]
	sketch.piece(&"pencil", cone, palette.pencil_wood)
	var lead_base: Vector2 = tip - along * 5.0
	var lead: PackedVector2Array = [lead_base + side * 0.35, tip, lead_base - side * 0.35]
	sketch.shade(lead, palette.ink)


## Lv 2+: big felt scissors with teal handle rings, blades up.
static func _scissors(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2) -> void:
	for side: float in [-1.0, 1.0]:
		var blade: PackedVector2Array = [
			foot + Vector2(side * 1.0, 0.0),
			foot + Vector2(side * 5.0, -60.0),
			foot + Vector2(side * 11.0, -48.0),
			foot + Vector2(side * 11.0, 0.0),
		]
		sketch.piece(&"scissors", blade, palette.metal)
		sketch.disc(&"scissors", foot + Vector2(side * 9.0, 8.0), 8.0, palette.paint_trim)
	sketch.dot(foot + Vector2(0.0, -6.0), 2.5, palette.metal_dark)


static func _front_face(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, level: int
) -> void:
	sketch.block(&"box", box, palette.wood, true)
	for i: int in [1, 2]:
		var y: float = box.position.y + box.size.y * i / 3.0
		var gap: PackedVector2Array = [Vector2(box.position.x, y), Vector2(box.end.x, y)]
		sketch.line(gap, palette.wood_grain, 2.5)
	_grain(sketch, palette, box)
	for i: int in 3:
		var y: float = box.position.y + box.size.y * (i + 0.5) / 3.0
		sketch.dot(Vector2(box.position.x + 7.0, y), 2.0, palette.nail)
		sketch.dot(Vector2(box.end.x - 7.0, y), 2.0, palette.nail)
	sketch.parts.append(&"nails")
	if level >= 3:
		_paint(sketch, palette, box)
		_brass_corners(sketch, palette, box)
	if level >= 2:
		var clasp_color: Color = palette.brass if level >= 3 else palette.metal
		var clasp: Rect2 = Rect2(box.get_center().x - 10.0, box.position.y - 4.0, 20.0, 18.0)
		sketch.block(&"clasp", clasp, clasp_color)
		sketch.dot(clasp.get_center() + Vector2(0.0, 2.0), 2.5, palette.box_inside)


## Wood grain squiggles on the planks.
static func _grain(sketch: BuildingSketch, palette: WorldPalette, box: Rect2) -> void:
	var color: Color = Color(palette.wood_grain, 0.7)
	for i: int in 3:
		var y: float = box.position.y + box.size.y * (i + 0.3) / 3.0
		var x: float = box.position.x + 14.0 + (i % 2) * box.size.x * 0.35
		var squiggle: PackedVector2Array = [
			Vector2(x, y), Vector2(x + 18, y - 2), Vector2(x + 36, y + 1), Vector2(x + 50, y)
		]
		sketch.line(squiggle, color, 1.5)


## Lv 3: a painted band across the middle plank with felt stars on it.
static func _paint(sketch: BuildingSketch, palette: WorldPalette, box: Rect2) -> void:
	var band_corner: Vector2 = box.position + Vector2(10.0, box.size.y / 3.0 + 4.0)
	var band: Rect2 = Rect2(band_corner, Vector2(box.size.x - 20.0, box.size.y / 3.0 - 8.0))
	sketch.block(&"paint", band, palette.paint)
	var top_edge: PackedVector2Array = [band.position, Vector2(band.end.x, band.position.y)]
	var bottom_edge: PackedVector2Array = [Vector2(band.position.x, band.end.y), band.end]
	sketch.line(top_edge, palette.paint_trim, 3.0)
	sketch.line(bottom_edge, palette.paint_trim, 3.0)
	for i: int in 3:
		var x: float = band.position.x + band.size.x * (i + 0.5) / 3.0
		var at: Vector2 = Vector2(x, band.get_center().y)
		sketch.shade(BuildingSketch.star(at, band.size.y * 0.4), palette.tag)


## Lv 3: brass L-brackets on the front's four corners.
static func _brass_corners(sketch: BuildingSketch, palette: WorldPalette, box: Rect2) -> void:
	var arm: float = 16.0
	var thick: float = 5.0
	var corners: PackedVector2Array = BuildingSketch.corners(box)
	var inward: Array[Vector2] = [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]
	for i: int in 4:
		var c: Vector2 = corners[i]
		var d: Vector2 = inward[i]
		var bracket: PackedVector2Array = [
			c,
			c + Vector2(d.x * arm, 0.0),
			c + Vector2(d.x * arm, d.y * thick),
			c + Vector2(d.x * thick, d.y * thick),
			c + Vector2(d.x * thick, d.y * arm),
			c + Vector2(0.0, d.y * arm),
		]
		sketch.shade(bracket, palette.brass)
		sketch.dot(c + d * 9.0, 1.6, palette.brass_dark)
	sketch.parts.append(&"brass_corners")


static func _side_face(
	sketch: BuildingSketch, palette: WorldPalette, box: Rect2, depth: Vector2, level: int
) -> void:
	var top: Vector2 = Vector2(box.end.x, box.position.y)
	var bottom: Vector2 = box.end
	var side: PackedVector2Array = [bottom, bottom + depth, top + depth, top]
	sketch.piece(&"box", side, palette.wood_side)
	for i: int in [1, 2]:
		var from: Vector2 = top.lerp(bottom, i / 3.0)
		sketch.line([from, from + depth], palette.wood_grain, 2.0)
	if level >= 3:
		var band: Vector2 = Vector2(0.0, 6.0)
		var trim: PackedVector2Array = [top, top + depth, top + depth + band, top + band]
		sketch.shade(trim, palette.brass_dark)


## Lv 3: a sturdy wooden rack beside the box (base plank, two square posts, a crossbar) with a
## toy sword and a felt bow hanging between the posts. Nothing crosses a post, so every piece
## keeps a clean outline.
static func _weapon_rack(sketch: BuildingSketch, palette: WorldPalette, box: Rect2) -> void:
	var right: float = box.position.x - 6.0
	var left: float = right - 50.0
	var top: float = box.position.y - 30.0
	var base: Rect2 = Rect2(left - 3.0, -9.0, right - left + 6.0, 9.0)
	LookParts.footprint_shadow(sketch, base)
	sketch.block(&"weapon_rack", base, palette.wood_side)
	for x: float in [left, right - 8.0]:
		var post: Rect2 = Rect2(x, top, 8.0, base.position.y - top)
		sketch.block(&"weapon_rack", post, palette.wood)
		var side: Rect2 = Rect2(x + 5.0, top, 3.0, post.size.y)
		sketch.shade(BuildingSketch.corners(side), palette.wood_side)
	var bar: Rect2 = Rect2(left - 3.0, top, right - left + 6.0, 10.0)
	sketch.block(&"weapon_rack", bar, palette.wood_top)
	var grain_y: float = bar.position.y + 6.0
	var grain: PackedVector2Array = [Vector2(left, grain_y), Vector2(right, grain_y)]
	sketch.line(grain, palette.wood_grain, 1.2)
	_rack_sword(sketch, palette, left + 17.0, top)
	_rack_bow(sketch, palette, right - 14.0, top)


## A toy sword hanging point-down from the rack's bar: pommel above, grip through the bar.
static func _rack_sword(
	sketch: BuildingSketch, palette: WorldPalette, x: float, top: float
) -> void:
	var blade: PackedVector2Array = [
		Vector2(x - 5.0, top + 18.0),
		Vector2(x + 5.0, top + 18.0),
		Vector2(x + 5.0, -26.0),
		Vector2(x, -17.0),
		Vector2(x - 5.0, -26.0),
	]
	sketch.piece(&"rack_sword", blade, palette.metal)
	sketch.line([Vector2(x - 1.5, top + 22.0), Vector2(x - 1.5, -26.0)], palette.glass_shine, 1.5)
	_inked(sketch, Rect2(x - 3.5, top - 4.0, 7.0, 18.0), WorldPalette.pick(palette.toys, 1))
	_inked(sketch, Rect2(x - 10.0, top + 13.0, 20.0, 6.0), palette.brass)
	sketch.disc(&"rack_sword", Vector2(x, top - 7.0), 5.0, palette.brass)


## A felt bow hanging from a peg on the bar, its string straight.
static func _rack_bow(sketch: BuildingSketch, palette: WorldPalette, x: float, top: float) -> void:
	var arc: PackedVector2Array = []
	var length: float = -30.0 - top
	for i: int in 9:
		var t: float = float(i) / 8.0
		arc.append(Vector2(x - sin(t * PI) * 10.0, top + 12.0 + t * length))
	sketch.line([arc[0], arc[arc.size() - 1]], palette.tag, 1.5)
	sketch.rod(&"rack_bow", arc, WorldPalette.pick(palette.toys, 2), 5.0)
	sketch.disc(&"weapon_rack", Vector2(x, top + 5.0), 3.5, palette.brass_dark)


## A small block with its own thin ink line, for pieces drawn in front of the bar.
static func _inked(sketch: BuildingSketch, rect: Rect2, color: Color) -> void:
	sketch.block(&"rack_sword", rect, color)
	# One line per side: a closed line would be filled solid by the kit.
	var edge: PackedVector2Array = BuildingSketch.corners(rect)
	for i: int in edge.size():
		sketch.line([edge[i], edge[(i + 1) % edge.size()]], WorldPalette.current().ink, 1.5)


## Ruin: the box is knocked over onto a loose plank, a plank of its front is broken, the lid lies
## flat on the floor and the ball has rolled out.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var box: Rect2 = _front(1)
	var depth: Vector2 = _depth(1)
	sketch.shadow(_floor_shadow(box, depth))
	var plank: Rect2 = Rect2(box.end.x - 30.0, -12.0, 72.0, 12.0)
	sketch.block(&"loose_plank", plank, palette.wood_side)
	var grain_from: Vector2 = plank.position + Vector2(8.0, 6.0)
	sketch.line([grain_from, plank.end - Vector2(10.0, 5.0)], palette.wood_grain, 1.5)
	sketch.turn(-0.14, Vector2(box.position.x, 0.0))
	_opening(sketch, palette, box, depth)
	sketch.block(&"broken_box", box, palette.wood)
	var left: float = box.position.x
	var rim: float = box.position.y
	var gap: PackedVector2Array = [
		Vector2(left + 40.0, rim + 2.0),
		Vector2(left + 78.0, rim + 2.0),
		Vector2(left + 70.0, rim + 18.0),
		Vector2(left + 60.0, rim + 12.0),
		Vector2(left + 50.0, rim + 24.0),
	]
	sketch.shade(gap, palette.box_inside)
	var y: float = rim + box.size.y * 0.66
	sketch.line([Vector2(left, y), Vector2(box.end.x, y)], palette.wood_grain, 2.5)
	_side_face(sketch, palette, box, depth, 1)
	sketch.straighten()
	var lid: PackedVector2Array = [
		Vector2(left - 50.0, -2.0),
		Vector2(left + 20.0, -2.0),
		Vector2(left + 36.0, 10.0),
		Vector2(left - 34.0, 10.0),
	]
	sketch.piece(&"fallen_lid", lid, palette.wood_top)
	sketch.line([lid[0].lerp(lid[2], 0.2), lid[0].lerp(lid[2], 0.6)], palette.wood_grain, 1.5)
	var ball: Vector2 = Vector2(box.end.x + 52.0, -12.0)
	sketch.disc(&"rolled_ball", ball, 12.0, WorldPalette.pick(palette.toys, 1))
