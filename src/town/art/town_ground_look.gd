class_name TownGroundLook
extends RefCounted
## The Pillow Fort's ground in the Sunny patchwork look (spec 05 §3.1): a quilt of plain,
## gingham, polka-dot and corduroy patches with stitched seams, coloured thread paths to each
## building, the tape measure road from the fort door, props between the buildings (cushions,
## toy blocks, felt flowers, loose buttons, safety pins, marbles, spools with a thread trail) and
## the pillow walls with a rick-rack trim. Everything is built once per layout with the building
## art kit and baked into four meshes (one draw call each): quilt, paths, props, walls. Layers
## keep the kit's "all ink first" rule from hiding a prop's outline under the quilt.

## Patch kinds, in the order of `WorldPalette.quilt_patches` / `quilt_patterns`.
enum Patch { PLAIN, GINGHAM, POLKA, CORDUROY }

const SEAM_WIDTH: float = 3.0
const SEAM_DASH: float = 10.0
const SEAM_GAP: float = 8.0
const GINGHAM_STEP: float = 30.0
const POLKA_STEP: float = 40.0
const POLKA_RADIUS: float = 5.0
const CORDUROY_STEP: float = 12.0
## Every this many plain patches gets a felt star or heart.
const APPLIQUE_EVERY: int = 2
## A big sewn-on button sits on every this many seam crossings (where nothing stands on it).
const CROSSING_BUTTON_EVERY: int = 3
const CROSSING_BUTTON_RADIUS: float = 11.0
const THREAD_WIDTH: float = 4.0
const THREAD_DASH: float = 13.0
const THREAD_GAP: float = 9.0
## Tape measure ticks: one every TICK_STEP px, a long one (and a number) every LONG_TICK ticks.
const TICK_STEP: float = 14.0
const LONG_TICK: int = 5
const WALL_PILLOW: float = 220.0
const RICK_RACK_STEP: float = 16.0
const RICK_RACK_HEIGHT: float = 7.0
const RICK_RACK_WIDTH: float = 6.0

## Built layers per layout: [quilt, paths, props, walls].
static var _cache: Dictionary[TownLayout, Array] = {}


## The four baked layers of `layout`'s ground, back to front (built the first time).
static func layers(layout: TownLayout) -> Array[BuildingSketch]:
	if not _cache.has(layout):
		_cache[layout] = [quilt(layout), paths(layout), props(layout), walls(layout)]
	var result: Array[BuildingSketch] = []
	result.assign(_cache[layout])
	return result


## Which patch kind lies at column `col`, row `row`: neighbours always differ.
static func patch_at(col: int, row: int) -> Patch:
	return posmod(col + 3 * row, Patch.size()) as Patch


## Where the tape measure's numbers go (one per long tick), with the road's direction there.
static func road_numbers(layout: TownLayout) -> Array[Transform2D]:
	var marks: Array[Transform2D] = []
	var line: PackedVector2Array = layout.road_line()
	var ticks: int = 0
	for at: Transform2D in _walk(line, TICK_STEP):
		ticks += 1
		if ticks % LONG_TICK == 0 and layout.play_rect().has_point(at.origin):
			marks.append(at)
	return marks


static func quilt(layout: TownLayout) -> BuildingSketch:
	var palette: WorldPalette = WorldPalette.current()
	var sketch: BuildingSketch = BuildingSketch.new()
	var side: float = layout.quilt_patch
	var play: Rect2 = layout.play_rect()
	var cols: int = ceili(play.size.x / side)
	var rows: int = ceili(play.size.y / side)
	var plain_count: int = 0
	var appliques: int = 0
	for row: int in rows:
		for col: int in cols:
			var rect: Rect2 = Rect2(col * side, row * side, side, side).intersection(play)
			var kind: Patch = patch_at(col, row)
			sketch.shade(BuildingSketch.corners(rect), palette.quilt_patches[kind])
			var pattern: Color = Color(palette.quilt_patterns[kind], palette.pattern_alpha)
			match kind:
				Patch.GINGHAM:
					_gingham(sketch, rect, pattern)
				Patch.POLKA:
					_polka(sketch, rect, pattern)
				Patch.CORDUROY:
					sketch.stripes(BuildingSketch.corners(rect), pattern, CORDUROY_STEP, 5.0, true)
				Patch.PLAIN:
					if plain_count % APPLIQUE_EVERY == 0:
						_applique(sketch, rect.get_center(), appliques)
						appliques += 1
					plain_count += 1
	var seam: Color = palette.quilt_seam
	var x: float = side
	while x < play.size.x:
		_dashed(sketch, [Vector2(x, 0.0), Vector2(x, play.size.y)], seam, SEAM_WIDTH, SEAM_DASH)
		x += side
	var y: float = side
	while y < play.size.y:
		_dashed(sketch, [Vector2(0.0, y), Vector2(play.size.x, y)], seam, SEAM_WIDTH, SEAM_DASH)
		y += side
	return sketch


