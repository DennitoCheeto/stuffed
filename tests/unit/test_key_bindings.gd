extends GutTest
## KeyBindings (spec 10 §5, §9, AC-112): every listed action can take a new key, a used key swaps,
## Esc / F1 / F11 stay fixed, Reset brings the shipped keys back, hints read the bound key, and
## the bindings survive save + reload (hard rule 10); a broken file keeps the shipped keys.

const TEST_PATH: String = "user://test_unit_keys.json"

var _old_path: String


func before_each() -> void:
	_old_path = GameSettings.path
	GameSettings.path = TEST_PATH
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.reset()


func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	GameSettings.reset()
	GameSettings.path = _old_path


func _write(text: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _first_key(action: StringName) -> Key:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event as InputEventKey
			return key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	return KEY_NONE


func test_every_listed_action_exists_with_its_own_shipped_key() -> void:
	# Play keys and level-up card keys are separate groups (S skips and walks down).
	var seen: Array[Array] = [[], []]
	for id: String in KeyBindings.ACTIONS:
		assert_true(KeyBindings.NAMES.has(id), "%s has a name" % id)
		var action: StringName = KeyBindings.action_name(id)
		assert_true(InputMap.has_action(action), "%s is an action" % action)
		var key: Key = KeyBindings.default_key(id)
		assert_ne(key, KEY_NONE, "%s ships with a key" % id)
		var group: Array = seen[1 if KeyBindings.is_card_key(id) else 0]
		assert_false(group.has(key), "%s's key is used once in its group" % id)
		group.append(key)
		assert_eq(KeyBindings.key_of(id), key, "%s starts on its shipped key" % id)
	assert_eq(KeyBindings.action_name("dash"), &"p1_dash")
	assert_eq(KeyBindings.action_name("card_1"), &"pick_card_1", "player 1's cards are shared")
	assert_eq(KeyBindings.action_name("dash", 1), &"p2_dash", "per player index")


func test_ac112_every_action_can_be_rebound() -> void:
	# F13, F14, ...: keys nothing uses.
	for i: int in KeyBindings.ACTIONS.size():
		var id: String = KeyBindings.ACTIONS[i]
		var key: Key = (KEY_F13 + i) as Key
		assert_eq(KeyBindings.bind(id, key), "", "%s: nothing swapped" % id)
		assert_eq(KeyBindings.key_of(id), key, "%s rebound" % id)
		assert_eq(_first_key(KeyBindings.action_name(id)), key, "%s in the InputMap" % id)
	assert_false(KeyBindings.is_default())


func test_ac112_a_used_key_swaps_with_the_other_action() -> void:
	var space: Key = KeyBindings.key_of("dash")
	var e: Key = KeyBindings.key_of("interact")
	assert_eq(KeyBindings.bind("dash", e), "interact", "interact gave its key")
	assert_eq(KeyBindings.key_of("dash"), e)
	assert_eq(KeyBindings.key_of("interact"), space, "interact got dash's old key")
	assert_eq(KeyBindings.action_with(e, "dash"), "dash", "one action per key")
	assert_eq(InputMap.action_get_events(&"p1_interact").size(), 1, "only one key on interact")
	assert_eq(KeyBindings.bind("banish", KEY_R), "reroll", "card keys swap among themselves")
	assert_eq(KeyBindings.key_of("reroll"), KEY_B)


func test_play_and_card_keys_may_share_a_key() -> void:
	assert_eq(KeyBindings.key_of("skip"), KEY_S, "S skips ...")
	assert_eq(KeyBindings.key_of("move_down"), KEY_S, "... and walks down (shipped)")
	assert_eq(KeyBindings.bind("dash", KEY_1), "", "no swap across groups")
	assert_eq(KeyBindings.key_of("card_1"), KEY_1, "card 1 keeps its key")
	assert_eq(KeyBindings.key_of("dash"), KEY_1)
	assert_true(GameSettings.save())
	GameSettings.load_saved()
	assert_eq(KeyBindings.key_of("dash"), KEY_1, "a shared key reloads")


func test_ac112_esc_f1_and_f11_stay_fixed() -> void:
	for key: Key in [KEY_ESCAPE, KEY_F1, KEY_F11]:
		KeyBindings.bind("dash", key)
		assert_eq(KeyBindings.key_of("dash"), KEY_SPACE, "%s can't be taken" % key)
	assert_eq(_first_key(&"pause"), KEY_ESCAPE, "Esc still pauses")
	assert_eq(_first_key(&"dev_menu"), KEY_F1, "F1 still opens the dev menu")


func test_ac112_reset_restores_the_shipped_keys() -> void:
	KeyBindings.bind("dash", KEY_SHIFT)
	KeyBindings.bind("reroll", KEY_F2)
	KeyBindings.bind("tricks", KEY_E)
	KeyBindings.reset()
	assert_true(KeyBindings.is_default())
	assert_eq(KeyBindings.key_of("dash"), KEY_SPACE)
	assert_eq(KeyBindings.key_of("tricks"), KEY_T)
	assert_eq(KeyBindings.key_of("interact"), KEY_E)


func test_ac112_hints_read_the_bound_key() -> void:
	assert_eq(KeyBindings.fill("{interact}   Rebuild"), "E   Rebuild", "shipped key")
	KeyBindings.bind("interact", KEY_F)
	KeyBindings.bind("use_pocket", KEY_SHIFT)
	assert_eq(KeyBindings.fill("{interact}   Rebuild"), "F   Rebuild")
	assert_eq(KeyBindings.key_text("use_pocket"), "Shift")
	assert_eq(PlayerInput.new(0).key_text("use_pocket"), "Shift", "the player's key_text too")
	assert_eq(KeyBindings.fill("no keys here"), "no keys here")


func test_ac112_bindings_survive_save_and_reload() -> void:
	KeyBindings.bind("dash", KEY_SHIFT)
	KeyBindings.bind("interact", KEY_T)
	KeyBindings.bind("card_4", KEY_F2)
	assert_true(GameSettings.save(), "written")
	var text: String = FileAccess.get_file_as_string(TEST_PATH)
	var saved: Dictionary = JSON.parse_string(text)
	assert_true(saved["bindings"].has("p1"), "stored per player index")
	KeyBindings.reset()
	assert_eq(KeyBindings.key_of("dash"), KEY_SPACE, "reset in between")
	GameSettings.load_saved()
	assert_eq(KeyBindings.key_of("dash"), KEY_SHIFT, "dash reloaded")
	assert_eq(KeyBindings.key_of("interact"), KEY_T, "interact reloaded")
	assert_eq(KeyBindings.key_of("tricks"), KEY_E, "the swapped key reloaded")
	assert_eq(KeyBindings.key_of("card_4"), KEY_F2, "card key reloaded")


func test_broken_or_odd_bindings_keep_the_shipped_keys() -> void:
	_write(JSON.stringify({"bindings": "nonsense"}))
	GameSettings.load_saved()
	assert_true(KeyBindings.is_default(), "not a dictionary")
	var odd: Dictionary = {"dash": "Escape", "skip": "NoSuchKey", "tricks": 7}
	_write(JSON.stringify({"bindings": {"p1": odd}}))
	GameSettings.load_saved()
	assert_true(KeyBindings.is_default(), "fixed, unknown and odd keys are ignored")
	_write(JSON.stringify({"bindings": {"p1": {"dash": "E"}}}))
	GameSettings.load_saved()
	assert_true(KeyBindings.is_default(), "one key on two actions: shipped keys")
	_write(JSON.stringify({"bindings": {"p1": {"dash": "Shift"}}}))
	GameSettings.load_saved()
	assert_eq(KeyBindings.key_of("dash"), KEY_SHIFT, "a partial file applies what it has")
	assert_eq(KeyBindings.key_of("interact"), KEY_E, "the rest stays shipped")
	_write("not json")
	GameSettings.load_saved()
	assert_true(KeyBindings.is_default(), "a broken file")
