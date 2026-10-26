class_name PartyShopLook
extends RefCounted
## The Party Shop in the art kit's style (spec 05 §3.2): a pink strawberry pincushion with sewing
## pins as flag poles. Ruin: the cushion lies squashed flat with stuffing poking out, its leaves
## and pins on the floor. Lv 1: the plump cushion with three pins. Lv 2: balloons tied to the pins.
## Lv 3: bunting between the pins, a pennant on every pin and confetti all around.

## Half width and height of the cushion per level (design units).
const HALF_WIDTHS: Array[float] = [62.0, 68.0, 74.0]
const HEIGHTS: Array[float] = [64.0, 70.0, 76.0]
## The pins: where they stand (share of the half width), how far they stick out, their lean.
const PIN_SPOTS: Array[float] = [-0.5, 0.05, 0.55]
const PIN_LENGTHS: Array[float] = [50.0, 68.0, 46.0]
const PIN_LEANS: Array[float] = [-10.0, 2.0, 12.0]
## Where each balloon floats from its pin's head.
const BALLOONS: Array[Vector2] = [Vector2(-24.0, -44.0), Vector2(6.0, -58.0), Vector2(26.0, -40.0)]
const BALLOON_COLORS: Array[int] = [3, 0, 2]
## Lv 3 confetti bits: position, and turn in radians.
const CONFETTI: Array[Vector3] = [
	Vector3(-104.0, -4.0, 0.4),
	Vector3(-86.0, 4.0, -0.7),
	Vector3(-60.0, 8.0, 1.1),
	Vector3(56.0, 6.0, -0.3),
	Vector3(88.0, 2.0, 0.9),
	Vector3(106.0, -6.0, -1.2),
	Vector3(-96.0, -96.0, 0.6),
	Vector3(-60.0, -170.0, -0.5),
	Vector3(96.0, -110.0, 1.3),
	Vector3(64.0, -180.0, 0.2),
]


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
	LookParts.footprint_shadow(sketch, Rect2(-hw + 6.0, -12.0, hw * 2.0 - 12.0, 12.0))
	var heads: PackedVector2Array = _pins(sketch, palette, hw, h)
	_cushion(sketch, palette, hw, h)
	if level >= 3:
		_confetti(sketch, palette)
		LookParts.bunting(sketch, &"bunting", heads[0], heads[1], 12.0, 3)
		LookParts.bunting(sketch, &"bunting", heads[1], heads[2], 12.0, 3)
		for i: int in heads.size():
			var flag: PackedVector2Array = [
				heads[i] + Vector2(1.0, 7.0),
				heads[i] + Vector2(20.0, 12.0),
				heads[i] + Vector2(1.0, 18.0),
			]
			sketch.piece(&"pin_pennants", flag, WorldPalette.pick(palette.toys, i + 2))
	if level >= 2:
		for i: int in heads.size():
			_balloon(sketch, palette, heads[i], heads[i] + BALLOONS[i], BALLOON_COLORS[i])
	for i: int in heads.size():
		sketch.disc(&"pins", heads[i], 7.0, WorldPalette.pick(palette.toys, i))
		sketch.dot(heads[i] + Vector2(-2.0, -2.0), 2.0, palette.glass_shine)


## The pin shafts (their feet hide inside the cushion); returns where their round heads sit.
static func _pins(
	sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float
) -> PackedVector2Array:
	var heads: PackedVector2Array = []
	for i: int in PIN_SPOTS.size():
		var foot: Vector2 = Vector2(PIN_SPOTS[i] * hw, -h * 0.55)
		var head: Vector2 = Vector2(foot.x + PIN_LEANS[i], -h - PIN_LENGTHS[i])
		sketch.rod(&"pins", [foot, head], palette.metal, 3.0)
		heads.append(head)
	return heads


## A chunky strawberry cushion: segment seams, a shaded side, seeds and a leaf cap.
static func _cushion(sketch: BuildingSketch, palette: WorldPalette, hw: float, h: float) -> void:
	var shape: PackedVector2Array = _cushion_shape(hw, h)
	sketch.piece(&"cushion", shape, palette.pincushion)
	var side: Rect2 = Rect2(hw * 0.45, -h - 2.0, hw, h + 4.0)
	LookParts.clip_shade(sketch, shape, side, palette.pincushion_dark)
	for share: float in [-0.55, -0.18, 0.18, 0.55]:
		var seam: PackedVector2Array = [
			Vector2(share * 0.3 * hw, -h + 6.0),
			Vector2(share * 0.95 * hw, -h * 0.5),
			Vector2(share * 0.75 * hw, -6.0),
		]
		sketch.seam(seam)
	var inner: Array[PackedVector2Array] = Geometry2D.offset_polygon(shape, -9.0)
	for row: int in 3:
		var y: float = -h * (0.25 + row * 0.22)
		var x: float = -hw + 14.0 + (row % 2) * 9.0
		while x < hw - 10.0:
			var seed_at: Vector2 = Vector2(x, y)
			if not inner.is_empty() and Geometry2D.is_point_in_polygon(seed_at, inner[0]):
				sketch.dot(seed_at, 2.2, palette.tag)
			x += 18.0
	var shine: PackedVector2Array = LookParts.oval(Vector2(-hw * 0.5, -h * 0.68), 8.0, 4.0, 10)
	sketch.shade(shine, Color(palette.glass_shine, 0.5))
	_leaf_cap(sketch, palette, Vector2(0.0, -h + 2.0), 24.0, 0.5, &"leaf_cap")


