class_name SewingNeedle
extends Control
## The sewing moment on a tile (spec 09 §6): a needle bobs in and out of the felt and leaves a
## row of stitches behind it, then it's gone. Lies over the whole tile; draws nothing at rest.

const NEEDLE: Color = Color("#c8cbd6")
const NEEDLE_EDGE: Color = UiColors.INK
const THREAD: Color = UiColors.PURPLE
## Stitches along the row, and how many times the needle dips in.
const STITCHES: int = 7
const DIPS: float = 4.0

## 0 = not started, 1 = done (hidden).
var progress: float = 1.0:
	set(value):
		progress = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_sewing() -> bool:
	return progress < 1.0


func _draw() -> void:
	if progress >= 1.0:
		return
	var left: Vector2 = Vector2(size.x * 0.12, size.y * 0.86)
	var right: Vector2 = Vector2(size.x * 0.88, size.y * 0.86)
	var shown: int = floori(progress * STITCHES)
	for i: int in shown:
		var a: Vector2 = left.lerp(right, (i + 0.15) / STITCHES)
		var b: Vector2 = left.lerp(right, (i + 0.75) / STITCHES)
		draw_line(a, b, THREAD, 3.0, true)
	var tip: Vector2 = left.lerp(right, progress)
	tip.y -= absf(sin(progress * PI * DIPS)) * 18.0
	var tail: Vector2 = tip + Vector2(22.0, -34.0)
	draw_line(tip, tail, NEEDLE_EDGE, 6.0, true)
	draw_line(tip, tail, NEEDLE, 3.5, true)
	draw_arc(tail, 4.0, 0.0, TAU, 12, NEEDLE_EDGE, 1.5, true)
