class_name LoadoutSlot
extends Control
## One HUD slot: a small felt icon of an owned weapon or item with its level. Empty slots are a
## faint circle, so the player sees how much room is left. An evolved weapon's slot gets a golden
## frame and a small star (spec 02 §20).

const SLOT_SIZE: Vector2 = Vector2(44, 44)
const EMPTY_ALPHA: float = 0.35
const FRAME_COLOR: Color = Color("#f2c230")
const LEVEL_COLOR: Color = UiColors.GOLD
const FRAME_WIDTH: float = 3.0
const STAR_RADIUS: float = 9.0
const STAR_OUTLINE: float = 1.5
## The baked frame picture: pixels per slot unit, and how far it reaches past the slot (the star
## sticks out at the top right).
const PICTURE_SCALE: float = 2.0
const PICTURE_MARGIN: float = 8.0

## Frame pictures per slot size (see `frame_picture`).
static var _pictures: Dictionary[Vector2i, Texture2D] = {}

## The icon shown ("" = empty slot).
var icon_name: StringName = &""
## 0 = empty.
var level: int = 0
## True for an evolved weapon (golden frame + star).
var evolved: bool = false
## Draws the golden frame and star on top of the icon.
var frame: Control = Control.new()

var _icon: UpgradeIcon = UpgradeIcon.new()
var _level_label: Label = Label.new()


func _init() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(_draw_frame)
	add_child(frame)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_level_label.offset_right = 4.0
	_level_label.offset_bottom = 6.0
	_level_label.add_theme_font_override("font", UiFonts.heading())
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", LEVEL_COLOR)
	_level_label.add_theme_color_override("font_outline_color", UiColors.HUD_OUTLINE)
	_level_label.add_theme_constant_override("outline_size", 6)
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level_label)
	show_upgrade(&"", 0)


## Shows `icon` at `upgrade_level`; level 0 makes the slot empty. `is_evolved` adds the golden
## frame and star.
func show_upgrade(icon: StringName, upgrade_level: int, is_evolved: bool = false) -> void:
	icon_name = icon if upgrade_level > 0 else &""
	level = upgrade_level
	evolved = is_evolved and level > 0
	_icon.icon = icon_name
	_level_label.text = str(level) if level > 0 and not evolved else ""
	modulate.a = 1.0 if level > 0 else EMPTY_ALPHA
	frame.visible = evolved
	frame.queue_redraw()


func _draw_frame() -> void:
	var picture: Texture2D = frame_picture(frame.size)
	var margin: Vector2 = Vector2.ONE * PICTURE_MARGIN
	frame.draw_texture_rect(picture, Rect2(-margin, frame.size + margin * 2.0), false)


## The golden ring and star for a slot of `slot_size`, drawn once into a small shared picture
## (one draw call per slot; drawn as an arc, a felt star and its outline it cost ~8 per evolved
## slot, spec 11 §10). Cached per size.
static func frame_picture(slot_size: Vector2) -> Texture2D:
	var key: Vector2i = Vector2i(slot_size.round())
	if _pictures.has(key):
		return _pictures[key]
	var margin: float = PICTURE_MARGIN
	var area: Vector2 = slot_size + Vector2.ONE * margin * 2.0
	var pixels: Vector2i = Vector2i((area * PICTURE_SCALE).ceil()).max(Vector2i.ONE)
	var image: Image = Image.create_empty(pixels.x, pixels.y, false, Image.FORMAT_RGBA8)
	var center: Vector2 = slot_size / 2.0
	var ring: float = minf(slot_size.x, slot_size.y) / 2.0 + 1.0
	var star: PackedVector2Array = star_points(slot_size)
	var corner: Vector2 = Vector2.ONE * margin
	for y: int in pixels.y:
		for x: int in pixels.x:
			# The pixel's middle in the slot's own units.
			var at: Vector2 = (Vector2(x, y) + Vector2.ONE * 0.5) / PICTURE_SCALE - corner
			var color: Color = Color(FRAME_COLOR, 0.0)
			var ring_cover: float = FRAME_WIDTH / 2.0 + 0.5 - absf(at.distance_to(center) - ring)
			color = _over(color, FRAME_COLOR, ring_cover)
			var edge: float = _edge_distance(at, star)
			var inside: bool = Geometry2D.is_point_in_polygon(at, star)
			color = _over(color, FRAME_COLOR, 0.5 + edge if inside else 0.5 - edge)
			color = _over(color, UiColors.HUD_OUTLINE, STAR_OUTLINE / 2.0 + 0.5 - edge)
			image.set_pixel(x, y, color)
	var picture: ImageTexture = ImageTexture.create_from_image(image)
	_pictures[key] = picture
	return picture


## The star's corners (top-right corner of a slot of `slot_size`).
static func star_points(slot_size: Vector2) -> PackedVector2Array:
	var star_at: Vector2 = Vector2(slot_size.x - 3.0, 3.0)
	var points: PackedVector2Array = []
	for i: int in 10:
		var reach: float = STAR_RADIUS if i % 2 == 0 else STAR_RADIUS * 0.45
		points.append(star_at + Vector2.from_angle(TAU * i / 10.0 - PI / 2.0) * reach)
	return points


## `color` laid over `under` with `cover` (0..1, clamped) of its alpha.
static func _over(under: Color, color: Color, cover: float) -> Color:
	var amount: float = clampf(cover, 0.0, 1.0) * color.a
	if amount <= 0.0:
		return under
	var alpha: float = amount + under.a * (1.0 - amount)
	var mixed: Color = (color * amount + under * under.a * (1.0 - amount)) / alpha
	mixed.a = alpha
	return mixed


## Distance from `at` to the nearest edge of the closed `shape`.
static func _edge_distance(at: Vector2, shape: PackedVector2Array) -> float:
	var nearest: float = INF
	for i: int in shape.size():
		var on_edge: Vector2 = Geometry2D.get_closest_point_to_segment(
			at, shape[i], shape[(i + 1) % shape.size()]
		)
		nearest = minf(nearest, at.distance_to(on_edge))
	return nearest
