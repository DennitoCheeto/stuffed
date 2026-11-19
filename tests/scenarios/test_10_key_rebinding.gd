extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §5, §8, §9, AC-112): Settings → Controls lists player 1's actions. Click a
## key, press a new one: it's bound at once and works in the game. A used key swaps, Esc cancels,
## F1 is fixed, Reset brings the shipped keys back. Every key hint (town prompts, building card,
## tricks, level-up cards, gift box) shows the bound key, and the keys survive a restart.

const SETTLE: float = 0.1

## Where the hero dashed from (filled by `_on_dashed`).
var _dashes: Array[Vector2] = []


func after_each() -> void:
	GameSettings.reset()
	super.after_each()


func _on_dashed(from: Vector2, _direction: Vector2) -> void:
	_dashes.append(from)


func _open_controls() -> SettingsPanel:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	title.settings.tabs[SettingsPanel.Tab.CONTROLS].pressed.emit()
	await wait_process_frames(1)
	return title.settings


## A real key press: both the key and its place on the keyboard (GUT's sender sets only the key).
func _press_key(key: Key) -> void:
	sender.send_event(_key_event(key, true))
	await wait_physics_frames(2)
	sender.send_event(_key_event(key, false))
	await wait_physics_frames(1)


func _key_event(key: Key, down: bool) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = down
	return event


func _rebind(page: ControlsPage, id: String, key: Key) -> void:
	page.keys[id].pressed.emit()
	await wait_process_frames(1)
	await _press_key(key)


func _restart() -> void:
	remove_child(main)
	main.queue_free()
	await wait_process_frames(1)
	GameSettings.reset()
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	await wait_physics_frames(1)


func test_ac112_controls_lists_every_action_with_its_key() -> void:
	var panel: SettingsPanel = await _open_controls()
	var page: ControlsPage = panel.controls
	assert_true(page.is_visible_in_tree(), "the Controls tab shows the key list")
	for id: String in KeyBindings.ACTIONS:
		assert_true(page.keys[id].is_visible_in_tree(), "%s listed" % id)
		assert_eq(page.labels[id].text, KeyBindings.NAMES[id])
	assert_eq(page.keys["dash"].text, "Space")
	assert_eq(page.keys["interact"].text, "E")
	assert_eq(page.keys["card_1"].text, "1")
	assert_eq(page.keys["banish"].text, "B")
	assert_true(page.reset_button.is_visible_in_tree(), "Reset to defaults")


func test_ac112_a_new_key_is_bound_at_once_and_dashes_in_the_run() -> void:
	var panel: SettingsPanel = await _open_controls()
	var page: ControlsPage = panel.controls
	page.keys["dash"].pressed.emit()
	await wait_process_frames(1)
	assert_eq(page.listening, "dash", "waiting for a key")
	assert_eq(page.keys["dash"].text, ControlsPage.LISTENING_TEXT)
	assert_string_contains(page.note.text, "Dash")
	await _press_key(KEY_SHIFT)
	assert_eq(page.listening, "", "bound")
	assert_eq(page.keys["dash"].text, "Shift", "the tag shows the new key")
	assert_eq(KeyBindings.key_of("dash"), KEY_SHIFT)
	assert_eq(panel.tab_index, SettingsPanel.Tab.CONTROLS, "still on Controls")
	panel.close()
	var run: Run = await start_run()
	run.spawner.active = false
	var hero: Player = first_player()
	_dashes.clear()
	hero.dashed.connect(_on_dashed)
	await wait_seconds(0.5)
	await _press_key(KEY_SPACE)
	assert_eq(_dashes.size(), 0, "Space doesn't dash any more")
	await _press_key(KEY_SHIFT)
	assert_eq(_dashes.size(), 1, "Shift dashes")


func test_ac112_a_used_key_swaps_esc_cancels_and_f1_is_fixed() -> void:
	var panel: SettingsPanel = await _open_controls()
	var page: ControlsPage = panel.controls
	await _rebind(page, "interact", KEY_T)
	assert_eq(KeyBindings.key_of("interact"), KEY_T)
	assert_eq(KeyBindings.key_of("tricks"), KEY_E, "tricks took interact's old key")
	assert_eq(page.keys["tricks"].text, "E", "both tags updated")
	assert_string_contains(page.note.text, "Tricks", "the note says what moved")
	page.keys["dash"].pressed.emit()
	await wait_process_frames(1)
	await _press_key(KEY_F1)
	assert_eq(page.listening, "dash", "F1 can't be taken: still waiting")
	assert_string_contains(page.note.text, "F1")
	await _press_key(KEY_ESCAPE)
	assert_eq(page.listening, "", "Esc cancels")
	assert_true(panel.is_open(), "Esc while waiting doesn't close Settings")
	assert_eq(KeyBindings.key_of("dash"), KEY_SPACE, "nothing changed")
	await _press_key(KEY_ESCAPE)
	assert_false(panel.is_open(), "the next Esc closes Settings")


