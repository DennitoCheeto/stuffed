class_name FortLook
extends RefCounted
## The Pillow Fort in the art kit's style (spec 05 §3.2): a wall of stacked pillows between two
## cushion towers, a patchwork quilt roof and the glowing Bedroom door. As the town grows it gets
## its pieces (`TownFort.PIECES`): a flag, string lights, a second tower, bunting, window boxes
## and a big banner. Built around the fort's bottom middle; the door matches `door_rect`.

## Half width of the pillow wall (it ends inside the towers, so its seams never cross them) and
## its height (share of the fort's height).
const WALL_HALF: float = 124.0
const WALL_SHARE: float = 0.58
## The cushion towers: width and height (share of the fort's height).
const TOWER_WIDTH: float = 80.0
const TOWER_SHARE: float = 0.78
## Size of one quilt patch on the roof.
const PATCH: float = 44.0
const WINDOW_X: float = 88.0
const WINDOW_R: float = 19.0


## The fort with the first `pieces` of `TownFort.PIECES`, for `layout`'s fort and door.
static func build(layout: TownLayout, pieces: PackedStringArray) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new()
	var palette: WorldPalette = WorldPalette.current()
	var fort: Rect2 = layout.fort_rect
	var bottom: Vector2 = Vector2(fort.get_center().x, fort.end.y)
	var half: float = fort.size.x / 2.0
	var wall_top: float = -fort.size.y * WALL_SHARE
	var tower_top: float = -fort.size.y * TOWER_SHARE
	LookParts.box_shadow(sketch, -half + 20.0, fort.size.x - 40.0, Vector2(24.0, -14.0))
	if pieces.has("second_tower"):
		_turret(sketch, palette, -half + TOWER_WIDTH / 2.0, tower_top)
	_roof(sketch, palette, wall_top, -fort.size.y + 10.0)
	var door: Rect2 = Rect2(layout.door_rect.position - bottom, layout.door_rect.size)
	_wall(sketch, palette, wall_top, door)
	_eave(sketch, palette, wall_top)
	if pieces.has("string_lights"):
		var from: Vector2 = Vector2(-WALL_HALF, wall_top + 8.0)
		LookParts.fairy_lights(sketch, &"string_lights", from, Vector2(-from.x, from.y), 18.0, 13)
	var middle: float = wall_top * 0.62
	_windows(sketch, palette, middle)
	if pieces.has("bunting"):
		var from: Vector2 = Vector2(-WALL_HALF + 16.0, wall_top * 0.86)
		LookParts.bunting(sketch, &"bunting", from, Vector2(-from.x, from.y), 22.0, 9)
	if pieces.has("window_boxes"):
		_window_boxes(sketch, palette, middle + WINDOW_R + 4.0)
	_door(sketch, palette, door)
	for i: int in 2:
		var x: float = -half + TOWER_WIDTH / 2.0 if i == 0 else half - TOWER_WIDTH / 2.0
		_tower(sketch, palette, x, tower_top, WorldPalette.pick(palette.fort_towers, i))
	if pieces.has("big_banner"):
		_banner(sketch, palette, half - TOWER_WIDTH / 2.0, tower_top)
	if pieces.has("flag"):
		LookParts.pin_flag(sketch, &"flag", Vector2(0.0, -fort.size.y + 12.0), 58.0, palette.clover)
	return sketch


## Three rows of plump pillows, each with tuft buttons and a seam that stops at the door.
static func _wall(sketch: BuildingSketch, palette: WorldPalette, top: float, door: Rect2) -> void:
	var doorway: PackedVector2Array = BuildingSketch.corners(door.grow(12.0))
	var row_height: float = -top / 3.0
	for row: int in 3:
		var inset: float = 4.0 if row == 1 else 0.0
		var y: float = -row_height * (row + 1)
		var pillow: Rect2 = Rect2(-WALL_HALF + inset, y, (WALL_HALF - inset) * 2.0, row_height)
		var color: Color = palette.fort_wall if row != 1 else palette.fort_wall.darkened(0.04)
		sketch.block(&"pillow_wall", pillow, color)
		var ring: PackedVector2Array = BuildingSketch.corners(pillow.grow(-palette.seam_inset))
		ring.append(ring[0])
		for stitched: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(ring, doorway):
			sketch.seam(stitched)
		var seam_y: float = pillow.end.y - 1.0
		var under: PackedVector2Array = [
			Vector2(pillow.position.x, seam_y), Vector2(pillow.end.x, seam_y)
		]
		sketch.line(under, Color(palette.ink, 0.12), 3.0)
		var x: float = pillow.position.x + 38.0 + row * 12.0
		while x < pillow.end.x - 20.0:
			sketch.dot(Vector2(x, pillow.get_center().y), 3.2, palette.fort_wall_side)
			x += 64.0


