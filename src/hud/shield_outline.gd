class_name ShieldOutline
extends Control
## Second Helping on the HUD (spec 06 §3.1): while the hero has a shield, a light outline in their
## colour wraps the health bar. The outline closes clockwise from the top left as the shield fills
## (a full ring = the biggest shield). Never the danger red of enemies (AC-73).

## How much lighter than the hero's floor ring the outline is.
const LIGHTEN: float = 0.5
const WIDTH: float = 4.0
## The outline sits this far outside the bar.
const GAP: float = 3.0

var color: Color = Color.WHITE

var _player: Player


func _init() -> void:
	name = "ShieldOutline"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false


## Follows `player`'s shield.
func follow(player: Player) -> void:
	_player = player
	var markers: Array[Color] = UiColors.PLAYER_MARKERS
	color = markers[player.player_index % markers.size()].lightened(LIGHTEN)
	player.shield_changed.connect(_on_shield_changed)
	refresh()


## 0 = no shield, 1 = the biggest shield.
func share() -> float:
	if _player == null or _player.max_shield <= 0.0:
		return 0.0
	return clampf(_player.shield / _player.max_shield, 0.0, 1.0)


func refresh() -> void:
	visible = share() > 0.0
	queue_redraw()


func _on_shield_changed(_shield: float) -> void:
	refresh()


func _draw() -> void:
	var box: Rect2 = Rect2(Vector2.ZERO, size).grow(GAP)
	var path: PackedVector2Array = outline_path(corners_of(box), share())
	if path.size() >= 2:
		draw_polyline(path, color, WIDTH, true)


## The corners of `box`, clockwise from the top left.
static func corners_of(box: Rect2) -> PackedVector2Array:
	var top_right: Vector2 = Vector2(box.end.x, box.position.y)
	return [box.position, top_right, box.end, Vector2(box.position.x, box.end.y)]


## The part of the closed outline through `corners` that `amount` (0..1) covers, from the first
## corner on.
static func outline_path(corners: PackedVector2Array, amount: float) -> PackedVector2Array:
	var total: float = 0.0
	for i: int in corners.size():
		total += corners[i].distance_to(corners[(i + 1) % corners.size()])
	var left: float = total * clampf(amount, 0.0, 1.0)
	var path: PackedVector2Array = [corners[0]]
	for i: int in corners.size():
		var from: Vector2 = corners[i]
		var to: Vector2 = corners[(i + 1) % corners.size()]
		var length: float = from.distance_to(to)
		if left >= length:
			path.append(to)
			left -= length
			continue
		if left > 0.0:
			path.append(from.lerp(to, left / length))
		break
	return path
