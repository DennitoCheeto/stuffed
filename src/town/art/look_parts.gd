class_name LookParts
extends RefCounted
## Small pieces the building looks share (spec 05 §2.2): cotton reels, pin flags, fairy lights,
## bunting, teddy heads, ovals and the contact shadow. All of them draw into a `BuildingSketch`
## in design units, with colours from the world palette.

## How far a floor shadow sits right and down of the object's footprint (light from the top-left).
const SHADOW_NUDGE: Vector2 = Vector2(9.0, 5.0)


## The floor shadow under a footprint `rect` (its floor area in 3/4 view), nudged right and down.
static func footprint_shadow(sketch: BuildingSketch, rect: Rect2) -> void:
	var nudged: Rect2 = Rect2(rect.position + SHADOW_NUDGE, rect.size)
	sketch.shadow(BuildingSketch.corners(nudged))


## The floor shadow of a box in 3/4 view: its front bottom edge from `left` (`width` wide) and the
## side going back by `depth`, nudged right and down like the Armory's.
static func box_shadow(sketch: BuildingSketch, left: float, width: float, depth: Vector2) -> void:
	var front_left: Vector2 = Vector2(left, 0.0) + SHADOW_NUDGE
	var front_right: Vector2 = Vector2(left + width, 0.0) + SHADOW_NUDGE
	sketch.shadow([front_left, front_right, front_right + depth, front_left + depth])


## Points around an oval (a flat round thing seen from the 3/4 view).
static func oval(center: Vector2, rx: float, ry: float, segments: int = 18) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in segments:
		points.append(center + Vector2.from_angle(TAU * i / segments) * Vector2(rx, ry))
	return points


## A flat disc seen from the side with chamfered ends (a reel's flange, a plate, a table top):
## `hw` half wide, `thick` high, standing on `bottom`. The lower half is shaded.
static func flange(
	sketch: BuildingSketch,
	part: StringName,
	at: Vector2,
	hw: float,
	thick: float,
	top_color: Color,
	side_color: Color
) -> void:
	var mid: float = at.y - thick / 2.0
	var cut: float = minf(thick * 0.5, hw * 0.3)
	var disc: PackedVector2Array = [
		Vector2(at.x - hw, mid),
		Vector2(at.x - hw + cut, at.y),
		Vector2(at.x + hw - cut, at.y),
		Vector2(at.x + hw, mid),
		Vector2(at.x + hw - cut, at.y - thick),
		Vector2(at.x - hw + cut, at.y - thick),
	]
	sketch.piece(part, disc, top_color)
	sketch.shade([disc[0], disc[1], disc[2], disc[3]], side_color)


## A cotton reel standing on `foot` (bottom middle): flange, thread with windings, flange.
## `hw` is the thread's half width, `h` its height. Returns the y of the reel's top.
static func reel(
	sketch: BuildingSketch,
	part: StringName,
	foot: Vector2,
	hw: float,
	h: float,
	flange_thick: float,
	thread: Color
) -> float:
	var palette: WorldPalette = WorldPalette.current()
	var overhang: float = maxf(hw * 0.3, 5.0)
	flange(sketch, part, foot, hw + overhang, flange_thick, palette.wood_top, palette.wood)
	var core: Rect2 = Rect2(foot.x - hw, foot.y - flange_thick - h, hw * 2.0, h)
	sketch.block(part, core, thread)
	var winding: Color = thread.darkened(0.18)
	var y: float = core.position.y + 4.0
	while y < core.end.y - 2.0:
		var wind: PackedVector2Array = [Vector2(core.position.x, y), Vector2(core.end.x, y + 1.5)]
		sketch.line(wind, winding, 1.2)
		y += 6.0
	var side: Rect2 = Rect2(core.end.x - hw * 0.3, core.position.y, hw * 0.3, h)
	sketch.shade(BuildingSketch.corners(side), Color(palette.ink, 0.14))
	var shine: Rect2 = Rect2(core.position.x + hw * 0.18, core.position.y + 3.0, 4.0, h - 6.0)
	sketch.shade(BuildingSketch.corners(shine), Color(palette.glass_shine, 0.35))
	var top: Vector2 = Vector2(foot.x, core.position.y)
	flange(sketch, part, top, hw + overhang, flange_thick, palette.wood_top, palette.wood)
	return core.position.y - flange_thick


