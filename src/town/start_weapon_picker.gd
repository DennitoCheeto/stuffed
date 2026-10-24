class_name StartWeaponPicker
extends CanvasLayer
## Choosing Banane's starting weapon at the Toy Box Armory, level 3 (spec 03 §6): one tile per
## unlocked weapon (felt icon + name), the current one marked. Arrow keys / mouse to move,
## Enter / Space / click to choose, Esc to close. Keeps working while the town is paused.
## Stitched Scrapbook look (spec 04 §6.6): the felt cloth, a taped felt patch with a
## hand-written title, the tiles are sewn buttons and "Now" sits on a fabric tag.

## A weapon was chosen (its upgrade pool id).
signal chosen(id: StringName)
## The picker closed (after a choice or Esc).
signal closed

const COLUMNS: int = 5
const TILE_SIZE: Vector2 = Vector2(196, 186)
## The current weapon's tile: teal stitches and a teal "Now" tag.
const CURRENT_COLOR: Color = UiColors.STICKER_TEAL

## Weapon id -> its tile.
var tiles: Dictionary[StringName, SewnButton] = {}
## The weapon Banane starts with right now.
var current: StringName = &""
var cloth: MenuCloth = MenuCloth.new(0.92)
var panel: FeltPanel = FeltPanel.new(-1.0)
var title: HandTitle = HandTitle.new("Starting weapon", 58)
var motion: ScreenMotion = ScreenMotion.new()

var _grid: GridContainer


func _init() -> void:
	layer = 19
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cloth)
	add_child(motion)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel.add_tape(0.2, -5.0).add_tape(0.8, 4.0, UiColors.TAPE_PINK)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	panel.content.add_child(box)
	box.add_child(title)
	var hint: Label = UiFonts.label(
		"Banane starts every run with it.   Esc: close", 24, UiColors.INK_SOFT
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", 14)
	_grid.add_theme_constant_override(&"v_separation", 14)
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
		var tile: SewnButton = _tile(weapon, weapon.id == now)
		tile.pressed.connect(choose.bind(weapon.id))
		_grid.add_child(tile)
		tiles[weapon.id] = tile
	visible = true
	motion.open([panel])
	if tiles.has(now):
		tiles[now].grab_focus()
	elif not tiles.is_empty():
		(tiles.values()[0] as SewnButton).grab_focus()


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
	motion.finish()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


func _tile(weapon: UpgradeDef, is_current: bool) -> SewnButton:
	var tile: SewnButton = SewnButton.new()
	tile.caption.visible = false
	tile.box.radius = 24.0
	tile.box.pad(14, 12)
	tile.face.custom_minimum_size = TILE_SIZE
	if is_current:
		tile.set_stitch(CURRENT_COLOR.darkened(0.25))
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.face.add_child(column)
	var icon: UpgradeIcon = UpgradeIcon.new()
	icon.icon = weapon.icon
	icon.custom_minimum_size = Vector2(88, 88)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(icon)
	var name_label: Label = UiFonts.label(weapon.display_name, 22, UiColors.INK, UiFonts.heading())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(TILE_SIZE.x - 28.0, 0.0)
	column.add_child(name_label)
	if is_current:
		var mark: FabricTag = FabricTag.new("Now", CURRENT_COLOR, UiColors.STICKER_TEAL_INK, 16)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(mark)
	return tile
