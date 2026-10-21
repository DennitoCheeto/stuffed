class_name ZombiePuppet
extends Node2D
## A zombie plushie made of felt parts (docs/art/felt-style-concept.html): torn seams, a button
## eye, an X eye, a mismatched patch. The parts are drawn once into the FeltAtlas and shown here
## as sprites, moved like a puppet. Its Zombie calls `animate` every frame.

## The teddy concept is about 200 units tall; this makes it about 60 px tall.
const DRAW_SCALE: float = 0.3
## Concept point that sits on the zombie's centre.
const ANCHOR: Vector2 = Vector2(100, 165)
## Concept point the body rocks and squishes around (its feet).
const ROOT_PIVOT: Vector2 = Vector2(100, 228)
const SHADOW_PIVOT: Vector2 = Vector2(100, 232)
const ARM_LEFT_PIVOT: Vector2 = Vector2(64, 142)
const ARM_RIGHT_PIVOT: Vector2 = Vector2(136, 142)
const BODY_PIVOT: Vector2 = Vector2(100, 175)
const HEAD_PIVOT: Vector2 = Vector2(100, 90)
const EYE_PIVOT: Vector2 = Vector2(80, 82)
## Dark edge around the parts, in concept units: enemies get the strongest contrast.
const OUTLINE: float = 6.0
const SHAMBLE_STEPS_PER_SECOND: float = 1.3
const FLASH_TIME: float = 0.08

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
const EYE_COLOR: Color = Color("#2a2a2a")
const EYE_HOLE_COLOR: Color = Color("#666666")
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.35)

var origin: Node2D
var root: Node2D
var body: Sprite2D
var head: Node2D
var arm_left: Sprite2D
var arm_right: Sprite2D
var eye: Sprite2D
## White silhouette shown for a moment when the zombie is hit.
var flash: Sprite2D

var _phase: float = 0.0
var _side: float = 1.0


## Every zombie part as a felt piece, for FeltAtlas to draw once.
static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var parts: Dictionary[StringName, FeltPiece] = {
		&"shambler/shadow": _shadow_part(),
		&"shambler/arm_left": _arm_part(Vector2(55, 160), ARM_LEFT_PIVOT, -25.0),
		&"shambler/arm_right": _arm_part(Vector2(145, 160), ARM_RIGHT_PIVOT, 25.0),
		&"shambler/body": _body_part(),
		&"shambler/head": _head_part(),
		&"shambler/eye": _eye_part(),
		&"shambler/flash": _flash_part(),
	}
	return parts


## Builds the sprites. `phase` (0..1) makes zombies shamble out of step with each other.
func build(phase: float) -> void:
	_phase = phase * TAU
	origin = Node2D.new()
	origin.scale = Vector2.ONE * DRAW_SCALE
	add_child(origin)
	_sprite(origin, &"shambler/shadow", SHADOW_PIVOT - ANCHOR)
	root = Node2D.new()
	root.position = ROOT_PIVOT - ANCHOR
	origin.add_child(root)
	arm_left = _sprite(root, &"shambler/arm_left", ARM_LEFT_PIVOT - ROOT_PIVOT)
	arm_right = _sprite(root, &"shambler/arm_right", ARM_RIGHT_PIVOT - ROOT_PIVOT)
	body = _sprite(root, &"shambler/body", BODY_PIVOT - ROOT_PIVOT)
	head = Node2D.new()
	head.position = HEAD_PIVOT - ROOT_PIVOT
	root.add_child(head)
	_sprite(head, &"shambler/head", Vector2.ZERO)
	eye = _sprite(head, &"shambler/eye", EYE_PIVOT - HEAD_PIVOT)
	flash = _sprite(root, &"shambler/flash", BODY_PIVOT - ROOT_PIVOT)
	flash.visible = false


## Poses the puppet: shambling while `moving`, a squish for a moment after a hit.
func animate(time: float, moving: bool, since_hit: float, facing_left: bool) -> void:
	if facing_left:
		_side = -1.0
	elif moving:
		_side = 1.0
	origin.scale = Vector2(DRAW_SCALE * _side, DRAW_SCALE)
	var p: float = time * TAU * SHAMBLE_STEPS_PER_SECOND + _phase
	var sway: float = sin(p) if moving else 0.3 * sin(p * 0.3)
	root.rotation_degrees = 6.0 * sway
	root.position = ROOT_PIVOT - ANCHOR + Vector2(0.0, -absf(sway) * 5.0)
	var swing: float = 14.0 * sin(p - 0.8)
	arm_left.rotation_degrees = swing
	arm_right.rotation_degrees = -swing
	head.rotation_degrees = 5.0 * sin(p - 0.4)
	var squish: float = 0.0
	if since_hit < 0.5:
		squish = exp(-7.0 * since_hit) * cos(TAU * 3.0 * since_hit)
	root.scale = Vector2(1.0 + 0.18 * squish, 1.0 - 0.22 * squish)
	flash.visible = since_hit < FLASH_TIME


## The pieces that fly apart when the zombie dies (the button eye flies on its own).
func burst_pieces() -> Array[Node2D]:
	return [body, arm_left, arm_right, head, eye]


