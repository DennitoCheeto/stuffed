extends Node2D
## Readability helpers drawn over the hero (vision §6.1): the real hit area as a ringed spot,
## the dash cooldown ring around it, and a small health bar under the feet with the dash pip
## below it (#330): it fills while the dash recharges and lights up with a pop when it is ready.

## The hit spot (#339, option A): zombies only hurt the hero when they touch this circle, so it
## is drawn at exactly the hit radius: a soft light disc, a crisp light ring on its edge with a
## dark outline (reads on every hero and floor) and a small dot in the middle. Never danger red.
const HIT_FILL: Color = Color(1.0, 1.0, 1.0, 0.3)
const HIT_RING: Color = Color(1.0, 1.0, 1.0, 0.95)
const HIT_RING_WIDTH: float = 2.0
const HIT_EDGE: Color = Color(0.1, 0.09, 0.12, 0.75)
const HIT_EDGE_WIDTH: float = 4.0
const HIT_DOT_RADIUS: float = 2.5
## The dash cooldown ring sits just outside the hit spot.
const DASH_RING_GAP: float = 4.0
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
## Pocket Pickup's carried toy right of the small bar.
const POCKET_SIZE: float = 14.0
## The dash pip under the small bar.
const DASH_PIP_SIZE: Vector2 = Vector2(22.0, 4.0)
const DASH_PIP_GAP: float = 3.0
const DASH_PIP_READY: Color = UiColors.HUD_TEXT
const DASH_PIP_WAITING: Color = Color(0.66, 0.6, 0.8, 0.7)
const DASH_POP_SECONDS: float = 0.3
const DASH_POP_GROW: float = 0.6

var _player: Player
var _warning: LowHealthWarning
var _pocket_key: StringName = &""
var _pocket_texture: AtlasTexture
var _dash_was_ready: bool = true
var _dash_pop_left: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player


func _process(delta: float) -> void:
	if _player != null:
		var ready_now: bool = _player.dash_ready_ratio() >= 1.0
		if ready_now and not _dash_was_ready:
			_dash_pop_left = DASH_POP_SECONDS
		_dash_was_ready = ready_now
	_dash_pop_left = maxf(_dash_pop_left - delta, 0.0)
	queue_redraw()


## True while the dash pip pops (the dash just got ready; for tests).
func is_dash_popping() -> bool:
	return _dash_pop_left > 0.0


func _draw() -> void:
	if _player == null:
		return
	_draw_hitbox_and_dash_ring()
	_draw_health_bar()


func _draw_hitbox_and_dash_ring() -> void:
	var radius: float = hit_ring_radius()
	draw_circle(Vector2.ZERO, radius, HIT_FILL)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, HIT_EDGE, HIT_EDGE_WIDTH, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, HIT_RING, HIT_RING_WIDTH, true)
	draw_circle(Vector2.ZERO, HIT_DOT_RADIUS + 1.0, HIT_EDGE)
	draw_circle(Vector2.ZERO, HIT_DOT_RADIUS, HIT_RING)
	var ratio: float = _player.dash_ready_ratio()
	if ratio < 1.0:
		var start: float = -PI / 2.0
		var dash: float = radius + DASH_RING_GAP
		draw_arc(Vector2.ZERO, dash, start, start + TAU * ratio, 24, DASH_RING_COLOR, 2.0)


## The radius the hit spot is drawn at: the hero's real hit radius (zombies touching it hurt).
func hit_ring_radius() -> float:
	return _player.stats.hitbox_radius if _player != null else 0.0


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
	if _player.has_spare_stuffing() or _is_low():
		_draw_heart(bar)
	if _player.pocket != null:
		_draw_pocket(bar)
	_draw_dash_pip(bar)


## The dash pip centred under the small bar: a light fill growing while the dash recharges, bright
## (and briefly bigger) when it is ready.
func _draw_dash_pip(bar: Rect2) -> void:
	var grow: float = 1.0 + DASH_POP_GROW * sin(PI * _dash_pop_left / DASH_POP_SECONDS)
	var pip_size: Vector2 = DASH_PIP_SIZE * grow
	var top: float = bar.end.y + DASH_PIP_GAP + (DASH_PIP_SIZE.y - pip_size.y) / 2.0
	var pip: Rect2 = Rect2(Vector2(-pip_size.x / 2.0, top), pip_size)
	draw_rect(pip.grow(1.0), HEALTH_BACK_COLOR)
	var ratio: float = clampf(_player.dash_ready_ratio(), 0.0, 1.0)
	if ratio >= 1.0:
		draw_rect(pip, DASH_PIP_READY)
	elif ratio > 0.0:
		draw_rect(Rect2(pip.position, Vector2(pip.size.x * ratio, pip.size.y)), DASH_PIP_WAITING)


func _is_low() -> bool:
	if _warning == null:
		_warning = LowHealthWarning.of(_player)
	return _warning != null and _warning.active


## The little heart left of the small bar: Spare Stuffing still there, or low health (then it
## pulses on each heartbeat, spec 10 §7).
func _draw_heart(bar: Rect2) -> void:
	var half: float = HEART_SIZE / 2.0
	var color: Color = HEART_COLOR
	if _is_low():
		half *= _warning.heart_scale()
		color = _warning.heart_color(HEART_COLOR)
	var heart_at: Vector2 = Vector2(bar.position.x - HEART_SIZE, bar.get_center().y)
	FeltDraw.fill(self, SpareHeartPatch.heart_points(heart_at, half + 1.0), INK)
	FeltDraw.fill(self, SpareHeartPatch.heart_points(heart_at, half), color)


## True while the small bar's heart is up for low health (for tests).
func shows_low_heart() -> bool:
	return _is_low()


## Pocket Pickup: the carried toy, small, right of the small bar on a dark felt dot.
func _draw_pocket(bar: Rect2) -> void:
	var key: StringName = FloorPickupLook.key(_player.pocket.id)
	if _pocket_key != key:
		_pocket_key = key
		_pocket_texture = FeltAtlas.part_texture(key)
	var center: Vector2 = Vector2(bar.end.x + POCKET_SIZE / 2.0 + 2.0, bar.get_center().y)
	draw_circle(center, POCKET_SIZE / 2.0 + 1.0, INK)
	draw_circle(center, POCKET_SIZE / 2.0, UiColors.HUD_FELT)
	var box: Vector2 = Vector2.ONE * (POCKET_SIZE - 2.0)
	draw_texture_rect(_pocket_texture, Rect2(center - box / 2.0, box), false)


## Second Helping: a light outline in the hero's colour that closes as the shield fills.
func _draw_shield(bar: Rect2) -> void:
	var corners: PackedVector2Array = ShieldOutline.corners_of(bar.grow(SHIELD_GAP))
	var share: float = clampf(_player.shield / _player.max_shield, 0.0, 1.0)
	var path: PackedVector2Array = ShieldOutline.outline_path(corners, share)
	var markers: Array[Color] = UiColors.PLAYER_MARKERS
	var color: Color = markers[_player.player_index % markers.size()].lightened(SHIELD_LIGHTEN)
	if path.size() >= 2:
		draw_polyline(path, color, SHIELD_WIDTH, true)
