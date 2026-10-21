class_name SockKingLook
extends RefCounted
## The boss: the Sock Puppet King. A tall striped zombie sock whose toe is his head, with a big
## felt mouth, a button eye and an X eye, a crooked cardboard crown and a little red cape that
## flaps behind him.

const OUTLINE: float = 6.0
const SOCK_COLOR: Color = Color("#d9ccb4")
const STRIPE_COLOR: Color = Color("#b34a3f")
const HEEL_COLOR: Color = Color("#c4b598")
const MOUTH_COLOR: Color = Color("#5a1f2a")
const TONGUE_COLOR: Color = Color("#d9707a")
const CROWN_COLOR: Color = Color("#c79a55")
const CROWN_DARK_COLOR: Color = Color("#8a6330")
const JEWEL_COLORS: PackedColorArray = [Color("#4fc3f7"), Color("#7bd88f"), Color("#ff7ad9")]
const CAPE_COLOR: Color = Color("#8e2d3f")
const CAPE_TRIM_COLOR: Color = Color("#f2c230")
const DARN_COLOR: Color = Color("#7f8fa8")
const DARN_STITCH_COLOR: Color = Color("#3d4658")
const X_EYE_COLOR: Color = Color("#2a2a2a")
const BODY_CENTER: Vector2 = Vector2(100, 180)
const BODY_RADII: Vector2 = Vector2(36, 48)
const HEAD_CENTER: Vector2 = Vector2(102, 104)
const HEAD_RADII: Vector2 = Vector2(48, 36)


static func spec() -> ZombieLook:
	var look: ZombieLook = ZombieLook.new()
	look.prefix = "sock_king"
	look.anchor = Vector2(100, 160)
	look.root_pivot = Vector2(100, 228)
	look.shadow_pivot = Vector2(100, 232)
	look.limb_left_pivot = Vector2(84, 136)
	look.limb_right_pivot = Vector2(116, 136)
	look.body_pivot = BODY_CENTER
	look.head_pivot = HEAD_CENTER
	look.eye_pivot = Vector2(86, 94)
	look.steps_per_second = 1.0
	look.sway_degrees = 7.0
	look.bounce = 4.0
	look.limb_swing = 10.0
	look.limbs_mirrored = true
	return look


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var look: ZombieLook = spec()
	var parts: Dictionary[StringName, FeltPiece] = {
		look.key("shadow"): ZombieLook.shadow(look.shadow_pivot, Vector2(52, 12)),
		look.key("limb_left"): _cape(look.limb_left_pivot, -1.0),
		look.key("limb_right"): _cape(look.limb_right_pivot, 1.0),
		look.key("body"): _body(look.body_pivot),
		look.key("head"): _head(look.head_pivot),
		look.key("eye"): ZombieLook.button_eye(look.eye_pivot, 8.0),
		look.key("flash"): _flash(look),
	}
	return parts


## One half of the cape, hanging from the shoulder `base` to the side `side` (-1 left, 1 right).
static func _cape(base: Vector2, side: float) -> FeltPiece:
	var outline: PackedVector2Array = [
		base,
		base + Vector2(side * 22, 10),
		base + Vector2(side * 40, 88),
		base + Vector2(side * 4, 92),
	]
	var cape: FeltPiece = ZombieLook.part(base, outline, CAPE_COLOR)
	cape.outline_width = OUTLINE
	var hem: PackedVector2Array = [base + Vector2(side * 38, 82), base + Vector2(side * 6, 86)]
	cape.add_line(hem, CAPE_TRIM_COLOR, 5.0)
	return cape


static func _body(pivot: Vector2) -> FeltPiece:
	var body: FeltPiece = ZombieLook.part(pivot, FeltShapes.ellipse(pivot, BODY_RADII), SOCK_COLOR)
	body.outline_width = OUTLINE
	body.add_layer(FeltShapes.ellipse(Vector2(124, 214), Vector2(20, 12)), HEEL_COLOR)
	for y: float in [148.0, 166.0, 184.0, 202.0]:
		var half: float = BODY_RADII.x * sqrt(1.0 - pow((y - pivot.y) / BODY_RADII.y, 2.0)) - 3.0
		body.add_line(FeltShapes.points([pivot.x - half, y, pivot.x + half, y]), STRIPE_COLOR, 7.0)
	var darn: Vector2 = Vector2(82, 192)
	body.add_layer(FeltShapes.circle(darn, 9.0, 14), DARN_COLOR)
	for offset: float in [-4.0, 0.0, 4.0]:
		var across: PackedVector2Array = [darn + Vector2(-8, offset), darn + Vector2(8, offset)]
		body.add_line(across, DARN_STITCH_COLOR, 1.5)
	return body


## The sock's toe: a wide head with a big felt mouth, an X eye and the cardboard crown.
static func _head(pivot: Vector2) -> FeltPiece:
	var head: FeltPiece = ZombieLook.part(
		pivot, FeltShapes.ellipse(HEAD_CENTER, HEAD_RADII), SOCK_COLOR
	)
	head.outline_width = OUTLINE
	head.add_line(FeltShapes.points([60, 96, 146, 92]), STRIPE_COLOR, 6.0)
	head.add_layer(FeltShapes.ellipse(Vector2(108, 120), Vector2(32, 10), 20), MOUTH_COLOR)
	head.add_layer(FeltShapes.ellipse(Vector2(114, 124), Vector2(12, 5), 12), TONGUE_COLOR)
	head.add_line(FeltShapes.points([112, 82, 126, 96]), X_EYE_COLOR, 3.0)
	head.add_line(FeltShapes.points([126, 82, 112, 96]), X_EYE_COLOR, 3.0)
	var crown: PackedVector2Array = FeltShapes.points(
		[68, 78, 64, 40, 80, 56, 92, 30, 104, 52, 118, 34, 126, 56, 142, 42, 136, 76]
	)
	head.add_layer(crown, CROWN_DARK_COLOR)
	head.add_layer(FeltShapes.shrunk(crown, 0.88), CROWN_COLOR)
	head.add_line(FeltShapes.points([70, 70, 134, 68]), CROWN_DARK_COLOR, 3.0)
	for i: int in JEWEL_COLORS.size():
		var jewel: Vector2 = Vector2(82 + i * 20, 62 - (i % 2) * 4)
		head.add_layer(FeltShapes.circle(jewel, 5.0, 10), JEWEL_COLORS[i])
	return head


## White silhouette of body and head (relative to the body pivot).
static func _flash(look: ZombieLook) -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.ellipse(look.body_pivot, BODY_RADII)
	var flash: FeltPiece = ZombieLook.part(look.body_pivot, silhouette, Color.WHITE)
	flash.soft = false
	flash.add_layer(FeltShapes.ellipse(HEAD_CENTER, HEAD_RADII), Color.WHITE)
	flash.add_layer(FeltShapes.ellipse(Vector2(124, 214), Vector2(20, 12)), Color.WHITE)
	return flash