## The patchwork quilt roof draped over the wall, with a lavender trim along the eave.
static func _roof(sketch: BuildingSketch, palette: WorldPalette, eave: float, peak: float) -> void:
	var reach: float = WALL_HALF + 6.0
	var roof: PackedVector2Array = [
		Vector2(-reach, eave + 8.0), Vector2(reach, eave + 8.0), Vector2(0.0, peak)
	]
	sketch.piece(&"quilt_roof", roof, WorldPalette.pick(palette.fort_roof, 0))
	var columns: int = ceili(reach * 2.0 / PATCH)
	var rows: int = ceili((eave - peak) / PATCH) + 1
	for row: int in rows:
		for column: int in columns:
			var corner: Vector2 = Vector2(-reach + column * PATCH, peak + row * PATCH)
			var square: Rect2 = Rect2(corner, Vector2.ONE * PATCH)
			var patch: PackedVector2Array = BuildingSketch.corners(square)
			for cut: PackedVector2Array in Geometry2D.intersect_polygons(patch, roof):
				sketch.shade(cut, WorldPalette.pick(palette.fort_roof, row + column * 3))
	for row: int in range(1, rows):
		var y: float = peak + row * PATCH
		_seam_inside(sketch, [Vector2(-reach, y), Vector2(reach, y)], roof)
	for column: int in range(1, columns):
		var x: float = -reach + column * PATCH
		_seam_inside(sketch, [Vector2(x, peak), Vector2(x, eave + 8.0)], roof)


## The lavender trim along the roof's eave, sewn over the top of the wall.
static func _eave(sketch: BuildingSketch, palette: WorldPalette, eave: float) -> void:
	var reach: float = WALL_HALF
	sketch.block(&"quilt_roof", Rect2(-reach, eave - 6.0, reach * 2.0, 12.0), palette.paint, true)


## A stitched seam along `path`, only where it lies inside `shape`.
static func _seam_inside(
	sketch: BuildingSketch, path: PackedVector2Array, shape: PackedVector2Array
) -> void:
	for inside: PackedVector2Array in Geometry2D.intersect_polyline_with_polygon(path, shape):
		sketch.seam(inside)


## A tall cushion tower with a plump top, a tuft button and a shaded right side.
static func _tower(
	sketch: BuildingSketch, palette: WorldPalette, x: float, top: float, color: Color
) -> void:
	var half: float = TOWER_WIDTH / 2.0
	var body: PackedVector2Array = [
		Vector2(x - half, 0.0),
		Vector2(x + half, 0.0),
		Vector2(x + half, top + 10.0),
		Vector2(x + half - 8.0, top),
		Vector2(x - half + 8.0, top),
		Vector2(x - half, top + 10.0),
	]
	sketch.piece(&"towers", body, color, true)
	var side: Rect2 = Rect2(x + half - 16.0, top, 16.0, -top)
	LookParts.clip_shade(sketch, body, side, Color(palette.ink, 0.1))
	var cap: Vector2 = Vector2(x, top + 6.0)
	LookParts.flange(sketch, &"towers", cap, half + 4.0, 16.0, color.lightened(0.12), color)
	LookParts.button(sketch, Vector2(x, top * 0.55), 6.0, 2)