## Thread paths to the buildings, then the tape measure on top of their ends.
static func paths(layout: TownLayout) -> BuildingSketch:
	var palette: WorldPalette = WorldPalette.current()
	var sketch: BuildingSketch = BuildingSketch.new()
	for i: int in layout.spots.size():
		var line: PackedVector2Array = layout.thread_line(layout.spots[i])
		if line.size() < 2:
			continue
		var color: Color = WorldPalette.pick(palette.thread_paths, i)
		_dashed(sketch, line, color, THREAD_WIDTH, THREAD_DASH, THREAD_GAP)
		sketch.dot(line[line.size() - 1], THREAD_WIDTH * 1.4, color)
	_tape(sketch, layout)
	return sketch


static func props(layout: TownLayout) -> BuildingSketch:
	var palette: WorldPalette = WorldPalette.current()
	var sketch: BuildingSketch = BuildingSketch.new()
	_crossing_buttons(sketch, layout)
	for i: int in layout.cushions.size():
		_cushion(sketch, layout.cushions[i], WorldPalette.pick(palette.cushions, i))
	for i: int in layout.block_piles.size():
		_blocks(sketch, layout.block_piles[i], i)
	for i: int in layout.flowers.size():
		_flower(sketch, layout.flowers[i], i)
	for i: int in layout.loose_buttons.size():
		_loose_button(sketch, layout.loose_buttons[i], i)
	for i: int in layout.safety_pins.size():
		_safety_pin(sketch, layout.safety_pins[i], -0.35 + 0.7 * i)
	for i: int in layout.marbles.size():
		_marble(sketch, layout.marbles[i], i)
	for i: int in layout.spools.size():
		_spool(sketch, layout.spools[i], i)
	return sketch


## Big pillows all around the quilt (the walls are separate physics bodies), with a rick-rack
## trim along the quilt's edge.
static func walls(layout: TownLayout) -> BuildingSketch:
	var palette: WorldPalette = WorldPalette.current()
	var sketch: BuildingSketch = BuildingSketch.new()
	var outer: Rect2 = layout.outer_rect()
	var t: float = layout.wall_thickness
	var size: Vector2 = layout.size
	var index: int = 0
	var across: int = maxi(roundi(outer.size.x / WALL_PILLOW), 1)
	var width: float = outer.size.x / across
	for i: int in across:
		var x: float = outer.position.x + width * i
		var color: Color = WorldPalette.pick(palette.pillow_walls, index)
		var next: Color = WorldPalette.pick(palette.pillow_walls, index + 1)
		_pillow(sketch, Rect2(x, outer.position.y, width, t), color)
		_pillow(sketch, Rect2(x, size.y, width, t), next)
		index += 1
	var down: int = maxi(roundi(size.y / WALL_PILLOW), 1)
	var height: float = size.y / down
	for i: int in down:
		var y: float = height * i
		var color: Color = WorldPalette.pick(palette.pillow_walls, index)
		var next: Color = WorldPalette.pick(palette.pillow_walls, index + 1)
		_pillow(sketch, Rect2(-t, y, t, height), color)
		_pillow(sketch, Rect2(size.x, y, t, height), next)
		index += 1
	var corners: PackedVector2Array = BuildingSketch.corners(layout.play_rect())
	for i: int in corners.size():
		var from: Vector2 = corners[i]
		var to: Vector2 = corners[(i + 1) % corners.size()]
		sketch.rod(&"rick_rack", _zigzag(from, to), palette.rick_rack, RICK_RACK_WIDTH)
	return sketch


