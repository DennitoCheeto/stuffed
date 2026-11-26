class_name TownLoadoutColumn
extends VBoxContainer
## One player's column on the town's "My loadout" page (spec 04b §3): the hero (photo, name,
## passive), the starting weapon (level and where it comes from) and the three gear slots.
## Read only: it just shows what the next run will use.

const WIDTH: float = 560.0
const PHOTO_SIZE: Vector2 = Vector2(150, 104)
const ICON_SIZE: Vector2 = Vector2(40, 40)
const GEAR_SIZE: Vector2 = Vector2(40, 40)
const NAME_SIZE: int = 22
const SMALL_SIZE: int = 16
const HEADING_SIZE: int = 19

var player_index: int = 0
var heading: HandTitle
var photo: HeroPhoto
## What is shown, for tests: hero id, passive text, starting weapon id/name/level/source.
var hero_id: StringName = &""
var passive_text: String = ""
var start_weapon: StringName = &""
var start_level: int = 1
var start_source: String = ""
## One entry per gear slot (Head, Body, Charm): {slot, id, name, level, effect, empty}.
## A slot with nothing on has id "" and `empty` = the hint ("" before the Workshop shows).
var gear_rows: Array[Dictionary] = []

var _texts: LoadoutTexts


## `start` is the weapon the hero starts with at `level`; `picked` = chosen at the Armory.
## `workshop_shown` = the Sewing Workshop is revealed (empty slots then say where to sew).
func _init(
	index: int,
	hero: HeroStats,
	start: UpgradeDef,
	level: int,
	picked: bool,
	worn: WornGear,
	workshop_shown: bool,
	texts: LoadoutTexts
) -> void:
	_texts = texts
	player_index = index
	name = "Player%dTownLoadout" % (index + 1)
	custom_minimum_size.x = WIDTH
	add_theme_constant_override(&"separation", 6)
	var color: Color = UiColors.PLAYER_MARKERS[index % UiColors.PLAYER_MARKERS.size()]
	heading = HandTitle.new(texts.heading % [index + 1, hero.display_name], 32, color, -1.5)
	heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(heading)
	_add_hero(hero)
	_add_start_weapon(start, level, picked)
	_add_gear(worn, workshop_shown)


func _add_hero(hero: HeroStats) -> void:
	hero_id = hero.id
	passive_text = hero.passive_text
	var row: HBoxContainer = _row(14)
	var frame: PhotoFrame = PhotoFrame.new("", PHOTO_SIZE, -2.0, UiColors.TAPE_TEAL)
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo = HeroPhoto.new(hero, false)
	frame.picture.add_child(photo)
	row.add_child(frame)
	var text: VBoxContainer = VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiFonts.label(hero.passive_name, NAME_SIZE, UiColors.INK, UiFonts.heading()))
	text.add_child(_wrapped(passive_text, SMALL_SIZE + 1, UiColors.INK, WIDTH - PHOTO_SIZE.x - 50))
	row.add_child(text)
	add_child(row)


func _add_start_weapon(start: UpgradeDef, level: int, picked: bool) -> void:
	add_child(_section(_texts.start_heading))
	start_level = level
	start_source = _texts.armory_weapon if picked else _texts.own_weapon
	var row: HBoxContainer = _row(10)
	if start != null:
		start_weapon = start.id
		var icon: UpgradeIcon = UpgradeIcon.new()
		icon.icon = start.icon
		icon.custom_minimum_size = ICON_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var text: VBoxContainer = VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 0)
	var line: HBoxContainer = _row(10)
	var weapon_name: String = start.display_name if start != null else ""
	line.add_child(UiFonts.label(weapon_name, NAME_SIZE, UiColors.INK, UiFonts.heading()))
	line.add_child(FabricTag.new(_texts.start_level % level, UiColors.TAG, UiColors.INK, 15))
	text.add_child(line)
	text.add_child(UiFonts.label(start_source, SMALL_SIZE, UiColors.INK_SOFT))
	row.add_child(text)
	add_child(row)


func _add_gear(worn: WornGear, workshop_shown: bool) -> void:
	add_child(_section(_texts.gear_heading))
	var rules: GearRules = GearRules.current()
	for slot: int in rules.slot_titles.size():
		var piece: GearDef = _piece_in(worn, slot)
		var entry: Dictionary = {
			"slot": slot, "id": &"", "name": "", "level": 0, "effect": "", "empty": ""
		}
		var row: HBoxContainer = _row(10)
		var title: Label = UiFonts.label(rules.slot_titles[slot], SMALL_SIZE, UiColors.INK_SOFT)
		title.custom_minimum_size.x = 56.0
		row.add_child(title)
		if piece != null:
			var level: int = worn.level_of(piece)
			entry["id"] = piece.id
			entry["name"] = piece.display_name
			entry["level"] = level
			var stitch: GearLevel = piece.level(level)
			var has_effect: bool = stitch != null and stitch.effect != ""
			entry["effect"] = stitch.effect if has_effect else piece.text
			var picture: GearPicture = GearPicture.new(piece, false)
			picture.level = level
			picture.custom_minimum_size = GEAR_SIZE
			row.add_child(picture)
			var text: VBoxContainer = VBoxContainer.new()
			text.add_theme_constant_override(&"separation", 0)
			var line: HBoxContainer = _row(8)
			line.add_child(UiFonts.label(piece.display_name, SMALL_SIZE + 2, UiColors.INK))
			line.add_child(UiFonts.label(_texts.gear_level % level, SMALL_SIZE, UiColors.GOLD_EDGE))
			text.add_child(line)
			var effect: String = entry["effect"]
			text.add_child(_wrapped(effect, SMALL_SIZE - 1, UiColors.INK_SOFT, WIDTH - 130.0))
			row.add_child(text)
		else:
			entry["empty"] = _texts.empty_gear if workshop_shown else ""
			var words: String = _texts.empty_gear if workshop_shown else _texts.no_gear
			row.add_child(UiFonts.label(words, SMALL_SIZE, UiColors.INK_SOFT))
		gear_rows.append(entry)
		add_child(row)


static func _piece_in(worn: WornGear, slot: int) -> GearDef:
	if worn == null:
		return null
	for piece: GearDef in worn.pieces:
		if piece.slot == slot:
			return piece
	return null


func _section(text: String) -> Label:
	return UiFonts.label(text, HEADING_SIZE, UiColors.INK_SOFT, UiFonts.heading())


static func _row(gap: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", gap)
	return row


static func _wrapped(text: String, font_size: int, color: Color, width: float) -> Label:
	var label: Label = UiFonts.label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = width
	return label
