class_name TownPuff
extends Node2D
## The rebuild moment's felt puff (spec 03 §11): soft tufts burst out of a building's spot and
## fade, while a row of stitches runs once around it. `size` 1 = a rebuild, smaller = an upgrade.
## Frees itself when done.

const SECONDS: float = 0.7
const TUFTS: int = 12
const TUFT_COLOR: Color = Color("#f4efe6")
const TUFT_SHADE_COLOR: Color = Color("#cfcad6")
const STITCH_COLOR: Color = Color("#f6e7b0")

var rect: Rect2
var size: float = 1.0
var age: float = 0.0


func _init(around: Rect2, puff_size: float = 1.0) -> void:
	rect = around
	size = puff_size
	z_index = 2


func _process(delta: float) -> void:
	age += delta
	if age >= SECONDS:
		queue_free()
		return
	queue_redraw()


## 0 at the start, 1 when it's over.
func progress() -> float:
	return clampf(age / SECONDS, 0.0, 1.0)


func _draw() -> void:
	var t: float = progress()
	var fade: float = 1.0 - t * t
	var middle: Vector2 = rect.get_center()
	var reach: Vector2 = rect.size * (0.45 + 0.4 * size * t)
	for i: int in TUFTS:
		var angle: float = TAU * i / TUFTS + 0.3
		var at: Vector2 = middle + Vector2(cos(angle), sin(angle)) * reach
		var r: float = (18.0 + 10.0 * (i % 3)) * size * (1.0 - 0.4 * t)
		draw_circle(at + Vector2(0, 4), r, Color(TUFT_SHADE_COLOR, fade))
		draw_circle(at, r, Color(TUFT_COLOR, fade))
	_draw_stitches(minf(t / 0.7, 1.0), fade)


## Dashes running around the spot's edge, `share` of the way round.
func _draw_stitches(share: float, fade: float) -> void:
	var edge: Rect2 = rect.grow(14.0)
	var corners: PackedVector2Array = [
		edge.position,
		Vector2(edge.end.x, edge.position.y),
		edge.end,
		Vector2(edge.position.x, edge.end.y),
		edge.position
	]
	var length: float = 2.0 * (edge.size.x + edge.size.y)
	var left: float = length * share
	for i: int in 4:
		var from: Vector2 = corners[i]
		var to: Vector2 = corners[i + 1]
		var side: float = from.distance_to(to)
		var part: float = minf(left, side)
		if part <= 0.0:
			break
		var dashes: int = int(part / 22.0)
		var step: Vector2 = from.direction_to(to) * 22.0
		for d: int in dashes:
			var start: Vector2 = from + step * d
			draw_line(start, start + step * 0.55, Color(STITCH_COLOR, fade), 4.0)
		left -= side
