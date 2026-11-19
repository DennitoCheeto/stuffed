class_name SewingTable
extends CanvasLayer
## The sewing table at the Sewing Workshop (spec 09 §6, AC-98): left a photo of your hero with
## its 3 slots (what you wear in each), right the 9 pieces as tiles, one row per slot. Click a
## tile or press E on it for its main action (Sew / Stitch / Wear / Take off), R takes the
## piece off, Esc closes. Below: the Workshop's own upgrade (E at a built Workshop opens the
## table, so its upgrade lives here). Same look family as the Tricks panel and the hero picker.
## Keeps working while the town waits.

## The player wants `piece`'s main action.
signal act_requested(piece: GearDef)
## The player wants to take off what they wear in `slot`.
signal take_off_requested(slot: GearDef.Slot)
## The player wants to upgrade the Workshop.
signal upgrade_requested
signal closed

const PHOTO_SIZE: Vector2 = Vector2(230, 190)
const SLOT_TAG_WIDTH: float = 92.0

## The Workshop's building (null = closed).
var building: TownBuilding
## The player at the table (0 = player 1): what they wear is shown and changed.
var opener: int = 0
## Piece id -> its tile, in table order.
var tiles: Dictionary[StringName, GearTile] = {}
## One line per slot under the hero photo: what's on (or "nothing on").
var slot_labels: Array[Label] = []
var cloth: MenuCloth = MenuCloth.new(0.92)
var panel: FeltPanel = FeltPanel.new(-1.0)
var title: HandTitle
var level_tag: FabricTag = FabricTag.new("", UiColors.TAG, UiColors.INK, 20)
var photo_frame: PhotoFrame
var hint_label: Label
var upgrade_button: SewnButton = SewnButton.new("")
var upgrade_cost: HBoxContainer = HBoxContainer.new()
var motion: ScreenMotion = ScreenMotion.new()

var _rules: GearRules = GearRules.current()
var _save: TownSave
var _rows: VBoxContainer = VBoxContainer.new()
var _slot_box: VBoxContainer = VBoxContainer.new()
var _building_names: Dictionary[String, String] = {}


func _init() -> void:
	name = "SewingTable"
	layer = 19
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cloth)
	add_child(motion)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel.add_tape(0.12, -4.0, UiColors.TAPE_PINK).add_tape(0.88, 5.0, UiColors.TAPE_TEAL)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.content.add_child(column)
	title = HandTitle.new(_rules.table_title, 56)
	column.add_child(title)
	level_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(level_tag)
	var body: HBoxContainer = HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 26)
	column.add_child(body)
	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override(&"separation", 10)
	body.add_child(left)
	photo_frame = PhotoFrame.new("", PHOTO_SIZE, -2.0, UiColors.TAPE_GOLD)
	photo_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	photo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(photo_frame)
	_slot_box.add_theme_constant_override(&"separation", 8)
	left.add_child(_slot_box)
	_rows.add_theme_constant_override(&"separation", 10)
	body.add_child(_rows)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 18)
	column.add_child(bottom)
	hint_label = UiFonts.label("", 22, UiColors.INK_SOFT)
	hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(hint_label)
	upgrade_cost.add_theme_constant_override(&"separation", 12)
	upgrade_cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	upgrade_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(upgrade_cost)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	bottom.add_child(upgrade_button)
	_build_rows()


func is_open() -> bool:
	return visible


## Opens the table at the Workshop `shop` for player `by` with the town in `save`.
## `names` maps building ids to their names (for "Build the Watchtower to Lv 2").
## `hero` is the hero player `by` plays (on the photo).
func open(
	shop: TownBuilding, save: TownSave, by: int, hero: HeroStats, names: Dictionary[String, String]
) -> void:
	building = shop
	opener = by
	_save = save
	_building_names = names
	for old: Node in photo_frame.picture.get_children():
		photo_frame.picture.remove_child(old)
		old.queue_free()
	photo_frame.picture.add_child(HeroPhoto.new(hero, false))
	photo_frame.caption.text = hero.display_name
	photo_frame.caption.visible = true
	refresh()
	visible = true
	motion.open([panel])
	_first_tile().grab_focus()


