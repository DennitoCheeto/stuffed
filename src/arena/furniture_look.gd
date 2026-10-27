class_name FurnitureLook
extends RefCounted
## The Bedroom's furniture and the decorations of its six places (spec 05 §4.2) in the Sunny
## patchwork look: the bed with its shadow over the top-left corner, the alphabet block towers of
## block city, giant crayons, a sharpener with shavings and scribbles in the crayon corner, the
## sewing box, pincushion, scissors and a big spool with its thread trail in the sewing corner,
## and the wooden train loop round the toy box. Built once with the building art kit and baked into
## two meshes (one draw call each): FLOOR (what you walk over) and PIECES (what blocks). Two layers
## keep the kit's "all ink first" rule from hiding a piece's outline under a floor decoration.
## Look numbers in data/arena/bedroom_room.tres, colours from the world palette.

## Layers, back to front.
enum Layer { FLOOR, PIECES }

## Letters painted on the alphabet blocks (each needs a stroke glyph in `LookParts.GLYPHS`).
const BLOCK_LETTERS: String = "ABCHOPSTY"
const BLOCK_GAP: float = 5.0
const BLOCK_CORNER: float = 12.0
## Share of a block's height that shows its darker front face.
const BLOCK_FRONT: float = 0.16
const SHADE_STEPS: int = 4
const TRACK_PIECES: int = 14
const TRACK_SAMPLES: int = 8
const CAR_LENGTH: float = 150.0
const CAR_GAP: float = 26.0
const WHEEL_RADIUS: float = 9.0

## Built layers per layout and room: key -> [floor, pieces].
static var _cache: Dictionary[String, Array] = {}


## The two baked layers of `layout`'s furniture, back to front (built the first time).
static func layers(layout: FurnitureLayout, room: BedroomRoom) -> Array[BuildingSketch]:
	var key: String = "%d|%d" % [layout.get_instance_id(), room.get_instance_id()]
	if not _cache.has(key):
		var floor_layer: BuildingSketch = BuildingSketch.new()
		var pieces: BuildingSketch = BuildingSketch.new()
		for i: int in layout.pieces.size():
			_add(floor_layer, pieces, layout.pieces[i], room, i)
		_cache[key] = [floor_layer, pieces]
	var result: Array[BuildingSketch] = []
	result.assign(_cache[key])
	return result


static func _add(
	floor_layer: BuildingSketch,
	pieces: BuildingSketch,
	piece: FurniturePiece,
	room: BedroomRoom,
	index: int
) -> void:
	var rect: Rect2 = piece.rect
	match piece.kind:
		FurniturePiece.Kind.BED:
			bed_shade(floor_layer, rect, room)
			bed(pieces, rect)
		FurniturePiece.Kind.TOY_BOX:
			toy_box(pieces, rect)
		FurniturePiece.Kind.BLOCK_TOWER:
			tower(pieces, rect, index)
		FurniturePiece.Kind.CRAYON:
			crayon(pieces, rect, index)
		FurniturePiece.Kind.SHARPENER:
			shavings(floor_layer, rect)
			sharpener(pieces, rect)
		FurniturePiece.Kind.SCRIBBLES:
			scribbles(floor_layer, rect, room)
		FurniturePiece.Kind.SEWING_BOX:
			sewing_box(pieces, rect)
		FurniturePiece.Kind.PINCUSHION:
			pincushion(pieces, rect)
		FurniturePiece.Kind.SCISSORS:
			scissors(floor_layer, rect)
		FurniturePiece.Kind.SPOOL:
			spool(floor_layer, rect, room, index)
		FurniturePiece.Kind.TRAIN_TRACK:
			train_loop(floor_layer, rect, room)


## The bed's shadow: a few soft see-through layers that dim the corner around the bed.
static func bed_shade(sketch: BuildingSketch, rect: Rect2, room: BedroomRoom) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var alpha: float = palette.shadow.a * room.bed_shade_strength / SHADE_STEPS
	var color: Color = Color(palette.shadow, alpha)
	for step: int in SHADE_STEPS:
		var reach: float = room.bed_shade_reach * (step + 1.0) / SHADE_STEPS
		var start: Vector2 = rect.position - Vector2.ONE * reach * 0.3
		var area: Rect2 = Rect2(start, rect.end + Vector2.ONE * reach - start)
		sketch.shade(FeltDraw.rounded(area, reach * 0.8), color)
	sketch.mark(&"bed_shadow")


