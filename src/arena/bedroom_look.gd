class_name BedroomLook
extends RefCounted
## The Bedroom's floor and room in the Sunny patchwork look (spec 05 §4.1): honey floorboards with
## grain, knots and nails, the patchwork rug in the middle (where every run starts) with stitched
## seams and sewn-on buttons, the toy-block walls, and the top wall with wallpaper, a baseboard and
## two windows with curtains. Built once with the building art kit and baked: the boards in tiles
## (`board_tiles`, so the camera skips the tiles it does not see), then rug, walls and details.
## Layers keep the kit's "all ink first" rule from hiding a window's or button's outline under
## the wallpaper or the rug. The sunbeams that fall from the windows are one more mesh whose light
## fades out softly (`sunbeams`).
## Numbers in data/arena/bedroom_room.tres, colours from the world palette.

## Layers, back to front.
enum Layer { RUG, WALLS, DETAILS }

const BOARD_GAP: float = 3.0
const NAIL_RADIUS: float = 3.0
const NAIL_INSET: float = 12.0
const GRAIN_STEP: float = 120.0
const GRAIN_WOBBLE: float = 4.0
const KNOT_SIZE: Vector2 = Vector2(9.0, 22.0)
const RUG_SEAM_WIDTH: float = 3.0
const RUG_SEAM_DASH: float = 10.0
## Rug pattern strength: share of the palette's pattern alpha, and how much darker than the patch.
const RUG_PATTERN_SHARE: float = 0.6
const RUG_PATTERN_DARKER: float = 0.14
const BLOCK_INNER_ALPHA: float = 0.35
const WALL_STRIPE_STEP: float = 64.0
const WALL_STRIPE_WIDTH: float = 22.0
const WALL_SHADOW_DEPTH: float = 26.0
const FRAME: float = 14.0
const BAR_WIDTH: float = 12.0
const SILL_HEIGHT: float = 18.0
const CURTAIN_WIDTH: float = 90.0
const CURTAIN_STEP: float = 18.0

## Built layers per room: key -> [rug, walls, details].
static var _cache: Dictionary[String, Array] = {}
static var _boards: Dictionary[String, Array] = {}
static var _beams: Dictionary[String, ArrayMesh] = {}


## The baked layers on top of the boards, back to front (built the first time).
static func layers(
	size: Vector2, wall: float, room: BedroomRoom, rugs: Array[Rect2]
) -> Array[BuildingSketch]:
	var key: String = _key(size, wall, room, rugs)
	if not _cache.has(key):
		var rug: BuildingSketch = BuildingSketch.new()
		var details: BuildingSketch = BuildingSketch.new()
		for rect: Rect2 in rugs:
			patchwork(rug, details, rect, room)
		windows(details, room)
		_cache[key] = [rug, walls(size, wall, room), details]
	var result: Array[BuildingSketch] = []
	result.assign(_cache[key])
	return result


## The see-through sunbeams from the windows as one mesh (soft sides, fading out down the room).
static func sunbeams(size: Vector2, room: BedroomRoom) -> ArrayMesh:
	var key: String = _key(size, 0.0, room, [])
	if not _beams.has(key):
		_beams[key] = _bake_beams(room)
	return _beams[key]


## The corners of the beam under window `index` (top-left, top-right, bottom-right, bottom-left).
static func beam(room: BedroomRoom, index: int) -> PackedVector2Array:
	var half: float = room.window_size.x / 2.0
	var x: float = room.window_centers[index]
	var shift: float = room.sunbeam_slant * room.sunbeam_length
	var down: float = room.sunbeam_length
	return [
		Vector2(x - half, 0.0),
		Vector2(x + half, 0.0),
		Vector2(x + half + shift, down),
		Vector2(x - half + shift, down),
	]


## Where window `index` sits on the top wall (the glass, without its frame).
static func window_rect(room: BedroomRoom, index: int) -> Rect2:
	var size: Vector2 = room.window_size
	var top: float = -room.window_bottom - size.y
	return Rect2(room.window_centers[index] - size.x / 2.0, top, size.x, size.y)


