class_name ConfettiBlast
extends Node2D
## A Party Popper's confetti (spec 02b §3, §5): soft multicolour felt bits shoot out from where
## it was pulled, spread over the whole screen, then flutter down and fade. One node draws all
## of them, so it stays cheap.

const PIECES: int = 170
## How fast the bits slow down after the pop (per second): higher = they stop sooner.
const DRAG: float = 4.0
## Slow sinking once they hang in the air, and how much they sway.
const SINK: float = 40.0
const SWAY: float = 14.0
const PIECE_SIZE: Vector2 = Vector2(11.0, 6.0)
## Banane's soft colours, never the red/orange of enemy danger (vision §6).
const COLORS: Array[Color] = [
	Color("#8fd3f4"),
	Color("#b9a4f0"),
	Color("#9be3b8"),
	Color("#f7e27a"),
	Color("#f4a8d6"),
	Color("#ffffff"),
]

var lifetime: float = 1.4

var _time: float = 0.0
var _targets: PackedVector2Array = []
var _spins: PackedFloat32Array = []
var _phases: PackedFloat32Array = []
var _colors: Array[Color] = []


## Bits start at `origin` and land spread over `view` (both in world coordinates).
func _init(
	origin: Vector2 = Vector2.ZERO, view: Rect2 = Rect2(), seconds: float = 1.4, seed_value: int = 0
) -> void:
	position = origin
	lifetime = seconds
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for i: int in PIECES:
		var spot: Vector2 = view.position + Vector2(rng.randf(), rng.randf()) * view.size
		_targets.append(spot - origin)
		_spins.append(rng.randf_range(-9.0, 9.0))
		_phases.append(rng.randf() * TAU)
		_colors.append(COLORS[i % COLORS.size()])


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	queue_redraw()


## Where bit `i` is now (relative to the origin): it shoots out, slows down, then sinks and sways.
func piece_offset(i: int) -> Vector2:
	var out: float = 1.0 - exp(-DRAG * _time)
	var sway: float = sin(_time * 5.0 + _phases[i]) * SWAY * out
	return _targets[i] * out + Vector2(sway, SINK * _time * _time)


func piece_count() -> int:
	return _targets.size()


func piece_color(i: int) -> Color:
	return _colors[i]


func _draw() -> void:
	var fade: float = clampf((lifetime - _time) / (lifetime * 0.35), 0.0, 1.0)
	for i: int in _targets.size():
		var color: Color = _colors[i]
		color.a = fade
		var turn: float = _spins[i] * _time + _phases[i]
		# The flip (cos) makes each bit look like a thin card tumbling in the air.
		var flip: float = maxf(absf(cos(turn * 1.3)), 0.25)
		draw_set_transform(piece_offset(i), turn, Vector2(1.0, flip))
		draw_rect(Rect2(-PIECE_SIZE / 2.0, PIECE_SIZE), color)
	draw_set_transform(Vector2.ZERO)
