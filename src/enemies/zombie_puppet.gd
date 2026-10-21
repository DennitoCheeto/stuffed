class_name ZombiePuppet
extends Node2D
## A zombie plushie made of felt parts. The parts are drawn once into the FeltAtlas and shown here
## as sprites, moved like a puppet. Which parts and how they move comes from its ZombieLook.
## Its Zombie calls `animate` every frame.

const FLASH_TIME: float = 0.08
## How much bigger it gets at the end of a wind-up (x, y).
const PUFF_SIZE: Vector2 = Vector2(0.4, 0.3)
## Colour it glows towards while puffing up (the colour of the stuffing ball it will spit).
const PUFF_TINT: Color = Color(1.8, 0.7, 0.9)

var look: ZombieLook
var origin: Node2D
var root: Node2D
var body: Sprite2D
var head: Node2D
## Arms for the teddy, ears for the sock bunny.
var limb_left: Sprite2D
var limb_right: Sprite2D
var eye: Sprite2D
## White silhouette shown for a moment when the zombie is hit.
var flash: Sprite2D

var _phase: float = 0.0
var _side: float = 1.0


## Builds the sprites. `phase` (0..1) keeps zombies from moving in perfect step.
func build(zombie_look: ZombieLook, phase: float) -> void:
	look = zombie_look
	_phase = phase * TAU
	origin = Node2D.new()
	origin.scale = Vector2.ONE * look.draw_scale
	add_child(origin)
	_sprite(origin, "shadow", look.shadow_pivot - look.anchor)
	root = Node2D.new()
	root.position = look.root_pivot - look.anchor
	origin.add_child(root)
	limb_left = _sprite(root, "limb_left", look.limb_left_pivot - look.root_pivot)
	limb_right = _sprite(root, "limb_right", look.limb_right_pivot - look.root_pivot)
	body = _sprite(root, "body", look.body_pivot - look.root_pivot)
	head = Node2D.new()
	head.position = look.head_pivot - look.root_pivot
	root.add_child(head)
	_sprite(head, "head", Vector2.ZERO)
	eye = _sprite(head, "eye", look.eye_pivot - look.head_pivot)
	flash = _sprite(root, "flash", look.body_pivot - look.root_pivot)
	flash.visible = false


## Poses the puppet: walking while `moving`, a squish for a moment after a hit.
func animate(time: float, moving: bool, since_hit: float, facing_left: bool) -> void:
	if facing_left:
		_side = -1.0
	elif moving:
		_side = 1.0
	origin.scale = Vector2(look.draw_scale * _side, look.draw_scale)
	var p: float = time * TAU * look.steps_per_second + _phase
	var sway: float = sin(p) if moving else 0.3 * sin(p * 0.3)
	root.rotation_degrees = look.sway_degrees * sway
	root.position = look.root_pivot - look.anchor + Vector2(0.0, -absf(sway) * look.bounce)
	var swing: float = look.limb_swing * sin(p - 0.8)
	limb_left.rotation_degrees = swing
	limb_right.rotation_degrees = -swing if look.limbs_mirrored else swing * 0.7
	head.rotation_degrees = 5.0 * sin(p - 0.4)
	var squish: float = 0.0
	if since_hit < 0.5:
		squish = exp(-7.0 * since_hit) * cos(TAU * 3.0 * since_hit)
	root.scale = Vector2(1.0 + 0.18 * squish, 1.0 - 0.22 * squish)
	flash.visible = since_hit < FLASH_TIME


## Puffs up before spitting (call after `animate`): 0 = normal, 1 = fully puffed, about to spit.
## The body swells and glows, so you see a shot coming.
func puff(amount: float) -> void:
	var swell: float = clampf(amount, 0.0, 1.0)
	root.scale *= Vector2.ONE + PUFF_SIZE * swell
	root.modulate = Color.WHITE.lerp(PUFF_TINT, swell)


## While stunned the zombie spins around (call after `animate`); 0 = not stunned.
func spin(stun_left: float) -> void:
	if stun_left > 0.0:
		origin.rotation = stun_left * TAU * 1.5
	else:
		origin.rotation = 0.0


## The pieces that fly apart when the zombie dies (the button eye flies on its own).
func burst_pieces() -> Array[Node2D]:
	return [body, limb_left, limb_right, head, eye]


func _sprite(parent: Node2D, part: String, at: Vector2) -> Sprite2D:
	var sprite: Sprite2D = FeltAtlas.make_sprite(look.key(part))
	sprite.position = at
	parent.add_child(sprite)
	return sprite