## The bed seen from above: a wooden frame, a pillow with a sleeping teddy, a checked blanket.
static func bed(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	_shadow(sketch, FeltDraw.rounded(rect, 36.0))
	sketch.piece(&"bed", FeltDraw.rounded(rect, 36.0), palette.bed_frame, true)
	var inner: Rect2 = rect.grow(-30.0)
	var pillow_height: float = inner.size.y * 0.18
	var pillow: Rect2 = Rect2(inner.position, Vector2(inner.size.x, pillow_height)).grow(-12.0)
	sketch.shade(FeltDraw.rounded(pillow, 40.0), palette.bed_pillow)
	sketch.seam(FeltDraw.rounded(pillow.grow(-10.0), 30.0), true)
	sketch.mark(&"pillow")
	var teddy: Vector2 = pillow.get_center() + Vector2(-pillow.size.x * 0.2, 6.0)
	LookParts.teddy_head(sketch, &"bed_teddy", teddy, 34.0, true)
	var top: Vector2 = inner.position + Vector2(0.0, pillow_height)
	var blanket: Rect2 = Rect2(top, inner.size - Vector2(0.0, pillow_height))
	var cover: PackedVector2Array = FeltDraw.rounded(blanket, 26.0)
	sketch.shade(cover, palette.bed_blanket)
	var check: Color = Color(palette.bed_fold, palette.pattern_alpha)
	sketch.stripes(cover, check, 120.0, 60.0, true)
	sketch.stripes(cover, check, 120.0, 60.0, false)
	var fold: Rect2 = Rect2(blanket.position, Vector2(blanket.size.x, 70.0))
	sketch.shade(FeltDraw.rounded(fold, 26.0), palette.bed_fold)
	var hem: float = fold.end.y - 14.0
	sketch.seam([Vector2(fold.position.x + 20.0, hem), Vector2(fold.end.x - 20.0, hem)])
	sketch.mark(&"blanket")


## The toy box: a sewn wooden chest with a lid and a painted band.
static func toy_box(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	_shadow(sketch, FeltDraw.rounded(rect, 24.0))
	sketch.piece(&"toy_box", FeltDraw.rounded(rect, 24.0), palette.toy_box, true)
	var lid: Rect2 = Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.35)).grow(-10.0)
	sketch.shade(FeltDraw.rounded(lid, 18.0), palette.toy_box_lid)
	var band_width: float = 44.0
	var band_left: float = rect.get_center().x - band_width / 2.0
	var band: Rect2 = Rect2(band_left, rect.position.y + 6.0, band_width, rect.size.y - 12.0)
	sketch.shade(FeltDraw.rounded(band, 10.0), palette.toy_box_band)
	var clasp: Vector2 = Vector2(rect.get_center().x, lid.end.y + 4.0)
	sketch.dot(clasp, 12.0, palette.brass)
	sketch.dot(clasp, 5.0, palette.brass_dark)
	sketch.mark(&"toy_box_lid")


