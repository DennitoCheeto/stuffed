class_name CardControlButton
extends Button
## One of the Reroll / Skip / Banish buttons under the level-up cards (spec 02 §20): its own
## colour, a felt icon, a big key badge, the uses left as dots and a one-line explanation.
## Used up: greyed out with "none left".

const BUTTON_SIZE: Vector2 = Vector2(340, 118)
const BACK_COLOR: Color = Color("#2a2633")
const GREY: Color = Color("#5a5566")
const TEXT_COLOR: Color = Color("#f7f3ea")
const HINT_COLOR: Color = Color("#d8d4e0")
const NONE_LEFT: String = "none left"
const DOT_RADIUS: float = 8.0
const DOT_GAP: float = 22.0

## The button's own colour (edge, key badge, filled dots).
var color: Color = Color.WHITE
var uses_left: int = 0
var uses_max: int = 0
var icon_view: UpgradeIcon = UpgradeIcon.new()
var title_label: Label = Label.new()
var key_label: Label = Label.new()
var hint_label: Label = Label.new()
## Shows "none left" instead of the dots once used up.
var status_label: Label = Label.new()
## Draws the uses left as dots (filled = left, hollow = used).
var dots: Control = Control.new()


func _init(title: String, key: String, hint: String, icon_name: StringName, own: Color) -> void:
	color = own
	custom_minimum_size = BUTTON_SIZE
	focus_mode = Control.FOCUS_ALL
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	icon_view.icon = icon_name
	icon_view.custom_minimum_size = Vector2(60, 60)
	icon_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_view)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 2)
	row.add_child(column)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	column.add_child(top)
	_style(title_label, title, 30, TEXT_COLOR)
	top.add_child(title_label)
	_style(key_label, key, 30, BACK_COLOR)
	key_label.custom_minimum_size = Vector2(46, 46)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(key_label)
	var middle: HBoxContainer = HBoxContainer.new()
	column.add_child(middle)
	dots.custom_minimum_size = Vector2(0, DOT_RADIUS * 2.0 + 4.0)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dots.draw.connect(_draw_dots)
	middle.add_child(dots)
	_style(status_label, NONE_LEFT, 20, GREY.lightened(0.3))
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(status_label)
	_style(hint_label, hint, 17, HINT_COLOR)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint_label)
	for part: Control in [icon_view, column, top, middle, dots]:
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_uses(0, 0)


## Shows `left` of `most` uses; at 0 the button greys out and says "none left".
func show_uses(left: int, most: int) -> void:
	uses_left = left
	uses_max = maxi(most, left)
	disabled = left <= 0
	dots.visible = not disabled
	status_label.visible = disabled
	var edge: Color = GREY if disabled else color
	add_theme_stylebox_override("normal", _panel(edge))
	add_theme_stylebox_override("hover", _panel(edge.lightened(0.3)))
	add_theme_stylebox_override("pressed", _panel(edge.lightened(0.5)))
	add_theme_stylebox_override("disabled", _panel(GREY))
	add_theme_stylebox_override("focus", _panel(edge.lightened(0.5), false))
	key_label.add_theme_stylebox_override("normal", _badge(edge))
	modulate = Color(1, 1, 1, 0.6) if disabled else Color.WHITE
	dots.queue_redraw()


## "●●○" style text of the uses left, or "none left" (for tests and logs).
func uses_text() -> String:
	if disabled:
		return NONE_LEFT
	return "●".repeat(uses_left) + "○".repeat(uses_max - uses_left)


## Marks this button as active (banish mode: choosing which card).
func set_active(on: bool) -> void:
	var edge: Color = color.lightened(0.4) if on else color
	if not disabled:
		add_theme_stylebox_override("normal", _panel(edge, true, on))


func _draw_dots() -> void:
	var y: float = dots.size.y / 2.0
	for index: int in uses_max:
		var at: Vector2 = Vector2(DOT_RADIUS + 2.0 + index * DOT_GAP, y)
		if index < uses_left:
			dots.draw_circle(at, DOT_RADIUS, color)
		else:
			dots.draw_arc(at, DOT_RADIUS - 1.5, 0.0, TAU, 16, color.darkened(0.2), 3.0)


func _panel(edge: Color, filled: bool = true, tinted: bool = false) -> StyleBoxFlat:
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = BACK_COLOR.lerp(edge, 0.35 if tinted else 0.12)
	panel.draw_center = filled
	panel.border_color = edge
	panel.set_border_width_all(5)
	panel.set_corner_radius_all(18)
	panel.shadow_color = Color(0, 0, 0, 0.35)
	panel.shadow_size = 6 if filled else 0
	return panel


func _badge(fill: Color) -> StyleBoxFlat:
	var badge: StyleBoxFlat = StyleBoxFlat.new()
	badge.bg_color = fill
	badge.set_corner_radius_all(12)
	return badge


func _style(label: Label, text: String, font_size: int, font_color: Color) -> void:
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
