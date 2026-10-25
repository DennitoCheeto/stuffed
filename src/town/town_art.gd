class_name TownArt
extends RefCounted
## Shared felt drawing for the Pillow Fort: soft pillows with a stitched edge, and labels.
## Colours come from the world palette (spec 05 §2.1): never the red/orange of enemy danger.

const SHADOW_OFFSET: Vector2 = Vector2(8.0, 12.0)
## How see-through the stitches on a pillow are.
const STITCH_ALPHA: float = 0.45


## A pillow: a rounded felt rect with a shadow and a stitched border.
static func pillow(canvas: CanvasItem, rect: Rect2, color: Color, shadow: bool = true) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var radius: int = roundi(minf(rect.size.x, rect.size.y) * 0.3)
	if shadow:
		var shadow_rect: Rect2 = Rect2(rect.position + SHADOW_OFFSET, rect.size)
		canvas.draw_style_box(_box(palette.shadow, radius), shadow_rect)
	canvas.draw_style_box(_box(color, radius), rect)
	var inner: Rect2 = rect.grow(-minf(rect.size.x, rect.size.y) * 0.12)
	var stitch: StyleBoxFlat = _box(Color.TRANSPARENT, maxi(radius - 6, 2))
	stitch.border_color = Color(palette.seam_light, STITCH_ALPHA)
	stitch.set_border_width_all(2)
	canvas.draw_style_box(stitch, inner)


## A label for signs and prompts (world space), centred on `center_x`.
static func label(text: String, font_size: int) -> Label:
	var palette: WorldPalette = WorldPalette.current()
	var result: Label = Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override(&"font_size", font_size)
	result.add_theme_color_override(&"font_color", palette.sign_text)
	result.add_theme_color_override(&"font_outline_color", palette.sign_outline)
	result.add_theme_constant_override(&"outline_size", 8)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## Puts `target` so that its middle sits at `center_x` and its top at `top`.
static func center_label(target: Label, center_x: float, top: float, width: float) -> void:
	target.size = Vector2(width, 0.0)
	target.position = Vector2(center_x - width / 2.0, top)


static func _box(color: Color, radius: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box
