extends Node2D
## Placeholder drawing of Banane (the felt puppet comes in M1-02), plus the readability helpers:
## the hitbox dot, the dash cooldown ring and the small health bar.

const BODY_COLOR: Color = Color("#f2b52e")
const HOOD_COLOR: Color = Color("#f7f3ea")
const BEAK_COLOR: Color = Color("#f47a3a")
const FEET_COLOR: Color = Color("#f08a3c")
const EYE_COLOR: Color = Color("#4a2e1a")
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.3)
const HITBOX_DOT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.75)
const DASH_RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.55)
const HEALTH_BACK_COLOR: Color = Color(0.1, 0.09, 0.12, 0.8)
const HEALTH_FILL_COLOR: Color = Color("#7bd88f")
const HEALTH_BAR_SIZE: Vector2 = Vector2(44.0, 5.0)

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _player == null:
		return
	var side: float = -1.0 if _player.facing.x < 0.0 else 1.0
	var stretch: Vector2 = Vector2(1.25, 0.8) if _player.is_dashing() else Vector2.ONE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(stretch.x * side, stretch.y))
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_hitbox_and_dash_ring()
	_draw_health_bar()


func _draw_body() -> void:
	draw_rect(Rect2(-12.0, 18.0, 9.0, 10.0), FEET_COLOR)
	draw_rect(Rect2(4.0, 18.0, 9.0, 10.0), FEET_COLOR)
	draw_circle(Vector2(0.0, 4.0), 22.0, BODY_COLOR)
	draw_circle(Vector2(0.0, -14.0), 17.0, HOOD_COLOR)
	var beak: PackedVector2Array = [Vector2(10, -12), Vector2(26, -9), Vector2(10, -5)]
	draw_colored_polygon(beak, BEAK_COLOR)
	draw_circle(Vector2(6.0, -17.0), 2.5, EYE_COLOR)


func _draw_hitbox_and_dash_ring() -> void:
	var radius: float = _player.stats.hitbox_radius
	draw_circle(Vector2.ZERO, radius * 0.35, HITBOX_DOT_COLOR)
	var ratio: float = _player.dash_ready_ratio()
	if ratio < 1.0:
		var start: float = -PI / 2.0
		draw_arc(Vector2.ZERO, radius * 0.75, start, start + TAU * ratio, 24, DASH_RING_COLOR, 2.0)


func _draw_health_bar() -> void:
	var top_left: Vector2 = Vector2(-HEALTH_BAR_SIZE.x / 2.0, 36.0)
	draw_rect(Rect2(top_left, HEALTH_BAR_SIZE), HEALTH_BACK_COLOR)
	var ratio: float = 0.0
	if _player.max_health > 0.0:
		ratio = _player.health / _player.max_health
	var fill: Vector2 = Vector2(HEALTH_BAR_SIZE.x * ratio, HEALTH_BAR_SIZE.y)
	draw_rect(Rect2(top_left, fill), HEALTH_FILL_COLOR)
