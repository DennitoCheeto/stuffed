class_name LuckyJarLook
extends RefCounted
## The Lucky Jar in the art kit's style (spec 05 §3.2): a glass jar of buttons and coins with a
## gingham cloth lid. Ruin: tipped over and cracked, the lid rolled off, buttons spilled.
## Lv 1: a small jar with a few buttons. Lv 2: a full jar with a bow and a lucky tag. Lv 3: a big
## jar with a gold lid heaped with coins, fairy lights and a clover flag.

## Half width and height of the standing jar per level (design units).
const HALF_WIDTHS: Array[float] = [44.0, 54.0, 64.0]
const HEIGHTS: Array[float] = [92.0, 120.0, 146.0]
## How full the jar is per level (share of its height).
const FILLS: Array[float] = [0.0, 0.5, 0.72]


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var hw: float = HALF_WIDTHS[level - 1]
	var h: float = HEIGHTS[level - 1]
	sketch.shadow(_floor_shadow(hw))
	if level >= 3:
		_clover_flag(sketch, palette, Vector2(hw + 18.0, 0.0), h * 0.85)
	_jar(sketch, palette, hw, h, level)
	if level == 1:
		_cloth_lid(sketch, palette, hw, h, false)
	elif level == 2:
		_cloth_lid(sketch, palette, hw, h, true)
		_tag(sketch, palette, Vector2(hw - 6.0, -h * 0.62))
	else:
		_gold_lid(sketch, palette, hw, h)
		_fairy_lights(sketch, palette, hw, h)
		_sparkles(sketch, palette, hw, h)


## The glass body with what's inside, its shaded side and the shine.
static func _jar(
	sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float, level: int
) -> void:
	sketch.piece(&"jar", _jar_shape(hw, h), palette.glass)
	var fill: float = h * FILLS[level - 1]
	if level == 1:
		_buttons_on_floor(sketch, palette, hw)
	elif level == 2:
		sketch.shade(_heap(hw, fill), WorldPalette.pick(palette.buttons, 3).lightened(0.35))
		sketch.parts.append(&"button_heap")
		_buttons_in_heap(sketch, palette, hw, fill, 7)
		_coin(sketch, palette, Vector2(-hw * 0.2, -fill * 0.45), 7.0)
		_coin(sketch, palette, Vector2(hw * 0.45, -fill * 0.3), 7.0)
		sketch.parts.append(&"coins")
	else:
		sketch.shade(_heap(hw, fill), palette.coin)
		sketch.parts.append(&"gold_heap")
		for i: int in 9:
			var row: int = floori(i / 3.0)
			var x: float = -hw * 0.7 + (i % 3) * hw * 0.7 + (8.0 if row == 1 else 0.0)
			_coin(sketch, palette, Vector2(x, -fill * (0.2 + 0.28 * row)), 8.0)
		_buttons_in_heap(sketch, palette, hw, fill, 5)
	var side: PackedVector2Array = [
		Vector2(hw - 14.0, -8.0),
		Vector2(hw - 2.0, -8.0),
		Vector2(hw - 2.0, -h + 18.0),
		Vector2(hw - 14.0, -h + 6.0),
	]
	sketch.shade(side, Color(palette.glass_side, 0.7))
	var shine: PackedVector2Array = [
		Vector2(-hw + 8.0, -h + 22.0),
		Vector2(-hw + 16.0, -h + 14.0),
		Vector2(-hw + 16.0, -24.0),
		Vector2(-hw + 8.0, -18.0),
	]
	sketch.shade(shine, palette.glass_shine)
	var small_shine: Rect2 = Rect2(-hw + 22.0, -h + 18.0, 4.0, h * 0.3)
	sketch.shade(BuildingSketch.corners(small_shine), Color(palette.glass_shine, 0.6))
	sketch.block(&"neck", Rect2(-hw + 10.0, -h - 10.0, hw * 2.0 - 20.0, 12.0), palette.glass_side)


## A chunky jar outline: straight sides, chamfered shoulders and foot.
static func _jar_shape(hw: float, h: float) -> PackedVector2Array:
	return [
		Vector2(-hw + 6.0, 0.0),
		Vector2(hw - 6.0, 0.0),
		Vector2(hw, -8.0),
		Vector2(hw, -h + 16.0),
		Vector2(hw - 14.0, -h),
		Vector2(-hw + 14.0, -h),
		Vector2(-hw, -h + 16.0),
		Vector2(-hw, -8.0),
	]


## The pile inside the jar: a bumpy top at `fill` height.
static func _heap(hw: float, fill: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(-hw + 4.0, -6.0), Vector2(hw - 4.0, -6.0)]
	var bumps: int = 6
	for i: int in range(bumps, -1, -1):
		var x: float = lerpf(-hw + 4.0, hw - 4.0, float(i) / bumps)
		var y: float = -fill + (6.0 if i % 2 == 1 else 0.0)
		points.append(Vector2(x, y))
	return points