## Honey floorboards running from the top wall towards you, joints shifted column by column, cut
## into tiles of `room.board_tile` (each board goes into the tile its top left corner is in), so a
## camera only draws the tiles it sees. Built the first time.
static func board_tiles(size: Vector2, room: BedroomRoom) -> Array[BuildingSketch]:
	var key: String = _key(size, 0.0, room, [])
	if not _boards.has(key):
		_boards[key] = _build_boards(size, room)
	var result: Array[BuildingSketch] = []
	result.assign(_boards[key])
	return result


static func _build_boards(size: Vector2, room: BedroomRoom) -> Array[BuildingSketch]:
	var palette: WorldPalette = WorldPalette.current()
	var floor_rect: Rect2 = Rect2(Vector2.ZERO, size)
	var lengths: PackedFloat32Array = room.plank_lengths
	var width: float = room.plank_width
	var columns: int = ceili(size.x / width)
	var tile_columns: int = maxi(ceili(size.x / room.board_tile.x), 1)
	var tile_rows: int = maxi(ceili(size.y / room.board_tile.y), 1)
	var tiles: Array[BuildingSketch] = []
	for i: int in tile_columns * tile_rows:
		tiles.append(BuildingSketch.new())
	var count: int = 0
	for col: int in columns:
		var k: int = col * 2
		var y: float = -lengths[k % lengths.size()] * fposmod(col * 0.37, 1.0)
		while y < size.y:
			var length: float = lengths[k % lengths.size()]
			var rect: Rect2 = Rect2(col * width, y, width, length).intersection(floor_rect)
			k += 1
			y += length
			if rect.size.y <= 1.0:
				continue
			var tx: int = mini(floori(rect.position.x / room.board_tile.x), tile_columns - 1)
			var ty: int = mini(floori(rect.position.y / room.board_tile.y), tile_rows - 1)
			var sketch: BuildingSketch = tiles[ty * tile_columns + tx]
			sketch.shade(BuildingSketch.corners(rect), WorldPalette.pick(palette.board_colors, k))
			_grain(sketch, rect, room.grain_lines, count, palette.board_grain)
			if count % room.knot_every == 0:
				_knot(sketch, rect, count, palette.board_grain)
			_nails(sketch, rect, size, palette.board_seam)
			if col > 0:
				var left: PackedVector2Array = [rect.position, Vector2(rect.position.x, rect.end.y)]
				sketch.line(left, palette.board_seam, BOARD_GAP)
			if rect.end.y < size.y:
				var from: Vector2 = rect.position + Vector2(BOARD_GAP, rect.size.y)
				var to: Vector2 = rect.end - Vector2(BOARD_GAP, 0.0)
				sketch.line([from, to], palette.board_seam, BOARD_GAP)
			count += 1
	for sketch: BuildingSketch in tiles:
		for part: StringName in [&"floorboards", &"wood_grain", &"knots", &"nails"]:
			sketch.mark(part)
	return tiles


