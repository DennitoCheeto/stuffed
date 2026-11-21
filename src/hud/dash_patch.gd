class_name DashPatch
extends Control
## The dash on the HUD (#330): a small felt patch next to the health bar with a dash mark and the
## dash key. While the dash cools down the mark is dim and a light fill rises from the bottom;
## when the dash is ready again the mark lights up and the patch pops. Dark HUD felt like the
## other backings, never a danger colour.

const SIZE: Vector2 = Vector2(46.0, 44.0)
const FILL: Color = UiColors.HUD_FELT
const INK: Color = UiColors.HUD_OUTLINE
const STITCH: Color = UiColors.HUD_STITCH
const INK_WIDTH: float = 2.5
const ROUND: float = 9.0
const CORNER_POINTS: int = 5
## The cooldown fill rising from the bottom while the dash recharges.
const CHARGE_COLOR: Color = Color(0.66, 0.6, 0.8, 0.5)
## The dash mark: bright when ready, dim while it recharges.
const READY_COLOR: Color = UiColors.HUD_TEXT
const WAITING_COLOR: Color = Color(0.66, 0.6, 0.8, 0.45)
const MARK_WIDTH: float = 3.0
const KEY_FONT_SIZE: int = 13
## The patch grows by `POP_GROW` and settles back over `POP_SECONDS` when the dash is ready.
const POP_SECONDS: float = 0.3
const POP_GROW: float = 0.25

var key_label: Label
## Pops since the run started (for tests).
var pops: int = 0

var _player: Player
var _was_ready: bool = true
var _pop_left: float = 0.0


func _init() -> void:
	add_to_group(KeyBindings.HINTS)
	name = "DashPatch"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	key_label = Label.new()
	key_label.add_theme_font_size_override("font_size", KEY_FONT_SIZE)
	key_label.add_theme_color_override("font_color", UiColors.HUD_TEXT)
	key_label.add_theme_color_override("font_outline_color", INK)
	key_label.add_theme_constant_override("outline_size", 4)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.position = Vector2(0.0, SIZE.y - 21.0)
	key_label.size = Vector2(SIZE.x, 18.0)
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(key_label)


## Shows `player`'s dash.
func follow(player: Player) -> void:
	_player = player
	show_keys()


## Keys were changed in Settings.
func show_keys() -> void:
	if _player != null:
		key_label.text = _player.key_text("dash")


## 0 right after a dash, 1 when it is ready.
func charge() -> float:
	return _player.dash_ready_ratio() if _player != null else 1.0


func is_ready() -> bool:
	return charge() >= 1.0


func is_popping() -> bool:
	return _pop_left > 0.0


func _process(delta: float) -> void:
	var ready_now: bool = is_ready()
	if ready_now and not _was_ready:
		_pop_left = POP_SECONDS
		pops += 1
	_was_ready = ready_now
	_pop_left = maxf(_pop_left - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	# Containers reset a child's scale, so the pop is drawn bigger around the middle instead.
	var grow: float = 1.0 + POP_GROW * sin(PI * _pop_left / POP_SECONDS)
	draw_set_transform(SIZE / 2.0 * (1.0 - grow), 0.0, Vector2.ONE * grow)
	var rect: Rect2 = Rect2(Vector2.ZERO, SIZE).grow(-1.0)
	FeltDraw.fill(self, patch_points(rect), INK)
	var inner: Rect2 = rect.grow(-INK_WIDTH)
	FeltDraw.fill(self, patch_points(inner), FILL)
	var share: float = charge()
	var height: float = (inner.size.y - 4.0) * share
	if share < 1.0 and height > 0.5:
		var top_left: Vector2 = Vector2(inner.position.x + 2.0, inner.end.y - 2.0 - height)
		draw_rect(Rect2(top_left, Vector2(inner.size.x - 4.0, height)), CHARGE_COLOR)
	draw_multiline(mark_lines(), READY_COLOR if share >= 1.0 else WAITING_COLOR, MARK_WIDTH)
	var stitch: PackedVector2Array = patch_points(inner.grow(-3.0))
	stitch.append(stitch[0])
	draw_polyline(stitch, STITCH, 1.0)
	draw_set_transform(Vector2.ZERO)


## The dash mark: an arrow to the right with two speed lines behind it (pairs of points).
func mark_lines() -> PackedVector2Array:
	var mid: float = 15.0
	var lines: PackedVector2Array = []
	lines.append_array(PackedVector2Array([Vector2(20.0, mid), Vector2(34.0, mid)]))
	lines.append_array(PackedVector2Array([Vector2(28.0, mid - 6.0), Vector2(34.0, mid)]))
	lines.append_array(PackedVector2Array([Vector2(28.0, mid + 6.0), Vector2(34.0, mid)]))
	lines.append_array(PackedVector2Array([Vector2(9.0, mid - 5.0), Vector2(17.0, mid - 5.0)]))
	lines.append_array(PackedVector2Array([Vector2(12.0, mid + 5.0), Vector2(17.0, mid + 5.0)]))
	return lines


## A felt patch with round corners inside `rect`.
static func patch_points(rect: Rect2) -> PackedVector2Array:
	var points: PackedVector2Array = []
	var corners: Array[Vector2] = [
		Vector2(rect.end.x - ROUND, rect.position.y + ROUND),
		Vector2(rect.end.x - ROUND, rect.end.y - ROUND),
		Vector2(rect.position.x + ROUND, rect.end.y - ROUND),
		Vector2(rect.position.x + ROUND, rect.position.y + ROUND),
	]
	for i: int in corners.size():
		var start: float = -PI / 2.0 + PI / 2.0 * i
		for step: int in CORNER_POINTS + 1:
			var angle: float = start + PI / 2.0 * step / CORNER_POINTS
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * ROUND)
	return points
