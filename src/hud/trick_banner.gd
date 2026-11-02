class_name TrickBanner
extends PanelContainer
## The small HUD banner that names a building trick the first time it fires in a run (spec 06
## §2.5, AC-70): "Spare Stuffing!" on a dark felt backing, in the colour of the hero it helped
## (never the danger red/orange of enemies, AC-73). Sits under the big arrival banner, so both
## can show at once. Stays still like the rest of the HUD.

## Distance from the top of the screen (the big banner ends around 300 px).
const TOP: float = 330.0
## The banner fades out over its last this many seconds.
const FADE: float = 0.4
## How much lighter than the hero's floor ring the name is, so it reads on the dark backing.
const LIGHTEN: float = 0.45
## Tricks that fire together share a line, at most this many names per line and this many lines
## (the oldest names drop off), so the banner never grows down over the hero in the middle.
const NAMES_PER_LINE: int = 3
const MAX_LINES: int = 2
const NAME_GAP: String = "  ·  "

var title: Label
var subtitle: Label

var _left: float = 0.0
var _names: PackedStringArray = []


func _init() -> void:
	name = "TrickBanner"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = TOP
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var backing: StyleBoxFelt = StyleBoxFelt.hud(12.0)
	backing.pad(26, 8)
	add_theme_stylebox_override("panel", backing)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	add_child(column)
	subtitle = _label(20, UiFonts.body(800), UiColors.HUD_TEXT)
	subtitle.text = "Town trick"
	column.add_child(subtitle)
	title = _label(40, UiFonts.heading(), UiColors.HUD_TEXT)
	column.add_child(title)


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	modulate.a = clampf(_left / FADE, 0.0, 1.0)
	visible = _left > 0.0


## Shows "<trick_name>!" in player `player_index`'s colour for `seconds`. A trick that fires
## while the banner still shows joins it (Head Start + Second Toy at the start): up to
## NAMES_PER_LINE names side by side, at most MAX_LINES lines.
func show_trick(trick_name: String, player_index: int, seconds: float) -> void:
	if not visible:
		_names.clear()
	_names.append("%s!" % trick_name)
	while _names.size() > NAMES_PER_LINE * MAX_LINES:
		_names.remove_at(0)
	var lines: PackedStringArray = []
	for start: int in range(0, _names.size(), NAMES_PER_LINE):
		lines.append(NAME_GAP.join(_names.slice(start, start + NAMES_PER_LINE)))
	title.text = "\n".join(lines)
	title.add_theme_color_override("font_color", color_for(player_index))
	_left = seconds
	modulate.a = 1.0
	visible = true


## The name's colour for player `player_index`: their floor ring's colour, lighter.
static func color_for(player_index: int) -> Color:
	var markers: Array[Color] = UiColors.PLAYER_MARKERS
	return markers[player_index % markers.size()].lightened(LIGHTEN)


func _label(font_size: int, font: Font, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", UiColors.HUD_OUTLINE)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