## A patchwork rug on `rect`: an outlined edge band with a stitched line, patches with tone-on-tone
## patterns and coloured seams in `sketch`; the sewn-on buttons on the crossings go in `details`.
static func patchwork(
	sketch: BuildingSketch, details: BuildingSketch, rect: Rect2, room: BedroomRoom
) -> void:
	var palette: WorldPalette = WorldPalette.current()
	sketch.piece(&"rug", BuildingSketch.corners(rect), palette.rug_border)
	sketch.seam(BuildingSketch.corners(rect.grow(-room.rug_border * 0.5)), true)
	var inner: Rect2 = rect.grow(-room.rug_border)
	var cols: int = maxi(roundi(inner.size.x / room.rug_patch), 1)
	var rows: int = maxi(roundi(inner.size.y / room.rug_patch), 1)
	var patch: Vector2 = Vector2(inner.size.x / cols, inner.size.y / rows)
	var alpha: float = palette.pattern_alpha * RUG_PATTERN_SHARE
	for row: int in rows:
		for col: int in cols:
			var cell: Rect2 = Rect2(inner.position + patch * Vector2(col, row), patch)
			var color: Color = WorldPalette.pick(palette.rug_patches, col + 2 * row)
			sketch.shade(BuildingSketch.corners(cell), color)
			var pattern: Color = Color(color.darkened(RUG_PATTERN_DARKER), alpha)
			match posmod(col + row, 4):
				1:
					TownGroundLook.gingham(sketch, cell, pattern)
				2:
					TownGroundLook.polka(sketch, cell, pattern)
				3:
					sketch.stripes(BuildingSketch.corners(cell), pattern, 12.0, 5.0, true)
	sketch.mark(&"rug_patches")
	for col: int in range(1, cols):
		var x: float = inner.position.x + patch.x * col
		var line: PackedVector2Array = [Vector2(x, inner.position.y), Vector2(x, inner.end.y)]
		var color: Color = WorldPalette.pick(palette.rug_seams, col)
		TownGroundLook.dashed(sketch, line, color, RUG_SEAM_WIDTH, RUG_SEAM_DASH)
	for row: int in range(1, rows):
		var y: float = inner.position.y + patch.y * row
		var line: PackedVector2Array = [Vector2(inner.position.x, y), Vector2(inner.end.x, y)]
		var color: Color = WorldPalette.pick(palette.rug_seams, row + 1)
		TownGroundLook.dashed(sketch, line, color, RUG_SEAM_WIDTH, RUG_SEAM_DASH)
	sketch.mark(&"rug_seams")
	var crossing: int = 0
	for row: int in range(1, rows):
		for col: int in range(1, cols):
			if crossing % room.rug_button_every == 0:
				var at: Vector2 = inner.position + patch * Vector2(col, row)
				_button(details, at, room.rug_button_radius, crossing)
			crossing += 1


## The toy-block walls on the left, right and bottom, and the top wall with wallpaper and a
## baseboard (the windows are on the details layer).
static func walls(size: Vector2, t: float, room: BedroomRoom) -> BuildingSketch:
	var palette: WorldPalette = WorldPalette.current()
	var sketch: BuildingSketch = BuildingSketch.new()
	var shadow: Rect2 = Rect2(0.0, 0.0, size.x, WALL_SHADOW_DEPTH)
	sketch.shade(BuildingSketch.corners(shadow), palette.shadow)
	var across: int = ceili((size.x + t * 2.0) / t)
	for i: int in across:
		_block(sketch, Rect2(-t + i * t, size.y, t, t), i + 1)
	for i: int in ceili(size.y / t):
		_block(sketch, Rect2(-t, i * t, t, t), i + 2)
		_block(sketch, Rect2(size.x, i * t, t, t), i + 3)
	var height: float = room.top_wall_height
	var wall: Rect2 = Rect2(-t, -height, size.x + t * 2.0, height)
	sketch.block(&"top_wall", wall, palette.wallpaper)
	var paper: Rect2 = Rect2(wall.position, wall.size - Vector2(0.0, room.baseboard_height))
	var stripe: Color = Color(palette.wallpaper_stripe, palette.pattern_alpha)
	sketch.stripes(BuildingSketch.corners(paper), stripe, WALL_STRIPE_STEP, WALL_STRIPE_WIDTH, true)
	var board: Rect2 = Rect2(-t, -room.baseboard_height, wall.size.x, room.baseboard_height)
	sketch.shade(BuildingSketch.corners(board), palette.wood)
	var lip: Rect2 = Rect2(board.position, Vector2(board.size.x, board.size.y * 0.3))
	sketch.shade(BuildingSketch.corners(lip), palette.wood_top)
	sketch.line([board.position, Vector2(board.end.x, board.position.y)], palette.ink, 2.0)
	sketch.line([Vector2(-t, 0.0), Vector2(board.end.x, 0.0)], palette.ink, 2.0)
	sketch.mark(&"baseboard")
	return sketch


