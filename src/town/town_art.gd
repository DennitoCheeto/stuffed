class_name TownArt
extends RefCounted
## Shared drawing for the Pillow Fort: world labels for signs and prompts.
## Colours come from the world palette (spec 05 §2.1): never the red/orange of enemy danger.

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
