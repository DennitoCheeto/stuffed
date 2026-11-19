class_name PlushiePuppet
extends Node2D
## A plushie hero (spec 08 §6): drawn from the same felt look as its town plushie (PlushieLook,
## calmed colours so Böbö's brown never reads as danger) at hero size, walking with its
## PlushieGait (#147: steps and arm swing, Böbö's waddle, Robbar's hop). Drawn shape by shape
## every frame, one plushie costs ~50 draw calls, so the walk is baked once into one picture
## (`picture`: a rest frame, the walk cycle at half and full stride, two waving frames) and
## shown as one sprite with the zombies' ink outline around the silhouette (hero_sprite.gdshader).
## The hop, waddle, squash, dash lean, hit flash, fall and cheer move that sprite, like
## Banane's puppet. The floor shadow stays down while the hero hops.

enum State { IDLE, WALK, DASH, HIT, CHEER, DOWN }

const SHADER: Shader = preload("res://src/player/hero_sprite.gdshader")
## The picture is drawn at this scale (sharp when the camera zooms in).
const BAKE_SCALE: float = 2.0
## Walk frames per cycle (two steps or two hops), at each stride in WALK_AMOUNTS.
const WALK_PHASES: int = 12
const WALK_AMOUNTS: Array[float] = [0.5, 1.0]
## The waving frames of the cheer (right arm half up, all the way up).
const WAVES: Array[float] = [0.5, 1.0]
const COLUMNS: int = 6
## Room around each frame for the outline and the swinging arms (pixels).
const PAD: float = 8.0
## The same ink outline as the zombies and Banane: about 2 px on screen (#172).
const OUTLINE_PIXELS: float = BananePuppet.OUTLINE * BananePuppet.DRAW_SCALE
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.3)
## Below this stride the rest frame shows.
const REST_STRIDE: float = 0.25
## How high the cheer jumps and how far the dash leans forward (pixels).
const CHEER_JUMP: float = 12.0
const DASH_LEAN: float = 4.0
const HIT_RECOIL: float = 4.0
## How far a fallen hero tips over (radians).
const DOWN_TILT: float = 0.35

var state: State = State.IDLE
## The calmed look the hero is drawn with.
var look: PlushieDef
## The baked frames (rendered once), the sprite showing one of them and the node it hangs on.
var picture: SubViewport
var sprite: Sprite2D
var body: Node2D
var shadow: Node2D
## The frame shown right now (0 = standing still).
var frame: int = 0
## The sewn-on gear on the hero (spec 09 §7): its sprites hang on `body`.
var gear_view: HeroGear

var _hero: HeroStats
var _player: Player
var _size: float = 20.0
var _cell: Vector2 = Vector2.ZERO
var _feet: Vector2 = Vector2.ZERO
var _material: ShaderMaterial
var _time: float = 0.0
var _state_time: float = 0.0
var _walk_time: float = 0.0
var _stride: float = 0.0
var _side: float = 1.0
var _flash: float = 0.0


## `hero` must be a plushie hero (HeroStats.plushie set).
func setup(hero: HeroStats) -> void:
	_hero = hero
	look = hero.plushie.calmed()
	_size = hero.puppet_height / PlushieLook.top(look, 1.0)


func _ready() -> void:
	_player = get_parent() as Player
	if look == null and _player != null:
		setup(_player.stats)
	_build()
	if _player != null:
		_player.dashed.connect(_on_dashed)
		_player.hurt.connect(_on_hurt)
		_player.celebrated.connect(_on_celebrated)
		_player.died.connect(_on_died)
		_player.gear_changed.connect(dress)
		dress()


func _process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	_state_time += delta
	_update_state()
	_update_stride(delta)
	_apply()
	_update_invulnerable_blink()


## The drawing unit of the look (PlushieLook's `u`, pixels).
func unit() -> float:
	return _size * look.height


## How tall the puppet is (pixels from its feet to the top of its head).
func height() -> float:
	return PlushieLook.top(look, _size)


## How far into its walk the hero is (0 = standing, 1 = full walk; eases in and out).
func stride() -> float:
	return _stride


## Where its feet, arms and body are in its walk right now (a rest pose when standing still).
func walk_pose() -> PlushiePose:
	if look.gait == null:
		return PlushiePose.new()
	return look.gait.pose(_walk_time, _stride)


func frame_count() -> int:
	return 1 + WALK_PHASES * WALK_AMOUNTS.size() + WAVES.size()


## The first waving frame (the cheer).
func wave_frame() -> int:
	return 1 + WALK_PHASES * WALK_AMOUNTS.size()


