class_name SpareHeartPatch
extends Control
## The hero's heart patch next to the health bar. It shows while the hero can still pop back up
## (Spare Stuffing, spec 06 §3.1) and while their health is low (spec 10 §7, AC-115): then it
## pulses on every heartbeat of their `LowHealthWarning`. Rose like the health bar, lighter on a
## beat, never the danger red of enemies (AC-73).

const SIZE: Vector2 = Vector2(34.0, 32.0)
const FILL: Color = UiColors.HEALTH
const INK: Color = UiColors.HUD_OUTLINE
const STITCH: Color = Color(1.0, 1.0, 1.0, 0.75)
const INK_WIDTH: float = 3.0
## The stitches run this far inside the edge.
const STITCH_INSET: float = 0.72
const POINTS: int = 40

var _player: Player
var _warning: LowHealthWarning


func _init() -> void:
	name = "SpareHeartPatch"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	visible = false


## Shows the patch while `player` has Spare Stuffing left or low health.
func follow(player: Player) -> void:
	_player = player
	player.popped_back_up.connect(refresh)
	refresh()


func refresh() -> void:
	if _player == null or not is_instance_valid(_player):
		visible = false
		return
	if _warning == null:
		_warning = LowHealthWarning.of(_player)
	visible = _player.has_spare_stuffing() or shows_low_health()


## True while the patch is up for low health (it pulses then).
func shows_low_health() -> bool:
	return _warning != null and _warning.active


func _process(_delta: float) -> void:
	var was_low: bool = visible and shows_low_health()
	refresh()
	if shows_low_health() or was_low:
		queue_redraw()


## How big the heart is drawn now (1 = normal; bigger on a heartbeat).
func pulse_scale() -> float:
	return _warning.heart_scale() if shows_low_health() else 1.0


func fill_color() -> Color:
	return _warning.heart_color(FILL) if shows_low_health() else FILL


func _draw() -> void:
	var center: Vector2 = SIZE / 2.0
	var grow: float = pulse_scale()
	draw_set_transform(center * (1.0 - grow), 0.0, Vector2.ONE * grow)
	var outer: PackedVector2Array = heart_points(center, SIZE.x / 2.0 + INK_WIDTH)
	FeltDraw.fill(self, outer, INK)
	FeltDraw.fill(self, heart_points(center, SIZE.x / 2.0), fill_color())
	draw_heart_stitches(self, center, SIZE.x / 2.0 * STITCH_INSET, STITCH, 1.5)
	draw_set_transform(Vector2.ZERO)


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
