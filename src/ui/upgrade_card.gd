class_name UpgradeCard
extends Button
## One level-up card: key number, icon, name, "New!" / "Lv 2 → 3" and one line of what it does.

const CARD_SIZE: Vector2 = Vector2(340, 400)
const CARD_COLOR: Color = Color("#2a2633")
const EDGE_COLOR: Color = Color("#4a4358")
const HIGHLIGHT_COLOR: Color = Color("#f2b52e")

var offer: UpgradeOffer

var _key_label: Label = Label.new()
var _icon: UpgradeIcon = UpgradeIcon.new()
var _name_label: Label = Label.new()
var _level_label: Label = Label.new()
var _text_label: Label = Label.new()


func _init() -> void:
	custom_minimum_size = CARD_SIZE
	focus_mode = Control.FOCUS_ALL
	add_theme_stylebox_override("normal", _panel(EDGE_COLOR))
	add_theme_stylebox_override("hover", _panel(HIGHLIGHT_COLOR.darkened(0.3)))
	add_theme_stylebox_override("pressed", _panel(HIGHLIGHT_COLOR))
	add_theme_stylebox_override("focus", _panel(HIGHLIGHT_COLOR, false))
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 28)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override("separation", 14)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_style(_key_label, 24, Color("#a9a3b8"))
	_icon.custom_minimum_size = Vector2(110, 110)
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style(_name_label, 34, Color("#f7f3ea"))
	_style(_level_label, 24, Color("#f2b52e"))
	_style(_text_label, 22, Color("#d8d4e0"))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for part: Control in [_key_label, _icon, _name_label, _level_label, _text_label]:
		column.add_child(part)


## Shows `card_offer` as card number `number` (1-3).
func show_offer(card_offer: UpgradeOffer, number: int) -> void:
	offer = card_offer
	_key_label.text = "[%d]" % number
	_icon.icon = offer.upgrade.icon
	_name_label.text = offer.upgrade.display_name
	_level_label.text = offer.level_text()
	_text_label.text = offer.description()


## A felt card panel; `filled` false draws only the edge (the focus ring on top of the card).
func _panel(edge: Color, filled: bool = true) -> StyleBoxFlat:
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = CARD_COLOR
	panel.draw_center = filled
	panel.border_color = edge
	panel.set_border_width_all(4)
	panel.set_corner_radius_all(18)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 8 if filled else 0
	return panel


func _style(label: Label, font_size: int, color: Color) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