## Dashes of `color` along `line` (seams, thread paths), `width` thick.
static func _dashed(
	sketch: BuildingSketch,
	line: PackedVector2Array,
	color: Color,
	width: float,
	dash: float,
	gap: float = SEAM_GAP
) -> void:
	var period: float = dash + gap
	var walked: float = 0.0
	var current: PackedVector2Array = []
	for i: int in range(1, line.size()):
		var from: Vector2 = line[i - 1]
		var to: Vector2 = line[i]
		var length: float = from.distance_to(to)
		var along: float = 0.0
		while along < length:
			var phase: float = fmod(walked, period)
			var left: float = (dash - phase) if phase < dash else (period - phase)
			var step: float = minf(left, length - along)
			if phase < dash:
				if current.is_empty():
					current.append(from.lerp(to, along / length))
				current.append(from.lerp(to, (along + step) / length))
				if step >= left:
					sketch.line(current, color, width)
					current = PackedVector2Array()
			along += step
			walked += step
	if current.size() >= 2:
		sketch.line(current, color, width)


## Points every `step` px along `line`, each with the line's direction there (x axis = along).
static func _walk(line: PackedVector2Array, step: float) -> Array[Transform2D]:
	var result: Array[Transform2D] = []
	var next: float = step
	var walked: float = 0.0
	for i: int in range(1, line.size()):
		var from: Vector2 = line[i - 1]
		var to: Vector2 = line[i]
		var length: float = from.distance_to(to)
		if length <= 0.0:
			continue
		while next <= walked + length:
			var at: Vector2 = from.lerp(to, (next - walked) / length)
			result.append(Transform2D((to - from).angle(), at))
			next += step
		walked += length
	return result


static func _gingham(sketch: BuildingSketch, rect: Rect2, color: Color) -> void:
	var area: PackedVector2Array = BuildingSketch.corners(rect)
	sketch.stripes(area, color, GINGHAM_STEP, GINGHAM_STEP / 2.0, true)
	sketch.stripes(area, color, GINGHAM_STEP, GINGHAM_STEP / 2.0, false)


static func _polka(sketch: BuildingSketch, rect: Rect2, color: Color) -> void:
	var row: int = 0
	var y: float = rect.position.y + POLKA_STEP / 2.0
	while y < rect.end.y:
		var x: float = rect.position.x + POLKA_STEP * (0.25 if row % 2 == 0 else 0.75)
		while x < rect.end.x:
			sketch.shade(FeltDraw.circle(Vector2(x, y), POLKA_RADIUS, 10), color)
			x += POLKA_STEP
		y += POLKA_STEP
		row += 1


