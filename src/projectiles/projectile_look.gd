class_name ProjectileLook
extends RefCounted
## The felt shots (banana peel, sewing pin, needle, button, cloud, yarn ball, thimble and its
## shadow, yarn burst, whip lash, zipper beam), the zombies' stuffing ball and the bloater's
## cloud, drawn once into the FeltAtlas. Shapes are in "atlas units": three times the on-screen
## size, for a sharp bake.
## Players' shots are soft and quiet; enemy bullets are bright with a dark outline (vision §6.1).

const DRAW_SCALE: float = 1.0 / 3.0
const UNITS: float = 3.0
const PEEL: StringName = &"shot/peel"
const PIN: StringName = &"shot/pin"
const NEEDLE: StringName = &"shot/needle"
const BUTTON: StringName = &"shot/button"
const CLOUD: StringName = &"shot/cloud"
const YARN: StringName = &"shot/yarn"
const THIMBLE: StringName = &"shot/thimble"
const SHADOW: StringName = &"shot/shadow"
const RING: StringName = &"shot/ring"
const DISC: StringName = &"shot/disc"
const DUST: StringName = &"shot/dust"
const BURST: StringName = &"shot/burst"
const WHIP: StringName = &"shot/whip"
const ZIPPER: StringName = &"shot/zipper"
const SPLIT_PEEL: StringName = &"shot/split_peel"
const VOLLEY_PIN: StringName = &"shot/volley_pin"
const STORM_NEEDLE: StringName = &"shot/storm_needle"
const BOMB_BALL: StringName = &"shot/bomb_ball"
const GLITTER: StringName = &"shot/glitter"
const SPARKLE: StringName = &"shot/sparkle"
const BULLET: StringName = &"bullet/stuffing"
const HAZARD: StringName = &"bullet/cloud"
## On-screen radius of the stuffing ball part; bigger bullets scale it.
const BULLET_RADIUS: float = 8.0
## On-screen radius the bloater cloud is drawn at; bigger clouds scale it.
const HAZARD_RADIUS: float = 40.0
## The peel is drawn a little bigger than its outline numbers.
const PEEL_SIZE: float = 1.3
const PEEL_COLOR: Color = Color("#efe3a0")
const PIN_LENGTH: float = 30.0
const PIN_SHAFT_COLOR: Color = Color("#d9d6e3")
const PIN_HEAD_COLOR: Color = Color("#e0475b")
const NEEDLE_LENGTH: float = 30.0
const NEEDLE_COLOR: Color = Color("#cfd3e0")
const BUTTON_RADIUS: float = 7.0
const BUTTON_COLOR: Color = Color("#8fc9b9")
const BUTTON_HOLE_COLOR: Color = Color("#4f7f73")
## On-screen radius the cloud and the shadow are drawn at; bigger areas scale them.
const CLOUD_RADIUS: float = 40.0
const CLOUD_COLOR: Color = Color("#e9e2f2")
const YARN_RADIUS: float = 9.0
const YARN_COLOR: Color = Color("#e98aa8")
const YARN_STRAND_COLOR: Color = Color("#b65a7c")
const THIMBLE_SIZE: float = 1.4
const THIMBLE_COLOR: Color = Color("#c9c3b4")
const THIMBLE_DOT_COLOR: Color = Color("#8d8676")
const SHADOW_RADIUS: float = 30.0
const SHADOW_COLOR: Color = Color("#1a1620")
const SHADOW_RIM_COLOR: Color = Color("#d8d0c0")
## The mortar's landing ring and its fill: drawn RING_RADIUS across, scaled to the hit area.
## Soft banana cream, never enemy red/orange (vision §6, hard rule 9).
const RING_RADIUS: float = 40.0
const RING_WIDTH: float = 3.0
const RING_COLOR: Color = Color("#f3e3a2")
const RING_STITCH_COLOR: Color = Color("#c9b878")
const DUST_RADIUS: float = 8.0
const DUST_COLOR: Color = Color("#e6dccb")
## On-screen sizes the burst, the whip's arc and the zipper are drawn at; weapons scale them.
const BURST_RADIUS: float = 40.0
const WHIP_RADIUS: float = 100.0
## Width of the whip's arc in degrees (the weapon's spread is drawn at this width).
const WHIP_ARC: float = 120.0
const WHIP_COLOR: Color = Color("#f0d78c")
const ZIPPER_LENGTH: float = 400.0
const ZIPPER_COLOR: Color = Color("#8fc4d9")
const ZIPPER_TEETH_COLOR: Color = Color("#dfeef4")
## Evolved weapons' shots (spec 02 §20): their own soft colours, never enemy red/orange.
const SPLIT_PEEL_COLOR: Color = Color("#a8ecc8")
const VOLLEY_SHAFT_COLOR: Color = Color("#efe9ff")
const VOLLEY_HEAD_COLOR: Color = Color("#b48cf0")
const STORM_NEEDLE_COLOR: Color = Color("#a8dcff")
const STORM_EYE_COLOR: Color = Color("#f4fbff")
const BOMB_COLOR: Color = Color("#6fd3c6")
const BOMB_STRAND_COLOR: Color = Color("#2f8f86")
## Glitter speck (trail) and sparkle pop (hit flash): white felt stars, tinted by the ShotLook.
const GLITTER_RADIUS: float = 5.0
const SPARKLE_RADIUS: float = 30.0
const BULLET_COLOR: Color = Color("#ff3d6e")
const BULLET_CORE_COLOR: Color = Color("#ffe1ea")
const BULLET_OUTLINE_COLOR: Color = Color("#14101a")


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	return {
		PEEL: _peel(),
		PIN: _pin(),
		NEEDLE: _needle(),
		BUTTON: _button(),
		CLOUD: _cloud(),
		YARN: _yarn(),
		THIMBLE: _thimble(),
		SHADOW: _shadow(),
		RING: _ring(),
		DISC: _disc(),
		DUST: _dust(),
		BURST: _burst(),
		WHIP: _whip(),
		ZIPPER: _zipper(),
		SPLIT_PEEL: _peel(SPLIT_PEEL_COLOR),
		VOLLEY_PIN: _pin(VOLLEY_SHAFT_COLOR, VOLLEY_HEAD_COLOR),
		STORM_NEEDLE: _needle(STORM_NEEDLE_COLOR, STORM_EYE_COLOR),
		BOMB_BALL: _yarn(BOMB_COLOR, BOMB_STRAND_COLOR),
		GLITTER: _star(GLITTER_RADIUS, 4),
		SPARKLE: _star(SPARKLE_RADIUS, 8),
		BULLET: _bullet(),
		HAZARD: _hazard(),
	}


