class_name FrogLook
extends RefCounted
## The spitter: a zombie frog. A squat felt body with a pale belly and a torn patch, a wide head
## with two eye bumps (a button eye and an X eye) and a long stitched mouth. Puffs up before it
## spits (ZombiePuppet.puff).

const OUTLINE: float = 6.0
const BODY_COLOR: Color = Color("#5f8f80")
const HEAD_COLOR: Color = Color("#6c9c8c")
const LEG_COLOR: Color = Color("#58857a")
const BELLY_COLOR: Color = Color("#c3cfa2")
const SPOT_COLOR: Color = Color("#4b7266")
const PATCH_COLOR: Color = Color("#b07a4f")
const PATCH_STITCH_COLOR: Color = Color("#f0d9b5")
const STUFFING_COLOR: Color = Color("#f4f1e8")
const MOUTH_COLOR: Color = Color("#2f3d38")
const X_EYE_COLOR: Color = Color("#2a2a2a")
const BODY_RADII: Vector2 = Vector2(52, 42)
const HEAD_CENTER: Vector2 = Vector2(100, 128)
const HEAD_RADII: Vector2 = Vector2(56, 32)
const LEFT_BUMP: Vector2 = Vector2(72, 98)
const RIGHT_BUMP: Vector2 = Vector2(128, 98)
const BUMP_RADIUS: float = 18.0


static func spec() -> ZombieLook:
	var look: ZombieLook = ZombieLook.new()
	look.prefix = "frog"
	look.anchor = Vector2(100, 170)
	look.root_pivot = Vector2(100, 222)
	look.shadow_pivot = Vector2(100, 226)
	look.limb_left_pivot = Vector2(64, 196)
	look.limb_right_pivot = Vector2(136, 196)
	look.body_pivot = Vector2(100, 182)
	look.head_pivot = HEAD_CENTER
	look.eye_pivot = LEFT_BUMP
	look.steps_per_second = 2.0
	look.sway_degrees = 3.0
	look.bounce = 12.0
	look.limb_swing = 10.0
	look.limbs_mirrored = true
	return look


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var look: ZombieLook = spec()
	var parts: Dictionary[StringName, FeltPiece] = {
		look.key("shadow"): ZombieLook.shadow(look.shadow_pivot, Vector2(58, 11)),
		look.key("limb_left"): _leg(Vector2(52, 212), look.limb_left_pivot, -15.0),
		look.key("limb_right"): _leg(Vector2(148, 212), look.limb_right_pivot, 15.0),
		look.key("body"): _body(look.body_pivot),
		look.key("head"): _head(look.head_pivot),
		look.key("eye"): ZombieLook.button_eye(look.eye_pivot, 10.0),
		look.key("flash"): _flash(look),
	}
	return parts


static func _leg(center: Vector2, hip: Vector2, tilt: float) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(center, Vector2(20, 11), 18)
	var leg: FeltPiece = ZombieLook.part(hip, FeltShapes.rotated(shape, center, tilt), LEG_COLOR)
	leg.outline_width = OUTLINE
	return leg


static func _body(pivot: Vector2) -> FeltPiece:
	var body: FeltPiece = ZombieLook.part(pivot, FeltShapes.ellipse(pivot, BODY_RADII), BODY_COLOR)
	body.outline_width = OUTLINE
	body.add_layer(FeltShapes.ellipse(Vector2(100, 192), Vector2(34, 26)), BELLY_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(60, 168), 6.0, 12), SPOT_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(142, 176), 5.0, 12), SPOT_COLOR)
	var patch_center: Vector2 = Vector2(122, 196)
	var patch: PackedVector2Array = FeltShapes.points([110, 186, 134, 186, 134, 206, 110, 206])
	body.add_layer(FeltShapes.rotated(patch, patch_center, 10.0), PATCH_COLOR)
	var stitch: PackedVector2Array = FeltShapes.points(
		[113, 189, 131, 189, 131, 203, 113, 203, 113, 189]
	)
	body.add_line(FeltShapes.rotated(stitch, patch_center, 10.0), PATCH_STITCH_COLOR, 1.5)
	body.add_layer(FeltShapes.circle(Vector2(80, 206), 6.0, 12), STUFFING_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(88, 211), 4.5, 12), STUFFING_COLOR)
	return body


static func _head(pivot: Vector2) -> FeltPiece:
	var head: FeltPiece = ZombieLook.part(
		pivot, FeltShapes.circle(LEFT_BUMP, BUMP_RADIUS, 20), HEAD_COLOR
	)
	head.outline_width = OUTLINE
	head.add_layer(FeltShapes.circle(RIGHT_BUMP, BUMP_RADIUS, 20), HEAD_COLOR)
	head.add_layer(FeltShapes.ellipse(HEAD_CENTER, HEAD_RADII, 28), HEAD_COLOR)
	head.add_layer(FeltShapes.circle(Vector2(84, 116), 4.0, 10), SPOT_COLOR)
	head.add_layer(FeltShapes.circle(Vector2(118, 120), 3.0, 10), SPOT_COLOR)
	head.add_line(FeltShapes.points([121, 91, 135, 105]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([135, 91, 121, 105]), X_EYE_COLOR, 3.0)
	var mouth: PackedVector2Array = FeltShapes.points(
		[66, 136, 84, 143, 100, 145, 116, 143, 134, 136]
	)
	head.add_line(mouth, MOUTH_COLOR, 2.5)
	for x: float in [80.0, 92.0, 104.0, 116.0]:
		var y: float = 145.0 if x > 85.0 and x < 112.0 else 142.0
		head.add_line(FeltShapes.points([x, y - 5, x + 2, y + 4]), MOUTH_COLOR, 2.0)
	return head


## White silhouette of body, head and eye bumps (relative to the body pivot).
static func _flash(look: ZombieLook) -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.ellipse(look.body_pivot, BODY_RADII)
	var flash: FeltPiece = ZombieLook.part(look.body_pivot, silhouette, Color.WHITE)
	flash.soft = false
	flash.add_layer(FeltShapes.ellipse(HEAD_CENTER, HEAD_RADII, 28), Color.WHITE)
	flash.add_layer(FeltShapes.circle(LEFT_BUMP, BUMP_RADIUS, 20), Color.WHITE)
	flash.add_layer(FeltShapes.circle(RIGHT_BUMP, BUMP_RADIUS, 20), Color.WHITE)
	return flash
