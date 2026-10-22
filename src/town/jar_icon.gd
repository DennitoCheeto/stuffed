class_name JarIcon
extends Control
## A small felt picture of one town material (spec 03 §3): a gold-foil chocolate coin, a white
## stuffing tuft or a thread spool. Drawn in code; only a handful are on screen.

const MATERIALS: PackedStringArray = ["coins", "stuffing", "thread"]
const NAMES: Dictionary[String, String] = {
	"coins": "Coins", "stuffing": "Stuffing", "thread": "Thread"
}
const COIN_COLOR: Color = Color("#e3bd55")
const COIN_EDGE_COLOR: Color = Color("#b48d36")
const STUFFING_COLOR: Color = Color("#f1eee8")
const STUFFING_SHADE_COLOR: Color = Color("#cfcad6")
const THREAD_COLOR: Color = Color("#6fb3b8")
const SPOOL_COLOR: Color = Color("#b89a72")
const STITCH_COLOR: Color = Color(1.0, 1.0, 1.0, 0.45)

## "coins", "stuffing" or "thread".
var material_id: String = "coins":
	set(value):
		material_id = value
		queue_redraw()


func _init(id: String = "coins", side: float = 40.0) -> void:
	material_id = id
	custom_minimum_size = Vector2.ONE * side
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var middle: Vector2 = size / 2.0
	var r: float = minf(size.x, size.y) * 0.42
	match material_id:
		"coins":
			draw_circle(middle, r, COIN_EDGE_COLOR)
			draw_circle(middle, r * 0.82, COIN_COLOR)
			draw_arc(middle, r * 0.58, 0.0, TAU, 20, STITCH_COLOR, 2.0)
		"stuffing":
			for offset: Vector2 in [Vector2(-0.4, 0.2), Vector2(0.4, 0.2), Vector2(0.0, -0.25)]:
				draw_circle(middle + offset * r + Vector2(0, 2), r * 0.55, STUFFING_SHADE_COLOR)
				draw_circle(middle + offset * r, r * 0.55, STUFFING_COLOR)
		_:
			var body: Rect2 = Rect2(middle - Vector2(r * 0.6, r * 0.7), Vector2(r * 1.2, r * 1.4))
			draw_rect(body, THREAD_COLOR)
			for i: int in 3:
				var y: float = body.position.y + body.size.y * (0.25 + 0.25 * i)
				draw_line(Vector2(body.position.x, y), Vector2(body.end.x, y), STITCH_COLOR, 1.5)
			var cap: Vector2 = Vector2(r * 1.8, r * 0.3)
			draw_rect(Rect2(middle - Vector2(cap.x / 2.0, r * 0.95), cap), SPOOL_COLOR)
			draw_rect(Rect2(middle + Vector2(-cap.x / 2.0, r * 0.65), cap), SPOOL_COLOR)