## Makes `sprite` show part `key` at its on-screen size (times `size_factor`).
static func apply(sprite: Sprite2D, key: StringName, size_factor: float = 1.0) -> void:
	FeltAtlas.show_part(sprite, key)
	sprite.scale *= DRAW_SCALE * size_factor


static func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for point: Vector2 in points:
		result.append(point * factor)
	return result


static func _peel(color: Color = PEEL_COLOR) -> FeltPiece:
	var peel: FeltPiece = FeltPiece.new()
	var outline: PackedVector2Array = FeltShapes.svg_path(
		PackedFloat32Array([-14, 6, -8, -10, 8, -10, 14, 6, 6, -2, -6, -2, -14, 6])
	)
	peel.polygon = _scaled(outline, PEEL_SIZE * UNITS)
	peel.color = color
	return peel


## Points along +x: the tip at the pivot, the round head at the back.
static func _pin(
	shaft_color: Color = PIN_SHAFT_COLOR, head_color: Color = PIN_HEAD_COLOR
) -> FeltPiece:
	var pin: FeltPiece = FeltPiece.new()
	pin.soft = false
	var shaft: PackedVector2Array = FeltShapes.points(
		PackedFloat32Array([-PIN_LENGTH, -1.5, 0, -1.5, 7, 0, 0, 1.5, -PIN_LENGTH, 1.5])
	)
	pin.polygon = _scaled(shaft, UNITS)
	pin.color = shaft_color
	var head: Vector2 = Vector2(-PIN_LENGTH, 0.0) * UNITS
	pin.add_layer(FeltShapes.circle(head, 4.0 * UNITS), head_color)
	return pin