static func _cushion_shape(hw: float, h: float) -> PackedVector2Array:
	return [
		Vector2(-hw + 12.0, 0.0),
		Vector2(hw - 12.0, 0.0),
		Vector2(hw, -14.0),
		Vector2(hw, -h * 0.5),
		Vector2(hw * 0.72, -h * 0.88),
		Vector2(hw * 0.3, -h),
		Vector2(-hw * 0.3, -h),
		Vector2(-hw * 0.72, -h * 0.88),
		Vector2(-hw, -h * 0.5),
		Vector2(-hw, -14.0),
	]


## The green felt leaves: a star squashed flat by `squash`, with a stem.
static func _leaf_cap(
	sketch: BuildingSketch,
	palette: WorldPalette,
	at: Vector2,
	r: float,
	squash: float,
	part: StringName
) -> void:
	sketch.rod(part, [at, at + Vector2(3.0, -r * 0.5)], palette.clover, 5.0)
	var leaves: PackedVector2Array = []
	for i: int in 12:
		var radius: float = r if i % 2 == 0 else r * 0.38
		var point: Vector2 = Vector2.from_angle(i * PI / 6.0) * radius
		leaves.append(at + Vector2(point.x, point.y * squash))
	sketch.piece(part, leaves, palette.clover)


## A felt balloon on a string tied to a pin head.
static func _balloon(
	sketch: BuildingSketch, palette: WorldPalette, tie: Vector2, center: Vector2, index: int
) -> void:
	var bottom: Vector2 = center + Vector2(0.0, 19.0)
	var middle: Vector2 = tie.lerp(bottom, 0.5) + Vector2(5.0, 0.0)
	sketch.line([tie, middle, bottom], palette.light_cord, 1.4)
	var color: Color = WorldPalette.pick(palette.toys, index)
	sketch.piece(&"balloons", LookParts.oval(center, 15.0, 19.0), color)
	var knot: PackedVector2Array = [
		bottom + Vector2(-4.0, 4.0), bottom + Vector2(4.0, 4.0), bottom + Vector2(0.0, -1.0)
	]
	sketch.piece(&"balloons", knot, color)
	var shine: PackedVector2Array = LookParts.oval(center + Vector2(-6.0, -7.0), 3.0, 5.0, 10)
	sketch.shade(shine, palette.glass_shine)


## Lv 3: little felt confetti bits on the floor and in the air.
static func _confetti(sketch: BuildingSketch, palette: WorldPalette) -> void:
	sketch.parts.append(&"confetti")
	for i: int in CONFETTI.size():
		var bit: Vector3 = CONFETTI[i]
		var at: Vector2 = Vector2(bit.x, bit.y)
		var along: Vector2 = Vector2.from_angle(bit.z) * 5.0
		var across: Vector2 = along.orthogonal() * 0.5
		var shape: PackedVector2Array = [
			at - along - across, at + along - across, at + along + across, at - along + across
		]
		sketch.shade(shape, WorldPalette.pick(palette.toys, i))


## Ruin: the cushion lies squashed flat with a torn seam and stuffing poking out; its leaves and
## two pins lie on the floor.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var hw: float = 74.0
	var h: float = 32.0
	LookParts.footprint_shadow(sketch, Rect2(-hw - 30.0, -12.0, hw * 2.0 + 50.0, 12.0))
	var shape: PackedVector2Array = _cushion_shape(hw, h)
	sketch.piece(&"flat_cushion", shape, palette.pincushion)
	LookParts.clip_shade(sketch, shape, Rect2(hw * 0.45, -h - 2.0, hw, h + 4.0), palette.ribbon)
	var tear: PackedVector2Array = [Vector2(4.0, -h + 4.0), Vector2(22.0, -h + 1.0)]
	sketch.line(tear, palette.box_inside, 3.0)
	for puff: Vector3 in [Vector3(8.0, -h - 4.0, 9.0), Vector3(20.0, -h - 8.0, 8.0)]:
		sketch.disc(&"stuffing_tufts", Vector2(puff.x, puff.y), puff.z, palette.tissue)
	sketch.disc(&"stuffing_tufts", Vector2(-44.0, -h - 2.0), 7.0, palette.tissue)
	_leaf_cap(sketch, palette, Vector2(-hw - 14.0, -4.0), 20.0, 0.3, &"fallen_leaves")
	var pins: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(36.0, 6.0), Vector2(92.0, -2.0)]),
		PackedVector2Array([Vector2(-30.0, 8.0), Vector2(8.0, 10.0)]),
	]
	for i: int in pins.size():
		sketch.rod(&"fallen_pins", pins[i], palette.metal, 3.0)
		sketch.disc(&"fallen_pins", pins[i][1], 6.0, WorldPalette.pick(palette.toys, i))
