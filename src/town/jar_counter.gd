class_name JarCounter
extends HBoxContainer
## A material icon with its amount ("[coin] 120"), for the town HUD and the Brought home screen.

const TEXT_COLOR: Color = UiColors.HUD_TEXT
const OUTLINE_COLOR: Color = UiColors.HUD_OUTLINE

var material_id: String = "coins"
var icon: JarIcon
var amount_label: Label
## The number shown right now.
var shown: int = 0


func _init(id: String, font_size: int = 28, icon_side: float = 40.0) -> void:
	material_id = id
	name = id.capitalize()
	add_theme_constant_override(&"separation", 10)
	icon = JarIcon.new(id, icon_side)
	add_child(icon)
	amount_label = Label.new()
	amount_label.add_theme_font_override(&"font", UiFonts.heading())
	amount_label.add_theme_font_size_override(&"font_size", font_size)
	amount_label.add_theme_color_override(&"font_color", TEXT_COLOR)
	amount_label.add_theme_color_override(&"font_outline_color", OUTLINE_COLOR)
	amount_label.add_theme_constant_override(&"outline_size", 8)
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(amount_label)
	show_amount(0)


func show_amount(value: int, prefix: String = "") -> void:
	shown = value
	amount_label.text = "%s%d" % [prefix, value]


## Dark ink without the outline, for numbers on a cream felt panel (end screen).
func on_felt(ink: Color = UiColors.INK) -> JarCounter:
	amount_label.add_theme_color_override(&"font_color", ink)
	amount_label.add_theme_constant_override(&"outline_size", 0)
	amount_label.add_theme_font_override(&"font", UiFonts.heading())
	return self
