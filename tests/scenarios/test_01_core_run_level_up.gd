extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §8, AC-17, AC-18, AC-21): level-up cards.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
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


func test_ac17_full_xp_bar_pauses_and_shows_three_different_cards() -> void:
	await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(300, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	await wait_physics_frames(5)
	await _level_up()
	assert_true(run.level_up_screen.is_open(), "cards are shown")
	assert_true(run.is_frozen(), "the run is paused")
	var time_before: float = run.elapsed
	var zombie_before: Vector2 = zombie.position
	await wait_physics_frames(30)
	assert_eq(run.elapsed, time_before, "timer stopped")
	assert_eq(zombie.position, zombie_before, "zombies stopped")
	var cards: Array[UpgradeCard] = run.level_up_screen.cards
	assert_eq(cards.size(), 3)
	var ids: Dictionary[StringName, bool] = {}
	for card: UpgradeCard in cards:
		ids[card.offer.upgrade.id] = true
	assert_eq(ids.size(), 3, "three different upgrades")


func test_ac17_key_pick_applies_and_continues() -> void:
	await _quiet_run()
	run.upgrade_pool = _only([&"quick_feet"])
	await _level_up()
	await _press("pick_card_1")
	await wait_physics_frames(2)
	assert_false(run.level_up_screen.is_open(), "cards closed")
	assert_false(run.is_frozen(), "the run goes on")
	assert_eq(first_player().picked_upgrades, PackedStringArray(["Quick Feet 1"]))
	var time_before: float = run.elapsed
	await wait_physics_frames(10)
	assert_gt(run.elapsed, time_before, "timer runs again")


func test_ac17_click_picks_a_card() -> void:
	await _quiet_run()
	await _level_up()
	var second: UpgradeCard = run.level_up_screen.cards[1]
	second.pressed.emit()
	await wait_physics_frames(2)
	assert_false(run.level_up_screen.is_open())
	assert_eq(first_player().picked_upgrades.size(), 1)


func test_ac17_run_waits_until_a_card_is_picked() -> void:
	await _quiet_run()
	await _level_up()
	await wait_seconds(1.0)
	assert_true(run.level_up_screen.is_open(), "still waiting")
	assert_true(run.is_frozen())


func test_ac18_quick_feet_makes_banane_faster() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	run.upgrade_pool = _only([&"quick_feet"])
	await _level_up()
	await _press("pick_card_1")
	await wait_physics_frames(2)
	var start: Vector2 = banane.global_position
	await hold_action("p1_move_right", 30)
	var expected: float = banane.stats.move_speed * 1.1 * 30.0 / FPS
	assert_almost_eq(banane.global_position.x - start.x, expected, 6.0, "10% faster")


func test_ac18_boosts_and_snack_do_what_they_say() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.take_hit(50.0, "Shambler")
	for upgrade: UpgradeDef in POOL.upgrades:
		if upgrade.kind == UpgradeDef.Kind.BOOST:
			banane.apply_upgrade(UpgradeOffer.new(upgrade, 1))
	assert_almost_eq(banane.move_speed(), banane.stats.move_speed * 1.1, 0.01, "Quick Feet")
	assert_eq(banane.max_health, 120.0, "Extra Stuffing: +20 max health")
	assert_eq(banane.health, 70.0, "... and heals 20")
	assert_almost_eq(banane.pickup_range, 78.0, 0.01, "Magnet Pocket: +30%")
	assert_almost_eq(banane.attack_speed, 1.1, 0.001, "Quick Hands: +10%")
	banane.apply_upgrade(UpgradeOffer.new(POOL.snack, 1))
	assert_eq(banane.health, 106.0, "Banana Snack heals 30% of 120")


func test_ac18_weapon_card_levels_up_the_boomerang() -> void:
	run = await start_run()
	run.spawner.active = false
	var banane: Player = first_player()
	run.upgrade_pool = _only([&"peel_boomerang"])
	await _level_up()
	await _press("pick_card_1")
	assert_eq(banane.weapon(&"peel_boomerang").level, 2)


func test_ac21_two_level_ups_show_two_card_screens() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	watch_signals(run.level_up_screen)
	banane.add_xp(5 + 7)
	assert_eq(banane.progress.level, 3, "two levels at once")
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)
	await _press("pick_card_1")
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	assert_true(run.level_up_screen.is_open(), "the second screen follows")
	assert_true(run.is_frozen())
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)
	await _press("pick_card_2")
	await wait_physics_frames(2)
	assert_false(run.level_up_screen.is_open())
	assert_false(run.is_frozen())
	assert_eq(banane.picked_upgrades.size(), 2)
	assert_signal_emit_count(run.level_up_screen, "picked", 2)


func test_level_up_moment_banane_quacks() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.add_xp(5)
	await wait_process_frames(3)
	var puppet: BananePuppet = banane.get_node("Puppet") as BananePuppet
	assert_eq(puppet.state, BananePuppet.State.QUACK, "deadpan quack while the run is paused")
