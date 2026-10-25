class_name BananePuppet
extends Node2D
## Banane as a felt puppet: separate pieces (feet, body, peel hood, three flaps, beak, eye)
## moved in code. Shapes and motion follow docs/art/felt-style-concept.html and
## animation-concept.html.

enum State { IDLE, WALK, DASH, HIT, QUACK, DOWN }

const FELT_SHADER: Shader = preload("res://src/puppet/felt.gdshader")
## The concept drawing is about 220 units tall; this makes Banane about 75 px tall.
const DRAW_SCALE: float = 0.34
## Concept point that sits on the hitbox centre.
const ANCHOR: Vector2 = Vector2(100, 185)
## Concept point the whole body waddles, leans and squishes around (between the feet).
const ROOT_PIVOT: Vector2 = Vector2(100, 242)
const WALK_STEPS_PER_SECOND: float = 2.2
const DASH_ANIM_TIME: float = 0.3
const HIT_ANIM_TIME: float = 0.6
const HIT_FLASH_TIME: float = 0.09
## The level-up moment: jump, deadpan "QUACK.", sunglasses.
const QUACK_TIME: float = 1.4
## Where the sunglasses sit on the head (concept point).
const SHADES_PIVOT: Vector2 = Vector2(105, 76)
const INVULNERABLE_BLINK: float = 0.08
const EYE_BLINK_EVERY: float = 3.2
const WALK_SPEED_THRESHOLD: float = 5.0

const BODY_COLOR: Color = Color("#f2b52e")
const BODY_SEAM_COLOR: Color = Color("#c98d17")
const HOOD_COLOR: Color = Color("#f7f3ea")
const HOOD_SEAM_COLOR: Color = Color("#cfc6b4")
const FLAP_COLOR: Color = Color("#f2ede2")
const MIDDLE_FLAP_COLOR: Color = Color("#f4efe5")
const BEAK_COLOR: Color = Color("#f47a3a")
const LOWER_BEAK_COLOR: Color = Color("#e8692c")
const FEET_COLOR: Color = Color("#f08a3c")
const EYE_COLOR: Color = Color("#4a2e1a")
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.45)
## The same dark ink outline as the zombies (about 2 px on screen), so Banane stands out on the
## light Sunny patchwork floors (#172, vision §6).
const OUTLINE: float = 6.0
const OUTLINE_COLOR: Color = Color("#1d1a24")

var state: State = State.IDLE

var _player: Player
var _time: float = 0.0
var _state_time: float = 0.0
var _side: float = 1.0
var _material: ShaderMaterial
var _origin: FeltPiece
var _shadow: FeltPiece
var _root: FeltPiece
var _foot_left: FeltPiece
var _foot_right: FeltPiece
var _head: FeltPiece
var _hood: FeltPiece
var _beak: FeltPiece
var _lower_beak: FeltPiece
var _eye: FeltPiece
var _flap_left: FeltPiece
var _flap_right: FeltPiece
var _flap_middle: FeltPiece
var _shades: FeltPiece
var _quack_label: Label
var _outlined: Array[FeltPiece] = []


func _ready() -> void:
	_player = get_parent() as Player
	_build()
	if _player != null:
		_player.dashed.connect(_on_dashed)
		_player.hurt.connect(_on_hurt)
		_player.celebrated.connect(_on_celebrated)
		_player.died.connect(_on_died)


func _process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	_state_time += delta
	_update_state()
	_apply(_pose())
	_update_invulnerable_blink()


func _on_dashed(_from_position: Vector2, _direction: Vector2) -> void:
	_enter(State.DASH)


func _on_hurt(_amount: float) -> void:
	_enter(State.HIT)


## Plays even while the run is frozen for the level-up cards.
func _on_celebrated() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enter(State.QUACK)


## Banane deflates when he falls (sad squeak in M1-12).
func _on_died(_player_who_died: Player) -> void:
	_enter(State.DOWN)


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _update_state() -> void:
	match state:
		State.DOWN:
			pass
		State.QUACK:
			if _state_time >= QUACK_TIME:
				process_mode = Node.PROCESS_MODE_INHERIT
				_enter(_moving_state())
		State.HIT:
			if _state_time >= HIT_ANIM_TIME:
				_enter(_moving_state())
		State.DASH:
			if _state_time >= DASH_ANIM_TIME and not _player.is_dashing():
				_enter(_moving_state())
		_:
			var moving: State = _moving_state()
			if moving != state:
				_enter(moving)


