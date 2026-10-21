extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §7, AC-10, AC-11, AC-12): reroll, skip and banish on the level-up screen.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## A pool with only these upgrades (plus the snack), so a scenario knows which cards appear.
func _only(ids: Array[StringName]) -> UpgradePool:
	var pool: UpgradePool = POOL.duplicate()
	pool.upgrades = []
	for upgrade: UpgradeDef in POOL.upgrades:
		if ids.has(upgrade.id):
			pool.upgrades.append(upgrade)
	return pool


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


func _card_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: UpgradeCard in run.level_up_screen.cards:
		ids.append(card.offer.upgrade.id)
	return ids


func test_ac10_reroll_shows_three_new_cards_and_counts_down() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	assert_eq(screen.reroll_button.text, "Reroll [R]  3 left", "the count is on the button")
	var before: Array[StringName] = _card_ids()
	await _press("reroll_cards")
	var after: Array[StringName] = _card_ids()
	assert_eq(after.size(), 3, "3 cards again")
	for id: StringName in before:
		assert_does_not_have(after, id, "every card is new")
	assert_eq(first_player().card_controls.rerolls_left, 2, "one reroll used")
	assert_eq(screen.reroll_button.text, "Reroll [R]  2 left")
	assert_true(screen.is_open(), "still choosing")
	assert_true(run.is_frozen(), "still paused")


func test_ac10_with_no_rerolls_left_the_button_is_disabled() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	screen.reroll_button.pressed.emit()
	await _press("reroll_cards")
	await _press("reroll_cards")
	assert_eq(first_player().card_controls.rerolls_left, 0)
	assert_true(screen.reroll_button.disabled, "disabled at 0")
	assert_eq(screen.reroll_button.text, "Reroll [R]  0 left")
	var before: Array[StringName] = _card_ids()
	await _press("reroll_cards")
	assert_eq(_card_ids(), before, "R does nothing at 0")
	await _press("pick_card_1")
	await _level_up()
	assert_true(screen.reroll_button.disabled, "still none on the next level-up")


func test_ac11_skip_closes_without_an_upgrade_and_heals_a_little() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.health = banane.max_health * 0.5
	var weapons_before: int = banane.weapons().size()
	await _level_up()
	assert_eq(run.level_up_screen.skip_button.text, "Skip [S]  3 left")
	await _press("skip_cards")
	await wait_physics_frames(2)
	assert_false(run.level_up_screen.is_open(), "cards closed")
	assert_false(run.is_frozen(), "the run goes on")
	assert_eq(banane.picked_upgrades.size(), 0, "no upgrade taken")
	assert_eq(banane.weapons().size(), weapons_before)
	assert_eq(banane.item_levels.size(), 0)
	var healed: float = banane.max_health * (0.5 + POOL.skip_heal)
	assert_almost_eq(banane.health, healed, 0.01, "a small heal")
	assert_eq(banane.card_controls.skips_left, 2, "one skip used")


func test_ac11_skip_button_click_and_disabled_at_zero() -> void:
	await _quiet_run()
	for used: int in 3:
		await _level_up()
		run.level_up_screen.skip_button.pressed.emit()
		await wait_physics_frames(2)
		assert_false(run.level_up_screen.is_open(), "skip %d closes the cards" % (used + 1))
	await _level_up()
	assert_true(run.level_up_screen.skip_button.disabled, "disabled at 0")
	await _press("skip_cards")
	assert_true(run.level_up_screen.is_open(), "S does nothing at 0")


func test_ac12_banished_card_is_replaced_and_never_offered_again() -> void:
	await _quiet_run()
	var ids: Array[StringName] = [&"quick_feet", &"magnet_pocket", &"big_spool", &"thick_felt"]
	run.upgrade_pool = _only(ids)
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	assert_eq(screen.banish_button.text, "Banish [B]  2 left")
	var before: Array[StringName] = _card_ids()
	var victim: StringName = before[1]
	await _press("banish_card")
	assert_true(screen.banishing, "B asks which card")
	assert_eq(screen.title_label.text, LevelUpScreen.BANISH_TITLE)
	await _press("pick_card_2")
	assert_false(screen.banishing)
	var after: Array[StringName] = _card_ids()
	assert_does_not_have(after, victim, "the banished card is gone")
	assert_eq(after[0], before[0], "the other cards stay")
	assert_eq(after[2], before[2], "the other cards stay")
	assert_eq(first_player().picked_upgrades.size(), 0, "banishing doesn't pick")
	assert_eq(screen.banish_button.text, "Banish [B]  1 left")
	for level: int in 8:
		await _press("pick_card_1")
		await _level_up()
		assert_does_not_have(_card_ids(), victim, "level-up %d: never offered again" % (level + 2))
		await _press("reroll_cards")
		assert_does_not_have(_card_ids(), victim, "not after a reroll either")


func test_ac12_pressing_b_again_cancels_and_banish_runs_out() -> void:
	await _quiet_run()
	await _level_up()
	var screen: LevelUpScreen = run.level_up_screen
	await _press("banish_card")
	await _press("banish_card")
	assert_false(screen.banishing, "B again cancels")
	screen.banish_button.pressed.emit()
	screen.cards[0].pressed.emit()
	await wait_process_frames(2)
	await _press("banish_card")
	await _press("pick_card_3")
	assert_eq(first_player().card_controls.banishes_left, 0)
	assert_true(screen.banish_button.disabled, "disabled at 0")
	await _press("banish_card")
	assert_false(screen.banishing, "B does nothing at 0")
	assert_true(screen.is_open(), "still choosing")
