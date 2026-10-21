class_name ElephantLook
extends RefCounted
## The tank: a big zombie elephant. A heavy grey felt body on stubby legs with a sewn-on patch,
## huge floppy ears, a long stitched trunk, a button eye and an X eye. Drawn larger than the
## others and stomps slowly.

const OUTLINE: float = 6.0
const BODY_COLOR: Color = Color("#7a8093")
const HEAD_COLOR: Color = Color("#868c9e")
const EAR_COLOR: Color = Color("#737a8c")
const INNER_EAR_COLOR: Color = Color("#b49aa5")
const LEG_COLOR: Color = Color("#6d7385")
const PATCH_COLOR: Color = Color("#5c7d6a")
const PATCH_STITCH_COLOR: Color = Color("#d9e6c9")
const TRUNK_LINE_COLOR: Color = Color("#565c6c")
const TUSK_COLOR: Color = Color("#ece4d0")
const X_EYE_COLOR: Color = Color("#2a2a2a")
const BODY_RADII: Vector2 = Vector2(56, 48)
const HEAD_CENTER: Vector2 = Vector2(100, 104)
const HEAD_RADIUS: float = 40.0


static func spec() -> ZombieLook:
	var look: ZombieLook = ZombieLook.new()
	look.prefix = "elephant"
	look.anchor = Vector2(100, 160)
	look.root_pivot = Vector2(100, 230)
	look.shadow_pivot = Vector2(100, 234)
	look.limb_left_pivot = Vector2(70, 92)
	look.limb_right_pivot = Vector2(130, 92)
	look.body_pivot = Vector2(100, 178)
	look.head_pivot = HEAD_CENTER
	look.eye_pivot = Vector2(84, 96)
	look.draw_scale = 0.5
	look.steps_per_second = 0.8
	look.sway_degrees = 4.0
	look.bounce = 3.0
	look.limb_swing = 9.0
	look.limbs_mirrored = true
	return look


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var look: ZombieLook = spec()
	var parts: Dictionary[StringName, FeltPiece] = {
		look.key("shadow"): ZombieLook.shadow(look.shadow_pivot, Vector2(64, 13)),
		look.key("limb_left"): _ear(Vector2(50, 108), look.limb_left_pivot, -12.0),
		look.key("limb_right"): _ear(Vector2(150, 108), look.limb_right_pivot, 12.0),
		look.key("body"): _body(look.body_pivot),
		look.key("head"): _head(look.head_pivot),
		look.key("eye"): ZombieLook.button_eye(look.eye_pivot, 8.0),
		look.key("flash"): _flash(look),
	}
	return parts


static func _ear(center: Vector2, base: Vector2, tilt: float) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(center, Vector2(30, 38), 24)
	var ear: FeltPiece = ZombieLook.part(base, FeltShapes.rotated(shape, center, tilt), EAR_COLOR)
	ear.outline_width = OUTLINE
	var inner: PackedVector2Array = FeltShapes.ellipse(center, Vector2(17, 25), 20)
	ear.add_layer(FeltShapes.rotated(inner, center, tilt), INNER_EAR_COLOR)
	return ear


static func _body(pivot: Vector2) -> FeltPiece:
	var body: FeltPiece = ZombieLook.part(pivot, FeltShapes.ellipse(pivot, BODY_RADII), BODY_COLOR)
	body.outline_width = OUTLINE
	for x: float in [66.0, 134.0]:
		body.add_layer(FeltShapes.ellipse(Vector2(x, 220), Vector2(16, 12), 16), LEG_COLOR)
	var patch_center: Vector2 = Vector2(128, 182)
	var patch: PackedVector2Array = FeltShapes.points([112, 168, 144, 168, 144, 196, 112, 196])
	body.add_layer(FeltShapes.rotated(patch, patch_center, -6.0), PATCH_COLOR)
	var stitch: PackedVector2Array = FeltShapes.points(
		[115, 171, 141, 171, 141, 193, 115, 193, 115, 171]
	)
	body.add_line(FeltShapes.rotated(stitch, patch_center, -6.0), PATCH_STITCH_COLOR, 1.5)
	return body


static func _head(pivot: Vector2) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.circle(HEAD_CENTER, HEAD_RADIUS, 28)
	var head: FeltPiece = ZombieLook.part(pivot, shape, HEAD_COLOR)
	head.outline_width = OUTLINE
	var trunk: PackedVector2Array = FeltShapes.points(
		[88, 118, 112, 118, 114, 150, 122, 168, 112, 176, 100, 160]
	)
	head.add_layer(trunk, HEAD_COLOR)
	for y: float in [130.0, 142.0, 154.0]:
		head.add_line(FeltShapes.points([92 + (y - 130) * 0.3, y, 112, y]), TRUNK_LINE_COLOR, 2.0)
	head.add_layer(FeltShapes.points([80, 126, 74, 146, 86, 130]), TUSK_COLOR)
	head.add_line(FeltShapes.points([109, 89, 123, 103]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([123, 89, 109, 103]), X_EYE_COLOR, 3.0)
	return head


## White silhouette of body, head and trunk (relative to the body pivot).
static func _flash(look: ZombieLook) -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.ellipse(look.body_pivot, BODY_RADII)
	var flash: FeltPiece = ZombieLook.part(look.body_pivot, silhouette, Color.WHITE)
	flash.soft = false
	flash.add_layer(FeltShapes.circle(HEAD_CENTER, HEAD_RADIUS, 28), Color.WHITE)
	flash.add_layer(FeltShapes.ellipse(Vector2(50, 108), Vector2(30, 38), 24), Color.WHITE)
	flash.add_layer(FeltShapes.ellipse(Vector2(150, 108), Vector2(30, 38), 24), Color.WHITE)
	return flash