func _moving_state() -> State:
	if _player.velocity.length() > WALK_SPEED_THRESHOLD:
		return State.WALK
	return State.IDLE


func _pose() -> Pose:
	var pose: Pose = Pose.new()
	var t: float = _state_time
	match state:
		State.WALK:
			var p: float = _time * TAU * WALK_STEPS_PER_SECOND
			pose.tilt = 6.0 * sin(p)
			pose.lift = Vector2(0.0, -absf(sin(p)) * 6.0)
			pose.foot_left = Vector2(3.0 * cos(p), -maxf(0.0, sin(p)) * 9.0)
			pose.foot_right = Vector2(-3.0 * cos(p), -maxf(0.0, -sin(p)) * 9.0)
			pose.flap = -9.0 * sin(p - 0.9)
			pose.head_tilt = -2.5 * sin(p - 0.5)
			pose.squash = _squash(1.0 - 0.035 * cos(2.0 * p))
			pose.eye_open = _eye_blink()
		State.IDLE:
			var breath: float = _time * TAU * 0.5
			pose.squash = _squash(1.0 + 0.025 * sin(breath))
			pose.flap = 2.0 * sin(breath - 0.8)
			pose.head_tilt = 1.5 * sin(breath * 0.5)
			pose.eye_open = _eye_blink()
		State.DASH:
			var k: float = sin(minf(t / DASH_ANIM_TIME, 1.0) * PI)
			pose.squash = Vector2(1.0 + 0.3 * k, 1.0 - 0.22 * k)
			pose.tilt = 14.0 * k
			pose.lift = Vector2(10.0 * k, 0.0)
			pose.flap = -25.0 * k
			pose.foot_left = Vector2(-8.0, -4.0) * k
			pose.foot_right = Vector2(-10.0, -6.0) * k
		State.HIT:
			var wobble: float = _spring(t, 3.0, 7.0)
			pose.squash = Vector2(1.0 + 0.18 * wobble, 1.0 - 0.22 * wobble)
			pose.lift = Vector2(-12.0 * exp(-8.0 * t), 0.0)
			pose.flap = 18.0 * wobble
			pose.flash = 1.0 if t < HIT_FLASH_TIME else 0.0
			pose.eye_open = 0.1 if t < 0.35 else 1.0
		State.QUACK:
			_quack_pose(pose, t)
		State.DOWN:
			var sag: float = minf(t / 0.5, 1.0)
			pose.squash = Vector2(1.0 + 0.3 * sag, 1.0 - 0.45 * sag)
			pose.flap = 30.0 * sag
			pose.head_tilt = 12.0 * sag
			pose.eye_open = 0.1
	return pose


func _apply(pose: Pose) -> void:
	if absf(_player.facing.x) > 0.01:
		_side = signf(_player.facing.x)
	_origin.scale = Vector2(DRAW_SCALE * _side, DRAW_SCALE)
	_root.position = ROOT_PIVOT - ANCHOR + pose.lift
	_root.rotation_degrees = pose.tilt
	_root.scale = pose.squash
	# The feet stay on the ground while the body bobs (but jump along when he jumps).
	var feet_counter: Vector2 = Vector2(-pose.lift.x * 0.3, -pose.lift.y * (1.0 - pose.jump))
	_foot_left.position = _foot_left.pivot - ROOT_PIVOT + feet_counter + pose.foot_left
	_foot_right.position = _foot_right.pivot - ROOT_PIVOT + feet_counter + pose.foot_right
	_flap_left.rotation_degrees = pose.flap
	_flap_right.rotation_degrees = pose.flap * 0.8
	_flap_middle.rotation_degrees = pose.flap * 0.6
	_head.rotation_degrees = pose.head_tilt
	_eye.scale = Vector2(1.0, pose.eye_open)
	_material.set_shader_parameter("flash", pose.flash)
	var air: float = clampf(-pose.lift.y / 40.0, 0.0, 1.0)
	_shadow.scale = Vector2.ONE * (1.0 - 0.35 * air)
	_lower_beak.rotation_degrees = pose.beak
	_shades.modulate.a = pose.shades
	_shades.position = SHADES_PIVOT - _head.pivot + Vector2(0.0, -30.0 * (1.0 - pose.shades))
	_quack_label.visible = pose.quack_text > 0.0
	_quack_label.modulate.a = pose.quack_text


