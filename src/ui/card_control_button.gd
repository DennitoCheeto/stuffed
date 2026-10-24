class_name CardControlButton
extends SewnButton
## One of the Reroll / Skip / Banish buttons under the level-up cards (spec 02 §20, spec 04
## §6.3): a sewn cream button with its own colour on the stitches, a felt icon, the key on a
## fabric tag, the uses left as little sewing buttons and a one-line explanation.
## Used up: flat and faded with "none left"; pressing it then wiggles "nope".

const BUTTON_SIZE: Vector2 = Vector2(340, 118)
const NONE_LEFT: String = "none left"
const DOT_RADIUS: float = 9.0
const DOT_GAP: float = 24.0

## The button's own colour (stitches, key tag, the uses left).
var color: Color = Color.WHITE
var uses_left: int = 0
var uses_max: int = 0
var icon_view: UpgradeIcon = UpgradeIcon.new()
var title_label: Label
var key_tag: FabricTag
var key_label: Label
var hint_label: Label
## Shows "none left" instead of the dots once used up.
var status_label: Label = UiFonts.label(NONE_LEFT, 19, UiColors.INK_SOFT)
## Draws the uses left as sewing buttons (full colour = left, faded = used).
var dots: Control = Control.new()


func _init(title: String, key: String, hint: String, icon_name: StringName, own: Color) -> void:
	super("", false)
	color = own
	box.radius = 24.0
	box.stitch_inset = 7.0
	box.pad(14, 10)
	box.stitch = own.darkened(0.15)
	_base_stitch = box.stitch
	face.custom_minimum_size = BUTTON_SIZE
	caption.visible = false
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	face.add_child(row)
	icon_view.icon = icon_name
	icon_view.custom_minimum_size = Vector2(60, 60)
	icon_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon_view)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 2)
	row.add_child(column)
	var top: HBoxContainer = HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 10)
	column.add_child(top)
	title_label = UiFonts.label(title, 28, UiColors.INK, UiFonts.heading())
	top.add_child(title_label)
	key_tag = FabricTag.new(key, own, UiColors.INK, 22)
	key_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_label = key_tag.label
	top.add_child(key_tag)
	var middle: HBoxContainer = HBoxContainer.new()
	column.add_child(middle)
	dots.custom_minimum_size = Vector2(0, DOT_RADIUS * 2.0 + 4.0)
	dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dots.draw.connect(_draw_dots)
	middle.add_child(dots)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(status_label)
	hint_label = UiFonts.label(hint, 16, UiColors.INK_SOFT)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint_label)
	for part: Control in [row, icon_view, column, top, middle, dots]:
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_uses(0, 0)


## Shows `left` of `most` uses; at 0 the button is disabled and says "none left".
func show_uses(left: int, most: int) -> void:
	uses_left = left
	uses_max = maxi(most, left)
	disabled = left <= 0
	dots.visible = not disabled
	status_label.visible = disabled
	dots.queue_redraw()


## "●●○" style text of the uses left, or "none left" (for tests and logs).
func uses_text() -> String:
	if disabled:
		return NONE_LEFT
	return "●".repeat(uses_left) + "○".repeat(uses_max - uses_left)


## Marks this button as active (banish mode: choosing which card): its felt takes its colour.
func set_active(on: bool) -> void:
	box.fill = UiColors.FELT.lerp(color, 0.4) if on else UiColors.FELT


func is_active() -> bool:
	return box.fill != UiColors.FELT


func _draw_dots() -> void:
	var y: float = dots.size.y / 2.0
	for index: int in uses_max:
		var at: Vector2 = Vector2(DOT_RADIUS + 2.0 + index * DOT_GAP, y)
		var alpha: float = 1.0 if index < uses_left else 0.3
		SewingButtonArt.draw(dots, at, DOT_RADIUS, color, alpha)
