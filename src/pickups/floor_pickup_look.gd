class_name FloorPickupLook
extends RefCounted
## The felt floor pickups (spec 02b §3), drawn once into the FeltAtlas. Shapes are in "atlas
## units": three times the on-screen size, for a sharp bake. Banane's soft colours, never the
## red/orange of enemy danger (vision §6).

const DRAW_SCALE: float = 1.0 / 3.0
const MAGNET: StringName = &"floor/magnet"
const MAGNET_BLUE: Color = Color("#4f86d9")
const SILVER: Color = Color("#dfe4ec")
const OUTLINE_COLOR: Color = Color("#1d3a52")
## Soft white-gold glow under every pickup: noticeable, but quieter than enemy danger.
const GLOW_COLOR: Color = Color(1.0, 0.93, 0.66)
## Outer and inner radius of the magnet's bend, and how long its legs are (on screen, pixels).
const MAGNET_OUTER: float = 13.0
const MAGNET_INNER: float = 6.0
const MAGNET_LEGS: float = 9.0
const MAGNET_TIPS: float = 5.0
const SNOW_GLOBE: StringName = &"floor/snow_globe"
const GLASS_BLUE: Color = Color("#cfe8f7")
const BASE_PURPLE: Color = Color("#8f73c4")
const SNOW_WHITE: Color = Color("#fbfbff")
const BANANE_YELLOW: Color = Color("#f2b52e")
const BEAK_ORANGE: Color = Color("#f47a3a")
## Radius of the glass ball (on screen, pixels).
const GLOBE_RADIUS: float = 11.0


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	return {MAGNET: _magnet(), SNOW_GLOBE: _snow_globe()}


## The atlas part for pickup `id` (e.g. &"magnet").
static func key(id: StringName) -> StringName:
	return StringName("floor/%s" % id)


## A blue horseshoe magnet with silver tips, opening downwards; its pivot is the middle of the
## bend.
static func _magnet() -> FeltPiece:
	var outer: float = MAGNET_OUTER / DRAW_SCALE
	var inner: float = MAGNET_INNER / DRAW_SCALE
	var legs: float = MAGNET_LEGS / DRAW_SCALE
	var magnet: FeltPiece = FeltPiece.new()
	magnet.polygon = _horseshoe(outer, inner, legs)
	magnet.color = MAGNET_BLUE
	magnet.outline_width = 5.0
	magnet.outline_color = OUTLINE_COLOR
	var tip: float = legs - MAGNET_TIPS / DRAW_SCALE
	for side: float in [-1.0, 1.0]:
		var a: float = side * inner
		var b: float = side * outer
		magnet.add_layer(FeltShapes.points([a, tip, b, tip, b, legs, a, legs]), SILVER)
	return magnet


## A thick upside-down U: the outer bend, down the right leg, back up inside, down the left.
static func _horseshoe(outer: float, inner: float, legs: float) -> PackedVector2Array:
	var points: PackedVector2Array = [Vector2(-outer, legs)]
	var steps: int = 14
	for i: int in steps + 1:
		var angle: float = PI + PI * i / steps
		points.append(Vector2(cos(angle), sin(angle)) * outer)
	points.append(Vector2(outer, legs))
	points.append(Vector2(inner, legs))
	for i: int in steps + 1:
		var angle: float = TAU - PI * i / steps
		points.append(Vector2(cos(angle), sin(angle)) * inner)
	points.append(Vector2(-inner, legs))
	return points


## A light blue glass ball on a purple base, with a tiny Banane and snowflakes inside; its pivot
## is the middle of the ball.
static func _snow_globe() -> FeltPiece:
	var unit: float = 1.0 / DRAW_SCALE
	var globe: FeltPiece = FeltPiece.new()
	globe.polygon = FeltShapes.circle(Vector2.ZERO, GLOBE_RADIUS * unit, 28)
	globe.color = GLASS_BLUE
	globe.outline_width = 5.0
	globe.outline_color = OUTLINE_COLOR
	var base: PackedFloat32Array = [-9.0, 7.0, 9.0, 7.0, 12.0, 15.0, -12.0, 15.0]
	for i: int in base.size():
		base[i] *= unit
	globe.add_layer(FeltShapes.points(base), BASE_PURPLE)
	# Tiny Banane: a yellow body with an orange beak, standing on a snowy hill.
	var hill: PackedVector2Array = FeltShapes.ellipse(Vector2(0, 6) * unit, Vector2(8, 3) * unit)
	globe.add_layer(hill, SNOW_WHITE)
	var body: PackedVector2Array = FeltShapes.ellipse(Vector2(0, 1) * unit, Vector2(3.5, 4.5) * unit)
	globe.add_layer(body, BANANE_YELLOW)
	globe.add_layer(FeltShapes.circle(Vector2(2.8, -0.5) * unit, 1.3 * unit, 10), BEAK_ORANGE)
	var flakes: Array[Vector2] = [Vector2(-6, -4), Vector2(5, -6), Vector2(-2, -8), Vector2(7, 1)]
	for flake: Vector2 in flakes:
		globe.add_layer(FeltShapes.circle(flake * unit, 1.0 * unit, 8), SNOW_WHITE)
	var shine: PackedVector2Array = []
	for i: int in 7:
		var angle: float = PI * (1.1 + 0.35 * i / 6.0)
		shine.append(Vector2(cos(angle), sin(angle)) * (GLOBE_RADIUS - 3.0) * unit)
	globe.add_line(shine, SNOW_WHITE, 4.0)
	return globe
