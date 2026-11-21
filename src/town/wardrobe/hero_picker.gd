class_name HeroPicker
extends CanvasLayer
## The hero picker at the Wardrobe (spec 08 §5, AC-85, AC-86): one photo tile per hero (Banane
## first) with name, starting weapon, passive and a strength / weakness tag. Heroes not rescued
## yet are silhouettes ("Rescue me in the Bedroom"); a hero another player plays shows "Player 1
## plays Pip" (co-op, spec 08 §8). Neither can be picked. Arrow keys / mouse / 1-5 to choose,
## Esc closes. Same look as the Armory's weapon picker. Keeps working while the town is paused.

## Player `slot` picked `hero`.
signal chosen(slot: int, hero: HeroStats)
## The picker closed (after a choice or Esc).
signal closed
## The picking player wants to hide (`on`) or show gear slot `slot` on their hero (-1 = all).
signal hide_requested(slot: int, on: bool)

const TILE_SIZE: Vector2 = Vector2(270, 372)
const PHOTO_SIZE: Vector2 = Vector2(214, 150)
const CURRENT_COLOR: Color = UiColors.STICKER_TEAL
const CARD_ACTIONS: Array[StringName] = [
	&"pick_card_1", &"pick_card_2", &"pick_card_3", &"pick_card_4"
]
const NUMBER_KEYS: Array[Key] = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

## Hero id -> its tile, in pick order.
var tiles: Dictionary[StringName, SewnButton] = {}
## Hero id -> its photo.
var photos: Dictionary[StringName, HeroPhoto] = {}
## Hero id -> the line under the photo ("Rescue me ...", "Player 2 plays ...", or the passive).
var notes: Dictionary[StringName, Label] = {}
## Which player is picking (0 = player 1).
var slot: int = 0
var cloth: MenuCloth = MenuCloth.new(0.92)
var panel: FeltPanel = FeltPanel.new(-1.0)
var title: HandTitle
var motion: ScreenMotion = ScreenMotion.new()
## The sewn X in the top right corner: closes it with the mouse (#325).
var close_button: CloseStitch
## Looks up each hero's starting weapon card (icon, name).
var pool: UpgradePool
## The gear toggles under the heroes (spec 09 §6, AC-100b): one eye per slot and "Hide all".
## Shown while the picking player wears something.
var gear_row: HBoxContainer = HBoxContainer.new()
var eye_toggles: Array[GearEyeToggle] = []
var hide_all_toggle: GearEyeToggle = GearEyeToggle.new(-1, "", true)