## Two windows on the top wall: frame with bars, sky and clouds, a sill, curtains on a rod.
static func windows(sketch: BuildingSketch, room: BedroomRoom) -> void:
	var palette: WorldPalette = WorldPalette.current()
	for i: int in room.window_centers.size():
		var glass: Rect2 = window_rect(room, i)
		var frame: Rect2 = glass.grow(FRAME)
		sketch.block(&"window", frame, palette.window_frame, true)
		LookParts.outlined(sketch, BuildingSketch.corners(glass), palette.window_sky)
		var cloud: Vector2 = glass.position + glass.size * Vector2(0.3 + 0.35 * i, 0.4)
		for bump: Vector3 in [Vector3(-34, 6, 22), Vector3(0, -6, 30), Vector3(36, 6, 22)]:
			sketch.dot(cloud + Vector2(bump.x, bump.y), bump.z, palette.tissue)
		var middle: Vector2 = glass.get_center()
		var upright: PackedVector2Array = [
			Vector2(middle.x, glass.position.y), Vector2(middle.x, glass.end.y)
		]
		var across: PackedVector2Array = [
			Vector2(glass.position.x, middle.y), Vector2(glass.end.x, middle.y)
		]
		sketch.line(upright, palette.window_frame, BAR_WIDTH)
		sketch.line(across, palette.window_frame, BAR_WIDTH)
		var shine: Vector2 = glass.position + Vector2(30.0, 24.0)
		var shine_big: PackedVector2Array = [shine + Vector2(0, 50), shine + Vector2(50, 0)]
		var shine_small: PackedVector2Array = [shine + Vector2(0, 80), shine + Vector2(80, 0)]
		sketch.line(shine_big, palette.glass_shine, 6.0)
		sketch.line(shine_small, palette.glass_shine, 3.0)
		sketch.mark(&"window_glass")
		var sill_x: float = frame.position.x - 24.0
		var sill: Rect2 = Rect2(sill_x, frame.end.y, frame.size.x + 48.0, SILL_HEIGHT)
		sketch.block(&"window_sill", sill, palette.wood_top)
		_curtain(sketch, frame, -1.0)
		_curtain(sketch, frame, 1.0)
		var rod_y: float = frame.position.y - 16.0
		var rod: PackedVector2Array = [
			Vector2(frame.position.x - CURTAIN_WIDTH - 20.0, rod_y),
			Vector2(frame.end.x + CURTAIN_WIDTH + 20.0, rod_y),
		]
		sketch.rod(&"curtain_rod", rod, palette.wood, 8.0)


static func _grain(
	sketch: BuildingSketch, rect: Rect2, lines: int, seed_index: int, color: Color
) -> void:
	for g: int in lines:
		var x: float = rect.position.x + rect.size.x * (g + 1.0) / (lines + 1.0)
		var phase: float = float(seed_index * 3 + g)
		var points: PackedVector2Array = []
		var y: float = rect.position.y + 10.0
		while y < rect.end.y - 10.0:
			points.append(Vector2(x + sin(phase + y / 90.0) * GRAIN_WOBBLE, y))
			y += GRAIN_STEP
		points.append(Vector2(x + sin(phase + rect.end.y / 90.0) * GRAIN_WOBBLE, rect.end.y - 10.0))
		if points.size() >= 2:
			sketch.line(points, color, 2.0)


static func _knot(sketch: BuildingSketch, rect: Rect2, seed_index: int, color: Color) -> void:
	var at: Vector2 = rect.get_center() + Vector2(0.0, (seed_index % 3 - 1) * rect.size.y * 0.25)
	var oval: PackedVector2Array = []
	for point: Vector2 in FeltDraw.circle(Vector2.ZERO, 1.0, 14):
		oval.append(at + point * KNOT_SIZE)
	sketch.shade(oval, color)


static func _nails(sketch: BuildingSketch, rect: Rect2, size: Vector2, color: Color) -> void:
	var left: float = rect.position.x + NAIL_INSET
	var right: float = rect.end.x - NAIL_INSET
	if rect.position.y > 0.0:
		sketch.dot(Vector2(left, rect.position.y + NAIL_INSET), NAIL_RADIUS, color)
		sketch.dot(Vector2(right, rect.position.y + NAIL_INSET), NAIL_RADIUS, color)
	if rect.end.y < size.y:
		sketch.dot(Vector2(left, rect.end.y - NAIL_INSET), NAIL_RADIUS, color)
		sketch.dot(Vector2(right, rect.end.y - NAIL_INSET), NAIL_RADIUS, color)


