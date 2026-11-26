class_name TownLoadoutPage
extends CenterContainer
## The town's "My loadout" page (spec 04b §3, AC-118): a taped felt patch with one
## `TownLoadoutColumn` per player in town and the shared `TownBonuses` strip under them.
## Read only. Back, Esc or any player's interact key closes it.

signal back_pressed

const TEXTS: LoadoutTexts = preload("res://data/ui/loadout_view.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")

var columns: Array[TownLoadoutColumn] = []
var bonuses: TownBonuses
var panel: FeltPanel = FeltPanel.new(-1.0)
var back_button: SewnButton = SewnButton.new("Back", true)
var motion: ScreenMotion = ScreenMotion.new()

var _column: VBoxContainer = VBoxContainer.new()
var _row: HBoxContainer = HBoxContainer.new()


func _init() -> void:
	name = "TownLoadoutPage"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(motion)
	panel.add_tape(0.1, 4.0, UiColors.TAPE_TEAL).add_tape(0.9, -5.0, UiColors.TAPE_PINK)
	add_child(panel)
	_column.add_theme_constant_override(&"separation", 10)
	panel.content.add_child(_column)
	_column.add_child(HandTitle.new(TEXTS.town_title, 46))
	_row.add_theme_constant_override(&"separation", 40)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_child(_row)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(back_pressed.emit)
	_column.add_child(back_button)


## Fills the page for the town in `save` (buildings on `layout`), one column per hero in
## `players` (in player order).
func show_loadout(save: TownSave, layout: TownLayout, players: Array[Player]) -> void:
	for old: Node in _row.get_children():
		_row.remove_child(old)
		old.queue_free()
	columns.clear()
	if bonuses != null:
		_column.remove_child(bonuses)
		bonuses.queue_free()
	var perks: TownPerks = TownPerks.from_save(save, layout)
	var workshop: TownSpot = layout.spot(GearRules.current().workshop)
	var workshop_shown: bool = workshop != null and not workshop.is_hidden_in(save)
	var ordered: Array[Player] = players.duplicate()
	ordered.sort_custom(func(a: Player, b: Player) -> bool: return a.player_index < b.player_index)
	for player: Player in ordered:
		var index: int = player.player_index
		var hero: HeroStats = player.stats
		var start: WeaponStats = perks.starting_weapon(POOL, hero.starting_weapon)
		var card: UpgradeDef = POOL.find(start.id) if start != null else null
		var head_start: TrickDef = perks.trick(&"head_start")
		var level: int = int(head_start.amount) if head_start != null else 1
		var picked: bool = start != hero.starting_weapon
		var shown: TownLoadoutColumn = TownLoadoutColumn.new(
			index, hero, card, level, picked, perks.gear(index), workshop_shown, TEXTS
		)
		_row.add_child(shown)
		columns.append(shown)
	bonuses = TownBonuses.new(layout, perks, TEXTS)
	_column.add_child(bonuses)
	_column.move_child(bonuses, _row.get_index() + 1)
	motion.open([panel])
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed(&"pause") or _is_interact(event):
		get_viewport().set_input_as_handled()
		back_pressed.emit()


## True for any player's interact key (each player opens and closes it with their own).
static func _is_interact(event: InputEvent) -> bool:
	for index: int in HeroRoster.MAX_PLAYERS:
		var action: StringName = KeyBindings.action_name("interact", index)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false