## A sewing button: a disc with two holes.
static func _button(
	sketch: BuildingSketch, palette: WorldPalette, at: Vector2, r: float, index: int
) -> void:
	sketch.dot(at, r, WorldPalette.pick(palette.buttons, index))
	sketch.dot(at + Vector2(-r * 0.3, 0.0), r * 0.18, palette.button_hole)
	sketch.dot(at + Vector2(r * 0.3, 0.0), r * 0.18, palette.button_hole)


static func _coin(sketch: BuildingSketch, palette: WorldPalette, at: Vector2, r: float) -> void:
	sketch.dot(at, r, palette.coin_rim)
	sketch.dot(at + Vector2(-0.8, -0.8), r - 2.0, palette.coin)


static func _buttons_on_floor(sketch: BuildingSketch, palette: WorldPalette, hw: float) -> void:
	sketch.parts.append(&"buttons")
	var spots: Array[Vector2] = [Vector2(-0.45, -12), Vector2(0.05, -11), Vector2(0.5, -13)]
	for i: int in spots.size():
		_button(sketch, palette, Vector2(spots[i].x * hw, spots[i].y), 8.0, i)
	_button(sketch, palette, Vector2(-0.2 * hw, -26.0), 8.0, 3)


static func _buttons_in_heap(
	sketch: BuildingSketch, palette: WorldPalette, hw: float, fill: float, count: int
) -> void:
	for i: int in count:
		var x: float = lerpf(-hw * 0.7, hw * 0.7, float(i) / maxf(count - 1, 1))
		var y: float = -fill * (0.3 + 0.5 * float((i * 7) % 5) / 4.0)
		_button(sketch, palette, Vector2(x, y), 8.0, i)


## A gingham cloth tied over the jar's mouth; `bow` adds a big ribbon bow.
static func _cloth_lid(
	sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float, bow: bool
) -> void:
	var top: float = -h - 10.0
	var cloth: PackedVector2Array = [
		Vector2(-hw - 12.0, top + 4.0),
		Vector2(-hw + 4.0, top - 16.0),
		Vector2(hw - 4.0, top - 16.0),
		Vector2(hw + 12.0, top + 4.0),
		Vector2(hw + 18.0, top + 28.0),
		Vector2(hw + 2.0, top + 10.0),
		Vector2(-hw - 2.0, top + 10.0),
		Vector2(-hw - 18.0, top + 28.0),
	]
	sketch.piece(&"gingham_lid", cloth, palette.gingham, true)
	sketch.stripes(cloth, Color(palette.gingham_check, 0.7), 12.0, 6.0, true)
	sketch.stripes(cloth, Color(palette.gingham_check, 0.7), 12.0, 6.0, false)
	var band_color: Color = palette.ribbon if bow else palette.twine
	sketch.block(&"lid_band", Rect2(-hw - 2.0, top + 2.0, hw * 2.0 + 4.0, 7.0), band_color)
	if not bow:
		return
	var knot: Vector2 = Vector2(0.0, top + 5.0)
	for side: float in [-1.0, 1.0]:
		var loop: PackedVector2Array = [
			knot,
			knot + Vector2(side * 22.0, -14.0),
			knot + Vector2(side * 26.0, 4.0),
		]
		sketch.piece(&"bow", loop, palette.ribbon)
		sketch.rod(&"bow", [knot, knot + Vector2(side * 10.0, 22.0)], palette.ribbon_dark, 5.0)
	sketch.disc(&"bow", knot, 6.0, palette.ribbon_dark)


## A paper tag on a string with a little clover drawn on it.
static func _tag(sketch: BuildingSketch, palette: WorldPalette, at: Vector2) -> void:
	sketch.line([at + Vector2(-8.0, -26.0), at], palette.light_cord, 1.5)
	var card: PackedVector2Array = [
		at,
		at + Vector2(30.0, 8.0),
		at + Vector2(26.0, 34.0),
		at + Vector2(-4.0, 26.0),
	]
	sketch.piece(&"lucky_tag", card, palette.tag)
	_clover(sketch, palette, at + Vector2(13.0, 17.0), 3.6, false)


## A big gold lid with a star on its front, coins heaped on top.
static func _gold_lid(sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float) -> void:
	var top: float = -h - 10.0
	for i: int in 5:
		var at: Vector2 = Vector2(-hw * 0.55 + i * hw * 0.27, top - 26.0 - (i % 2) * 6.0)
		sketch.disc(&"lid_coins", at, 9.0, palette.coin_rim)
		sketch.dot(at + Vector2(-1.0, -1.0), 7.0, palette.coin)
	var lid: Rect2 = Rect2(-hw - 6.0, top - 18.0, hw * 2.0 + 12.0, 22.0)
	sketch.block(&"gold_lid", lid, palette.gold_lid)
	var rim: Rect2 = Rect2(lid.position.x, lid.end.y - 7.0, lid.size.x, 7.0)
	sketch.shade(BuildingSketch.corners(rim), palette.gold_lid_dark)
	for i: int in range(1, 8):
		var x: float = lid.position.x + lid.size.x * i / 8.0
		var ridge: PackedVector2Array = [Vector2(x, lid.position.y + 3.0), Vector2(x, rim.end.y)]
		sketch.line(ridge, palette.gold_lid_dark, 1.5)
	sketch.shade(BuildingSketch.star(Vector2(0.0, lid.get_center().y - 2.0), 8.0), palette.tag)


