extends Node2D
## Readability helpers drawn over the hero (vision §6.1): the real hitbox as a small soft dot,
## the dash cooldown ring around it, and a small health bar under the feet.

const HITBOX_DOT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.75)
const HITBOX_DOT_EDGE: Color = Color(0.1, 0.09, 0.12, 0.5)
const DASH_RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)
const HEALTH_BACK_COLOR: Color = Color(0.1, 0.09, 0.12, 0.8)
const HEALTH_FILL_COLOR: Color = Color("#7bd88f")
const HEALTH_BAR_SIZE: Vector2 = Vector2(44.0, 5.0)
const HEALTH_BAR_Y: float = 38.0
## Second Helping's shield outline around the small bar.
const SHIELD_GAP: float = 1.5
const SHIELD_WIDTH: float = 2.0
const SHIELD_LIGHTEN: float = ShieldOutline.LIGHTEN
## Spare Stuffing's little heart left of the small bar.
const HEART_SIZE: float = 10.0
const HEART_COLOR: Color = UiColors.HEALTH
const INK: Color = UiColors.HUD_OUTLINE

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
	var bar: Rect2 = Rect2(top_left, HEALTH_BAR_SIZE)
	if _player.shield > 0.0 and _player.max_shield > 0.0:
		_draw_shield(bar)
	if _player.has_spare_stuffing():
		var heart_at: Vector2 = Vector2(bar.position.x - HEART_SIZE, bar.get_center().y)
		FeltDraw.fill(self, SpareHeartPatch.heart_points(heart_at, HEART_SIZE / 2.0 + 1.0), INK)
		FeltDraw.fill(self, SpareHeartPatch.heart_points(heart_at, HEART_SIZE / 2.0), HEART_COLOR)


## Second Helping: a light outline in the hero's colour that closes as the shield fills.
func _draw_shield(bar: Rect2) -> void:
	var corners: PackedVector2Array = ShieldOutline.corners_of(bar.grow(SHIELD_GAP))
	var share: float = clampf(_player.shield / _player.max_shield, 0.0, 1.0)
	var path: PackedVector2Array = ShieldOutline.outline_path(corners, share)
	var markers: Array[Color] = UiColors.PLAYER_MARKERS
	var color: Color = markers[_player.player_index % markers.size()].lightened(SHIELD_LIGHTEN)
	if path.size() >= 2:
		draw_polyline(path, color, SHIELD_WIDTH, true)