## Jump, beak open, "QUACK.", then the sunglasses drop on (animation-concept.html).
func _quack_pose(pose: Pose, t: float) -> void:
	var jump: float = sin(t / 0.5 * PI) if t < 0.5 else 0.0
	pose.lift = Vector2(0.0, -34.0 * jump)
	pose.jump = 1.0
	if t < 0.5:
		pose.squash = Vector2(1.0 - 0.1 * jump, 1.0 + 0.15 * jump)
	else:
		var wobble: float = _spring(t - 0.5, 3.0, 7.0)
		pose.squash = Vector2(1.0 + 0.12 * wobble, 1.0 - 0.15 * wobble)
	pose.beak = 22.0 if t > 0.15 and t < 0.75 else 0.0
	pose.flap = 20.0 * jump
	pose.quack_text = clampf((QUACK_TIME - t) * 3.0, 0.0, 1.0) if t > 0.15 else 0.0
	pose.shades = clampf((t - 0.55) * 4.0, 0.0, 1.0)


## Squash that keeps the volume: taller means thinner.
func _squash(height: float) -> Vector2:
	return Vector2(2.0 - height, height)


func _eye_blink() -> float:
	return 0.1 if fmod(_time, EYE_BLINK_EVERY) < 0.12 else 1.0


## Damped spring: 1 at t = 0, wobbles and settles to 0.
func _spring(t: float, frequency: float, decay: float) -> float:
	return exp(-decay * t) * cos(TAU * frequency * t)


## Blinks while Banane can't be hurt after a hit.
func _update_invulnerable_blink() -> void:
	var blinking: bool = _player.hurt_invulnerable_left() > 0.0
	var shown: bool = fmod(_time, INVULNERABLE_BLINK * 2.0) < INVULNERABLE_BLINK
	modulate.a = 0.35 if blinking and not shown else 1.0


## The felt pieces that carry the ink outline (for tests).
func outlined_pieces() -> Array[FeltPiece]:
	return _outlined


func _build() -> void:
	_material = ShaderMaterial.new()
	_material.shader = FELT_SHADER
	_origin = FeltPiece.new()
	_origin.pivot = ANCHOR
	_origin.material = _material
	add_child(_origin)
	var shadow_center: Vector2 = Vector2(100, 244)
	var shadow_shape: PackedVector2Array = FeltShapes.ellipse(shadow_center, Vector2(62, 13))
	_shadow = _origin.add_piece(shadow_center, shadow_shape, SHADOW_COLOR, false)
	_root = _origin.add_joint(ROOT_PIVOT)
	var left_foot: PackedVector2Array = _points([78, 222, 72, 242, 94, 242, 90, 222])
	_foot_left = _root.add_piece(Vector2(84, 232), left_foot, FEET_COLOR)
	_foot_right = _root.add_piece(
		Vector2(118, 232), _points([112, 222, 108, 242, 130, 242, 124, 222]), FEET_COLOR
	)
	var body_center: Vector2 = Vector2(100, 182)
	var body_shape: PackedVector2Array = FeltShapes.ellipse(body_center, Vector2(60, 50))
	var body: FeltPiece = _root.add_piece(body_center, body_shape, BODY_COLOR)
	body.set_seam(_svg([60, 196, 70, 230, 130, 230, 140, 196]), BODY_SEAM_COLOR)
	_build_head()
	_build_flaps()
	_outlined = [_foot_left, _foot_right, body, _hood, _lower_beak, _beak]
	_outlined.append_array([_flap_left, _flap_right, _flap_middle])
	for piece: FeltPiece in _outlined:
		piece.outline_width = OUTLINE
		piece.outline_color = OUTLINE_COLOR
	_quack_label = Label.new()
	_quack_label.text = "QUACK."
	_quack_label.position = Vector2(12, -96)
	_quack_label.add_theme_font_size_override("font_size", 24)
	_quack_label.add_theme_color_override("font_color", BODY_COLOR)
	_quack_label.add_theme_color_override("font_outline_color", Color("#1d1a24"))
	_quack_label.add_theme_constant_override("outline_size", 6)
	_quack_label.visible = false
	add_child(_quack_label)


