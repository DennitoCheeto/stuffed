class_name PigLook
extends RefCounted
## The bloater: a zombie balloon pig. A round, over-stuffed balloon body with a tied knot, a
## stretched seam about to split, tiny floppy ears, a snout, a button eye and an X eye. Waddles
## slowly; bursts into a stuffing cloud when killed.

const OUTLINE: float = 6.0
const BODY_COLOR: Color = Color("#b98592")
const EAR_COLOR: Color = Color("#a8737f")
const SNOUT_COLOR: Color = Color("#d7a3ad")
const NOSTRIL_COLOR: Color = Color("#6b3f4a")
const KNOT_COLOR: Color = Color("#9a6370")
const SEAM_COLOR: Color = Color("#7a4b57")
const STUFFING_COLOR: Color = Color("#f4f1e8")
const MOUTH_COLOR: Color = Color("#4a2e36")
const X_EYE_COLOR: Color = Color("#2a2a2a")
const BODY_CENTER: Vector2 = Vector2(100, 152)
const BODY_RADIUS: float = 60.0


static func spec() -> ZombieLook:
	var look: ZombieLook = ZombieLook.new()
	look.prefix = "pig"
	look.anchor = Vector2(100, 160)
	look.root_pivot = Vector2(100, 226)
	look.shadow_pivot = Vector2(100, 230)
	look.limb_left_pivot = Vector2(72, 104)
	look.limb_right_pivot = Vector2(128, 104)
	look.body_pivot = BODY_CENTER
	look.head_pivot = Vector2(100, 160)
	look.eye_pivot = Vector2(80, 138)
	look.draw_scale = 0.34
	look.steps_per_second = 1.0
	look.sway_degrees = 7.0
	look.bounce = 3.0
	look.limb_swing = 16.0
	look.limbs_mirrored = true
	return look


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var look: ZombieLook = spec()
	var parts: Dictionary[StringName, FeltPiece] = {
		look.key("shadow"): ZombieLook.shadow(look.shadow_pivot, Vector2(52, 10)),
		look.key("limb_left"): _ear([58, 112, 66, 82, 86, 100], look.limb_left_pivot),
		look.key("limb_right"): _ear([142, 112, 134, 82, 114, 100], look.limb_right_pivot),
		look.key("body"): _body(look.body_pivot),
		look.key("head"): _head(look.head_pivot),
		look.key("eye"): ZombieLook.button_eye(look.eye_pivot, 9.0),
		look.key("flash"): _flash(look),
	}
	return parts


static func _ear(corners: PackedFloat32Array, base: Vector2) -> FeltPiece:
	var ear: FeltPiece = ZombieLook.part(base, FeltShapes.points(corners), EAR_COLOR)
	ear.outline_width = OUTLINE
	return ear


static func _body(pivot: Vector2) -> FeltPiece:
	var balloon: PackedVector2Array = FeltShapes.circle(BODY_CENTER, BODY_RADIUS, 32)
	var body: FeltPiece = ZombieLook.part(pivot, balloon, BODY_COLOR)
	body.outline_width = OUTLINE
	body.add_layer(FeltShapes.points([90, 222, 100, 208, 110, 222]), KNOT_COLOR)
	body.add_layer(FeltShapes.ellipse(Vector2(76, 210), Vector2(10, 7), 12), EAR_COLOR)
	body.add_layer(FeltShapes.ellipse(Vector2(124, 210), Vector2(10, 7), 12), EAR_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(140, 128), 6.0, 12), STUFFING_COLOR)
	body.add_layer(FeltShapes.circle(Vector2(146, 138), 4.5, 12), STUFFING_COLOR)
	body.set_seam(FeltShapes.points([132, 104, 146, 120, 150, 144, 146, 168]), SEAM_COLOR)
	return body


static func _head(pivot: Vector2) -> FeltPiece:
	var snout_center: Vector2 = Vector2(100, 166)
	var snout: PackedVector2Array = FeltShapes.ellipse(snout_center, Vector2(20, 14), 20)
	var head: FeltPiece = ZombieLook.part(pivot, snout, SNOUT_COLOR)
	head.outline_width = 4.0
	head.add_layer(FeltShapes.ellipse(Vector2(93, 166), Vector2(3.5, 5), 10), NOSTRIL_COLOR)
	head.add_layer(FeltShapes.ellipse(Vector2(107, 166), Vector2(3.5, 5), 10), NOSTRIL_COLOR)
	head.add_line(FeltShapes.points([113, 131, 127, 145]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([127, 131, 113, 145]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([86, 190, 100, 194, 114, 190]), MOUTH_COLOR, 2.0)
	for x: float in [93.0, 100.0, 107.0]:
		head.add_line(FeltShapes.points([x, 188, x, 197]), MOUTH_COLOR, 1.5)
	return head


## White silhouette of the balloon body and ears (relative to the body pivot).
static func _flash(look: ZombieLook) -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.circle(BODY_CENTER, BODY_RADIUS, 32)
	var flash: FeltPiece = ZombieLook.part(look.body_pivot, silhouette, Color.WHITE)
	flash.soft = false
	flash.add_layer(FeltShapes.points([58, 112, 66, 82, 86, 100]), Color.WHITE)
	flash.add_layer(FeltShapes.points([142, 112, 134, 82, 114, 100]), Color.WHITE)
	return flash