## A felt star or heart sewn onto a plain patch.
static func _applique(sketch: BuildingSketch, at: Vector2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var shape: PackedVector2Array = BuildingSketch.star(at, 26.0)
	if index % 2 == 1:
		shape = _heart(at, 24.0)
	sketch.shade(shape, WorldPalette.pick(palette.quilt_appliques, index))
	for inner: PackedVector2Array in Geometry2D.offset_polygon(shape, -4.0):
		sketch.seam(inner, true)


static func _heart(at: Vector2, r: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in 24:
		var a: float = TAU * i / 24.0
		var x: float = 16.0 * pow(sin(a), 3)
		var y: float = 13.0 * cos(a) - 5.0 * cos(2.0 * a) - 2.0 * cos(3.0 * a) - cos(4.0 * a)
		points.append(at + Vector2(x, -y) * (r / 16.0))
	return points


## The tape measure: a yellow band with an ink outline, an edge stripe, ticks on both edges and
## a metal tab where it comes out of the fort door.
static func _tape(sketch: BuildingSketch, layout: TownLayout) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var line: PackedVector2Array = layout.road_line()
	if line.size() < 2:
		return
	var half: float = layout.road_width / 2.0
	sketch.rod(&"tape_measure", line, palette.road_tape[0], layout.road_width)
	var ticks: int = 0
	for at: Transform2D in _walk(line, TICK_STEP):
		ticks += 1
		var across: Vector2 = at.y.normalized()
		var long: bool = ticks % LONG_TICK == 0
		var length: float = half * (0.55 if long else 0.3)
		for edge: float in [-1.0, 1.0]:
			var outer: Vector2 = at.origin + across * edge * (half - 4.0)
			var inner: Vector2 = outer - across * edge * length
			sketch.line([outer, inner], palette.tape_ticks, 2.0 if long else 1.4)
	for edge: float in [-1.0, 1.0]:
		var stripe: PackedVector2Array = []
		for at: Transform2D in _walk(line, 6.0):
			stripe.append(at.origin + at.y.normalized() * edge * (half - 2.5))
		sketch.line(stripe, palette.road_tape[1], 3.0)
	var start: Vector2 = line[0]
	var direction: Vector2 = (line[1] - line[0]).normalized()
	var side: Vector2 = direction.orthogonal() * (half + 3.0)
	var tab: PackedVector2Array = [start + side, start - side]
	tab.append(start - side + direction * 12.0)
	tab.append(start + side + direction * 12.0)
	sketch.piece(&"tape_tab", tab, palette.metal)
	var groove: Vector2 = start + direction * 9.0
	sketch.line([groove + side, groove - side], palette.metal_dark)


## Big buttons sewn where quilt seams cross, where nothing stands on them and off the road.
static func _crossing_buttons(sketch: BuildingSketch, layout: TownLayout) -> void:
	var side: float = layout.quilt_patch
	var road: PackedVector2Array = layout.road_line()
	var count: int = 0
	var x: float = side
	while x < layout.size.x:
		var y: float = side
		while y < layout.size.y:
			var at: Vector2 = Vector2(x, y)
			count += 1
			if count % CROSSING_BUTTON_EVERY == 0 and _is_free(layout, at, road, 50.0):
				LookParts.button(sketch, at, CROSSING_BUTTON_RADIUS, count)
			y += side
		x += side


## True when nothing blocking, no road and no thread path lies within `margin` of `at`.
static func _is_free(
	layout: TownLayout, at: Vector2, road: PackedVector2Array, margin: float
) -> bool:
	for rect: Rect2 in layout.blocking_rects():
		if rect.grow(margin).has_point(at):
			return false
	if _near_line(road, at, margin + layout.road_width / 2.0):
		return false
	for each: TownSpot in layout.spots:
		if _near_line(layout.thread_line(each), at, margin):
			return false
	return true


static func _near_line(line: PackedVector2Array, at: Vector2, distance: float) -> bool:
	for i: int in range(1, line.size()):
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(at, line[i - 1], line[i])
		if nearest.distance_to(at) < distance:
			return true
	return false


## A loose cushion (plushies like to sit on it): a sewn rounded felt pillow with a button.
static func _cushion(sketch: BuildingSketch, at: Vector2, color: Color) -> void:
	var rect: Rect2 = Rect2(at - Vector2(70, 50), Vector2(140, 100))
	var shape: PackedVector2Array = FeltDraw.rounded(rect, 26.0)
	var under: Rect2 = Rect2(rect.position + LookParts.SHADOW_NUDGE, rect.size)
	sketch.shadow(FeltDraw.rounded(under, 26.0))
	sketch.piece(&"cushion", shape, color, true)
	var shade: Rect2 = Rect2(rect.position.x, rect.end.y - 22.0, rect.size.x, 22.0)
	LookParts.clip_shade(sketch, shape, shade, Color(WorldPalette.current().ink, 0.08))
	LookParts.button(sketch, at, 9.0, 1)


## Three toy blocks, one stacked on the other two.
static func _blocks(sketch: BuildingSketch, at: Vector2, seed_index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var spots: Array[Vector2] = [Vector2(-60, 0), Vector2(0, 0), Vector2(-30, -48)]
	for i: int in spots.size():
		var rect: Rect2 = Rect2(at + spots[i], Vector2(56, 52))
		if i < 2:
			LookParts.footprint_shadow(sketch, rect)
		var color: Color = WorldPalette.pick(palette.prop_blocks, i + seed_index)
		sketch.block(&"toy_block", rect, color, true)
		var top: Rect2 = Rect2(rect.position, Vector2(rect.size.x, 12.0))
		sketch.shade(BuildingSketch.corners(top), Color(palette.glass_shine, 0.3))


## A felt flower: five round petals around a yellow middle.
static func _flower(sketch: BuildingSketch, at: Vector2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var petal: Color = WorldPalette.pick(palette.flower_petals, index)
	var turn: float = 0.4 * index
	for i: int in 5:
		var offset: Vector2 = Vector2.from_angle(turn + TAU * i / 5.0) * 11.0
		sketch.disc(&"flower", at + offset, 8.0, petal)
	sketch.disc(&"flower", at, 6.0, palette.flower_middle)
	sketch.seam(FeltDraw.circle(at, 3.0, 8), true)


## A big sewing button dropped on the quilt: outlined, a raised rim and four holes.
static func _loose_button(sketch: BuildingSketch, at: Vector2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var color: Color = WorldPalette.pick(palette.buttons, index)
	sketch.shadow(LookParts.oval(at + Vector2(5, 6), 15.0, 13.0))
	sketch.disc(&"button", at, 15.0, color)
	var rim: PackedVector2Array = FeltDraw.circle(at, 10.5, 16)
	rim.append(rim[0])
	sketch.line(rim, color.darkened(0.15), 2.0)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		sketch.dot(at + corner * 3.6, 2.0, palette.button_hole)
	sketch.dot(at + Vector2(-6, -7), 2.5, Color(palette.glass_shine, 0.6))


## A safety pin lying on the quilt, turned by `angle`.
static func _safety_pin(sketch: BuildingSketch, at: Vector2, angle: float) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var along: Vector2 = Vector2.from_angle(angle)
	var across: Vector2 = along.orthogonal()
	var head: Vector2 = at + along * 34.0
	var coil: Vector2 = at - along * 34.0
	var wire: PackedVector2Array = [coil + across * 6.0, head + across * 6.0]
	wire.append(head - across * 6.0)
	wire.append(coil - across * 6.0)
	sketch.rod(&"safety_pin", wire, palette.metal, 3.0)
	sketch.disc(&"safety_pin", coil, 7.0, palette.metal)
	sketch.dot(coil, 3.5, palette.metal_dark)
	var cap: PackedVector2Array = [head + across * 10.0 - along * 6.0, head + across * 10.0]
	cap.append(head + along * 8.0)
	cap.append(head - across * 10.0)
	cap.append(head - across * 10.0 - along * 6.0)
	sketch.piece(&"safety_pin", cap, palette.metal_dark)


## A glass marble with a coloured swirl and a shine.
static func _marble(sketch: BuildingSketch, at: Vector2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	sketch.shadow(LookParts.oval(at + Vector2(6, 9), 15.0, 7.0))
	sketch.disc(&"marble", at, 15.0, WorldPalette.pick(palette.marbles, index))
	var swirl: PackedVector2Array = [at + Vector2(-9, 4), at + Vector2(-2, -4)]
	swirl.append(at + Vector2(5, 2))
	swirl.append(at + Vector2(9, -5))
	sketch.line(swirl, WorldPalette.pick(palette.toys, index + 1), 3.5)
	sketch.dot(at + Vector2(-5, -6), 4.0, palette.glass_shine)


## A cotton spool lying on its side with a wavy thread trail running off across the quilt.
static func _spool(sketch: BuildingSketch, at: Vector2, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var thread: Color = WorldPalette.pick(palette.thread_paths, index + 2)
	var away: float = 1.0 if index % 2 == 0 else -1.0
	var trail: PackedVector2Array = []
	for i: int in 9:
		var t: float = float(i) / 8.0
		var wave: float = sin(t * TAU * 1.5) * 22.0
		trail.append(at + Vector2(-away * (20.0 + t * 190.0), 30.0 + t * 110.0 + wave))
	sketch.rod(&"spool_thread", TownLayout.smooth(trail), thread, 3.0)
	LookParts.footprint_shadow(sketch, Rect2(at - Vector2(36, 4), Vector2(72, 30)))
	var core: Rect2 = Rect2(at - Vector2(28, 22), Vector2(56, 44))
	sketch.block(&"spool", core, thread)
	var winding: Color = thread.darkened(0.18)
	var x: float = core.position.x + 5.0
	while x < core.end.x - 2.0:
		sketch.line([Vector2(x, core.position.y), Vector2(x + 2.0, core.end.y)], winding, 1.2)
		x += 6.0
	for end: float in [core.position.x - 6.0, core.end.x - 6.0]:
		var flange: Rect2 = Rect2(end, core.position.y - 9.0, 12.0, core.size.y + 18.0)
		sketch.piece(&"spool", FeltDraw.rounded(flange, 4.0), palette.wood_top)
		var side: Rect2 = Rect2(end + 7.0, flange.position.y, 5.0, flange.size.y)
		sketch.shade(BuildingSketch.corners(side), palette.wood)


## A wall pillow: a sewn rounded felt pillow, a seam line where it meets the next one.
static func _pillow(sketch: BuildingSketch, rect: Rect2, color: Color) -> void:
	var radius: float = minf(rect.size.x, rect.size.y) * 0.3
	sketch.piece(&"pillow_wall", FeltDraw.rounded(rect, radius), color, true)


## A zigzag (rick-rack) from `from` to `to`.
static func _zigzag(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var length: float = from.distance_to(to)
	var along: Vector2 = (to - from) / length
	var across: Vector2 = along.orthogonal()
	var steps: int = maxi(roundi(length / RICK_RACK_STEP), 1)
	for i: int in steps + 1:
		var side: float = RICK_RACK_HEIGHT if i % 2 == 0 else -RICK_RACK_HEIGHT
		points.append(from + along * (length * i / steps) + across * side)
	return points