## Updates every tile, the slots on the photo, the hint and the upgrade button.
func refresh() -> void:
	if building == null or _save == null:
		return
	var def: BuildingDef = building.building
	level_tag.label.text = BuildingCard.level_text(building.level, def.max_level())
	for id: StringName in tiles:
		_show_tile(tiles[id])
	for slot: int in slot_labels.size():
		slot_labels[slot].text = slot_text(slot as GearDef.Slot)
	var hint: String = _rules.table_hint + "      " + _rules.table_close_hint
	hint_label.text = KeyBindings.fill(hint, opener)
	_show_upgrade()


## What the photo says for `slot`: the piece on (with its stitch dots), "nothing on" or the
## Workshop level that opens it.
func slot_text(slot: GearDef.Slot) -> String:
	if not GearBook.slot_open(_save, slot, _rules):
		return _rules.needs_workshop_text % _rules.slot_level(slot)
	var piece: GearDef = _rules.find(_save.gear.worn_in(opener, GearDef.SLOT_NAMES[slot]))
	if piece == null:
		return _rules.empty_slot
	var at: int = _save.gear.stitch_level(String(piece.id))
	return "%s %s" % [piece.display_name, GearTile.dots(at, piece.max_level())]


## Why `piece`'s tile can't do more right now for the player at the table: another player
## wears it, the slot or the next stitch needs a Workshop level, where its pattern comes from,
## what's missing, or its top stitch level ("" when nothing is in the way).
func note_for(piece: GearDef) -> String:
	var wear: GearBook.Wear = GearBook.wear_state(_save, piece, opener, _rules)
	if wear == GearBook.Wear.TAKEN:
		return _rules.taken_text % (_save.gear.wearer_of(String(piece.id)) + 1)
	if wear == GearBook.Wear.SLOT_LOCKED:
		return _rules.needs_workshop_text % _rules.slot_level(piece.slot)
	if wear == GearBook.Wear.CAN_WEAR:
		return ""
	return _step_note(piece, wear == GearBook.Wear.WORN)


## The label of the main action `now` for a piece at stitch level `at` ("" for NONE).
func action_text(now: GearBook.Action, at: int) -> String:
	match now:
		GearBook.Action.SEW:
			return _rules.sew_text
		GearBook.Action.STITCH:
			return _rules.stitch_text % (at + 1)
		GearBook.Action.WEAR:
			return _rules.wear_text
		GearBook.Action.TAKE_OFF:
			return _rules.take_off_text
	return ""


## Where `piece`'s pattern comes from ("Build the Watchtower to Lv 2", "Big Ted drops this").
func source_text(piece: GearDef) -> String:
	if piece.source_kind != GearDef.Source.BUILDING:
		return piece.found_text
	var place: String = _building_names.get(String(piece.source), String(piece.source))
	return _rules.building_source_text % [place, piece.source_level]


## The sewing moment on `piece`'s tile (already paid for): the needle, then a pop and a puff.
func play_sewn(piece: GearDef) -> void:
	var tile: GearTile = tiles[piece.id]
	tile.play_sewn(_rules.sewing_seconds)
	if not tile.is_sewing():
		_pop(tile)
		return
	var wait: Tween = create_tween()
	wait.tween_interval(_rules.sewing_seconds)
	wait.tween_callback(_pop.bind(tile))


## The tile that has the keyboard focus (null if none does).
func focused_tile() -> GearTile:
	var owner_view: Viewport = get_viewport()
	if owner_view == null:
		return null
	return owner_view.gui_get_focus_owner() as GearTile


func close() -> void:
	if not visible:
		return
	motion.finish()
	visible = false
	building = null
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	var tile: GearTile = focused_tile()
	if event.is_action_pressed(KeyBindings.action_name("interact", opener)):
		get_viewport().set_input_as_handled()
		if tile != null:
			_on_tile_pressed(tile)
		elif upgrade_button.has_focus():
			_on_upgrade_pressed()
		return
	if event.is_action_pressed(KeyBindings.action_name("reroll", opener)):
		get_viewport().set_input_as_handled()
		if tile != null and tile.worn:
			take_off_requested.emit(tile.piece.slot)
		elif tile != null:
			tile.nope()


