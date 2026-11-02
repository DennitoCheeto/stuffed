class_name PocketPatch
extends Control
## Pocket Pickup on the HUD (spec 06 §3.1): a small felt pocket next to the health bar while the
## hero has the trick. The carried floor pickup peeks out of it with the key that uses it; a
## double shows "x2". Dark HUD felt like the other backings, never danger red (AC-73).

const SIZE: Vector2 = Vector2(46.0, 44.0)
const FILL: Color = UiColors.HUD_FELT
const INK: Color = UiColors.HUD_OUTLINE
const STITCH: Color = UiColors.HUD_STITCH
const INK_WIDTH: float = 2.5
## The pocket's flap line sits this far down; the toy peeks out above it.
const FLAP_Y: float = 18.0
## How round the bottom corners are.
const ROUND: float = 12.0
const TOY_SIZE: Vector2 = Vector2(30.0, 30.0)
const KEY_FONT_SIZE: int = 15
const CORNER_POINTS: int = 6

## The toy in the pocket (hidden while empty).
var toy: TextureRect
## The key that uses it ("Q") and "x2" for a double.
var key_label: Label
var double_label: Label

var _player: Player


func _init() -> void:
	name = "PocketPatch"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = SIZE
	size = SIZE
	visible = false
	toy = TextureRect.new()
	toy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	toy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	toy.size = TOY_SIZE
	toy.position = Vector2((SIZE.x - TOY_SIZE.x) / 2.0, 2.0)
	toy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toy)
	key_label = _label(Vector2(SIZE.x - 15.0, SIZE.y - 20.0))
	double_label = _label(Vector2(3.0, SIZE.y - 20.0))
	double_label.text = "x2"


## Shows the pocket while `player` has Pocket Pickup.
func follow(player: Player) -> void:
	_player = player
	player.pocket_changed.connect(refresh)
	refresh()


func refresh() -> void:
	visible = _player != null and _player.has_trick(&"pocket_pickup")
	if not visible:
		return
	var kind: FloorPickupDef = _player.pocket
	toy.visible = kind != null
	key_label.visible = kind != null
	double_label.visible = kind != null and _player.pocket_double
	if kind != null:
		toy.texture = FeltAtlas.part_texture(FloorPickupLook.key(kind.id))
		key_label.text = _player.key_text("use_pocket")


## True while something is in the pocket (for tests).
func is_full() -> bool:
	return visible and toy.visible


## The pocket: a felt patch with round bottom corners, a stitched flap line and stitched edges.
func _draw() -> void:
	var outer: PackedVector2Array = pocket_points(Rect2(Vector2.ZERO, SIZE).grow(-1.0))
	FeltDraw.fill(self, outer, INK)
	var inner: PackedVector2Array = pocket_points(Rect2(Vector2.ZERO, SIZE).grow(-1.0 - INK_WIDTH))
	FeltDraw.fill(self, inner, FILL)
	var left: float = INK_WIDTH + 4.0
	var right: float = SIZE.x - INK_WIDTH - 4.0
	draw_dashed_line(Vector2(left, FLAP_Y), Vector2(right, FLAP_Y), STITCH, 1.5, 4.0)


## A pocket shape inside `rect`: flat top, round bottom corners.
static func pocket_points(rect: Rect2) -> PackedVector2Array:
	var points: PackedVector2Array = [rect.position, Vector2(rect.end.x, rect.position.y)]
	var corners: Array[Vector2] = [
		Vector2(rect.end.x - ROUND, rect.end.y - ROUND),
		Vector2(rect.position.x + ROUND, rect.end.y - ROUND),
	]
	for i: int in corners.size():
		var start: float = 0.0 if i == 0 else PI / 2.0
		for step: int in CORNER_POINTS + 1:
			var angle: float = start + PI / 2.0 * step / CORNER_POINTS
			points.append(corners[i] + Vector2(cos(angle), sin(angle)) * ROUND)
	return points


func _label(at: Vector2) -> Label:
	var label: Label = Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", KEY_FONT_SIZE)
	label.add_theme_color_override("font_color", UiColors.HUD_TEXT)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	add_child(label)
	return label