## A cord of soft bulbs sagging across the jar.
static func _fairy_lights(
	sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float
) -> void:
	var cord: PackedVector2Array = []
	var count: int = 7
	for i: int in count:
		var t: float = float(i) / (count - 1)
		var x: float = lerpf(-hw - 8.0, hw + 8.0, t)
		cord.append(Vector2(x, -h * 0.78 + sin(t * PI) * 18.0))
	sketch.line(cord, palette.light_cord, 2.0)
	for i: int in count:
		var bulb: Vector2 = cord[i] + Vector2(0.0, 6.0)
		sketch.disc(&"fairy_lights", bulb, 5.0, WorldPalette.pick(palette.fairy_lights, i))


static func _sparkles(sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float) -> void:
	for at: Vector2 in [Vector2(-hw - 20.0, -h - 20.0), Vector2(hw + 26.0, -h - 6.0)]:
		sketch.piece(&"sparkles", BuildingSketch.star(at, 9.0), palette.sparkle)


## A felt four-leaf clover flag on a pole.
static func _clover_flag(
	sketch: BuildingSketch, palette: WorldPalette, foot: Vector2, height: float
) -> void:
	var top: Vector2 = foot - Vector2(0.0, height)
	sketch.rod(&"clover_flag", [foot, top], palette.wood_side, 4.0)
	_clover(sketch, palette, top + Vector2(12.0, 8.0), 8.0, true)


static func _clover(
	sketch: BuildingSketch, palette: WorldPalette, at: Vector2, r: float, outlined: bool
) -> void:
	for i: int in 4:
		var leaf: Vector2 = at + Vector2.from_angle(PI / 4.0 + i * PI / 2.0) * r
		if outlined:
			sketch.disc(&"clover_flag", leaf, r, palette.clover)
		else:
			sketch.dot(leaf, r, palette.clover)


## Ruin: the jar lies on its side, cracked, the cloth lid lies flat, buttons are spilled.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var hw: float = 40.0
	var h: float = 96.0
	sketch.shadow(_floor_shadow(h * 0.55))
	sketch.parts.append(&"tipped_jar")
	sketch.turn(PI / 2.0, Vector2.ZERO, Vector2(-h * 0.55, -hw))
	sketch.piece(&"", _jar_shape(hw, h), palette.glass)
	sketch.shade(_heap(hw, 18.0), WorldPalette.pick(palette.buttons, 1).lightened(0.3))
	var crack: PackedVector2Array = [
		Vector2(-hw * 0.4, -h * 0.85),
		Vector2(-hw * 0.1, -h * 0.7),
		Vector2(-hw * 0.3, -h * 0.55),
		Vector2(hw * 0.1, -h * 0.4),
	]
	sketch.line(crack, palette.ink, 2.0)
	sketch.line([crack[1], Vector2(hw * 0.35, -h * 0.72)], palette.ink, 1.5)
	sketch.block(&"", Rect2(-hw + 10.0, -h - 10.0, hw * 2.0 - 20.0, 12.0), palette.glass_side)
	sketch.straighten()
	sketch.parts.append(&"crack")
	var lid: PackedVector2Array = [
		Vector2(h * 0.6, -4.0),
		Vector2(h * 0.6 + 36.0, -8.0),
		Vector2(h * 0.6 + 44.0, 2.0),
		Vector2(h * 0.6 + 6.0, 6.0),
	]
	sketch.piece(&"fallen_lid", lid, palette.gingham)
	sketch.stripes(lid, Color(palette.gingham_check, 0.7), 12.0, 6.0, true)
	for i: int in 4:
		var at: Vector2 = Vector2(-h * 0.6 - i * 12.0, -6.0 + (i % 2) * 8.0)
		sketch.disc(&"spilled_buttons", at, 7.0, WorldPalette.pick(palette.buttons, i))
		sketch.dot(at, 1.4, palette.button_hole)


## The contact shadow: a flat band under the object, falling to the bottom right.
static func _floor_shadow(half: float) -> PackedVector2Array:
	return [
		Vector2(-half - 8.0, 4.0),
		Vector2(half + 14.0, 4.0),
		Vector2(half + 26.0, -10.0),
		Vector2(-half + 4.0, -10.0),
	]
