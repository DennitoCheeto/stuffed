class_name ZombieBurst
extends Node2D
## A killed zombie bursting into its felt pieces plus a cloud of stuffing. The button eye pops
## off highest.

const LIFETIME: float = 0.8
const FADE_START: float = 0.45
## Pulls the pieces back down after they pop up (top-down "fake height").
const GRAVITY: float = 900.0
const FLUFF_COUNT: int = 10
const FLUFF_COLOR: Color = Color("#f4f1e8")

var _time: float = 0.0
var _pieces: Array[Node2D] = []
var _velocities: PackedVector2Array = []
var _spins: PackedFloat32Array = []
var _fluff_directions: PackedVector2Array = []
var _fluff_sizes: PackedFloat32Array = []


## Takes the zombie's pieces (keeping where they are on screen) and throws them apart.
func launch(puppet: ZombiePuppet, rng: RandomNumberGenerator) -> void:
	var pieces: Array[Node2D] = puppet.burst_pieces()
	for piece: Node2D in pieces:
		piece.reparent(self)
		var outward: Vector2 = piece.global_position - global_position
		var velocity: Vector2 = outward.normalized() * rng.randf_range(60.0, 160.0)
		velocity.y -= rng.randf_range(150.0, 260.0)
		if piece == puppet.eye:
			velocity.y -= 180.0
		_pieces.append(piece)
		_velocities.append(velocity)
		_spins.append(rng.randf_range(-10.0, 10.0))
	for i: int in FLUFF_COUNT:
		var angle: float = rng.randf() * TAU
		_fluff_directions.append(Vector2.from_angle(angle) * rng.randf_range(20.0, 55.0))
		_fluff_sizes.append(rng.randf_range(4.0, 9.0))


func _process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return
	for i: int in _pieces.size():
		_velocities[i].y += GRAVITY * delta
		_pieces[i].position += _velocities[i] * delta
		_pieces[i].rotation += _spins[i] * delta
	if _time > FADE_START:
		modulate.a = 1.0 - (_time - FADE_START) / (LIFETIME - FADE_START)
	queue_redraw()


func _draw() -> void:
	var spread: float = 1.0 - pow(1.0 - minf(_time / 0.35, 1.0), 3.0)
	var fluff: Color = FLUFF_COLOR
	fluff.a = 0.9 * (1.0 - _time / LIFETIME)
	for i: int in _fluff_directions.size():
		var grow: float = 0.6 + 0.6 * spread
		var center: Vector2 = _fluff_directions[i] * spread + Vector2(0.0, -12.0)
		draw_circle(center, _fluff_sizes[i] * grow, fluff)
