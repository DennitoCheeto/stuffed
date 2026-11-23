extends "res://tests/scenarios/run_scenario.gd"
## Scenario (#340, playtest 2026-11-21): a floor toy dropping and an elite arriving each show a
## short line on the HUD (not the big banner), and a new elite off screen gets an edge arrow for
## a few seconds. Texts and times come from data/run_rules.tres.

const RULES: RunRules = preload("res://data/run_rules.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.enemies.calm = true
	disarm(first_player())
	return run


func _threat_arrows() -> int:
	return Array(run.pickup_arrows.colors).count(PickupArrows.THREAT_COLOR)


func _wait_seconds(seconds: float) -> void:
	var until: float = run.elapsed + seconds
	while run.elapsed < until:
		await wait_process_frames(1)


func test_a_floor_toy_dropping_shows_a_short_line() -> void:
	await _quiet_run()
	assert_eq(run.hud.callout.shown_text(), "", "nothing at the start")
	run.drop_floor_pickup(&"magnet", first_player().global_position + Vector2(300.0, 0.0))
	await wait_process_frames(2)
	assert_eq(run.hud.callout.shown_text(), RULES.toy_callout)
	assert_false(run.hud.banner.visible, "not the big banner")
	assert_false(UiColors.is_danger(ArrivalCallout.TOY_COLOR), "never an enemy colour")
	await _wait_seconds(RULES.callout_seconds + 0.3)
	assert_eq(run.hud.callout.shown_text(), "", "it goes away by itself")


func test_an_elite_arriving_shows_a_line_and_a_short_arrow() -> void:
	await _quiet_run()
	var elite: Zombie = run.spawner.spawn_elite(SHAMBLER)
	assert_not_null(elite)
	await wait_process_frames(3)
	assert_eq(run.hud.callout.shown_text(), RULES.elite_callout)
	assert_false(run.hud.banner.visible, "not the big banner")
	assert_false(UiColors.is_danger(ArrivalCallout.ELITE_COLOR), "never an enemy colour")
	assert_eq(_threat_arrows(), 1, "an arrow points to the new elite off screen")
	await _wait_seconds(RULES.elite_arrow_seconds + 0.3)
	assert_eq(_threat_arrows(), 0, "the arrow only shows for a few seconds")
	assert_false(elite.dead, "the elite is still there")


func test_a_new_elite_on_screen_gets_no_arrow() -> void:
	await _quiet_run()
	var at: Vector2 = first_player().global_position + Vector2(250.0, 0.0)
	var elite: Zombie = run.enemies.spawn(SHAMBLER, at, run.spawner.schedule.elite_rules)
	run.spawner.elite_spawned.emit(elite)
	await wait_process_frames(3)
	assert_eq(run.hud.callout.shown_text(), RULES.elite_callout)
	assert_eq(_threat_arrows(), 0, "on screen: no arrow needed")