## Points along +x like the pin: thin, with a little eye at the back.
static func _needle(color: Color = NEEDLE_COLOR, eye_color: Color = BUTTON_HOLE_COLOR) -> FeltPiece:
	var needle: FeltPiece = FeltPiece.new()
	needle.soft = false
	var half: float = NEEDLE_LENGTH / 2.0
	var shaft: PackedVector2Array = FeltShapes.points(
		PackedFloat32Array([-half, -2.4, half - 6, -2, half, 0, half - 6, 2, -half, 2.4])
	)
	needle.polygon = _scaled(shaft, UNITS)
	needle.color = color
	var eye_center: Vector2 = Vector2(-half + 4.0, 0.0) * UNITS
	var eye: PackedVector2Array = FeltShapes.ellipse(eye_center, Vector2(2.6, 1.1) * UNITS)
	needle.add_layer(eye, eye_color)
	return needle


static func _button() -> FeltPiece:
	var button: FeltPiece = FeltPiece.new()
	var radius: float = BUTTON_RADIUS * UNITS
	button.polygon = FeltShapes.circle(Vector2.ZERO, radius, 20)
	button.color = BUTTON_COLOR
	for hole: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		button.add_layer(FeltShapes.circle(hole * radius * 0.28, radius * 0.14), BUTTON_HOLE_COLOR)
	return button


## A round puff of stuffing with smaller puffs around its edge; fills CLOUD_RADIUS.
static func _cloud() -> FeltPiece:
	var cloud: FeltPiece = FeltPiece.new()
	var radius: float = CLOUD_RADIUS * UNITS
	cloud.polygon = FeltShapes.circle(Vector2.ZERO, radius * 0.8, 28)
	cloud.color = CLOUD_COLOR
	for i: int in 7:
		var at: Vector2 = Vector2.from_angle(TAU * i / 7.0) * radius * 0.62
		cloud.add_layer(FeltShapes.circle(at, radius * 0.36), CLOUD_COLOR.lightened(0.15))
	return cloud


static func _yarn(color: Color = YARN_COLOR, strand_color: Color = YARN_STRAND_COLOR) -> FeltPiece:
	var ball: FeltPiece = FeltPiece.new()
	var radius: float = YARN_RADIUS * UNITS
	ball.polygon = FeltShapes.circle(Vector2.ZERO, radius, 22)
	ball.color = color
	for offset: float in [-0.45, 0.0, 0.45]:
		var strand: PackedVector2Array = FeltShapes.ellipse(
			Vector2(offset * radius, 0.0), Vector2(radius * 0.18, radius * 0.85), 12
		)
		ball.add_line(strand, strand_color, 2.0 * UNITS)
	return ball


## Upside down like a little bucket: wide rim at the bottom, dimples on the side.
static func _thimble() -> FeltPiece:
	var unit: float = THIMBLE_SIZE * UNITS
	var thimble: FeltPiece = FeltPiece.new()
	thimble.polygon = _scaled(
		FeltShapes.points(PackedFloat32Array([-7, 8, -5, -6, 0, -9, 5, -6, 7, 8])), unit
	)
	thimble.color = THIMBLE_COLOR
	for y: float in [-3.0, 2.0]:
		for x: float in [-2.5, 0.0, 2.5]:
			var dimple: PackedVector2Array = FeltShapes.circle(Vector2(x, y) * unit, 0.9 * unit, 8)
			thimble.add_layer(dimple, THIMBLE_DOT_COLOR)
	var rim: PackedVector2Array = FeltShapes.ellipse(Vector2(0, 8) * unit, Vector2(8, 2) * unit)
	thimble.add_layer(rim, THIMBLE_COLOR.darkened(0.15))
	return thimble


