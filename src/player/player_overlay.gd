extends Node2D
## Readability helpers drawn over the hero (vision §6.1): the real hitbox as a small soft dot,
## the dash cooldown ring around it, and a small health bar under the feet.

const HITBOX_DOT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.75)
const HITBOX_DOT_EDGE: Color = Color(0.1, 0.09, 0.12, 0.5)
const DASH_RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)
const HEALTH_BACK_COLOR: Color = Color(0.1, 0.09, 0.12, 0.8)
const HEALTH_FILL_COLOR: Color = Color("#7bd88f")
const HEALTH_BAR_SIZE: Vector2 = Vector2(44.0, 5.0)
const HEALTH_BAR_Y: float = 26.0

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _player == null:
		return
	_draw_hitbox_and_dash_ring()
	_draw_health_bar()


func _draw_hitbox_and_dash_ring() -> void:
	var radius: float = _player.stats.hitbox_radius
	draw_circle(Vector2.ZERO, radius * 0.35 + 1.0, HITBOX_DOT_EDGE)
	draw_circle(Vector2.ZERO, radius * 0.35, HITBOX_DOT_COLOR)
	var ratio: float = _player.dash_ready_ratio()
	if ratio < 1.0:
		var start: float = -PI / 2.0
		draw_arc(Vector2.ZERO, radius * 0.75, start, start + TAU * ratio, 24, DASH_RING_COLOR, 2.0)


func _draw_health_bar() -> void:
	var top_left: Vector2 = Vector2(-HEALTH_BAR_SIZE.x / 2.0, HEALTH_BAR_Y)
	draw_rect(Rect2(top_left, HEALTH_BAR_SIZE), HEALTH_BACK_COLOR)
	var ratio: float = 0.0
	if _player.max_health > 0.0:
		ratio = _player.health / _player.max_health
	var fill: Vector2 = Vector2(HEALTH_BAR_SIZE.x * ratio, HEALTH_BAR_SIZE.y)
	draw_rect(Rect2(top_left, fill), HEALTH_FILL_COLOR)
