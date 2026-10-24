class_name UiFonts
extends RefCounted
## The three free fonts of the Stitched Scrapbook (spec 04 §2.2, SIL Open Font License, see
## docs/art/credits.md): Fredoka for headings and big numbers, Patrick Hand for hand-written
## bits, Nunito for body text.

const FREDOKA: FontFile = preload("res://assets/fonts/Fredoka.ttf")
const PATRICK_HAND: FontFile = preload("res://assets/fonts/PatrickHand-Regular.ttf")
const NUNITO: FontFile = preload("res://assets/fonts/Nunito.ttf")

static var _cache: Dictionary[String, Font] = {}


## Round, friendly headings and big numbers.
static func heading(weight: int = 700) -> Font:
	return _weighted(FREDOKA, "heading", weight)


## Hand-written titles, stickers and photo captions.
static func hand() -> Font:
	return PATRICK_HAND


## Clean body text for stats and card text.
static func body(weight: int = 700) -> Font:
	return _weighted(NUNITO, "body", weight)


static func _weighted(file: FontFile, family: String, weight: int) -> Font:
	var key: String = "%s_%d" % [family, weight]
	if not _cache.has(key):
		var font: FontVariation = FontVariation.new()
		font.base_font = file
		var tag: int = TextServerManager.get_primary_interface().name_to_tag("wght")
		font.variation_opentype = {tag: weight}
		_cache[key] = font
	return _cache[key]


## A plain label in `font` (default: body text) for felt panels.
static func label(words: String, font_size: int, color: Color, font: Font = null) -> Label:
	var result: Label = Label.new()
	result.text = words
	result.add_theme_font_override(&"font", font if font != null else body())
	result.add_theme_font_size_override(&"font_size", font_size)
	result.add_theme_color_override(&"font_color", color)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
