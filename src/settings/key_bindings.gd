class_name KeyBindings
extends RefCounted
## The keys a player can change in Settings → Controls (spec 10 §5). Each listed action has one
## key; binding a key that another action of its group uses swaps the two keys, so no key does
## two things at once (groups: play keys and level-up card keys, see `SHARED`).
## Esc (pause / back), F1 (dev menu) and F11 (window) stay fixed. Bindings live in the InputMap
## and are saved per player index in settings.json (via GameSettings), so M7 can add player 2's
## keys. Hints never spell a key out: they ask for it (`key_text`, `fill`).

## The changeable actions, in the order the Controls tab lists them.
const ACTIONS: PackedStringArray = [
	"move_up",
	"move_left",
	"move_down",
	"move_right",
	"dash",
	"interact",
	"tricks",
	"use_pocket",
	"card_1",
	"card_2",
	"card_3",
	"card_4",
	"reroll",
	"skip",
	"banish",
]
## What the Controls tab calls each action.
const NAMES: Dictionary[String, String] = {
	"move_up": "Walk up",
	"move_left": "Walk left",
	"move_down": "Walk down",
	"move_right": "Walk right",
	"dash": "Dash",
	"interact": "Use / build",
	"tricks": "Tricks",
	"use_pocket": "Pocket",
	"card_1": "Card 1",
	"card_2": "Card 2",
	"card_3": "Card 3",
	"card_4": "Card 4",
	"reroll": "Reroll",
	"skip": "Skip",
	"banish": "Banish",
}
## The level-up screen's keys. They only work while the cards show (play is frozen then), so
## they may share a key with a play action (S skips and walks down). Inside each group (play,
## cards) a key belongs to one action. Player 1's card keys are the shared level-up actions
## (other players get "pN_card_1" ...).
const SHARED: Dictionary[String, StringName] = {
	"card_1": &"pick_card_1",
	"card_2": &"pick_card_2",
	"card_3": &"pick_card_3",
	"card_4": &"pick_card_4",
	"reroll": &"reroll_cards",
	"skip": &"skip_cards",
	"banish": &"banish_card",
}
## Keys no listed action may take.
const FIXED_KEYS: Array[Key] = [KEY_ESCAPE, KEY_F1, KEY_F11]
## Nodes that show a key outside the per-frame prompts join this group: `show_keys()` is called
## on them after a key changes.
const HINTS: StringName = &"key_hints"
## How many player slots the settings file can hold.
const MAX_PLAYERS: int = 4


## The InputMap action for `id` and player `player_index` (0 = player 1).
static func action_name(id: String, player_index: int = 0) -> StringName:
	if player_index == 0 and SHARED.has(id):
		return SHARED[id]
	return StringName("p%d_%s" % [player_index + 1, id])


## The key the game ships with for `id` (KEY_NONE if that player has no default keys).
static func default_key(id: String, player_index: int = 0) -> Key:
	var setting: String = "input/%s" % action_name(id, player_index)
	if not ProjectSettings.has_setting(setting):
		return KEY_NONE
	var data: Variant = ProjectSettings.get_setting(setting)
	if not data is Dictionary:
		return KEY_NONE
	for event: Variant in (data as Dictionary).get("events", []):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			return _code_of(key)
	return KEY_NONE


## The key bound to `id` right now (KEY_NONE if none).
static func key_of(id: String, player_index: int = 0) -> Key:
	var action: StringName = action_name(id, player_index)
	if not InputMap.has_action(action):
		return KEY_NONE
	for event: InputEvent in InputMap.action_get_events(action):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			return _code_of(key)
	return KEY_NONE


## The action in `id`'s group (play or cards) that uses `key` ("" if none).
static func action_with(key: Key, id: String, player_index: int = 0) -> String:
	for other: String in ACTIONS:
		if is_card_key(other) == is_card_key(id) and key_of(other, player_index) == key:
			return other
	return ""


## True for the level-up screen's keys (cards, Reroll, Skip, Banish).
static func is_card_key(id: String) -> bool:
	return SHARED.has(id)


static func is_fixed(key: Key) -> bool:
	return FIXED_KEYS.has(key)


