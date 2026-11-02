class_name SpareShockwave
extends Node2D
## Spare Stuffing's shockwave (spec 06 §3): when a hero pops back up, a soft ring in their colour
## grows out to the push radius and fades. Light and thin, so it stays quieter than enemy danger
## (vision §6, AC-73).

## How much lighter than the hero's floor ring the wave is.
const LIGHTEN: float = 0.35
const START_ALPHA: float = 0.7
const WIDTH: float = 6.0
## A fainter fill inside the ring.
const FILL_ALPHA: float = 0.12

var color: Color = Color.WHITE
var radius: float = 0.0
var lifetime: float = 0.5

var _time: float = 0.0


func _init(at: Vector2 = Vector2.ZERO, player_index: int = 0, reach: float = 0.0) -> void:
	position = at
	radius = reach
	var markers: Array[Color] = UiColors.PLAYER_MARKERS
	color = markers[player_index % markers.size()].lightened(LIGHTEN)


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	queue_redraw()


## 0 at the pop, 1 when the ring has reached its radius.
func progress() -> float:
	return clampf(_time / maxf(lifetime, 0.001), 0.0, 1.0)


## The ring's colour right now (fades out as it grows).
func ring_color() -> Color:
	return Color(color, START_ALPHA * (1.0 - progress()))


func _draw() -> void:
	var grown: float = radius * (1.0 - pow(1.0 - progress(), 3.0))
	var ring: Color = ring_color()
	draw_circle(Vector2.ZERO, grown, Color(color, FILL_ALPHA * ring.a / START_ALPHA))
	draw_arc(Vector2.ZERO, grown, 0.0, TAU, 48, ring, WIDTH, true)