func test_ac112_q_and_e_go_to_the_key_while_waiting() -> void:
	var panel: SettingsPanel = await _open_controls()
	var page: ControlsPage = panel.controls
	await _rebind(page, "use_pocket", KEY_E)
	assert_eq(panel.tab_index, SettingsPanel.Tab.CONTROLS, "E didn't switch the tab")
	assert_eq(KeyBindings.key_of("use_pocket"), KEY_E)
	assert_eq(KeyBindings.key_of("interact"), KEY_Q, "swapped")


func test_ac112_reset_restores_the_defaults() -> void:
	var panel: SettingsPanel = await _open_controls()
	var page: ControlsPage = panel.controls
	await _rebind(page, "dash", KEY_SHIFT)
	await _rebind(page, "reroll", KEY_X)
	page.reset_button.pressed.emit()
	await wait_process_frames(1)
	assert_true(KeyBindings.is_default(), "shipped keys back")
	assert_eq(page.keys["dash"].text, "Space")
	assert_eq(page.keys["reroll"].text, "R")
	GameSettings.load_saved()
	assert_true(KeyBindings.is_default(), "and saved")


func test_ac112_bindings_survive_a_restart() -> void:
	var panel: SettingsPanel = await _open_controls()
	await _rebind(panel.controls, "dash", KEY_SHIFT)
	await _rebind(panel.controls, "card_2", KEY_X)
	panel.close()
	await _restart()
	assert_eq(KeyBindings.key_of("dash"), KEY_SHIFT, "loaded on boot")
	assert_eq(KeyBindings.key_of("card_2"), KEY_X)
	panel = await _open_controls()
	assert_eq(panel.controls.keys["dash"].text, "Shift", "the tab shows it")
	assert_eq(panel.controls.keys["card_2"].text, "X")


func test_ac112_town_hints_show_the_bound_keys() -> void:
	var panel: SettingsPanel = await _open_controls()
	await _rebind(panel.controls, "interact", KEY_F)
	await _rebind(panel.controls, "tricks", KEY_G)
	await _rebind(panel.controls, "use_pocket", KEY_Z)
	panel.close()
	main.town.building_levels["snack_bar"] = 2
	main.town.tricks.append("picnic")
	main.town.materials = {"coins": 99999, "stuffing": 99999, "thread": 99999}
	var town: Town = await go_to_town()
	await wait_physics_frames(2)
	assert_eq(town.prompt_label.text, "F   Go to the Bedroom", "door prompt")
	var bar: TownBuilding = town.buildings[&"snack_bar"]
	var rect: Rect2 = bar.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	assert_eq(town.card.tricks_label.text, "G   Tricks (1 of 3)", "building card: tricks")
	assert_eq(town.prompt_label.text, "F   Upgrade to level 3", "building prompt")
	assert_true(town.tricks.open(bar), "the Tricks panel opens")
	await wait_physics_frames(1)
	assert_string_contains(town.tricks.panel.hint_label.text, "G or Esc", "tricks panel")
	assert_string_contains(town.tricks.panel.hint_label.text, "1 / 2 / 3", "card keys")
	var pocket: TrickDef = load("res://data/town/tricks/pocket_pickup.tres")
	var patch: TrickPatch = TrickPatch.new(pocket)
	assert_string_contains(patch.text_label.text, "use it with Z", "trick text")
	patch.free()
	town.tricks.toast.show_for("Snack Bar")
	assert_eq(town.tricks.toast.subtitle_label.text, "Walk up to it and press G", "tricks toast")


func test_ac112_level_up_and_gift_box_show_the_bound_keys() -> void:
	var panel: SettingsPanel = await _open_controls()
	await _rebind(panel.controls, "card_1", KEY_Z)
	await _rebind(panel.controls, "reroll", KEY_X)
	await _rebind(panel.controls, "interact", KEY_F)
	panel.close()
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	var hero: Player = first_player()
	hero.add_xp(hero.progress.xp_needed() - hero.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(UiFeel.STYLE.open_seconds + SETTLE)
	var screen: LevelUpScreen = run.level_up_screen
	assert_eq(screen.cards[0].key_tag.label.text, "Z", "card 1's key")
	assert_eq(screen.cards[1].key_tag.label.text, "2", "card 2 unchanged")
	assert_eq(screen.reroll_button.key_label.text, "X", "Reroll's key")
	assert_eq(screen.skip_button.key_label.text, "S")
	await _press_key(KEY_Z)
	await wait_physics_frames(2)
	assert_false(screen.is_open(), "Z picks card 1")
	run.pickups.buttons.clear()
	run.drop_gift_box(hero.position)
	await wait_until(_gift_showing.bind(run), 5.0)
	var gift: GiftBoxScreen = run.gift_screen
	await wait_seconds(gift.confirm_delay + UiFeel.STYLE.open_seconds + SETTLE)
	assert_string_contains(gift.continue_button.text, "/ F]", "gift box: Continue with F")
	await _press_key(KEY_E)
	assert_true(gift.visible, "E no longer closes it")
	await _press_key(KEY_F)
	assert_false(gift.visible, "F does")


func _gift_showing(run: Run) -> bool:
	return run.gift_screen.showing_contents
