class_name WatchtowerLook
extends RefCounted
## The Watchtower in the art kit's style (spec 05 §3.2): stacked cotton reels with a thimble
## lookout. Ruin: the reels have fallen over, thread unwound across the floor, the flag pin lies
## bent beside them. Lv 1: one big reel with a flag pin on top. Lv 2: two reels and a ladder.
## Lv 3: three reels, a thimble lookout with a plushie on watch and a pencil telescope.

## Each reel's thread half width and height (bottom reel first), and the flange thickness.
const REEL_HALF_WIDTHS: Array[float] = [34.0, 29.0, 25.0]
const REEL_HEIGHTS: Array[float] = [44.0, 38.0, 32.0]
const FLANGE: float = 11.0
## Thread colour per reel (index into the palette's toy colours).
const THREAD_COLORS: Array[int] = [2, 1, 0]
const REEL_PARTS: Array[StringName] = [&"reel", &"second_reel", &"third_reel"]
## The thimble lookout: half width at its rim and at its foot, and its height.
const CUP_TOP: float = 30.0
const CUP_FOOT: float = 21.0
const CUP_HEIGHT: float = 38.0


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var base: float = REEL_HALF_WIDTHS[0] * 1.3
	LookParts.footprint_shadow(sketch, Rect2(-base, -FLANGE, base * 2.0, FLANGE))
	var top: float = 0.0
	for i: int in level:
		top = _reel(sketch, palette, Vector2(0.0, top), i)
	if level >= 2:
		_ladder(sketch, palette, top)
	if level >= 3:
		_lookout(sketch, palette, top)
	else:
		LookParts.pin_flag(sketch, &"flag", Vector2(0.0, top), 50.0, palette.paint_trim)


static func _reel(sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, i: int) -> float:
	var thread: Color = WorldPalette.pick(palette.toys, THREAD_COLORS[i])
	var hw: float = REEL_HALF_WIDTHS[i]
	return LookParts.reel(sketch, REEL_PARTS[i], foot, hw, REEL_HEIGHTS[i], FLANGE, thread)


## Lv 2+: a wooden ladder leaning on the reels' right side, up to the top.
static func _ladder(sketch: BuildingSketch, palette: WorldPalette, top: float) -> void:
	var foot_x: float = REEL_HALF_WIDTHS[0] * 1.3 + 8.0
	var top_x: float = REEL_HALF_WIDTHS[1] * 1.3 + 2.0
	var width: float = 14.0
	var rail_top: float = top + 6.0
	for dx: float in [0.0, width]:
		var rail: PackedVector2Array = [Vector2(foot_x + dx, 0.0), Vector2(top_x + dx, rail_top)]
		sketch.rod(&"ladder", rail, palette.wood_side, 4.0)
	var y: float = -12.0
	while y > rail_top + 4.0:
		var t: float = y / rail_top
		var x: float = lerpf(foot_x, top_x, t)
		sketch.rod(&"ladder", [Vector2(x, y), Vector2(x + width, y)], palette.wood_top, 3.0)
		y -= 16.0


