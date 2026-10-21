class_name RecipesPage
extends PanelContainer
## The pause menu's Recipes page (spec 02 §5): every weapon + item pair that evolves, and what it
## becomes. Evolutions not seen yet show as "?". Back (or Esc) returns to the pause menu.

signal back_pressed

const UNSEEN: String = "?"
const HINT: String = "Weapon at level 5 + its item, then open a gift box"
const TEXT_COLOR: Color = Color("#f7f3ea")
const DIM_COLOR: Color = Color("#a9a3b8")
const HIGHLIGHT_COLOR: Color = Color("#f2b52e")

## One row per evolution, in the pool's order.
var rows: Array[RecipeRow] = []
var back_button: Button

var _list: VBoxContainer = VBoxContainer.new()


## Builds the page with the look of `panel_style` and `button` (copied from the pause menu).
func _init(panel_style: StyleBox, button: Button) -> void:
	add_theme_stylebox_override("panel", panel_style)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(make_label("Recipes", 44, HIGHLIGHT_COLOR))
	column.add_child(make_label(HINT, 20, DIM_COLOR))
	_list.add_theme_constant_override("separation", 10)
	column.add_child(_list)
	back_button = button
	back_button.text = "Back"
	back_button.pressed.connect(back_pressed.emit)
	column.add_child(back_button)


## Fills the rows from `pool`'s evolutions, showing the names of the ones seen so far.
func show_recipes(pool: UpgradePool) -> void:
	for row: RecipeRow in rows:
		row.queue_free()
	rows.clear()
	for evolution: EvolutionDef in pool.evolutions:
		var row: RecipeRow = RecipeRow.new()
		_list.add_child(row)
		row.show_recipe(evolution, pool, RecipeBook.is_seen(evolution.evolved.id))
		rows.append(row)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		back_pressed.emit()


## A centred line of text.
static func make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
