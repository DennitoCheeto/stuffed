class_name ControlsPage
extends VBoxContainer
## The Controls tab of Settings (spec 10 §5, AC-112): player 1's changeable actions in two
## columns, each with its key on a sewn tag. Click a tag (or Enter on it), then press a key: it's
## bound at once. A key another action uses swaps with it; Esc cancels; Esc / F1 / F11 can't be
## taken. "Reset to defaults" brings the shipped keys back. Every change emits `changed` (the
## panel saves).

signal changed

const FONT_SIZE: int = 22
const LABEL_WIDTH: float = 150.0
const KEY_WIDTH: float = 120.0
const LEFT_COLUMN: int = 8
const LISTENING_TEXT: String = "..."
const START_NOTE: String = "Click a key to change it."
const LISTEN_NOTE: String = "Press a key for %s (Esc: cancel)"
const BOUND_NOTE: String = "%s: %s"
const SWAP_NOTE: String = "%s   (%s moved to %s)"
const FIXED_NOTE: String = "%s is fixed: pick another key"
const RESET_NOTE: String = "Back to the default keys."
const RESET_TEXT: String = "Reset to defaults"

## Whose keys this page changes (player 1 until M7 adds player 2).
var player_index: int = 0
## Action id -> its key tag.
var keys: Dictionary[String, SewnButton] = {}
## Action id -> its name label.
var labels: Dictionary[String, Label] = {}
## The action waiting for a key ("" = none).
var listening: String = ""
var note: Label
var reset_button: SewnButton


## `make_tag` builds a sewn fabric tag from words (the Settings panel's tag style).
func _init(make_tag: Callable) -> void:
	add_theme_constant_override(&"separation", 16)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 30)
	add_child(columns)
	var left: VBoxContainer = _column(columns)
	var right: VBoxContainer = _column(columns)
	for i: int in KeyBindings.ACTIONS.size():
		var id: String = KeyBindings.ACTIONS[i]
		_add_row(left if i < LEFT_COLUMN else right, id, make_tag)
	var bottom: HBoxContainer = HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 14)
	add_child(bottom)
	note = UiFonts.label(START_NOTE, FONT_SIZE, UiColors.INK_SOFT)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(note)
	reset_button = make_tag.call(RESET_TEXT)
	reset_button.toggle_mode = false
	reset_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reset_button.pressed.connect(reset_keys)
	bottom.add_child(reset_button)


## Shows every action's key as it is bound now.
func refresh() -> void:
	for id: String in keys:
		keys[id].text = KeyBindings.key_text(id, player_index)
		keys[id].queue_redraw()


## Shows the page fresh (nothing waiting for a key).
func open() -> void:
	stop_listening()
	note.text = START_NOTE


## The next key pressed goes to `id`.
func listen(id: String) -> void:
	stop_listening()
	listening = id
	keys[id].text = LISTENING_TEXT
	keys[id].set_pressed_no_signal(true)
	note.text = LISTEN_NOTE % KeyBindings.NAMES[id]


## Stops waiting for a key; the tags show the bound keys again.
func stop_listening() -> void:
	if listening != "":
		keys[listening].set_pressed_no_signal(false)
	listening = ""
	refresh()


## Binds `key` to the action waiting for one (see `KeyBindings.bind`).
func press_key(key: Key) -> void:
	var id: String = listening
	if id == "":
		return
	if key == KEY_ESCAPE:
		stop_listening()
		note.text = START_NOTE
		return
	if KeyBindings.is_fixed(key):
		note.text = FIXED_NOTE % KeyBindings.key_name(key)
		return
	var other: String = KeyBindings.bind(id, key, player_index)
	stop_listening()
	var bound: String = BOUND_NOTE % [KeyBindings.NAMES[id], KeyBindings.key_text(id, player_index)]
	note.text = bound
	if other != "":
		var moved: String = KeyBindings.key_text(other, player_index)
		note.text = SWAP_NOTE % [bound, KeyBindings.NAMES[other], moved]
	changed.emit()
	_tell_hints()


func reset_keys() -> void:
	stop_listening()
	KeyBindings.reset(player_index)
	refresh()
	note.text = RESET_NOTE
	changed.emit()
	_tell_hints()


func _input(event: InputEvent) -> void:
	if listening == "" or not is_visible_in_tree():
		return
	var key: InputEventKey = event as InputEventKey
	if key == null:
		return
	get_viewport().set_input_as_handled()
	if not key.pressed or key.echo:
		return
	press_key(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)


func _tell_hints() -> void:
	if is_inside_tree():
		get_tree().call_group(KeyBindings.HINTS, &"show_keys")


func _column(parent: HBoxContainer) -> VBoxContainer:
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	parent.add_child(column)
	return column


func _add_row(column: VBoxContainer, id: String, make_tag: Callable) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	column.add_child(row)
	var label: Label = UiFonts.label(KeyBindings.NAMES[id], FONT_SIZE, UiColors.INK)
	label.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	row.add_child(label)
	labels[id] = label
	var tag: SewnButton = make_tag.call(KeyBindings.key_text(id, player_index))
	tag.face.custom_minimum_size.x = KEY_WIDTH
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.pressed.connect(listen.bind(id))
	row.add_child(tag)
	keys[id] = tag