## Lv "second_tower": a small turret with a pink cone roof on top of the left tower.
static func _turret(sketch: BuildingSketch, palette: WorldPalette, x: float, base: float) -> void:
	var color: Color = WorldPalette.pick(palette.fort_towers, 0).lightened(0.1)
	var body: Rect2 = Rect2(x - 28.0, base - 64.0, 56.0, 66.0)
	var cone: PackedVector2Array = [
		Vector2(x - 38.0, body.position.y + 4.0),
		Vector2(x + 38.0, body.position.y + 4.0),
		Vector2(x, body.position.y - 50.0),
	]
	sketch.piece(&"second_tower", cone, palette.pincushion)
	var shaded: Rect2 = Rect2(x + 10.0, cone[2].y, 40.0, 60.0)
	LookParts.clip_shade(sketch, cone, shaded, palette.pincushion_dark)
	sketch.block(&"second_tower", body, color, true)
	var window_at: Vector2 = body.get_center() - Vector2(0.0, 6.0)
	var window: PackedVector2Array = LookParts.oval(window_at, 9.0, 12.0)
	sketch.shade(window, palette.box_inside)


## Two round windows with wooden frames.
static func _windows(sketch: BuildingSketch, palette: WorldPalette, y: float) -> void:
	for x: float in [-WINDOW_X, WINDOW_X]:
		var at: Vector2 = Vector2(x, y)
		sketch.disc(&"windows", at, WINDOW_R + 5.0, palette.wood_top)
		sketch.dot(at, WINDOW_R, palette.glass)
		sketch.line([at - Vector2(WINDOW_R, 0.0), at + Vector2(WINDOW_R, 0.0)], palette.wood, 3.0)
		sketch.line([at - Vector2(0.0, WINDOW_R), at + Vector2(0.0, WINDOW_R)], palette.wood, 3.0)
		sketch.shade(LookParts.oval(at + Vector2(-8.0, -8.0), 3.0, 5.0, 10), palette.glass_shine)


## Flower boxes under the windows.
static func _window_boxes(sketch: BuildingSketch, palette: WorldPalette, y: float) -> void:
	for x: float in [-WINDOW_X, WINDOW_X]:
		for i: int in 4:
			var flower: Vector2 = Vector2(x - 21.0 + i * 14.0, y - 3.0 - (i % 2) * 4.0)
			sketch.disc(&"window_boxes", flower, 6.5, WorldPalette.pick(palette.toys, i + 1))
			sketch.dot(flower, 2.2, palette.sparkle)
		sketch.block(&"window_boxes", Rect2(x - 30.0, y, 60.0, 13.0), palette.wood, true)


## The arched Bedroom door: a wooden frame and the warm light of the room behind.
static func _door(sketch: BuildingSketch, palette: WorldPalette, door: Rect2) -> void:
	sketch.piece(&"door", _arch(door.grow_individual(10.0, 10.0, 10.0, 0.0)), palette.wood)
	sketch.piece(&"door", _arch(door), palette.door_glow)
	var inner: Rect2 = door.grow(-8.0)
	inner.size.y += 8.0
	sketch.line(_arch(inner), palette.door_glow_dark, 2.0)
	sketch.dot(door.position + Vector2(door.size.x * 0.78, door.size.y * 0.6), 5.0, palette.brass)


## An arch: `rect` with a round top as wide as the rect.
static func _arch(rect: Rect2) -> PackedVector2Array:
	var r: float = rect.size.x / 2.0
	var center: Vector2 = Vector2(rect.get_center().x, rect.position.y + r)
	var points: PackedVector2Array = [Vector2(rect.position.x, rect.end.y), rect.end]
	for i: int in 13:
		points.append(center + Vector2.from_angle(-i * PI / 12.0) * r)
	return points


## Lv "big_banner": a long lavender banner with a star hanging on the right tower.
static func _banner(sketch: BuildingSketch, palette: WorldPalette, x: float, top: float) -> void:
	var y: float = top + 26.0
	var banner: PackedVector2Array = [
		Vector2(x - 24.0, y),
		Vector2(x + 24.0, y),
		Vector2(x + 24.0, y + 92.0),
		Vector2(x, y + 76.0),
		Vector2(x - 24.0, y + 92.0),
	]
	sketch.rod(&"big_banner", [Vector2(x - 32.0, y), Vector2(x + 32.0, y)], palette.wood_side, 5.0)
	sketch.piece(&"big_banner", banner, palette.paint, true)
	sketch.piece(&"big_banner", BuildingSketch.star(Vector2(x, y + 38.0), 15.0), palette.sparkle)
