class_name LoadoutColumn
extends VBoxContainer
## One player's loadout on the pause menu's Loadout page (spec 04b §2): weapons with level and
## evolution hint, items with level, worn gear. Free slots show as faint empty slots.

const WIDTH: float = 520.0
const NAME_SIZE: int = 22
const SMALL_SIZE: int = 17
const HEADING_SIZE: int = 20
## Hint colours: partner owned / not owned yet / ready to evolve.
const OWNED_COLOR: Color = Color("#2f8f3e")
const MISSING_COLOR: Color = UiColors.INK_SOFT
const READY_COLOR: Color = UiColors.PURPLE
const ITEM_COLUMNS: int = 2

var player_index: int = 0
var heading: HandTitle
## One entry per owned weapon, in HUD order: {id, name, level, top, evolved, hint, hint_color}.
var weapon_rows: Array[Dictionary] = []
## One entry per owned item: {id, name, level, top}.
var item_rows: Array[Dictionary] = []
## The worn gear lines ("Lookout Cap Lv 2").
var gear_lines: PackedStringArray = []
## Faint empty slots (weapons + items).
var empty_slots: int = 0

var _texts: LoadoutTexts


func _init(
	player: Player, pool: UpgradePool, hidden: Array[StringName], texts: LoadoutTexts
) -> void:
	_texts = texts
	player_index = player.player_index
	name = "Player%dLoadout" % (player_index + 1)
	custom_minimum_size.x = WIDTH
	add_theme_constant_override(&"separation", 6)
	var color: Color = UiColors.PLAYER_MARKERS[player_index % UiColors.PLAYER_MARKERS.size()]
	var hero: String = player.stats.display_name if player.stats != null else ""
	heading = HandTitle.new(texts.heading % [player_index + 1, hero], 34, color, -1.5)
	heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	add_child(heading)
	_add_weapons(player, pool, hidden)
	_add_items(player, pool)
	_add_gear(player)


## The hint under weapon `weapon_id`: {text, color} ({} = it can't evolve, or its recipe is
## hidden because the hero isn't unlocked). "Ready" = maxed + partner owned (any level).
static func evolution_hint(
	weapon_id: StringName,
	maxed: bool,
	item_levels: Dictionary[StringName, int],
	pool: UpgradePool,
	hidden: Array[StringName],
	texts: LoadoutTexts
) -> Dictionary:
	if hidden.has(weapon_id):
		return {}
	for evolution: EvolutionDef in pool.evolutions:
		if evolution.weapon != weapon_id:
			continue
		var owned: bool = item_levels.has(evolution.partner)
		if maxed and owned:
			return {"text": texts.ready, "color": READY_COLOR}
		var partner: UpgradeDef = pool.find(evolution.partner)
		var partner_name: String = partner.display_name if partner != null else ""
		var seen: bool = RecipeBook.is_seen(evolution.evolved.id)
		var result: String = evolution.display_name() if seen else texts.unseen
		var color: Color = OWNED_COLOR if owned else MISSING_COLOR
		return {"text": texts.evolve_hint % [result, partner_name], "color": color}
	return {}


func _add_weapons(player: Player, pool: UpgradePool, hidden: Array[StringName]) -> void:
	add_child(_section(_texts.weapons_heading))
	var weapons: Array[Weapon] = player.weapons()
	for owned: Weapon in weapons:
		var evolved: bool = owned.stats.evolved_from != &""
		var entry: Dictionary = {
			"id": owned.stats.id,
			"name": owned.stats.display_name,
			"level": owned.level,
			"top": owned.stats.max_level(),
			"evolved": evolved,
		}
		var hint: Dictionary = {}
		if not evolved:
			var levels: Dictionary[StringName, int] = player.item_levels
			hint = evolution_hint(owned.stats.id, owned.is_maxed(), levels, pool, hidden, _texts)
		entry["hint"] = hint.get("text", "")
		weapon_rows.append(entry)
		add_child(_weapon_row(entry, _icon_for(pool, owned.stats.id), hint))
	var free: int = maxi(pool.max_weapons - weapons.size(), 0)
	if free > 0:
		add_child(_empty_row(free))


