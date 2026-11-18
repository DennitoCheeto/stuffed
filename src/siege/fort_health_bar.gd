class_name FortHealthBar
extends ProgressBar
## The pillow fort's health at the top middle of the screen during the night siege (spec 07
## §2, §7), under the timer and the boss bar's place. A HUD felt backing with a soft teal fill
## (the player's side, never a danger colour) that turns gold when the fort is nearly down. The
## wave counter (`WaveCounter`) sits right of it; an edge arrow points to the fort when it is hit
## off screen (`PickupArrows.watch_fort`).

const SIZE: Vector2 = Vector2(420.0, 28.0)
const TOP: float = 124.0
const FONT_SIZE: int = 20
const TEXT: String = "Fort"
## Below this share the fill turns gold (a warning).
const LOW_SHARE: float = 0.3
const FILL_COLOR: Color = UiColors.STICKER_TEAL
const LOW_COLOR: Color = UiColors.GOLD

var fort: SiegeFort
var label: Label

var _fill: StyleBoxFlat = StyleBoxFlat.new()


func _init(siege_fort: SiegeFort) -> void:
	name = "FortHealthBar"
	fort = siege_fort
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -SIZE.x / 2.0
	offset_right = SIZE.x / 2.0
	offset_top = TOP
	offset_bottom = TOP + SIZE.y
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	max_value = fort.max_health
	add_theme_stylebox_override("background", StyleBoxFelt.hud(12.0))
	_fill.set_corner_radius_all(10)
	_fill.anti_aliasing = true
	add_theme_stylebox_override("fill", _fill)
	label = UiFonts.label(TEXT, FONT_SIZE, UiColors.HUD_TEXT, UiFonts.heading())
	label.add_theme_color_override("font_outline_color", UiColors.HUD_OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	fort.health_changed.connect(_show)
	_show(fort.health, fort.max_health)


func fill_color() -> Color:
	return LOW_COLOR if fort.share() < LOW_SHARE else FILL_COLOR


func _show(health: float, _max_health: float) -> void:
	value = health
	_fill.bg_color = fill_color()