func _build_head() -> void:
	_head = _root.add_joint(Vector2(100, 140))
	var hood_shape: PackedVector2Array = _svg(
		[60, 150, 52, 85, 64, 28, 100, 24, 136, 28, 148, 85, 140, 150, 125, 136, 75, 136, 60, 150]
	)
	_hood = _head.add_piece(Vector2(100, 140), hood_shape, HOOD_COLOR)
	var hood_seam: PackedVector2Array = _svg(
		[66, 145, 58, 88, 70, 34, 100, 30, 130, 34, 142, 88, 134, 145]
	)
	_hood.set_seam(hood_seam, HOOD_SEAM_COLOR)
	var lower_beak: PackedVector2Array = _svg(
		[116, 98, 128, 100, 140, 100, 157, 99, 150, 110, 128, 110, 116, 104]
	)
	_lower_beak = _head.add_piece(Vector2(117, 99), lower_beak, LOWER_BEAK_COLOR)
	var beak: PackedVector2Array = _svg(
		[118, 88, 140, 82, 160, 90, 158, 99, 140, 101, 128, 101, 116, 98]
	)
	_beak = _head.add_piece(Vector2(130, 94), beak, BEAK_COLOR)
	var eye_center: Vector2 = Vector2(108, 78)
	_eye = _head.add_piece(eye_center, FeltShapes.circle(eye_center, 5.0), EYE_COLOR, false)
	var shine_center: Vector2 = Vector2(109.5, 76.5)
	var shine: PackedVector2Array = FeltShapes.circle(shine_center, 1.6, 10)
	_eye.add_piece(shine_center, shine, Color(1, 1, 1, 0.8), false)
	var lens: PackedVector2Array = _points(
		[100, 70, 118, 70, 121, 73, 121, 80, 118, 83, 100, 83, 97, 80, 97, 73]
	)
	_shades = _head.add_piece(SHADES_PIVOT, lens, Color("#111111"), false)
	_shades.add_line(_points([70, 76, 98, 74]), Color("#111111"), 3.0)
	_shades.add_line(_points([101, 73, 107, 73]), Color(1, 1, 1, 0.5), 2.0)
	_shades.modulate.a = 0.0


func _build_flaps() -> void:
	var left: PackedVector2Array = _svg(
		[60, 142, 46, 160, 46, 190, 56, 206, 66, 190, 72, 165, 78, 144]
	)
	var right: PackedVector2Array = _svg(
		[122, 144, 128, 165, 134, 190, 144, 206, 154, 190, 154, 160, 140, 142]
	)
	var middle: PackedVector2Array = _svg(
		[90, 140, 88, 160, 93, 176, 100, 184, 107, 176, 112, 160, 110, 140]
	)
	_flap_left = _root.add_piece(Vector2(68, 144), left, FLAP_COLOR)
	_flap_right = _root.add_piece(Vector2(132, 144), right, FLAP_COLOR)
	_flap_middle = _root.add_piece(Vector2(100, 140), middle, MIDDLE_FLAP_COLOR)


func _svg(numbers: Array) -> PackedVector2Array:
	return FeltShapes.svg_path(PackedFloat32Array(numbers))


func _points(numbers: Array) -> PackedVector2Array:
	return FeltShapes.points(PackedFloat32Array(numbers))


## Where every piece is in one moment of an animation.
class Pose:
	var lift: Vector2 = Vector2.ZERO
	var tilt: float = 0.0
	var squash: Vector2 = Vector2.ONE
	var foot_left: Vector2 = Vector2.ZERO
	var foot_right: Vector2 = Vector2.ZERO
	var flap: float = 0.0
	var head_tilt: float = 0.0
	var eye_open: float = 1.0
	var flash: float = 0.0
	## Lower beak opening, in degrees.
	var beak: float = 0.0
	## 0..1: how far the sunglasses have dropped on.
	var shades: float = 0.0
	## 0..1: how visible "QUACK." is.
	var quack_text: float = 0.0
	## 1 while the whole puppet jumps (feet included).
	var jump: float = 0.0
