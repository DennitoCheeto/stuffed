class_name StartWeaponPicker
extends CanvasLayer
## Choosing Banane's starting weapon at the Toy Box Armory, level 3 (spec 03 §6): one tile per
## unlocked weapon (felt icon + name), the current one marked. Arrow keys / mouse to move,
## Enter / Space / click to choose, Esc to close. Keeps working while the town is paused.

## A weapon was chosen (its upgrade pool id).
signal chosen(id: StringName)
## The picker closed (after a choice or Esc).
signal closed

const COLUMNS: int = 5
const TILE_SIZE: Vector2 = Vector2(220, 210)
const TILE_COLOR: Color = Color("#2a2633")
const EDGE_COLOR: Color = Color("#4a4358")
const HIGHLIGHT_COLOR: Color = Color("#f2b52e")
const CURRENT_COLOR: Color = Color("#cfe3f0")

## Weapon id -> its tile.
var tiles: Dictionary[StringName, Button] = {}
## The weapon Banane starts with right now.
var current: StringName = &""

var _grid: GridContainer


func _init() -> void:
	layer = 19
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.08, 0.85)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override(&"separation", 18)
	add_child(box)
	box.add_child(TownArt.label("Starting weapon", 56))
	box.add_child(TownArt.label("Banane starts every run with it.   Esc: close", 26))
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 16)
	_grid.add_theme_constant_override(&"v_separation", 16)
	box.add_child(_grid)


func is_open() -> bool:
	return visible


## Opens with one tile per weapon in `weapons`; `now` is the one Banane starts with now.
func open(weapons: Array[UpgradeDef], now: StringName) -> void:
	for old: Node in _grid.get_children():
		_grid.remove_child(old)
		old.queue_free()
	tiles.clear()
	current = now
	for weapon: UpgradeDef in weapons:
		var tile: Button = _tile(weapon, weapon.id == now)
		tile.pressed.connect(choose.bind(weapon.id))
		_grid.add_child(tile)
		tiles[weapon.id] = tile
	visible = true
	if tiles.has(now):
		tiles[now].grab_focus()
	elif not tiles.is_empty():
		(tiles.values()[0] as Button).grab_focus()


## Picks `id` as the starting weapon and closes.
func choose(id: StringName) -> void:
	if not visible or not tiles.has(id):
		return
	current = id
	chosen.emit(id)
	close()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _tile(weapon: UpgradeDef, is_current: bool) -> Button:
	var tile: Button = Button.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.focus_mode = Control.FOCUS_ALL
	var edge: Color = CURRENT_COLOR if is_current else EDGE_COLOR
	tile.add_theme_stylebox_override(&"normal", _panel(edge))
	tile.add_theme_stylebox_override(&"hover", _panel(HIGHLIGHT_COLOR.darkened(0.3)))
	tile.add_theme_stylebox_override(&"pressed", _panel(HIGHLIGHT_COLOR))
	tile.add_theme_stylebox_override(&"focus", _panel(HIGHLIGHT_COLOR, false))
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(column)
	var icon: UpgradeIcon = UpgradeIcon.new()
	icon.icon = weapon.icon
	icon.custom_minimum_size = Vector2(96, 96)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)
	var title: Label = TownArt.label(weapon.display_name, 24)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title)
	if is_current:
		var mark: Label = TownArt.label("Now", 20)
		mark.add_theme_color_override(&"font_color", CURRENT_COLOR)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(mark)
	return tile


func _panel(edge: Color, filled: bool = true) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = TILE_COLOR if filled else Color(0, 0, 0, 0)
	box.border_color = edge
	box.set_border_width_all(4)
	box.set_corner_radius_all(16)
	return box