## Lv 3: a thimble set on top like a lookout basket, a teddy on watch looking through a pencil
## telescope, and the flag pin moved to the rim.
static func _lookout(sketch: BuildingSketch, palette: WorldPalette, base: float) -> void:
	var rim: float = base - CUP_HEIGHT
	var metal: Color = palette.metal
	var back_rim: Vector2 = Vector2(0.0, rim + 5.0)
	LookParts.flange(sketch, &"thimble_lookout", back_rim, CUP_TOP + 2.0, 10.0, metal, metal)
	var opening: Rect2 = Rect2(-CUP_TOP + 4.0, rim - 4.0, CUP_TOP * 2.0 - 8.0, 5.0)
	sketch.shade(BuildingSketch.corners(opening), palette.box_inside)
	var flag_foot: Vector2 = Vector2(-CUP_TOP + 6.0, rim - 2.0)
	LookParts.pin_flag(sketch, &"flag", flag_foot, 46.0, palette.paint_trim)
	LookParts.teddy_head(sketch, &"plushie_on_watch", Vector2(-4.0, rim - 8.0), 13.0, false)
	var cup: PackedVector2Array = [
		Vector2(-CUP_FOOT, base),
		Vector2(CUP_FOOT, base),
		Vector2(CUP_FOOT + 5.0, base - 8.0),
		Vector2(CUP_TOP, rim + 1.0),
		Vector2(-CUP_TOP, rim + 1.0),
		Vector2(-CUP_FOOT - 5.0, base - 8.0),
	]
	sketch.piece(&"thimble_lookout", cup, palette.metal)
	var lip: Rect2 = Rect2(-CUP_TOP - 2.0, rim, CUP_TOP * 2.0 + 4.0, 6.0)
	sketch.shade(BuildingSketch.corners(lip), palette.metal_dark)
	for row: int in 3:
		var y: float = rim + 12.0 + row * 8.0
		var half: float = lerpf(CUP_TOP, CUP_FOOT, (y - rim) / CUP_HEIGHT) - 6.0
		var x: float = -half + (row % 2) * 3.5
		while x < half:
			sketch.dot(Vector2(x, y), 1.8, palette.metal_dark)
			x += 7.0
	var shine: Rect2 = Rect2(-CUP_TOP + 6.0, rim + 8.0, 4.0, CUP_HEIGHT - 16.0)
	sketch.shade(BuildingSketch.corners(shine), Color(palette.glass_shine, 0.6))
	_telescope(sketch, palette, Vector2(6.0, rim - 12.0))


## A yellow pencil telescope with a pink eyepiece and a glass lens, held up to the right.
static func _telescope(sketch: BuildingSketch, palette: WorldPalette, eye: Vector2) -> void:
	var lens: Vector2 = eye + Vector2(44.0, -22.0)
	var tube: PackedVector2Array = [eye, lens]
	sketch.rod(&"telescope", tube, WorldPalette.pick(palette.toys, 0), 9.0)
	var cap: PackedVector2Array = [lens.lerp(eye, 0.2), lens]
	sketch.rod(&"telescope", cap, WorldPalette.pick(palette.toys, 1), 13.0)
	sketch.dot(lens, 4.0, palette.glass)
	for i: int in [1, 2]:
		var at: Vector2 = eye.lerp(lens, i * 0.25)
		sketch.line([at + Vector2(-2.0, -4.0), at + Vector2(2.0, 4.0)], palette.brass_dark, 1.5)


## Ruin: the big reel lies on its side, the second one has rolled away tipped over, thread runs
## across the floor and the flag pin lies bent beside them.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var long: float = REEL_HEIGHTS[0] + FLANGE * 2.0
	var hw: float = REEL_HALF_WIDTHS[0]
	var wide: float = hw * 1.3
	LookParts.footprint_shadow(sketch, Rect2(-long - 30.0, -14.0, long + 130.0, 14.0))
	sketch.parts.append(&"fallen_reels")
	sketch.turn(PI / 2.0, Vector2.ZERO, Vector2(-30.0 - long, -wide))
	_reel(sketch, palette, Vector2.ZERO, 0)
	sketch.straighten()
	var thread: Color = WorldPalette.pick(palette.toys, THREAD_COLORS[1])
	var loose: PackedVector2Array = [
		Vector2(-34.0, -20.0),
		Vector2(-14.0, -3.0),
		Vector2(4.0, -9.0),
		Vector2(22.0, -4.0),
	]
	sketch.line(loose, thread, 2.5)
	sketch.parts.append(&"loose_thread")
	var corner: Vector2 = Vector2(REEL_HALF_WIDTHS[1] * 1.3, 0.0)
	sketch.turn(0.35, corner, Vector2(40.0, 0.0))
	_reel(sketch, palette, Vector2.ZERO, 1)
	sketch.straighten()
	var pin: PackedVector2Array = [Vector2(-70.0, 2.0), Vector2(-36.0, 0.0), Vector2(-16.0, -10.0)]
	sketch.rod(&"bent_flag", pin, palette.metal, 3.0)
	var flap: Vector2 = pin[1]
	var cloth: PackedVector2Array = [flap, flap + Vector2(-26.0, -4.0), flap + Vector2(-8.0, 12.0)]
	sketch.piece(&"bent_flag", cloth, palette.paint_trim)
	sketch.disc(&"bent_flag", pin[2], 5.0, palette.brass)
