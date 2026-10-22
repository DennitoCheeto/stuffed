class_name GiftCardView
extends PanelContainer
## One big card on the gift box screen (spec 02 §20): felt icon (old → new for an evolution),
## name, level change and one line of what it does. Looks like a level-up card.

const CARD_SIZE: Vector2 = Vector2(320, 380)
const EVOLUTION_SIZE: Vector2 = Vector2(460, 380)
const CARD_COLOR: Color = Color("#2a2633")
const EDGE_COLOR: Color = Color("#f2b52e")
const EVOLUTION_EDGE_COLOR: Color = Color("#ff7ad9")

var card: GiftCard
var icon: UpgradeIcon = UpgradeIcon.new()
## Evolutions only: the weapon it evolved from, left of an arrow.
var from_icon: UpgradeIcon = UpgradeIcon.new()
var arrow_label: Label = Label.new()
var title_label: Label = Label.new()
var level_label: Label = Label.new()
var text_label: Label = Label.new()


func _init(shown: GiftCard) -> void:
	card = shown
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = EVOLUTION_SIZE if card.is_evolution() else CARD_SIZE
	add_theme_stylebox_override(
		"panel", _panel(EVOLUTION_EDGE_COLOR if card.is_evolution() else EDGE_COLOR)
	)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	var icons: HBoxContainer = HBoxContainer.new()
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	icons.add_theme_constant_override("separation", 16)
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icons)
	for part: UpgradeIcon in [from_icon, icon]:
		part.custom_minimum_size = Vector2(110, 110)
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	from_icon.icon = card.from_icon
	icon.icon = card.icon
	_style(arrow_label, 48, Color("#f7f3ea"))
	arrow_label.text = "→"
	from_icon.visible = card.is_evolution()
	arrow_label.visible = card.is_evolution()
	icons.add_child(from_icon)
	icons.add_child(arrow_label)
	icons.add_child(icon)
	_style(title_label, 34, Color("#f7f3ea"))
	title_label.text = card.title
	_style(level_label, 28, EVOLUTION_EDGE_COLOR if card.is_evolution() else EDGE_COLOR)
	level_label.text = card.level_text
	_style(text_label, 22, Color("#d8d4e0"))
	text_label.text = card.text
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for part: Label in [title_label, level_label, text_label]:
		column.add_child(part)


func _panel(edge: Color) -> StyleBoxFlat:
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = CARD_COLOR
	panel.border_color = edge
	panel.set_border_width_all(4)
	panel.set_corner_radius_all(18)
	panel.set_content_margin_all(24)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 8
	return panel


func _style(label: Label, font_size: int, color: Color) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