func _build_rows() -> void:
	for slot: int in GearDef.SLOT_NAMES.size():
		var title_text: String = _rules.slot_titles[slot]
		var line: HBoxContainer = HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 8)
		var tag: FabricTag = FabricTag.new(title_text, UiColors.TAG, UiColors.INK, 18)
		tag.custom_minimum_size = Vector2(SLOT_TAG_WIDTH, 0.0)
		line.add_child(tag)
		var label: Label = UiFonts.label("", 19, UiColors.INK, UiFonts.heading())
		label.custom_minimum_size = Vector2(PHOTO_SIZE.x - SLOT_TAG_WIDTH + 30.0, 0.0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(label)
		_slot_box.add_child(line)
		slot_labels.append(label)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 12)
		var row_tag: FabricTag = FabricTag.new(title_text, UiColors.STICKER_PINK, UiColors.INK, 18)
		row_tag.custom_minimum_size = Vector2(SLOT_TAG_WIDTH, 0.0)
		row_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(row_tag)
		for piece: GearDef in _rules.pieces_in(slot as GearDef.Slot):
			var tile: GearTile = GearTile.new(piece)
			tile.pressed.connect(_on_tile_pressed.bind(tile))
			row.add_child(tile)
			tiles[piece.id] = tile
		_rows.add_child(row)


func _first_tile() -> Control:
	for id: StringName in tiles:
		if tiles[id].action != GearBook.Action.NONE:
			return tiles[id]
	return tiles.values()[0] if not tiles.is_empty() else upgrade_button


func _show_upgrade() -> void:
	for old: Node in upgrade_cost.get_children():
		upgrade_cost.remove_child(old)
		old.queue_free()
	var next: BuildingLevel = building.building.next(building.level)
	upgrade_button.visible = next != null
	upgrade_cost.visible = next != null
	if next == null:
		return
	upgrade_button.text = _rules.upgrade_text % (building.level + 1)
	var cost: Dictionary[String, int] = next.cost()
	for material: String in cost:
		if cost[material] <= 0:
			continue
		var counter: JarCounter = JarCounter.new(material, 20, 26.0).on_felt()
		counter.show_amount(cost[material])
		if _save.material(material) < cost[material]:
			counter.modulate = TownBuilding.SHORT_TINT
		upgrade_cost.add_child(counter)
	var ready: bool = _save.can_afford(next.cost()) and not building.damaged
	upgrade_button.set_stitch(GearTile.READY_STITCH if ready else UiColors.STITCH)


func _on_tile_pressed(tile: GearTile) -> void:
	if not tile.can_act:
		tile.nope()
		return
	act_requested.emit(tile.piece)


func _on_upgrade_pressed() -> void:
	var next: BuildingLevel = building.building.next(building.level) if building != null else null
	if next == null or not _save.can_afford(next.cost()):
		upgrade_button.nope()
		return
	upgrade_requested.emit()


func _pop(tile: GearTile) -> void:
	Sfx.play(&"pop")
	if is_inside_tree():
		add_child(TownPuff.new(tile.get_global_rect(), _rules.sewing_puff))


## The note about `piece`'s next sewing step (not sewn yet, or worn by the player at the table).
func _step_note(piece: GearDef, worn: bool) -> String:
	var step: GearBook.Step = GearBook.step_of(_save, piece, _rules)
	var text: String = ""
	if step == GearBook.Step.NO_PATTERN:
		text = source_text(piece)
	elif step == GearBook.Step.NO_WORKSHOP:
		text = _rules.repair_text
	elif step == GearBook.Step.NEEDS_LEVEL:
		var level: int = GearBook.workshop_level_needed(_save, piece, _rules)
		text = _rules.needs_workshop_text % level
	elif step == GearBook.Step.MISSING:
		var next: GearLevel = piece.level(_save.gear.stitch_level(String(piece.id)) + 1)
		text = BuildingCard.missing_text(_save.missing(next.cost()))
	elif step == GearBook.Step.MAXED and worn:
		text = _rules.maxed_text
	return text


## Works out `tile`'s action for the player at the table and shows it (the tile only draws).
func _show_tile(tile: GearTile) -> void:
	var piece: GearDef = tile.piece
	var now: GearBook.Action = GearBook.action_for(_save, piece, opener, _rules)
	var at: int = _save.gear.stitch_level(String(piece.id))
	var works: bool = GearBook.can_act(_save, piece, opener, _rules)
	var worn: bool = _save.gear.wearer_of(String(piece.id)) == opener
	var priced: bool = now == GearBook.Action.SEW or now == GearBook.Action.STITCH
	tile.show_state(_save, now, action_text(now, at), works, worn, priced, note_for(piece))