func _sprite(parent: Node2D, key: StringName, at: Vector2) -> Sprite2D:
	var sprite: Sprite2D = FeltAtlas.make_sprite(key)
	sprite.position = at
	parent.add_child(sprite)
	return sprite


static func _part(pivot: Vector2, outline: PackedVector2Array, fill: Color) -> FeltPiece:
	var piece: FeltPiece = FeltPiece.new()
	piece.pivot = pivot
	piece.polygon = FeltShapes.shifted(outline, -pivot)
	piece.color = fill
	return piece


static func _shadow_part() -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(SHADOW_PIVOT, Vector2(58, 12))
	var shadow: FeltPiece = _part(SHADOW_PIVOT, shape, SHADOW_COLOR)
	shadow.soft = false
	return shadow


static func _arm_part(center: Vector2, shoulder: Vector2, tilt: float) -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(center, Vector2(16, 22), 20)
	var arm: FeltPiece = _part(shoulder, FeltShapes.rotated(shape, center, tilt), ARM_COLOR)
	arm.outline_width = OUTLINE
	return arm


static func _body_part() -> FeltPiece:
	var shape: PackedVector2Array = FeltShapes.ellipse(BODY_PIVOT, Vector2(50, 55))
	var body_part: FeltPiece = _part(BODY_PIVOT, shape, BODY_COLOR)
	body_part.outline_width = OUTLINE
	var patch_center: Vector2 = Vector2(129, 173)
	var patch: PackedVector2Array = FeltShapes.points([115, 160, 143, 160, 143, 186, 115, 186])
	body_part.add_layer(FeltShapes.rotated(patch, patch_center, -8.0), PATCH_COLOR)
	var stitch: PackedVector2Array = FeltShapes.points(
		[118, 163, 140, 163, 140, 183, 118, 183, 118, 163]
	)
	body_part.add_line(FeltShapes.rotated(stitch, patch_center, -8.0), PATCH_STITCH_COLOR, 1.5)
	body_part.add_layer(FeltShapes.circle(Vector2(78, 196), 8.0, 12), STUFFING_COLOR)
	body_part.add_layer(FeltShapes.circle(Vector2(88, 203), 6.0, 12), STUFFING_COLOR)
	body_part.add_layer(FeltShapes.circle(Vector2(70, 205), 5.0, 12), STUFFING_COLOR)
	var rip: PackedVector2Array = FeltShapes.points([62, 188, 72, 196, 68, 202, 80, 206])
	body_part.add_line(rip, DARK_LINE_COLOR, 2.0)
	body_part.set_seam(FeltShapes.points([100, 135, 100, 225]), SEAM_COLOR)
	return body_part


static func _head_part() -> FeltPiece:
	var ear: PackedVector2Array = FeltShapes.circle(Vector2(62, 48), 18.0)
	var head_part: FeltPiece = _part(HEAD_PIVOT, ear, EAR_COLOR)
	head_part.outline_width = OUTLINE
	head_part.add_layer(FeltShapes.circle(Vector2(138, 48), 18.0), ARM_COLOR)
	head_part.add_layer(FeltShapes.circle(HEAD_PIVOT, 50.0, 28), HEAD_COLOR)
	head_part.add_layer(FeltShapes.ellipse(Vector2(100, 108), Vector2(22, 16), 20), MUZZLE_COLOR)
	head_part.add_line(FeltShapes.points([113, 75, 127, 89]), EYE_COLOR, 3.0)
	head_part.add_line(FeltShapes.points([127, 75, 113, 89]), EYE_COLOR, 3.0)
	head_part.add_line(FeltShapes.points([88, 116, 112, 116]), DARK_LINE_COLOR, 2.0)
	for x: float in [92.0, 100.0, 108.0]:
		head_part.add_line(FeltShapes.points([x, 111, x, 121]), DARK_LINE_COLOR, 2.0)
	return head_part


static func _eye_part() -> FeltPiece:
	var eye_part: FeltPiece = _part(EYE_PIVOT, FeltShapes.circle(EYE_PIVOT, 9.0, 16), EYE_COLOR)
	eye_part.soft = false
	for hole: Vector2 in [Vector2(77, 80), Vector2(83, 80), Vector2(77, 85), Vector2(83, 85)]:
		eye_part.add_layer(FeltShapes.circle(hole, 1.6, 8), EYE_HOLE_COLOR)
	return eye_part


## White silhouette of body, head and ears (relative to the body pivot).
static func _flash_part() -> FeltPiece:
	var silhouette: PackedVector2Array = FeltShapes.ellipse(BODY_PIVOT, Vector2(50, 55))
	var flash_part: FeltPiece = _part(BODY_PIVOT, silhouette, Color.WHITE)
	flash_part.soft = false
	flash_part.add_layer(FeltShapes.circle(HEAD_PIVOT, 50.0, 28), Color.WHITE)
	flash_part.add_layer(FeltShapes.circle(Vector2(62, 48), 18.0), Color.WHITE)
	flash_part.add_layer(FeltShapes.circle(Vector2(138, 48), 18.0), Color.WHITE)
	return flash_part
