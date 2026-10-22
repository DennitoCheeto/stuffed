extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §13, §15, AC-23, AC-25): the run log has the M2 fields, and with a second
## player cards, rerolls and evolutions belong to whoever earned them.

const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")

var run: Run
var finished_results: Array[RunResult] = []


func _quiet_run() -> Run:
	finished_results.clear()
	run = await start_run()
	run.spawner.active = false
	run.finished.connect(func(result: RunResult) -> void: finished_results.append(result))
	disarm(first_player())
	return run


func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _press(action: String) -> void:
	sender.action_down(action)
	await wait_process_frames(2)
	sender.action_up(action)
	await wait_process_frames(2)


## Levels `player` up once and waits until the cards can be picked.
func _level_up(player: Player) -> void:
	player.add_xp(player.progress.xp_needed() - player.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)


## Makes the Banana Split ready for `player` and opens a gift box at their feet.
func _evolve_at_a_box(player: Player) -> void:
	var pool: UpgradePool = run.upgrade_pool
	var boomerang: Weapon = player.add_weapon(player.stats.starting_weapon)
	boomerang.level = boomerang.stats.max_level()
	player.apply_upgrade(UpgradeOffer.new(pool.find(&"quick_feet"), 1))
	run.drop_gift_box(player.global_position)
	await _wait_until(run.gift_screen.is_open, 1.0)
	run.gift_screen.close()
	await wait_physics_frames(2)


func test_ac23_the_run_log_has_the_new_fields() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	run.elapsed = 30.0
	await _evolve_at_a_box(banane)
	await _level_up(banane)
	await _press("reroll_cards")
	await _press("banish_card")
	await _press("pick_card_1")
	await _press("skip_cards")
	assert_false(run.level_up_screen.is_open(), "the skip closed the cards")
	run.elapsed = 250.0
	var ted: Zombie = run.spawner.spawn_boss(run.spawner.schedule.mini_boss)
	run.enemies.damage(ted, ted.max_health * 10.0)
	await wait_physics_frames(2)
	var goal: float = run.rules.goal_seconds
	beat_the_boss(run)
	await wait_for_goal_screen(run)
	await _press("pick_card_1")
	assert_eq(finished_results.size(), 1, "the run ended")
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1, "one line in the log")
	if entries.is_empty():
		return
	var entry: Dictionary = entries[0]
	assert_eq(entry["evolutions"].size(), 1, "one evolution")
	assert_eq(entry["evolutions"][0]["weapon"], "Banana Split")
	assert_almost_eq(float(entry["evolutions"][0]["time"]), 30.0, 0.2, "and when")
	assert_eq(int(entry["rerolls_used"]), 1)
	assert_eq(int(entry["banishes_used"]), 1)
	assert_eq(int(entry["skips_used"]), 1)
	assert_almost_eq(float(entry["mini_boss_defeated_at"]), 250.0, 0.2, "Big Ted beaten")
	assert_almost_eq(float(entry["boss_defeated_at"]), goal, 0.2, "the King beaten")


func test_ac23_the_log_names_the_enemy_type_that_got_banane() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.health = 1.0
	run.enemies.spawn(SPITTER, banane.global_position + Vector2(260, 0))
	assert_true(await _wait_until(banane.is_dead, 6.0), "the spitter got him")
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1)
	if entries.is_empty():
		return
	assert_eq(entries[0]["killed_by"], "Spitter")
	assert_eq(entries[0]["boss_defeated_at"], null, "no boss beaten")
	assert_eq(entries[0]["mini_boss_defeated_at"], null)
	assert_eq(entries[0]["evolutions"], [])


func test_ac25_each_player_has_their_own_cards_and_rerolls() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(0, 400))
	disarm(second)
	banane.card_controls.use_reroll()
	await _level_up(second)
	var screen: LevelUpScreen = run.level_up_screen
	assert_eq(screen.reroll_button.text, "Reroll [R]  3 left", "player 2's own rerolls")
	await _press("reroll_cards")
	assert_eq(second.card_controls.rerolls_left, 2, "player 2 used one")
	assert_eq(banane.card_controls.rerolls_left, 2, "player 1's count is untouched")
	await _press("pick_card_1")
	assert_eq(second.picked_upgrades.size(), 1, "player 2 got the card")
	assert_eq(banane.picked_upgrades.size(), 0, "player 1 got nothing")


func test_ac25_an_evolution_goes_to_the_player_who_opened_the_box() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(0, 400))
	disarm(second)
	await _evolve_at_a_box(second)
	assert_not_null(second.weapon(&"banana_split"), "player 2 evolved")
	assert_null(banane.weapon(&"banana_split"), "player 1 did not")
	assert_eq(run.evolution_log.size(), 1)
	assert_eq(run.evolution_log[0]["player"], 1, "the log says who")
