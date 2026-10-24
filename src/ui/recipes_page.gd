class_name RecipesPage
extends CenterContainer
## The pause menu's Recipes page (spec 02 §5, look from spec 04): a taped felt patch listing every
## weapon + item pair that evolves, and what it becomes. Evolutions not seen yet show as "?".
## Back (or Esc) returns to the pause menu.

signal back_pressed

const UNSEEN: String = "?"
const HINT: String = "Weapon at level 5 + its item, then open a gift box"
const TEXT_COLOR: Color = UiColors.INK
const DIM_COLOR: Color = UiColors.INK_SOFT
const HIGHLIGHT_COLOR: Color = UiColors.PURPLE

## One row per evolution, in the pool's order.
var rows: Array[RecipeRow] = []
var panel: FeltPanel = FeltPanel.new(-1.0)
var back_button: SewnButton = SewnButton.new("Back", true)
var motion: ScreenMotion = ScreenMotion.new()

var _list: VBoxContainer = VBoxContainer.new()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(motion)
	panel.add_tape(0.1, -6.0, UiColors.TAPE_TEAL).add_tape(0.9, 5.0, UiColors.TAPE_PINK)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.content.add_child(column)
	column.add_child(HandTitle.new("Recipes", 52))
	column.add_child(make_label(HINT, 20, DIM_COLOR))
	_list.add_theme_constant_override("separation", 8)
	column.add_child(_list)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	motion.open([panel])
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		back_pressed.emit()


## A centred line of body text.
static func make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = UiFonts.label(text, font_size, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
