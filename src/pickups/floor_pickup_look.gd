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


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	return {MAGNET: _magnet()}


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
