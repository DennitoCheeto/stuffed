class_name ShamblerLook
extends RefCounted
## The shambler: a zombie teddy (docs/art/felt-style-concept.html). Torn seam, mismatched patch,
## stuffing poking out, a button eye and an X eye.

const OUTLINE: float = 6.0
const ARM_COLOR: Color = Color("#6f7c5e")
const BODY_COLOR: Color = Color("#76825f")
const HEAD_COLOR: Color = Color("#83906c")
const EAR_COLOR: Color = Color("#7d8a6a")
const MUZZLE_COLOR: Color = Color("#a9b08c")
const PATCH_COLOR: Color = Color("#8a5a7a")
const PATCH_STITCH_COLOR: Color = Color("#e6c7dc")
const STUFFING_COLOR: Color = Color("#f4f1e8")
const DARK_LINE_COLOR: Color = Color("#3d4530")
const SEAM_COLOR: Color = Color("#5c6649")
const X_EYE_COLOR: Color = Color("#2a2a2a")


static func spec() -> ZombieLook:
	var look: ZombieLook = ZombieLook.new()
	look.prefix = "shambler"
	look.anchor = Vector2(100, 165)
	look.root_pivot = Vector2(100, 228)
	look.shadow_pivot = Vector2(100, 232)
	look.limb_left_pivot = Vector2(64, 142)
	look.limb_right_pivot = Vector2(136, 142)
	look.body_pivot = Vector2(100, 175)
	look.head_pivot = Vector2(100, 90)
	look.eye_pivot = Vector2(80, 82)
	look.steps_per_second = 1.3
	look.sway_degrees = 6.0
	look.bounce = 5.0
	look.limb_swing = 14.0
	look.limbs_mirrored = true
	return look


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var look: ZombieLook = spec()
	var parts: Dictionary[StringName, FeltPiece] = {
		look.key("shadow"): ZombieLook.shadow(look.shadow_pivot, Vector2(58, 12)),
		look.key("limb_left"): _arm(Vector2(55, 160), look.limb_left_pivot, -25.0),
		look.key("limb_right"): _arm(Vector2(145, 160), look.limb_right_pivot, 25.0),
		look.key("body"): _body(look.body_pivot),
		look.key("head"): _head(look.head_pivot),
		look.key("eye"): ZombieLook.button_eye(look.eye_pivot, 9.0),
		look.key("flash"): _flash(look),
	}
	return parts


static func _arm(center: Vector2, shoulder: Vector2, tilt: float) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(center, Vector2(16, 22), 20)
	var outline: PackedVector2Array = FeltShapes.rotated(shape, center, tilt)
	var arm: FeltPiece = ZombieLook.part(shoulder, outline, ARM_COLOR)
	arm.outline_width = OUTLINE
	return arm


static func _body(pivot: Vector2) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(pivot, Vector2(50, 55))
	var body: FeltPiece = ZombieLook.part(pivot, shape, BODY_COLOR)
	body.outline_width = OUTLINE
	var patch_center: Vector2 = Vector2(129, 173)
	var patch: PackedVector2Array = FeltShapes.points([115, 160, 143, 160, 143, 186, 115, 186])
	body.add_layer(FeltShapes.rotated(patch, patch_center, -8.0), PATCH_COLOR)
	var stitch: PackedVector2Array = FeltShapes.points(
		[118, 163, 140, 163, 140, 183, 118, 183, 118, 163]
	)
	body.add_line(FeltShapes.rotated(stitch, patch_center, -8.0), PATCH_STITCH_COLOR, 1.5)
	body.add_layer(FeltShapes.circle(Vector2(78, 196), 8.0, 12), STUFFING_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(88, 203), 6.0, 12), STUFFING_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(70, 205), 5.0, 12), STUFFING_COLOR)
	var rip: PackedVector2Array = FeltShapes.points([62, 188, 72, 196, 68, 202, 80, 206])
	body.add_line(rip, DARK_LINE_COLOR, 2.0)
	body.set_seam(FeltShapes.points([100, 135, 100, 225]), SEAM_COLOR)
	return body


static func _head(pivot: Vector2) -> FeltPiece:
	var ear: PackedVector2Array = FeltShapes.circle(Vector2(62, 48), 18.0)
	var head: FeltPiece = ZombieLook.part(pivot, ear, EAR_COLOR)
	head.outline_width = OUTLINE
	head.add_layer(FeltShapes.circle(Vector2(138, 48), 18.0), ARM_COLOR)
	head.add_layer(FeltShapes.circle(pivot, 50.0, 28), HEAD_COLOR)
	head.add_layer(FeltShapes.ellipse(Vector2(100, 108), Vector2(22, 16), 20), MUZZLE_COLOR)
	head.add_line(FeltShapes.points([113, 75, 127, 89]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([127, 75, 113, 89]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([88, 116, 112, 116]), DARK_LINE_COLOR, 2.0)
	for x: float in [92.0, 100.0, 108.0]:
		head.add_line(FeltShapes.points([x, 111, x, 121]), DARK_LINE_COLOR, 2.0)
	return head


## White silhouette of body, head and ears (relative to the body pivot).
static func _flash(look: ZombieLook) -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.ellipse(look.body_pivot, Vector2(50, 55))
	var flash: FeltPiece = ZombieLook.part(look.body_pivot, silhouette, Color.WHITE)
	flash.soft = false
	flash.add_layer(FeltShapes.circle(look.head_pivot, 50.0, 28), Color.WHITE)
	flash.add_layer(FeltShapes.circle(Vector2(62, 48), 18.0), Color.WHITE)
	flash.add_layer(FeltShapes.circle(Vector2(138, 48), 18.0), Color.WHITE)
	return flash