## Binds `key` to `id`. If another listed action had it, that action gets `id`'s old key and its
## id is returned (else ""). A fixed key or a player without these actions changes nothing.
static func bind(id: String, key: Key, player_index: int = 0) -> String:
	if is_fixed(key) or key == KEY_NONE or not ACTIONS.has(id):
		return ""
	if not InputMap.has_action(action_name(id, player_index)):
		return ""
	var old: Key = key_of(id, player_index)
	if old == key:
		return ""
	var other: String = action_with(key, id, player_index)
	if other != "":
		_set_key(action_name(other, player_index), old)
	_set_key(action_name(id, player_index), key)
	return other


## Every listed action of `player_index` back to its shipped key.
static func reset(player_index: int = 0) -> void:
	for id: String in ACTIONS:
		var key: Key = default_key(id, player_index)
		if key != KEY_NONE and InputMap.has_action(action_name(id, player_index)):
			_set_key(action_name(id, player_index), key)


## True when every listed action of `player_index` has its shipped key.
static func is_default(player_index: int = 0) -> bool:
	for id: String in ACTIONS:
		if key_of(id, player_index) != default_key(id, player_index):
			return false
	return true


## How a key is written on screen ("E", "Space", "Shift"), as the keyboard's layout labels it.
static func key_name(key: Key) -> String:
	if key == KEY_NONE:
		return "?"
	var shown: Key = key
	if DisplayServer.get_name() != "headless":
		var label: Key = DisplayServer.keyboard_get_keycode_from_physical(key)
		if label != KEY_NONE:
			shown = label
	return OS.get_keycode_string(shown)


## The key text for `id` ("E"), for hints.
static func key_text(id: String, player_index: int = 0) -> String:
	return key_name(key_of(id, player_index))


## `text` with every "{action}" ("{interact}", "{tricks}", ...) replaced by player 1's key.
static func fill(text: String, player_index: int = 0) -> String:
	if not text.contains("{"):
		return text
	var filled: String = text
	for id: String in ACTIONS:
		filled = filled.replace("{%s}" % id, key_text(id, player_index))
	return filled


## The bindings as plain data: {"p1": {"dash": "Space", ...}} (the settings file's "bindings").
static func to_dict() -> Dictionary:
	var players: Dictionary = {}
	for index: int in MAX_PLAYERS:
		if default_key("dash", index) == KEY_NONE:
			continue
		var keys: Dictionary = {}
		for id: String in ACTIONS:
			keys[id] = OS.get_keycode_string(key_of(id, index))
		players["p%d" % (index + 1)] = keys
	return players


## Applies saved bindings on top of the shipped keys. Unknown names, fixed keys and a file that
## gives one key to two actions are ignored (that player keeps the shipped keys).
static func apply_dict(data: Variant) -> void:
	for index: int in MAX_PLAYERS:
		reset(index)
	if not data is Dictionary:
		return
	for index: int in MAX_PLAYERS:
		var keys: Variant = (data as Dictionary).get("p%d" % (index + 1))
		if keys is Dictionary:
			_apply_player(keys as Dictionary, index)


static func _apply_player(keys: Dictionary, player_index: int) -> void:
	var chosen: Dictionary[String, Key] = {}
	# Keys taken so far: [play keys, card keys].
	var used: Array[Array] = [[], []]
	for id: String in ACTIONS:
		var key: Key = default_key(id, player_index)
		var saved_name: Variant = keys.get(id)
		if saved_name is String:
			var saved: Key = OS.find_keycode_from_string(saved_name as String)
			if saved != KEY_NONE and not is_fixed(saved):
				key = saved
		if key == KEY_NONE:
			continue
		var group: Array = used[1 if is_card_key(id) else 0]
		if group.has(key):
			return
		group.append(key)
		chosen[id] = key
	for id: String in chosen:
		if InputMap.has_action(action_name(id, player_index)):
			_set_key(action_name(id, player_index), chosen[id])


## Puts `key` on `action` in place of its keyboard key (mouse / gamepad events stay).
static func _set_key(action: StringName, key: Key) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var bound: InputEventKey = InputEventKey.new()
	bound.physical_keycode = key
	InputMap.action_add_event(action, bound)


static func _code_of(key: InputEventKey) -> Key:
	return key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