func flash() -> float:
	return _flash


## The outline the sprite draws (tests): width in screen pixels and colour.
func outline_pixels() -> float:
	return float(_material.get_shader_parameter("outline_texels")) / BAKE_SCALE


func outline_color() -> Color:
	return _material.get_shader_parameter("outline_color")


func _on_dashed(_from_position: Vector2, _direction: Vector2) -> void:
	_enter(State.DASH)


func _on_hurt(_amount: float) -> void:
	_enter(State.HIT)


## Plays even while the run is frozen for the level-up cards.
func _on_celebrated() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enter(State.CHEER)


func _on_died(_player_who_died: Player) -> void:
	_enter(State.DOWN)


func _enter(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _update_state() -> void:
	match state:
		State.DOWN:
			# Stood back up (night siege).
			if not _player.is_dead():
				_enter(_moving_state())
		State.CHEER:
			if _state_time >= BananePuppet.QUACK_TIME:
				process_mode = Node.PROCESS_MODE_INHERIT
				_enter(_moving_state())
		State.HIT:
			if _state_time >= BananePuppet.HIT_ANIM_TIME:
				_enter(_moving_state())
		State.DASH:
			if _state_time >= BananePuppet.DASH_ANIM_TIME and not _player.is_dashing():
				_enter(_moving_state())
		_:
			var moving: State = _moving_state()
			if moving != state:
				_enter(moving)


func _moving_state() -> State:
	if _player.velocity.length() > BananePuppet.WALK_SPEED_THRESHOLD:
		return State.WALK
	return State.IDLE


## The walk eases in and out (like the town plushies) and keeps going under hits and dashes.
func _update_stride(delta: float) -> void:
	var moving: bool = _player.velocity.length() > BananePuppet.WALK_SPEED_THRESHOLD
	var goal: float = 1.0 if moving and state != State.DOWN else 0.0
	_stride = move_toward(_stride, goal, delta * _hero.stride_blend_speed)
	if _stride > 0.0:
		_walk_time += delta * _hero.walk_speedup
	else:
		_walk_time = 0.0


func _apply() -> void:
	if absf(_player.facing.x) > 0.01:
		_side = signf(_player.facing.x)
	var pose: PlushiePose = walk_pose()
	var lift: Vector2 = Vector2(0.0, -pose.hop * unit())
	var tilt: float = pose.tilt
	var squash: Vector2 = pose.squash
	_flash = 0.0
	frame = _walk_frame()
	var t: float = _state_time
	match state:
		State.DASH:
			var k: float = sin(minf(t / BananePuppet.DASH_ANIM_TIME, 1.0) * PI)
			squash *= Vector2(1.0 + 0.3 * k, 1.0 - 0.22 * k)
			tilt += deg_to_rad(14.0) * k
			lift.x += DASH_LEAN * k
		State.HIT:
			var wobble: float = _spring(t, 3.0, 7.0)
			squash *= Vector2(1.0 + 0.18 * wobble, 1.0 - 0.22 * wobble)
			lift.x -= HIT_RECOIL * exp(-8.0 * t)
			_flash = GameSettings.hero_flash() if t < BananePuppet.HIT_FLASH_TIME else 0.0
		State.CHEER:
			var jump: float = sin(t / 0.5 * PI) if t < 0.5 else 0.0
			lift.y -= CHEER_JUMP * jump
			if t < 0.5:
				squash = Vector2(1.0 - 0.1 * jump, 1.0 + 0.15 * jump)
			else:
				var settle: float = _spring(t - 0.5, 3.0, 7.0)
				squash = Vector2(1.0 + 0.12 * settle, 1.0 - 0.15 * settle)
			var up: bool = fmod(t, 0.4) < 0.2
			frame = wave_frame() + (1 if up else 0)
		State.DOWN:
			var sag: float = minf(t / 0.5, 1.0)
			squash = Vector2(1.0 + 0.3 * sag, 1.0 - 0.45 * sag)
			tilt = DOWN_TILT * sag
			frame = 0
	body.position = HeroMarker.FEET + Vector2(lift.x * _side, lift.y)
	body.rotation = tilt * _side
	body.scale = Vector2(_side, 1.0) * squash
	sprite.region_rect = _frame_rect(frame)
	_material.set_shader_parameter("flash", _flash)
	gear_view.set_flash(_flash)
	var air: float = clampf(-lift.y / CHEER_JUMP, 0.0, 1.0)
	shadow.scale = Vector2.ONE * (1.0 - 0.35 * air)


## The baked walk frame closest to the walk right now.
func _walk_frame() -> int:
	if look.gait == null or _stride < REST_STRIDE:
		return 0
	var level: int = 0 if _stride < 0.75 else 1
	var turn: float = _walk_time * look.gait.steps_per_second * PI
	var phase: int = roundi(fposmod(turn, TAU) / TAU * WALK_PHASES) % WALK_PHASES
	return 1 + level * WALK_PHASES + phase


## Damped spring: 1 at t = 0, wobbles and settles to 0.
func _spring(t: float, frequency: float, decay: float) -> float:
	return exp(-decay * t) * cos(TAU * frequency * t)


## Blinks while the hero can't be hurt after a hit.
func _update_invulnerable_blink() -> void:
	var blinking: bool = _player.hurt_invulnerable_left() > 0.0
	var every: float = BananePuppet.INVULNERABLE_BLINK
	var shown: bool = fmod(_time, every * 2.0) < every
	modulate.a = 0.35 if blinking and not shown else 1.0


func _frame_rect(index: int) -> Rect2:
	var cell: Vector2 = _cell * BAKE_SCALE
	return Rect2(Vector2(index % COLUMNS, floori(float(index) / COLUMNS)) * cell, cell)


func _build() -> void:
	var top: float = height()
	_cell = Vector2(top * 1.6, top * 1.5) + Vector2.ONE * PAD * 2.0
	_feet = Vector2(_cell.x / 2.0, PAD + top * 1.25)
	var rows: int = ceili(float(frame_count()) / COLUMNS)
	picture = SubViewport.new()
	picture.transparent_bg = true
	picture.size = Vector2i((Vector2(COLUMNS, rows) * _cell * BAKE_SCALE).ceil())
	picture.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter: Node2D = Node2D.new()
	painter.scale = Vector2.ONE * BAKE_SCALE
	painter.draw.connect(_paint.bind(painter))
	picture.add_child(painter)
	add_child(picture)
	shadow = Node2D.new()
	shadow.position = HeroMarker.FEET
	shadow.draw.connect(_draw_shadow)
	add_child(shadow)
	body = Node2D.new()
	body.position = HeroMarker.FEET
	add_child(body)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("outline_color", BananePuppet.OUTLINE_COLOR)
	_material.set_shader_parameter("outline_texels", OUTLINE_PIXELS * BAKE_SCALE)
	sprite = Sprite2D.new()
	sprite.texture = picture.get_texture()
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = _frame_rect(0)
	sprite.offset = -_feet * BAKE_SCALE
	sprite.scale = Vector2.ONE / BAKE_SCALE
	sprite.material = _material
	body.add_child(sprite)
	gear_view = HeroGear.new()
	add_child(gear_view)


## Draws every frame once into the picture: rest, the walk at each stride, the waves.
func _paint(canvas: Node2D) -> void:
	_paint_frame(canvas, 0, 0.0, null)
	for level: int in WALK_AMOUNTS.size():
		for phase: int in WALK_PHASES:
			var pose: PlushiePose = PlushiePose.new()
			if look.gait != null:
				var seconds: float = 2.0 * phase / (WALK_PHASES * look.gait.steps_per_second)
				pose = look.gait.pose(seconds, WALK_AMOUNTS[level])
			_paint_frame(canvas, 1 + level * WALK_PHASES + phase, 0.0, pose)
	for i: int in WAVES.size():
		_paint_frame(canvas, wave_frame() + i, WAVES[i], null)


func _paint_frame(canvas: Node2D, index: int, wave: float, pose: PlushiePose) -> void:
	var corner: Vector2 = Vector2(index % COLUMNS, floori(float(index) / COLUMNS)) * _cell
	PlushieLook.draw(canvas, look, corner + _feet, _size, wave, pose, false)


func _draw_shadow() -> void:
	var u: float = unit()
	shadow.draw_colored_polygon(PlushieLook.ellipse(Vector2.ZERO, u * 1.1, u * 0.3), SHADOW_COLOR)


## Draws what the hero wears (again, after the town changed it).
func dress() -> void:
	if _player != null:
		gear_view.dress(_player.gear, HeroGear.SIDE * _hero.gear_scale, _hang)


## A piece moves with the whole body (hop, waddle, squash, lean), drawn over the plushie.
func _hang(piece: GearDef, gear_sprite: Sprite2D) -> void:
	body.add_child(gear_sprite)
	gear_sprite.position = _hero.gear_anchor(piece.slot)
