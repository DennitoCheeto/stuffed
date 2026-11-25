class_name LoadoutPage
extends CenterContainer
## The pause menu's Loadout page (spec 04b §2): a taped felt patch with one `LoadoutColumn` per
## player, side by side. Back (or Esc) returns to the pause menu.

signal back_pressed

const TEXTS: LoadoutTexts = preload("res://data/ui/loadout_view.tres")

var columns: Array[LoadoutColumn] = []
var panel: FeltPanel = FeltPanel.new(1.0)
var back_button: SewnButton = SewnButton.new("Back", true)
var motion: ScreenMotion = ScreenMotion.new()

var _row: HBoxContainer = HBoxContainer.new()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(motion)
	panel.add_tape(0.12, 5.0, UiColors.TAPE_PINK).add_tape(0.88, -6.0, UiColors.TAPE_TEAL)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 12)
	panel.content.add_child(column)
	column.add_child(HandTitle.new(TEXTS.title, 52))
	_row.add_theme_constant_override(&"separation", 40)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_row)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(back_pressed.emit)
	column.add_child(back_button)


## Fills one column per hero in `players` (in player order). `hidden` weapons get no
## evolution hint (their hero isn't unlocked yet).
func show_loadout(players: Array[Player], pool: UpgradePool, hidden: Array[StringName]) -> void:
	for old: LoadoutColumn in columns:
		_row.remove_child(old)
		old.queue_free()
	columns.clear()
	var ordered: Array[Player] = players.duplicate()
	ordered.sort_custom(func(a: Player, b: Player) -> bool: return a.player_index < b.player_index)
	for player: Player in ordered:
		var shown: LoadoutColumn = LoadoutColumn.new(player, pool, hidden, TEXTS)
		_row.add_child(shown)
		columns.append(shown)
	motion.open([panel])
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		back_pressed.emit()