## An alphabet block tower seen from above: four letter blocks with one more stacked on top.
static func tower(sketch: BuildingSketch, rect: Rect2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	_shadow(sketch, FeltDraw.rounded(rect.grow(-BLOCK_GAP), BLOCK_CORNER))
	var half: Vector2 = rect.size / 2.0
	for i: int in 4:
		var cell: Rect2 = Rect2(rect.position + Vector2(i % 2, floorf(i / 2.0)) * half, half)
		var color: Color = WorldPalette.pick(palette.tower_blocks, i + index)
		var block: Rect2 = cell.grow(-BLOCK_GAP)
		sketch.piece(&"alphabet_blocks", FeltDraw.rounded(block, BLOCK_CORNER), color)
		_block_face(sketch, block, color, index * 3 + i)
	var top: Rect2 = Rect2(rect.position + half * 0.5 - Vector2(8.0, 12.0), half)
	var color_top: Color = WorldPalette.pick(palette.tower_blocks, index + 2)
	LookParts.outlined(sketch, FeltDraw.rounded(top, BLOCK_CORNER), color_top)
	_block_face(sketch, top, color_top, index * 3 + 5)
	sketch.mark(&"block_letters")


## A block's darker front face and its painted letter.
static func _block_face(sketch: BuildingSketch, block: Rect2, color: Color, letter: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var front_height: float = block.size.y * BLOCK_FRONT
	var front: Rect2 = Rect2(block.position, Vector2(block.size.x, front_height))
	front.position.y = block.end.y - front_height
	var shape: PackedVector2Array = FeltDraw.rounded(block, BLOCK_CORNER)
	LookParts.clip_shade(sketch, shape, front, color.darkened(0.16))
	var face: Rect2 = Rect2(block.position, block.size - Vector2(0.0, front_height))
	var size: float = face.size.x * 0.075
	var text: String = BLOCK_LETTERS[posmod(letter, BLOCK_LETTERS.length())]
	var at: Vector2 = face.get_center() - Vector2(2.0, 3.0) * size
	LookParts.letters(sketch, text, at, size, Color(palette.ink, 0.55), size * 0.7)


## A giant crayon lying on the floor (along its rect's long side): a paper wrapper and a
## sharpened tip. Odd ones point the other way.
static func crayon(sketch: BuildingSketch, rect: Rect2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var color: Color = WorldPalette.pick(palette.crayons, index)
	var flat: bool = rect.size.x >= rect.size.y
	var length: float = maxf(rect.size.x, rect.size.y)
	var thick: float = minf(rect.size.x, rect.size.y)
	var place: Transform2D = _along(rect, flat, index % 2 == 1)
	var tip: float = thick * 1.1
	var body: float = length - tip
	var outline: PackedVector2Array = [
		Vector2(10.0, 0.0),
		Vector2(body, 0.0),
		Vector2(length - 12.0, thick * 0.38),
		Vector2(length - 4.0, thick * 0.5),
		Vector2(length - 12.0, thick * 0.62),
		Vector2(body, thick),
		Vector2(10.0, thick),
		Vector2(0.0, thick - 10.0),
		Vector2(0.0, 10.0),
	]
	var shape: PackedVector2Array = _placed(place, outline)
	_shadow(sketch, shape)
	sketch.piece(&"crayon", shape, color)
	var paper: Rect2 = Rect2(thick * 0.5, 0.0, body - thick * 0.9, thick)
	sketch.shade(_placed(place, BuildingSketch.corners(paper)), palette.crayon_paper)
	for x: float in [paper.position.x + 14.0, paper.end.x - 14.0]:
		var band: Rect2 = Rect2(x - 5.0, 0.0, 10.0, thick)
		sketch.shade(_placed(place, BuildingSketch.corners(band)), color)
	var wave: PackedVector2Array = []
	for i: int in 9:
		var x: float = paper.position.x + 34.0 + (paper.size.x - 68.0) * i / 8.0
		wave.append(Vector2(x, thick * (0.5 + 0.12 * sin(i * 1.6))))
	sketch.line(_placed(place, wave), color, 5.0)
	var side: Rect2 = Rect2(0.0, thick * 0.78, body, thick * 0.22)
	sketch.shade(_placed(place, BuildingSketch.corners(side)), Color(palette.ink, 0.1))
	var shine: Rect2 = Rect2(12.0, thick * 0.14, body - 24.0, thick * 0.1)
	sketch.shade(_placed(place, BuildingSketch.corners(shine)), Color(palette.glass_shine, 0.3))
	sketch.mark(&"crayon_paper")


## The soft floor shadow of a piece shaped like `shape` (light from the top-left).
static func _shadow(sketch: BuildingSketch, shape: PackedVector2Array) -> void:
	sketch.shadow(Transform2D(0.0, LookParts.SHADOW_NUDGE * 1.6) * shape)


## Maps crayon units (x along the crayon, y across) onto `rect`.
static func _along(rect: Rect2, flat: bool, flip: bool) -> Transform2D:
	var along: Vector2 = Vector2.RIGHT if flat else Vector2.DOWN
	var across: Vector2 = Vector2.DOWN if flat else Vector2.RIGHT
	var origin: Vector2 = rect.position
	if flip:
		origin += along * maxf(rect.size.x, rect.size.y)
		along = -along
	return Transform2D(along, across, origin)


## `points` moved by `place`, still clockwise on screen (the kit's outline needs that).
static func _placed(place: Transform2D, points: PackedVector2Array) -> PackedVector2Array:
	var moved: PackedVector2Array = place * points
	if place.determinant() < 0.0:
		moved.reverse()
	return moved


## The crayon sharpener: a metal block with the hole and the blade screw.
static func sharpener(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var body: PackedVector2Array = FeltDraw.rounded(rect, 22.0)
	_shadow(sketch, body)
	sketch.piece(&"sharpener", body, palette.metal, true)
	var front: Rect2 = Rect2(rect.position.x, rect.end.y - 40.0, rect.size.x, 40.0)
	LookParts.clip_shade(sketch, body, front, palette.metal_dark)
	var hole: Vector2 = rect.position + Vector2(rect.size.x * 0.3, rect.size.y * 0.42)
	sketch.dot(hole, rect.size.y * 0.24, palette.metal_dark)
	sketch.dot(hole, rect.size.y * 0.16, palette.box_inside)
	var blade_x: float = rect.position.x + rect.size.x * 0.62
	var blade_size: Vector2 = Vector2(rect.size.x * 0.28, rect.size.y - 80.0)
	var blade: Rect2 = Rect2(Vector2(blade_x, rect.position.y + 24.0), blade_size)
	sketch.shade(FeltDraw.rounded(blade, 8.0), palette.glass)
	var screw: Vector2 = blade.get_center()
	sketch.dot(screw, 11.0, palette.metal_dark)
	sketch.line([screw - Vector2(6.0, 6.0), screw + Vector2(6.0, 6.0)], palette.metal, 3.0)
	sketch.mark(&"sharpener_blade")


## Curly crayon shavings on the floor below and right of the sharpener.
static func shavings(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	for i: int in 7:
		var x: float = rect.position.x + rect.size.x * (0.05 + 0.2 * i)
		var at: Vector2 = Vector2(x, rect.end.y + 46.0 + (i % 2) * 44.0)
		var frill: PackedVector2Array = []
		for k: int in 24:
			var angle: float = TAU * k / 24.0
			frill.append(at + Vector2.from_angle(angle) * 24.0 * (1.0 + 0.16 * sin(angle * 8.0)))
		sketch.piece(&"shavings", frill, WorldPalette.pick(palette.crayons, i))
		sketch.dot(at, 13.0, palette.pencil_wood)
		sketch.dot(at, 4.0, palette.wood_side)


## See-through crayon scribbles on the floorboards: zigzags, waves and spirals (open lines that
## never cross themselves, so none of them bakes as a blob).
static func scribbles(sketch: BuildingSketch, rect: Rect2, room: BedroomRoom) -> void:
	var palette: WorldPalette = WorldPalette.current()
	for s: int in room.scribble_count:
		var spot: Vector2 = Vector2(fposmod(s * 0.618 + 0.1, 1.0), fposmod(s * 0.382 + 0.27, 1.0))
		var inside: Rect2 = rect.grow(-120.0)
		var at: Vector2 = inside.position + inside.size * spot
		var turn: Transform2D = Transform2D(s * 0.9, at)
		var points: PackedVector2Array = []
		match s % 3:
			0:
				for i: int in 9:
					points.append(Vector2(-140.0 + 35.0 * i, 50.0 if i % 2 == 0 else -50.0))
			1:
				for i: int in 25:
					var t: float = i / 24.0
					points.append(Vector2(-160.0 + 320.0 * t, sin(t * TAU * 2.0) * 40.0))
			_:
				for i: int in 40:
					var angle: float = i * 0.4
					points.append(Vector2.from_angle(angle) * (12.0 + i * 2.2))
		var color: Color = Color(WorldPalette.pick(palette.crayons, s), room.scribble_alpha)
		sketch.line(turn * points, color, room.scribble_width)
	sketch.mark(&"scribbles")


## The sewing box: a wooden box with a quilted gingham lid, a brass handle and two little spools.
static func sewing_box(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var body: PackedVector2Array = FeltDraw.rounded(rect, 22.0)
	_shadow(sketch, body)
	sketch.piece(&"sewing_box", body, palette.wood)
	var front: Rect2 = Rect2(rect.position.x, rect.end.y - 54.0, rect.size.x, 54.0)
	LookParts.clip_shade(sketch, body, front, palette.wood_side)
	var lid: Rect2 = Rect2(rect.position, rect.size - Vector2(0.0, 54.0)).grow(-22.0)
	var quilt: PackedVector2Array = FeltDraw.rounded(lid, 16.0)
	sketch.shade(quilt, palette.gingham)
	var check: Color = Color(palette.gingham_check, palette.pattern_alpha)
	sketch.stripes(quilt, check, 36.0, 18.0, true)
	sketch.stripes(quilt, check, 36.0, 18.0, false)
	sketch.seam(FeltDraw.rounded(lid.grow(-12.0), 10.0), true)
	sketch.mark(&"sewing_lid")
	var middle: Vector2 = lid.get_center()
	var handle: PackedVector2Array = [middle - Vector2(70.0, 0.0), middle + Vector2(70.0, 0.0)]
	sketch.line(handle, palette.brass_dark, 20.0)
	sketch.line(handle, palette.brass, 12.0)
	var clasp: Vector2 = Vector2(rect.get_center().x, front.position.y + 20.0)
	sketch.dot(clasp, 13.0, palette.brass)
	for i: int in 2:
		var at: Vector2 = lid.position + Vector2(lid.size.x * (0.2 + 0.6 * i), lid.size.y * 0.7)
		var thread: Color = WorldPalette.pick(palette.thread_paths, i + 1)
		LookParts.outlined(sketch, FeltDraw.circle(at, 30.0, 20), palette.wood_top)
		sketch.dot(at, 22.0, thread)
		sketch.dot(at, 7.0, palette.wood_side)
	sketch.mark(&"sewing_spools")


## A tomato pincushion with its leaf and pins sticking out.
static func pincushion(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var middle: Vector2 = rect.get_center()
	var r: float = minf(rect.size.x, rect.size.y) / 2.0 - 4.0
	var cushion: PackedVector2Array = FeltDraw.circle(middle, r, 32)
	_shadow(sketch, cushion)
	sketch.piece(&"pincushion", cushion, palette.pincushion)
	var low: Rect2 = Rect2(middle.x - r, middle.y + r * 0.45, r * 2.0, r)
	LookParts.clip_shade(sketch, cushion, low, palette.pincushion_dark)
	for i: int in 6:
		var angle: float = TAU * i / 6.0 + 0.3
		var bend: Vector2 = Vector2.from_angle(angle + 0.25) * r * 0.55
		var segment: PackedVector2Array = [
			middle + Vector2.from_angle(angle) * r * 0.2,
			middle + bend,
			middle + Vector2.from_angle(angle) * r * 0.95,
		]
		sketch.line(segment, palette.pincushion_dark, 4.0)
	var leaf: PackedVector2Array = BuildingSketch.star(middle, r * 0.3)
	sketch.shade(leaf, palette.clover)
	sketch.mark(&"tomato_leaf")
	for i: int in 6:
		var angle: float = TAU * i / 6.0
		var head: Vector2 = middle + Vector2.from_angle(angle) * r * 0.62
		var shaft: Vector2 = head + Vector2.from_angle(angle + 0.8) * 26.0
		sketch.line([shaft, head], palette.metal_dark, 4.0)
		sketch.dot(head, 11.0, WorldPalette.pick(palette.buttons, i))
		sketch.dot(head - Vector2(3.0, 3.0), 3.5, palette.glass_shine)
	sketch.mark(&"pins")


## Giant scissors lying open on the floor (you walk over them).
static func scissors(sketch: BuildingSketch, rect: Rect2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var pivot: Vector2 = rect.position + rect.size * Vector2(0.42, 0.5)
	var tips: Array[Vector2] = [
		Vector2(rect.end.x - 6.0, pivot.y - rect.size.y * 0.3),
		Vector2(rect.end.x - 20.0, pivot.y + rect.size.y * 0.16),
	]
	var rings: Array[Vector2] = [
		Vector2(rect.position.x + 64.0, pivot.y - rect.size.y * 0.24),
		Vector2(rect.position.x + 64.0, pivot.y + rect.size.y * 0.24),
	]
	for i: int in 2:
		var handle: Color = WorldPalette.pick(palette.toys, 3 - i)
		var ring: PackedVector2Array = []
		for k: int in 19:
			var angle: float = 0.5 + (TAU - 1.0) * k / 18.0
			ring.append(rings[i] + Vector2.from_angle(angle) * Vector2(52.0, 40.0))
		sketch.rod(&"scissor_handles", ring, handle, 22.0)
		sketch.rod(&"scissor_handles", [ring[0], pivot], handle, 22.0)
		sketch.piece(&"scissor_blades", _blade(pivot, tips[i], 18.0), palette.metal)
	sketch.disc(&"scissor_screw", pivot, 13.0, palette.brass)


## A blade from `from` to its point `to`, `width` wide at the bottom (clockwise on screen).
static func _blade(from: Vector2, to: Vector2, width: float) -> PackedVector2Array:
	var along: Vector2 = from.direction_to(to)
	var side: Vector2 = along.orthogonal() * width
	var points: PackedVector2Array = [from - along * width, from + side, to, from - side * 0.4]
	if _area(points) < 0.0:
		points.reverse()
	return points


## Twice the signed area of `points` (positive = clockwise on screen, y down).
static func _area(points: PackedVector2Array) -> float:
	var total: float = 0.0
	for i: int in points.size():
		var next: Vector2 = points[(i + 1) % points.size()]
		total += points[i].x * next.y - next.x * points[i].y
	return total


## A big spool lying in the rect's bottom-left corner, its thread running in waves across the
## floor to a needle in the top-right corner.
static func spool(sketch: BuildingSketch, rect: Rect2, room: BedroomRoom, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var thread: Color = WorldPalette.pick(palette.thread_paths, index)
	var at: Vector2 = Vector2(rect.position.x + 110.0, rect.end.y - 90.0)
	var end: Vector2 = Vector2(rect.end.x - 60.0, rect.position.y + 60.0)
	var across: Vector2 = at.direction_to(end).orthogonal()
	var trail: PackedVector2Array = []
	for i: int in 13:
		var t: float = i / 12.0
		trail.append(at.lerp(end, t) + across * sin(t * TAU * 1.5) * 70.0 * t)
	sketch.rod(&"thread_trail", TownLayout.smooth(trail), thread, room.thread_width)
	var eye: Vector2 = end + Vector2(30.0, -18.0)
	sketch.rod(&"needle", [end - Vector2(46.0, -28.0), eye], palette.metal, 8.0)
	sketch.dot(eye - Vector2(5.0, -3.0), 3.0, palette.ink)
	LookParts.footprint_shadow(sketch, Rect2(at - Vector2(90, 10), Vector2(180, 80)))
	var core: Rect2 = Rect2(at - Vector2(75, 58), Vector2(150, 116))
	sketch.block(&"big_spool", core, thread)
	var winding: Color = thread.darkened(0.18)
	var x: float = core.position.x + 8.0
	while x < core.end.x - 4.0:
		sketch.line([Vector2(x, core.position.y), Vector2(x + 4.0, core.end.y)], winding, 2.0)
		x += 12.0
	for flange_x: float in [core.position.x - 14.0, core.end.x - 14.0]:
		var flange: Rect2 = Rect2(flange_x, core.position.y - 22.0, 28.0, core.size.y + 44.0)
		sketch.piece(&"big_spool", FeltDraw.rounded(flange, 10.0), palette.wood_top)
		var side: Rect2 = Rect2(flange_x + 16.0, flange.position.y + 4.0, 10.0, flange.size.y - 8.0)
		sketch.shade(FeltDraw.rounded(side, 4.0), palette.wood)


## The wooden train track loop in the rect, made of pieces with two grooves each, and a little
## train standing on its bottom straight.
static func train_loop(sketch: BuildingSketch, rect: Rect2, room: BedroomRoom) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var width: float = room.track_width
	var loop: Rect2 = rect.grow(-width / 2.0 - 8.0)
	var total: float = _loop_length(loop)
	var groove: float = width * 0.24
	for p: int in TRACK_PIECES:
		var middle: PackedVector2Array = []
		var inner: PackedVector2Array = []
		var outer: PackedVector2Array = []
		for k: int in TRACK_SAMPLES + 1:
			var s: float = total * (p + float(k) / TRACK_SAMPLES) / TRACK_PIECES
			middle.append(_loop_point(loop, s, 0.0))
			inner.append(_loop_point(loop, s, -groove))
			outer.append(_loop_point(loop, s, groove))
		sketch.rod(&"train_track", middle, palette.wood_top, width)
		sketch.line(inner, palette.wood, 6.0)
		sketch.line(outer, palette.wood, 6.0)
		var joint: PackedVector2Array = [
			_loop_point(loop, total * p / TRACK_PIECES, -width * 0.5),
			_loop_point(loop, total * p / TRACK_PIECES, width * 0.5),
		]
		sketch.line(joint, palette.wood_side, 3.0)
	sketch.mark(&"track_grooves")
	_train(sketch, loop, width)


## Engine and two wagons on the loop's bottom straight, heading left.
static func _train(sketch: BuildingSketch, loop: Rect2, width: float) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var y: float = loop.end.y
	var front: float = loop.get_center().x - CAR_LENGTH * 1.5 - CAR_GAP
	var height: float = width + 26.0
	for car: int in 3:
		var left: float = front + car * (CAR_LENGTH + CAR_GAP)
		var body: Rect2 = Rect2(left, y - height / 2.0, CAR_LENGTH, height)
		for wheel_x: float in [left + 30.0, body.end.x - 30.0]:
			for wheel_y: float in [body.position.y - 2.0, body.end.y + 2.0]:
				sketch.dot(Vector2(wheel_x, wheel_y), WHEEL_RADIUS, palette.ink)
		var color: Color = WorldPalette.pick(palette.toys, car + 2)
		LookParts.outlined(sketch, FeltDraw.rounded(body, 14.0), color)
		if car == 0:
			var cab: Rect2 = Rect2(body.end.x - 62.0, body.position.y + 10.0, 50.0, height - 20.0)
			LookParts.outlined(sketch, FeltDraw.rounded(cab, 8.0), color.darkened(0.15))
			var chimney: Vector2 = Vector2(left + 40.0, y)
			LookParts.outlined(sketch, FeltDraw.circle(chimney, 18.0, 16), palette.metal_dark)
			sketch.dot(chimney, 9.0, palette.box_inside)
		else:
			for b: int in 2:
				var cargo: Rect2 = Rect2(left + 18.0 + b * 60.0, y - 26.0, 52.0, 52.0)
				var block: Color = WorldPalette.pick(palette.tower_blocks, car + b)
				LookParts.outlined(sketch, FeltDraw.rounded(cargo, 8.0), block)
			var hook: PackedVector2Array = [Vector2(left - CAR_GAP, y), Vector2(left, y)]
			sketch.line(hook, palette.ink, 5.0)
	sketch.mark(&"toy_train")


## How long the stadium-shaped loop through the middle of `loop` is.
static func _loop_length(loop: Rect2) -> float:
	var r: float = loop.size.y / 2.0
	return 2.0 * (loop.size.x - 2.0 * r) + TAU * r


## The point `s` px along the loop (clockwise from the top-left end of the top straight),
## `offset` px further out.
static func _loop_point(loop: Rect2, s: float, offset: float) -> Vector2:
	var r: float = loop.size.y / 2.0
	var straight: float = loop.size.x - 2.0 * r
	var left: Vector2 = Vector2(loop.position.x + r, loop.get_center().y)
	var right: Vector2 = Vector2(loop.end.x - r, loop.get_center().y)
	var d: float = fposmod(s, _loop_length(loop))
	var arc: float = PI * r
	if d < straight:
		return Vector2(left.x + d, loop.position.y - offset)
	d -= straight
	if d < arc:
		return right + Vector2.from_angle(-PI / 2.0 + d / r) * (r + offset)
	d -= arc
	if d < straight:
		return Vector2(right.x - d, loop.end.y + offset)
	d -= straight
	return left + Vector2.from_angle(PI / 2.0 + d / r) * (r + offset)