## A sewing pin as a flag pole with a felt pennant and a round pin head.
static func pin_flag(
	sketch: BuildingSketch, part: StringName, foot: Vector2, height: float, color: Color
) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var top: Vector2 = foot - Vector2(0.0, height)
	sketch.rod(part, [foot, top], palette.metal, 3.0)
	var cloth: PackedVector2Array = [
		top + Vector2(1.0, 4.0), top + Vector2(34.0, 13.0), top + Vector2(1.0, 24.0)
	]
	sketch.piece(part, cloth, color)
	sketch.seam([cloth[0] + Vector2(4.0, 5.0), cloth[2] + Vector2(4.0, -5.0)])
	sketch.disc(part, top, 5.0, palette.brass)


## A cord of soft bulbs sagging from `from` to `to` (`sag` units down in the middle).
static func fairy_lights(
	sketch: BuildingSketch, part: StringName, from: Vector2, to: Vector2, sag: float, count: int
) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var cord: PackedVector2Array = sagging(from, to, sag, count)
	sketch.line(cord, palette.light_cord, 2.0)
	for i: int in count:
		var bulb: Vector2 = cord[i] + Vector2(0.0, 5.0)
		sketch.disc(part, bulb, 4.5, WorldPalette.pick(palette.fairy_lights, i))


## A string of little felt pennants sagging from `from` to `to`.
static func bunting(
	sketch: BuildingSketch, part: StringName, from: Vector2, to: Vector2, sag: float, count: int
) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var cord: PackedVector2Array = sagging(from, to, sag, count + 2)
	sketch.line(cord, palette.light_cord, 1.8)
	for i: int in range(1, count + 1):
		var at: Vector2 = cord[i]
		var flag: PackedVector2Array = [
			at + Vector2(-7.0, 0.0), at + Vector2(7.0, 0.0), at + Vector2(0.0, 15.0)
		]
		sketch.piece(part, flag, WorldPalette.pick(palette.toys, i))


## `count` points from `from` to `to`, hanging down `sag` in the middle.
static func sagging(from: Vector2, to: Vector2, sag: float, count: int) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in count:
		var t: float = float(i) / maxf(count - 1, 1)
		points.append(from.lerp(to, t) + Vector2(0.0, sin(t * PI) * sag))
	return points


## A teddy plushie's head (ears, muzzle, button eyes); `asleep` closes the eyes.
static func teddy_head(
	sketch: BuildingSketch, part: StringName, at: Vector2, r: float, asleep: bool
) -> void:
	var palette: WorldPalette = WorldPalette.current()
	for side: float in [-1.0, 1.0]:
		var ear: Vector2 = at + Vector2(side * r * 0.7, -r * 0.72)
		sketch.disc(part, ear, r * 0.4, palette.teddy)
		sketch.dot(ear, r * 0.2, palette.teddy_dark)
	sketch.disc(part, at, r, palette.teddy)
	sketch.dot(at + Vector2(0.0, r * 0.34), r * 0.42, palette.tag)
	sketch.dot(at + Vector2(0.0, r * 0.2), r * 0.15, palette.ink)
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = at + Vector2(side * r * 0.38, -r * 0.12)
		if asleep:
			var dip: Vector2 = Vector2(0.0, r * 0.1)
			var wide: Vector2 = Vector2(r * 0.16, 0.0)
			sketch.line([eye - wide, eye + dip, eye + wide], palette.ink, 1.4)
		else:
			sketch.dot(eye, r * 0.13, palette.ink)


## A sewing button: a disc with two holes.
static func button(sketch: BuildingSketch, at: Vector2, r: float, index: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	sketch.dot(at, r, WorldPalette.pick(palette.buttons, index))
	sketch.dot(at + Vector2(-r * 0.3, 0.0), r * 0.18, palette.button_hole)
	sketch.dot(at + Vector2(r * 0.3, 0.0), r * 0.18, palette.button_hole)


## A yellow felt pencil from `foot` to its sharpened `tip`.
static func pencil(sketch: BuildingSketch, part: StringName, foot: Vector2, tip: Vector2) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var along: Vector2 = (tip - foot).normalized()
	var wood_start: Vector2 = tip - along * 14.0
	sketch.rod(part, [foot, wood_start], WorldPalette.pick(palette.toys, 0), 11.0)
	var side: Vector2 = along.orthogonal() * 5.5
	sketch.piece(part, [wood_start + side, tip, wood_start - side], palette.pencil_wood)
	var lead_base: Vector2 = tip - along * 5.0
	sketch.shade([lead_base + side * 0.35, tip, lead_base - side * 0.35], palette.ink)


## Shades the part of `shape` inside `rect` (a darker side, a lighter top).
static func clip_shade(
	sketch: BuildingSketch, shape: PackedVector2Array, rect: Rect2, color: Color
) -> void:
	var box: PackedVector2Array = BuildingSketch.corners(rect)
	for cut: PackedVector2Array in Geometry2D.intersect_polygons(shape, box):
		sketch.shade(cut, color)
