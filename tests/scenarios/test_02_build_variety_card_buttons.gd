extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §20, AC-29): Reroll, Skip and Banish are big, clear buttons right under the
## cards: icon, key, uses left as dots, one line of what they do; they pulse on the first level-up;
## used up they grey out with "none left"; while banishing the cards are marked.

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## Levels Banane up once and waits until the cards can be picked.
func _level_up() -> void:
	var banane: Player = first_player()
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)


func _press(action: String) -> void:
	sender.action_down(action)
	await wait_process_frames(2)
	sender.action_up(action)
	await wait_process_frames(2)


func test_ac29_each_button_shows_icon_key_dots_and_what_it_does() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	var expected: Array[Array] = [
		[screen.reroll_button, "Reroll", "R", &"dice", "3 new cards", "●●●"],
		[screen.skip_button, "Skip", "S", &"arrow", "No card, heal a little", "●●●"],
		[screen.banish_button, "Banish", "B", &"scissors", "Remove a card for this run", "●●"],
	]
	var colors: Array[Color] = []
	for row: Array in expected:
		var button: CardControlButton = row[0]
		assert_true(button.is_visible_in_tree(), "%s is on screen" % row[1])
		assert_eq(button.title_label.text, row[1])
		assert_eq(button.key_label.text, row[2], "big key badge")
		assert_eq(button.icon_view.icon, row[3], "felt icon")
		assert_eq(button.hint_label.text, row[4], "one line of what it does")
		assert_eq(button.uses_text(), row[5], "uses left as dots")
		assert_true(button.dots.visible)
		assert_false(button.status_label.visible, "not used up")
		assert_does_not_have(colors, button.color, "own colour")
		colors.append(button.color)


func test_ac29_buttons_sit_right_under_the_cards_and_are_easy_to_see() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	var cards_bottom: float = screen.card_row.get_global_rect().end.y
	for button: CardControlButton in screen.controls():
		var rect: Rect2 = button.get_global_rect()
		assert_gt(rect.position.y, cards_bottom - 1.0, "under the cards")
		assert_lt(rect.position.y - cards_bottom, 40.0, "right under them")
		assert_gte(rect.size.x, UpgradeCard.CARD_SIZE.x * 0.9, "about as wide as a card")
		assert_gte(rect.size.y, 100.0, "big enough to notice")


func test_ac29_buttons_pulse_on_the_first_level_up_only() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	var screen: LevelUpScreen = run.level_up_screen
	assert_true(screen.is_pulsing(), "the first level-up pulses")
	var biggest: float = 1.0
	for i: int in 30:
		biggest = maxf(biggest, screen.reroll_button.scale.x)
		await wait_process_frames(1)
	assert_gt(biggest, 1.05, "the buttons grow and shrink")
	await wait_seconds(LevelUpScreen.PULSE_TIME)
	assert_false(screen.is_pulsing(), "the pulse stops")
	assert_almost_eq(screen.reroll_button.scale.x, 1.0, 0.001, "back to normal size")
	await _press("pick_card_1")
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(screen.cards_shown, 3.0)
	assert_false(screen.is_pulsing(), "no pulse on the second level-up")


func test_ac29_used_up_button_greys_out_and_says_none_left() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	for i: int in 3:
		await _press("reroll_cards")
	var button: CardControlButton = screen.reroll_button
	assert_true(button.disabled, "used up")
	assert_eq(button.uses_text(), "none left")
	assert_true(button.status_label.visible, "\"none left\" is shown")
	assert_eq(button.status_label.text, "none left")
	assert_false(button.dots.visible, "no dots")
	assert_lt(button.modulate.a, 1.0, "greyed out")
	assert_false(screen.skip_button.disabled, "the others still work")


func test_ac29_choosing_a_card_to_banish_marks_the_cards_and_esc_cancels() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	for card: UpgradeCard in screen.cards:
		assert_false(card.banish_mark.visible, "no mark before B")
	await _press("banish_card")
	assert_true(screen.banishing)
	await wait_process_frames(10)
	for card: UpgradeCard in screen.cards:
		assert_true(card.marked, "marked")
		assert_true(card.banish_mark.visible, "scissors mark")
		assert_eq(card.banish_mark.icon, &"scissors")
	var wiggled: bool = false
	for i: int in 10:
		wiggled = wiggled or absf(screen.cards[0].rotation) > 0.005
		await wait_process_frames(1)
	assert_true(wiggled, "the cards wiggle")
	await _press("pause")
	assert_false(screen.banishing, "Esc cancels")
	assert_true(screen.is_open(), "Esc doesn't close the cards")
	assert_false(run.pause_menu.visible, "Esc doesn't open the pause menu")
	for card: UpgradeCard in screen.cards:
		assert_false(card.banish_mark.visible, "marks gone")
		assert_almost_eq(card.rotation, 0.0, 0.001, "still again")
	assert_eq(first_player().card_controls.banishes_left, 2, "nothing banished")
