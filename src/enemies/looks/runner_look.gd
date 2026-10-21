class_name RunnerLook
extends RefCounted
## The runner: a zombie sock bunny. A striped sock body with a darned hole, long floppy ears (one
## torn and drooping), a button eye and an X eye. Hops fast.

const OUTLINE: float = 6.0
const SOCK_COLOR: Color = Color("#8c7f9e")
const STRIPE_COLOR: Color = Color("#6b5f80")
const HEAD_COLOR: Color = Color("#9a8dab")
const INNER_EAR_COLOR: Color = Color("#c3b8cf")
const DARN_COLOR: Color = Color("#c9b98f")
const DARN_STITCH_COLOR: Color = Color("#5b4f45")
const NOSE_COLOR: Color = Color("#5a4d6b")
const DARK_LINE_COLOR: Color = Color("#3b3247")
const X_EYE_COLOR: Color = Color("#2a2a2a")
const BODY_RADII: Vector2 = Vector2(34, 46)


static func spec() -> ZombieLook:
	var look: ZombieLook = ZombieLook.new()
	look.prefix = "runner"
	look.anchor = Vector2(100, 160)
	look.root_pivot = Vector2(100, 224)
	look.shadow_pivot = Vector2(100, 228)
	look.limb_left_pivot = Vector2(88, 78)
	look.limb_right_pivot = Vector2(112, 80)
	look.body_pivot = Vector2(100, 176)
	look.head_pivot = Vector2(100, 102)
	look.eye_pivot = Vector2(86, 98)
	look.steps_per_second = 3.2
	look.sway_degrees = 4.0
	look.bounce = 10.0
	look.limb_swing = 18.0
	look.limbs_mirrored = false
	return look


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var look: ZombieLook = spec()
	var left_ear: FeltPiece = _ear(Vector2(84, 46), Vector2(11, 34), -10.0, look.limb_left_pivot)
	var right_ear: FeltPiece = _ear(Vector2(130, 62), Vector2(10, 30), 55.0, look.limb_right_pivot)
	var parts: Dictionary[StringName, FeltPiece] = {
		look.key("shadow"): ZombieLook.shadow(look.shadow_pivot, Vector2(42, 10)),
		look.key("limb_left"): left_ear,
		look.key("limb_right"): right_ear,
		look.key("body"): _body(look.body_pivot),
		look.key("head"): _head(look.head_pivot),
		look.key("eye"): ZombieLook.button_eye(look.eye_pivot, 7.0),
		look.key("flash"): _flash(look),
	}
	return parts


static func _ear(center: Vector2, radii: Vector2, tilt: float, base: Vector2) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(center, radii)
	var outer: PackedVector2Array = FeltShapes.rotated(shape, center, tilt)
	var ear: FeltPiece = ZombieLook.part(base, outer, HEAD_COLOR)
	ear.outline_width = OUTLINE
	var inner: PackedVector2Array = FeltShapes.ellipse(center, radii * Vector2(0.45, 0.7))
	ear.add_layer(FeltShapes.rotated(inner, center, tilt), INNER_EAR_COLOR)
	return ear


static func _body(pivot: Vector2) -> FeltPiece:
	var body: FeltPiece = ZombieLook.part(pivot, FeltShapes.ellipse(pivot, BODY_RADII), SOCK_COLOR)
	body.outline_width = OUTLINE
	body.add_layer(FeltShapes.ellipse(Vector2(120, 214), Vector2(24, 12)), SOCK_COLOR)
	for y: float in [150.0, 168.0, 186.0]:
		var half: float = BODY_RADII.x * sqrt(1.0 - pow((y - pivot.y) / BODY_RADII.y, 2.0)) - 3.0
		body.add_line(FeltShapes.points([pivot.x - half, y, pivot.x + half, y]), STRIPE_COLOR, 7.0)
	var darn: Vector2 = Vector2(84, 196)
	body.add_layer(FeltShapes.circle(darn, 8.0, 14), DARN_COLOR)
	for offset: float in [-4.0, 0.0, 4.0]:
		var across: PackedVector2Array = [darn + Vector2(-7, offset), darn + Vector2(7, offset)]
		body.add_line(across, DARN_STITCH_COLOR, 1.5)
	return body


static func _head(pivot: Vector2) -> FeltPiece:
	var head: FeltPiece = ZombieLook.part(pivot, FeltShapes.circle(pivot, 34.0, 26), HEAD_COLOR)
	head.outline_width = OUTLINE
	head.add_layer(FeltShapes.ellipse(Vector2(100, 116), Vector2(14, 10), 16), INNER_EAR_COLOR)
	head.add_layer(FeltShapes.circle(Vector2(100, 110), 4.0, 10), NOSE_COLOR)
	head.add_line(FeltShapes.points([109, 89, 119, 99]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([119, 89, 109, 99]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([92, 121, 108, 121]), DARK_LINE_COLOR, 2.0)
	for x: float in [96.0, 104.0]:
		head.add_line(FeltShapes.points([x, 117, x, 125]), DARK_LINE_COLOR, 2.0)
	return head


static func _flash(look: ZombieLook) -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.ellipse(look.body_pivot, BODY_RADII)
	var flash: FeltPiece = ZombieLook.part(look.body_pivot, silhouette, Color.WHITE)
	flash.soft = false
	flash.add_layer(FeltShapes.circle(look.head_pivot, 34.0, 26), Color.WHITE)
	flash.add_layer(FeltShapes.ellipse(Vector2(120, 214), Vector2(24, 12)), Color.WHITE)
	return flash