static func _button(sketch: BuildingSketch, at: Vector2, r: float, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	sketch.disc(&"rug_buttons", at, r, WorldPalette.pick(palette.buttons, index))
	var hole: float = r * 0.32
	for offset: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		sketch.dot(at + offset * hole, r * 0.13, palette.button_hole)


static func _block(sketch: BuildingSketch, rect: Rect2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	sketch.block(&"toy_blocks", rect.grow(-2.0), WorldPalette.pick(palette.wall_blocks, index))
	var inner: PackedVector2Array = BuildingSketch.corners(rect.grow(-rect.size.x * 0.25))
	var light: Color = Color(palette.seam_light, BLOCK_INNER_ALPHA)
	sketch.line([inner[0], inner[1], inner[2]], light, 3.0)
	sketch.line([inner[2], inner[3], inner[0]], light, 3.0)


## A gingham curtain hanging beside `frame` (`side` -1 = left, 1 = right), tied back halfway.
static func _curtain(sketch: BuildingSketch, frame: Rect2, side: float) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var edge: float = frame.position.x if side < 0.0 else frame.end.x
	var outer: float = edge + side * (CURTAIN_WIDTH + 10.0)
	var inner: float = edge + side * 6.0
	var top: float = frame.position.y - 16.0
	var tie: float = frame.position.y + frame.size.y * 0.55
	var bottom: float = frame.end.y + SILL_HEIGHT + 30.0
	var waist: float = outer - side * CURTAIN_WIDTH * 0.35
	var points: PackedVector2Array = [
		Vector2(inner, top),
		Vector2(inner, frame.position.y + 20.0),
		Vector2(waist, tie),
		Vector2(inner + side * 4.0, bottom),
		Vector2(outer, bottom),
		Vector2(outer - side * 6.0, tie),
		Vector2(outer, top),
	]
	if side > 0.0:
		points.reverse()
	sketch.piece(&"curtains", points, palette.gingham)
	var check: Color = Color(palette.gingham_check, palette.pattern_alpha)
	sketch.stripes(points, check, CURTAIN_STEP, CURTAIN_STEP / 2.0, true)
	sketch.stripes(points, check, CURTAIN_STEP, CURTAIN_STEP / 2.0, false)
	var knot: PackedVector2Array = [Vector2(waist - 14.0, tie), Vector2(outer + side * 8.0, tie)]
	sketch.rod(&"curtain_ties", knot, palette.ribbon, 7.0)


static func _bake_beams(room: BedroomRoom) -> ArrayMesh:
	var palette: WorldPalette = WorldPalette.current()
	var light: Color = palette.sunbeam
	var strength: float = light.a * room.sunbeam_strength
	var soft: float = room.sunbeam_soft_edge
	var across: PackedFloat32Array = [0.0, soft, 1.0 - soft, 1.0]
	var across_alpha: PackedFloat32Array = [0.0, 1.0, 1.0, 0.0]
	var along: PackedFloat32Array = [0.0, 0.35, 1.0]
	var along_alpha: PackedFloat32Array = [1.0, 0.8, 0.0]
	var points: PackedVector2Array = []
	var colors: PackedColorArray = []
	for index: int in room.window_centers.size():
		var c: PackedVector2Array = beam(room, index)
		for v: int in along.size() - 1:
			for u: int in across.size() - 1:
				var quad: Array[Vector2i] = [
					Vector2i(u, v), Vector2i(u + 1, v), Vector2i(u + 1, v + 1), Vector2i(u, v + 1)
				]
				for corner: int in [0, 1, 2, 0, 2, 3]:
					var at: Vector2i = quad[corner]
					var top: Vector2 = c[0].lerp(c[1], across[at.x])
					var bottom: Vector2 = c[3].lerp(c[2], across[at.x])
					points.append(top.lerp(bottom, along[at.y]))
					var alpha: float = strength * across_alpha[at.x] * along_alpha[at.y]
					colors.append(Color(light, alpha))
	var mesh: ArrayMesh = ArrayMesh.new()
	if points.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_COLOR] = colors
	var uvs: PackedVector2Array = []
	uvs.resize(points.size())
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _key(size: Vector2, wall: float, room: BedroomRoom, rugs: Array[Rect2]) -> String:
	return "%s|%s|%d|%s" % [size, wall, room.get_instance_id(), rugs]
