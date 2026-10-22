class_name FluffPoofs
extends Node2D
## Little white puffs of fluff, one at each spot, that grow and fade (enemy bullets popped by a
## Snow Globe). One node draws all of them, so many puffs stay cheap.

const LIFETIME: float = 0.45
const PUFF_RADIUS: float = 9.0
## Little balls per puff and how far they spread.
const BALLS: int = 5
const SPREAD: float = 10.0
const FLUFF_COLOR: Color = Color("#f4f1e8")

var spots: PackedVector2Array = []

var _time: float = 0.0


func _init(at: PackedVector2Array = PackedVector2Array()) -> void:
	spots = at


func _process(delta: float) -> void:
	_time += delta
	if _time >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var share: float = _time / LIFETIME
	var grow: float = 1.0 - pow(1.0 - share, 3.0)
	var fluff: Color = FLUFF_COLOR
	fluff.a = 0.9 * (1.0 - share)
	for spot: Vector2 in spots:
		draw_circle(spot, PUFF_RADIUS * (0.6 + 0.4 * grow), fluff)
		for i: int in BALLS:
			var out: Vector2 = Vector2.from_angle(TAU * i / BALLS + 0.4) * SPREAD * grow
			draw_circle(spot + out, PUFF_RADIUS * 0.5, fluff)