## A flat dark ellipse with a pale rim (readable on the dark floor); fills SHADOW_RADIUS across.
static func _shadow() -> FeltPiece:
	var shadow: FeltPiece = FeltPiece.new()
	shadow.soft = false
	var radius: float = SHADOW_RADIUS * UNITS
	shadow.polygon = FeltShapes.ellipse(Vector2.ZERO, Vector2(radius, radius * 0.8))
	shadow.color = SHADOW_COLOR
	shadow.outline_width = 2.0 * UNITS
	shadow.outline_color = SHADOW_RIM_COLOR
	return shadow


## The mortar's landing ring: a felt band with a stitched seam inside; RING_RADIUS across.
static func _ring() -> FeltPiece:
	var ring: FeltPiece = FeltPiece.new()
	ring.soft = false
	var radius: float = RING_RADIUS * UNITS
	var band: PackedVector2Array = FeltShapes.circle(Vector2.ZERO, radius, 48)
	band.append(band[0])
	ring.add_line(band, RING_COLOR, RING_WIDTH * UNITS)
	var seam: PackedVector2Array = FeltShapes.circle(Vector2.ZERO, radius - 3.5 * UNITS, 48)
	seam.append(seam[0])
	ring.set_seam(seam, RING_STITCH_COLOR)
	return ring


## A flat disc that fills the landing ring as the thimble comes down; RING_RADIUS across.
static func _disc() -> FeltPiece:
	var disc: FeltPiece = FeltPiece.new()
	disc.soft = false
	disc.polygon = FeltShapes.circle(Vector2.ZERO, RING_RADIUS * UNITS, 48)
	disc.color = RING_COLOR
	return disc


## A small puff of felt dust kicked up by the landing.
static func _dust() -> FeltPiece:
	var dust: FeltPiece = FeltPiece.new()
	dust.polygon = FeltShapes.circle(Vector2.ZERO, DUST_RADIUS * UNITS, 16)
	dust.color = DUST_COLOR
	return dust


## A round puff of yarn with loose strands sticking out; fills BURST_RADIUS.
static func _burst() -> FeltPiece:
	var burst: FeltPiece = FeltPiece.new()
	burst.soft = false
	var radius: float = BURST_RADIUS * UNITS
	burst.polygon = FeltShapes.circle(Vector2.ZERO, radius * 0.85, 28)
	burst.color = YARN_COLOR
	for i: int in 9:
		var angle: float = TAU * i / 9.0
		var root: Vector2 = Vector2.from_angle(angle) * radius * 0.5
		var tip: Vector2 = Vector2.from_angle(angle + 0.2) * radius
		burst.add_line([root, tip], YARN_STRAND_COLOR, 2.0 * UNITS)
	return burst


## A crescent of thread around the pivot, centred on +x, WHIP_ARC wide; thickest in the middle.
static func _whip() -> FeltPiece:
	var whip: FeltPiece = FeltPiece.new()
	whip.soft = false
	var radius: float = WHIP_RADIUS * UNITS
	var half: float = deg_to_rad(WHIP_ARC) / 2.0
	var outer: PackedVector2Array = []
	var inner: PackedVector2Array = []
	for i: int in 25:
		var t: float = i / 24.0
		var angle: float = lerpf(-half, half, t)
		outer.append(Vector2.from_angle(angle) * radius)
		inner.append(Vector2.from_angle(angle) * radius * (1.0 - 0.2 * sin(PI * t)))
	inner.reverse()
	outer.append_array(inner)
	whip.polygon = outer
	whip.color = WHIP_COLOR
	return whip