var _rules: WardrobeRules = WardrobeRules.current()
var _row: HBoxContainer
var _order: Array[HeroStats] = []
## Heroes that can't be picked (not rescued, or another player has them). Their tiles stay
## enabled: a disabled button fades its face and the silhouette's felt pieces would show through.
var _blocked: Dictionary[StringName, bool] = {}
var _gear_rules: GearRules = GearRules.current()
var _save: TownSave


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
	close_button = panel.add_close(close)
	title = HandTitle.new(_rules.picker_title, 58)
	box.add_child(title)
	var hint: Label = UiFonts.label(_rules.picker_hint, 24, UiColors.INK_SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override(&"separation", 14)
	box.add_child(_row)
	_build_gear_row(box)


func is_open() -> bool:
	return visible


## Opens for player `by` with every hero in `roster`. `save` says who is unlocked; `taken` maps
## a hero id to the player slot playing it (other players only).
func open(by: int, roster: HeroRoster, save: TownSave, taken: Dictionary[StringName, int]) -> void:
	for old: Node in _row.get_children():
		_row.remove_child(old)
		old.queue_free()
	tiles.clear()
	photos.clear()
	notes.clear()
	_order.clear()
	_blocked.clear()
	slot = by
	var now: HeroStats = roster.heroes_for(save, HeroRoster.MAX_PLAYERS)[by]
	for hero: HeroStats in roster.heroes:
		var locked: bool = not roster.is_unlocked(hero, save)
		var taken_by: int = taken.get(hero.id, -1)
		var tile: SewnButton = _tile(hero, hero == now, locked, taken_by)
		tile.pressed.connect(choose.bind(hero))
		_row.add_child(tile)
		tiles[hero.id] = tile
		_order.append(hero)
	_save = save
	show_gear()
	visible = true
	motion.open([panel])
	if tiles.has(now.id):
		tiles[now.id].grab_focus()


## True when `hero` can be picked right now (unlocked and nobody else plays it).
func can_pick(hero: HeroStats) -> bool:
	return tiles.has(hero.id) and not _blocked.has(hero.id)


## Picks `hero` and closes. Locked and taken heroes say "nope".
func choose(hero: HeroStats) -> void:
	if not visible:
		return
	if not can_pick(hero):
		Sfx.play(&"nope")
		return
	chosen.emit(slot, hero)
	close()


func close() -> void:
	if not visible:
		return
	motion.finish()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	if event.is_action_pressed(KeyBindings.action_name("hide_gear", slot)):
		get_viewport().set_input_as_handled()
		var focused: GearEyeToggle = get_viewport().gui_get_focus_owner() as GearEyeToggle
		_on_eye_pressed(focused if focused != null else hide_all_toggle)
		return
	var at: int = _number_of(event)
	if at >= 0 and at < _order.size():
		get_viewport().set_input_as_handled()
		choose(_order[at])


## 1-4 are the level-up card keys (pick_card_1 ...), 5 is the plain key (-1 = none).
func _number_of(event: InputEvent) -> int:
	for i: int in CARD_ACTIONS.size():
		if event.is_action_pressed(CARD_ACTIONS[i]):
			return i
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return -1
	return NUMBER_KEYS.find(key.physical_keycode)


func _tile(hero: HeroStats, is_current: bool, locked: bool, taken_by: int) -> SewnButton:
	var tile: SewnButton = SewnButton.new()
	tile.caption.visible = false
	tile.box.radius = 24.0
	tile.box.pad(14, 12)
	tile.face.custom_minimum_size = TILE_SIZE
	if locked or taken_by >= 0:
		_blocked[hero.id] = true
		tile.set_stitch(UiColors.INK_SOFT)
	if is_current:
		tile.set_stitch(CURRENT_COLOR.darkened(0.25))
	var column: VBoxContainer = VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	column.add_theme_constant_override(&"separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.face.add_child(column)
	var words: String = "?" if locked else hero.display_name
	var frame: PhotoFrame = PhotoFrame.new(words, PHOTO_SIZE, -2.0, UiColors.TAPE_TEAL)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var photo: HeroPhoto = HeroPhoto.new(hero, locked)
	frame.picture.add_child(photo)
	photos[hero.id] = photo
	column.add_child(frame)
	if locked:
		_add_note(column, hero, _rules.locked_text, UiColors.INK_SOFT)
		return tile
	column.add_child(_weapon_row(hero))
	if taken_by >= 0:
		var text: String = _rules.taken_text % [taken_by + 1, hero.display_name]
		_add_note(column, hero, text, UiColors.INK_SOFT)
		return tile
	_add_note(column, hero, "%s: %s" % [hero.passive_name, hero.passive_text], UiColors.INK)
	var tags: HFlowContainer = HFlowContainer.new()
	tags.alignment = FlowContainer.ALIGNMENT_CENTER
	tags.add_theme_constant_override(&"h_separation", 6)
	tags.add_theme_constant_override(&"v_separation", 4)
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var teal: Color = UiColors.STICKER_TEAL_INK
	tags.add_child(FabricTag.new("+ " + hero.strength, UiColors.STICKER_TEAL, teal))
	var pink: Color = UiColors.STICKER_PINK_INK
	tags.add_child(FabricTag.new("- " + hero.weakness, UiColors.STICKER_PINK, pink))
	column.add_child(tags)
	if is_current:
		var ink: Color = UiColors.STICKER_TEAL_INK
		var mark: FabricTag = FabricTag.new(_rules.now_text, CURRENT_COLOR, ink, 16)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(mark)
	return tile


## The hero's starting weapon: its card icon and name.
func _weapon_row(hero: HeroStats) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card: UpgradeDef = null
	if pool != null and hero.starting_weapon != null:
		card = pool.find(hero.starting_weapon.id)
	if card != null:
		var icon: UpgradeIcon = UpgradeIcon.new()
		icon.icon = card.icon
		icon.custom_minimum_size = Vector2(36, 36)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var weapon_name: String = card.display_name if card != null else ""
	row.add_child(UiFonts.label(weapon_name, 20, UiColors.INK, UiFonts.heading()))
	return row


func _add_note(column: VBoxContainer, hero: HeroStats, text: String, color: Color) -> void:
	var note: Label = UiFonts.label(text, 18, color)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(TILE_SIZE.x - 28.0, 0.0)
	column.add_child(note)
	notes[hero.id] = note


## Shows what the picking player wears on every unlocked hero's photo and the toggles' states
## (after opening and after each toggle).
func show_gear() -> void:
	if _save == null:
		return
	var worn: WornGear = WornGear.of(_save, slot, _gear_rules)
	for id: StringName in photos:
		photos[id].wear(worn)
	gear_row.visible = not worn.pieces.is_empty()
	for eye: GearEyeToggle in eye_toggles:
		var on: bool = _save.gear.slot_hidden(slot, eye.slot)
		eye.show_hidden(on, _gear_rules.hidden_text if on else _gear_rules.shown_text)
	var all: bool = _save.gear.slot_hidden(slot, -1)
	var words: String = _gear_rules.show_all_text if all else _gear_rules.hide_all_text
	hide_all_toggle.show_hidden(all, words)


func _build_gear_row(box: VBoxContainer) -> void:
	gear_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gear_row.add_theme_constant_override(&"separation", 12)
	gear_row.visible = false
	var title_label: Label = UiFonts.label(_gear_rules.picker_gear_title, 20, UiColors.INK_SOFT)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gear_row.add_child(title_label)
	for index: int in GearDef.SLOT_NAMES.size():
		var eye: GearEyeToggle = GearEyeToggle.new(index, _gear_rules.slot_titles[index])
		eye.pressed.connect(_on_eye_pressed.bind(eye))
		gear_row.add_child(eye)
		eye_toggles.append(eye)
	hide_all_toggle.pressed.connect(_on_eye_pressed.bind(hide_all_toggle))
	hide_all_toggle.fit_words(
		PackedStringArray([_gear_rules.hide_all_text, _gear_rules.show_all_text])
	)
	gear_row.add_child(hide_all_toggle)
	box.add_child(gear_row)


func _on_eye_pressed(eye: GearEyeToggle) -> void:
	if visible:
		hide_requested.emit(eye.slot, not eye.hidden_now)