func _add_items(player: Player, pool: UpgradePool) -> void:
	add_child(_section(_texts.items_heading))
	var grid: GridContainer = GridContainer.new()
	grid.columns = ITEM_COLUMNS
	grid.add_theme_constant_override(&"h_separation", 16)
	grid.add_theme_constant_override(&"v_separation", 4)
	add_child(grid)
	for item: UpgradeDef in player.items:
		var level: int = player.item_levels.get(item.id, 0)
		item_rows.append(
			{"id": item.id, "name": item.display_name, "level": level, "top": item.top_level()}
		)
		var row: HBoxContainer = _row()
		row.add_child(_slot(item.icon, level, false))
		var text: VBoxContainer = VBoxContainer.new()
		text.add_theme_constant_override(&"separation", 0)
		text.add_child(UiFonts.label(item.display_name, SMALL_SIZE + 1, UiColors.INK))
		text.add_child(LevelDots.new(level, item.top_level()))
		row.add_child(text)
		grid.add_child(row)
	var free: int = maxi(pool.max_items - player.items.size(), 0)
	for index: int in free:
		empty_slots += 1
		grid.add_child(_slot(&"", 0, false))


func _add_gear(player: Player) -> void:
	add_child(_section(_texts.gear_heading))
	var worn: WornGear = player.gear
	if worn != null:
		for piece: GearDef in worn.pieces:
			gear_lines.append(_texts.gear_line % [piece.display_name, worn.level_of(piece)])
	var text: String = ", ".join(gear_lines) if not gear_lines.is_empty() else _texts.no_gear
	var label: Label = UiFonts.label(text, SMALL_SIZE + 1, UiColors.INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = WIDTH
	add_child(label)


func _weapon_row(entry: Dictionary, icon: StringName, hint: Dictionary) -> HBoxContainer:
	var row: HBoxContainer = _row()
	var evolved: bool = entry["evolved"]
	row.add_child(_slot(icon, entry["level"], evolved))
	var text: VBoxContainer = VBoxContainer.new()
	text.add_theme_constant_override(&"separation", 0)
	var line: HBoxContainer = _row()
	line.add_child(UiFonts.label(entry["name"], NAME_SIZE, UiColors.INK, UiFonts.heading()))
	var level: int = entry["level"]
	var top: int = entry["top"]
	if evolved:
		line.add_child(UiFonts.label(_texts.evolved, SMALL_SIZE, UiColors.GOLD_EDGE))
	elif level >= top:
		line.add_child(UiFonts.label(_texts.maxed, SMALL_SIZE, UiColors.GOLD_EDGE))
	else:
		line.add_child(LevelDots.new(level, top))
	text.add_child(line)
	if not hint.is_empty():
		text.add_child(UiFonts.label(hint["text"], SMALL_SIZE, hint["color"]))
	row.add_child(text)
	return row


## A row of `count` faint empty weapon slots.
func _empty_row(count: int) -> HBoxContainer:
	var row: HBoxContainer = _row()
	for index: int in count:
		empty_slots += 1
		row.add_child(_slot(&"", 0, false))
	return row


func _section(text: String) -> Label:
	return UiFonts.label(text, HEADING_SIZE, UiColors.INK_SOFT, UiFonts.heading())


static func _row() -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	return row


static func _slot(icon: StringName, level: int, evolved: bool) -> LoadoutSlot:
	var slot: LoadoutSlot = LoadoutSlot.new()
	slot.show_upgrade(icon, level, evolved)
	return slot


## The felt icon of a weapon or evolved weapon (like the HUD).
static func _icon_for(pool: UpgradePool, id: StringName) -> StringName:
	var upgrade: UpgradeDef = pool.find(id)
	if upgrade != null:
		return upgrade.icon
	var evolution: EvolutionDef = pool.evolution_into(id)
	return evolution.icon if evolution != null else &""