## A zipper from the pivot along +x, ZIPPER_LENGTH long, with teeth and a pull tab at the end.
static func _zipper() -> FeltPiece:
	var zipper: FeltPiece = FeltPiece.new()
	zipper.soft = false
	var length: float = ZIPPER_LENGTH * UNITS
	var half_width: float = 5.0 * UNITS
	zipper.polygon = FeltShapes.points(
		PackedFloat32Array([0, -half_width, length, -half_width, length, half_width, 0, half_width])
	)
	zipper.color = ZIPPER_COLOR
	var tooth: float = 4.0 * UNITS
	for i: int in int(length / (tooth * 2.0)):
		var x: float = i * tooth * 2.0 + (tooth if i % 2 == 1 else 0.0)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var box: Rect2 = Rect2(x, minf(0.0, side * half_width * 0.8), tooth, half_width * 0.8)
		zipper.add_layer(_rect_points(box), ZIPPER_TEETH_COLOR)
	var tab: PackedVector2Array = FeltShapes.ellipse(Vector2(length, 0.0), Vector2(4, 7) * UNITS)
	zipper.add_layer(tab, ZIPPER_TEETH_COLOR)
	return zipper


static func _rect_points(box: Rect2) -> PackedVector2Array:
	var top_right: Vector2 = Vector2(box.end.x, box.position.y)
	var bottom_left: Vector2 = Vector2(box.position.x, box.end.y)
	return [box.position, top_right, box.end, bottom_left]


static func _bullet() -> FeltPiece:
	var ball: FeltPiece = FeltPiece.new()
	ball.soft = false
	var radius: float = BULLET_RADIUS * UNITS
	ball.polygon = FeltShapes.circle(Vector2.ZERO, radius, 24)
	ball.color = BULLET_COLOR
	ball.outline_width = radius * 0.3
	ball.outline_color = BULLET_OUTLINE_COLOR
	var core: PackedVector2Array = FeltShapes.circle(Vector2(-0.2, -0.2) * radius, radius * 0.45)
	ball.add_layer(core, BULLET_CORE_COLOR)
	return ball


## The bloater's cloud: a see-through red haze with stuffing puffs, and a bright rim with a dark
## edge exactly at the hit radius (never as soft as the players' own Stuffing Cloud).
static func _hazard() -> FeltPiece:
	var cloud: FeltPiece = FeltPiece.new()
	cloud.soft = false
	var radius: float = HAZARD_RADIUS * UNITS
	cloud.polygon = FeltShapes.circle(Vector2.ZERO, radius, 40)
	cloud.color = Color(BULLET_COLOR, 0.28)
	var edge: PackedVector2Array = _closed_circle(Vector2.ZERO, radius * 0.97, 48)
	cloud.add_line(edge, BULLET_OUTLINE_COLOR, radius * 0.1)
	cloud.add_line(_closed_circle(Vector2.ZERO, radius * 0.95, 48), BULLET_COLOR, radius * 0.05)
	var puff_color: Color = Color(BULLET_CORE_COLOR, 0.6)
	for i: int in 5:
		var at: Vector2 = Vector2.from_angle(TAU * i / 5.0 + 0.4) * radius * 0.45
		cloud.add_line(_closed_circle(at, radius * 0.2, 16), puff_color, radius * 0.03)
	return cloud


static func _closed_circle(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var ring: PackedVector2Array = FeltShapes.circle(center, radius, segments)
	ring.append(ring[0])
	return ring


## A white felt star with `points` points, `radius` across on screen (tinted where it is used).
static func _star(radius: float, points: int) -> FeltPiece:
	var star: FeltPiece = FeltPiece.new()
	star.soft = false
	var outline: PackedVector2Array = []
	for i: int in points * 2:
		var reach: float = radius if i % 2 == 0 else radius * 0.4
		outline.append(Vector2.from_angle(TAU * i / (points * 2) - PI / 2.0) * reach * UNITS)
	star.polygon = outline
	star.color = Color.WHITE
	return star
