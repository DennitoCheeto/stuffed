class_name SpareHeartPatch
extends Control
## Spare Stuffing on the HUD (spec 06 §3.1): a small felt heart patch next to the health bar while
## the hero can still pop back up. It hides once the trick is used. Rose like the health bar,
## never the danger red of enemies (AC-73).

const SIZE: Vector2 = Vector2(34.0, 32.0)
const FILL: Color = UiColors.HEALTH
const INK: Color = UiColors.HUD_OUTLINE
const STITCH: Color = Color(1.0, 1.0, 1.0, 0.75)
const INK_WIDTH: float = 3.0
## The stitches run this far inside the edge.
const STITCH_INSET: float = 0.72
const POINTS: int = 40

var _player: Player


func _init() -> void:
	name = "SpareHeartPatch"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	visible = false


## Shows the patch while `player` has Spare Stuffing left.
func follow(player: Player) -> void:
	_player = player
	player.popped_back_up.connect(refresh)
	refresh()


func refresh() -> void:
	visible = _player != null and _player.has_spare_stuffing()


func _draw() -> void:
	var center: Vector2 = SIZE / 2.0
	var outer: PackedVector2Array = heart_points(center, SIZE.x / 2.0 + INK_WIDTH)
	FeltDraw.fill(self, outer, INK)
	FeltDraw.fill(self, heart_points(center, SIZE.x / 2.0), FILL)
	draw_heart_stitches(self, center, SIZE.x / 2.0 * STITCH_INSET, STITCH, 1.5)


## A heart of half-width `half` around `center` (the point at the bottom).
static func heart_points(center: Vector2, half: float, count: int = POINTS) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in count:
		var t: float = TAU * i / count
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		points.append(center + Vector2(x, y + 1.5) * half / 16.0)
	return points


## Dashed running stitches along a smaller heart.
static func draw_heart_stitches(
	canvas: CanvasItem, center: Vector2, half: float, color: Color, width: float
) -> void:
	var points: PackedVector2Array = heart_points(center, half, 24)
	for i: int in range(0, points.size(), 2):
		canvas.draw_line(points[i], points[(i + 1) % points.size()], color, width, true)
