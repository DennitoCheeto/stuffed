extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §7, AC-24, AC-25, AC-26): after the goal: End run, or endless until Banane
## falls.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
## Pop chain + celebration + input delay of the goal screen, plus a little slack.
const GOAL_SCREEN_WAIT: float = (
	Run.POP_CHAIN_TIME + Run.CELEBRATION_TIME + GoalScreen.INPUT_DELAY + 0.3
)

var run: Run


## Plays to the goal screen with Banane unarmed and very tough.
func _to_goal_screen() -> void:
	run = await start_run()
	var banane: Player = first_player()
	disarm(banane)
	banane.max_health = 1_000_000.0
	banane.health = banane.max_health
	run.elapsed = run.rules.goal_seconds - 0.1
	await wait_for_signal(run.goal_reached, 2.0)
	await wait_seconds(GOAL_SCREEN_WAIT)


func _press(action: String) -> void:
	sender.action_down(action)
	await wait_process_frames(2)
	sender.action_up(action)
	await wait_process_frames(2)


func _end_screen() -> EndScreen:
	return main.current_screen as EndScreen


func test_ac24_end_run_shows_you_survived_with_stats() -> void:
	await _to_goal_screen()
	var seed_value: int = run.seed_value
	await _press("pick_card_1")
	await wait_process_frames(2)
	var end: EndScreen = _end_screen()
	assert_not_null(end, "the end screen is shown")
	if end == null:
		return
	assert_eq(end.title_label.text, "You survived!")
	assert_string_contains(end.stats_label.text, "Time survived: 8:00")
	assert_string_contains(end.stats_label.text, "Level: 1")
	assert_string_contains(end.stats_label.text, "Zombies stuffed:")
	assert_eq(end.seed_label.text, "Seed %d" % seed_value)
	assert_true(end.try_again_button.has_focus(), "Try again is ready on the keyboard")


func test_ac25_keep_going_shows_endless_time() -> void:
	await _to_goal_screen()
	await _press("pick_card_2")
	assert_true(run.endless)
	await wait_physics_frames(roundi(1.5 * FPS))
	assert_string_starts_with(run.hud.timer_label.text, "Endless +0:01")


func test_ac25_every_endless_minute_makes_zombies_tougher() -> void:
	await _to_goal_screen()
	await _press("pick_card_2")
	run.elapsed = run.rules.goal_seconds + 61.0
	await wait_physics_frames(2)
	assert_eq(run.endless_minute, 1)
	assert_almost_eq(run.enemies.health_scale, run.rules.endless_health_scale(1), 0.0001)
	assert_almost_eq(run.enemies.damage_scale, run.rules.endless_damage_scale(1), 0.0001)
	assert_almost_eq(run.spawner.rate_scale, run.rules.endless_spawn_scale(1), 0.0001)
	var spot: Vector2 = first_player().global_position + Vector2(500, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	assert_almost_eq(zombie.max_health, SHAMBLER.max_health * 1.15, 0.001, "+15% health")
	assert_almost_eq(zombie.contact_damage, SHAMBLER.contact_damage * 1.15, 0.001, "+15% damage")
	run.elapsed = run.rules.goal_seconds + 125.0
	await wait_physics_frames(2)
	assert_eq(run.endless_minute, 2)
	assert_gt(run.enemies.health_scale, 1.15, "and tougher again the next minute")


func test_ac26_dying_in_endless_still_says_you_survived() -> void:
	await _to_goal_screen()
	await _press("pick_card_2")
	run.elapsed = run.rules.goal_seconds + 70.0
	var banane: Player = first_player()
	banane.health = 1.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	var end: EndScreen = _end_screen()
	assert_not_null(end, "the end screen is shown after Banane falls")
	if end == null:
		return
	assert_eq(end.title_label.text, "You survived!")
	assert_string_contains(end.stats_label.text, "Endless: +1:1")
	assert_string_contains(end.stats_label.text, "Got stuffed by: Shambler")


func test_dying_before_the_goal_says_banane_got_stuffed() -> void:
	run = await start_run()
	run.spawner.active = false
	var banane: Player = first_player()
	banane.health = 1.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_physics_frames(3)
	var puppet: BananePuppet = banane.get_node("Puppet") as BananePuppet
	assert_eq(puppet.state, BananePuppet.State.DOWN, "Banane deflates")
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	var end: EndScreen = _end_screen()
	assert_not_null(end)
	if end == null:
		return
	assert_eq(end.title_label.text, "Banane got stuffed")
	assert_false(end.stats_label.text.contains("Endless"))
