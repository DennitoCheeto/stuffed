extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §6, AC-43): the Lucky Jar, Watchtower and Snack Bar reach the next run with
## the numbers from data. Lucky Jar: more dots on Reroll / Skip / Banish. Watchtower: XP buttons
## fly in from further away. Snack Bar: more max health, and the run starts at full health.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const WATCHTOWER: BuildingDef = preload("res://data/town/buildings/watchtower.tres")
const SNACK_BAR: BuildingDef = preload("res://data/town/buildings/snack_bar.tres")
## Banane's own numbers.
const BANANE: HeroStats = preload("res://data/heroes/banane.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


func _open_level_up() -> LevelUpScreen:
	var banane: Player = first_player()
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	return run.level_up_screen


func test_ac43_without_buildings_a_run_has_the_plain_numbers() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	assert_eq(banane.max_health, BANANE.max_health)
	assert_eq(banane.pickup_range, BANANE.pickup_range)
	assert_eq(banane.card_controls.rerolls_left, POOL.rerolls_per_run)


func test_ac43_lucky_jar_adds_dots_to_reroll_skip_and_banish() -> void:
	main.town.building_levels["lucky_jar"] = 2
	await _quiet_run()
	var screen: LevelUpScreen = await _open_level_up()
	assert_eq(screen.reroll_button.uses_text(), "●".repeat(POOL.rerolls_per_run + 2))
	assert_eq(screen.skip_button.uses_text(), "●".repeat(POOL.skips_per_run + 2))
	assert_eq(screen.banish_button.uses_text(), "●".repeat(POOL.banishes_per_run + 2))
	assert_eq(run.make_result("died").rerolls_used, 0)


func test_ac43_watchtower_pulls_buttons_from_further_away() -> void:
	main.town.building_levels["watchtower"] = 3
	await _quiet_run()
	var banane: Player = first_player()
	var bonus: float = WATCHTOWER.reached(3).pickup_range_bonus
	assert_almost_eq(banane.pickup_range, BANANE.pickup_range * (1.0 + bonus), 0.01)
	# Just outside Banane's own range, inside the Watchtower's.
	var spot: Vector2 = banane.global_position + Vector2(BANANE.pickup_range + 8.0, 0)
	run.pickups.drop(EnemyStats.XpSize.MEDIUM, spot)
	await wait_physics_frames(40)
	assert_eq(run.pickups.buttons.size(), 0, "the button flew to Banane")
	assert_eq(banane.progress.xp, 3)


func test_ac43_snack_bar_adds_max_health_and_starts_full() -> void:
	main.town.building_levels["snack_bar"] = 1
	await _quiet_run()
	var banane: Player = first_player()
	var expected: float = BANANE.max_health + SNACK_BAR.reached(1).max_health_bonus
	assert_eq(banane.max_health, expected)
	assert_eq(banane.health, expected, "starts at full health")
	assert_eq(run.hud.health_bar.max_value, expected, "the health bar shows it")
