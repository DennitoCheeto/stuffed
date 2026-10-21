extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §6, §7, AC-11, AC-12, AC-23): runners, surges and breathers, the 5:00 goal.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


## A run where Banane can't die and the spawner uses a fixed seed.
func _tough_run() -> Run:
	run = await start_run()
	run.rng.seed = 42
	var banane: Player = first_player()
	banane.max_health = 1_000_000.0
	banane.health = banane.max_health
	disarm(banane)
	return run


func _count_spawns_from(time: float, seconds: float) -> Dictionary[String, int]:
	run.enemies.kill_all()
	var counts: Dictionary[String, int] = {"Shambler": 0, "Runner": 0}
	run.elapsed = time
	var before: Array[Zombie] = run.enemies.zombies.duplicate()
	await wait_physics_frames(roundi(seconds * FPS))
	for zombie: Zombie in run.enemies.zombies:
		if not before.has(zombie):
			counts[zombie.stats.display_name] += 1
	return counts


func test_ac11_runners_only_after_the_first_minute() -> void:
	await _tough_run()
	var early: Dictionary[String, int] = await _count_spawns_from(25.0, 3.0)
	assert_gt(early["Shambler"], 0, "shamblers from the start")
	assert_eq(early["Runner"], 0, "no runners before 1:00")
	var later: Dictionary[String, int] = await _count_spawns_from(150.0, 3.0)
	assert_gt(later["Runner"], 0, "runners join after 1:00")
	assert_gt(later["Shambler"], 0, "together with shamblers")


func test_ac11_runner_is_a_sock_bunny_and_fast() -> void:
	await _tough_run()
	var runner_stats: EnemyStats = run.spawner.schedule.runner
	var banane: Player = first_player()
	var runner: Zombie = run.enemies.spawn(runner_stats, banane.global_position + Vector2(400, 0))
	assert_eq(runner.puppet.look.prefix, "runner")
	var before: float = runner.position.distance_to(banane.global_position)
	await wait_physics_frames(60)
	var walked: float = before - runner.position.distance_to(banane.global_position)
	assert_almost_eq(walked, runner_stats.move_speed, 8.0, "about 125 px in a second")


func test_ac12_a_surge_spawns_clearly_more_than_a_breather() -> void:
	await _tough_run()
	var surge: Dictionary[String, int] = await _count_spawns_from(32.0, 2.0)
	var breather: Dictionary[String, int] = await _count_spawns_from(52.0, 2.0)
	var surge_total: int = surge["Shambler"] + surge["Runner"]
	var breather_total: int = breather["Shambler"] + breather["Runner"]
	var message: String = "surge %d vs breather %d" % [surge_total, breather_total]
	assert_gt(surge_total, breather_total * 3, message)


func _reach_goal_with_zombies() -> void:
	await _tough_run()
	var banane: Player = first_player()
	for i: int in 12:
		run.enemies.spawn(SHAMBLER, banane.global_position + Vector2.from_angle(i * 0.5) * 300.0)
	run.elapsed = run.rules.goal_seconds - 0.2
	watch_signals(run)
	await wait_for_signal(run.goal_reached, 2.0)


func test_ac23_goal_stops_spawning_and_pops_every_zombie() -> void:
	await _reach_goal_with_zombies()
	assert_false(run.spawner.active, "spawning stopped")
	assert_eq(run.hud.timer_label.text, "5:00 / 5:00")
	await wait_seconds(Run.POP_CHAIN_TIME + 0.2)
	assert_eq(run.enemies.alive_count(), 0, "every zombie popped")
	assert_eq(run.pickups.buttons.size(), 0, "the goal pops drop no XP")


func test_ac23_then_pauses_and_offers_end_run_or_keep_going() -> void:
	await _reach_goal_with_zombies()
	await wait_seconds(Run.POP_CHAIN_TIME + Run.CELEBRATION_TIME + GoalScreen.INPUT_DELAY + 0.3)
	assert_true(run.goal_screen.is_open(), "the choice is shown")
	assert_true(run.is_frozen(), "the run is paused")
	assert_eq(run.goal_screen.end_button.text, "[1]  End run")
	assert_eq(run.goal_screen.endless_button.text, "[2]  Keep going (endless)")


func test_ac23_key_1_ends_the_run_with_a_win() -> void:
	await _reach_goal_with_zombies()
	await wait_seconds(Run.POP_CHAIN_TIME + Run.CELEBRATION_TIME + GoalScreen.INPUT_DELAY + 0.3)
	sender.action_down("pick_card_1")
	await wait_process_frames(2)
	sender.action_up("pick_card_1")
	assert_signal_emitted(run, "ended_with_win")


func test_ac23_click_keep_going_continues_the_run() -> void:
	await _reach_goal_with_zombies()
	await wait_seconds(Run.POP_CHAIN_TIME + Run.CELEBRATION_TIME + GoalScreen.INPUT_DELAY + 0.3)
	run.goal_screen.endless_button.pressed.emit()
	assert_signal_emitted(run, "endless_started")
	assert_false(run.is_frozen(), "running again")
	assert_true(run.spawner.active, "zombies come again")
	var time_before: float = run.elapsed
	await wait_physics_frames(roundi(2.0 * FPS))
	assert_gt(run.elapsed, time_before, "the timer goes on")
	assert_gt(run.enemies.alive_count(), 0, "new zombies spawned")


func test_ac23_zombies_cannot_hurt_banane_while_the_goal_pops_them() -> void:
	await _tough_run()
	var banane: Player = first_player()
	banane.max_health = 100.0
	banane.health = 100.0
	run.elapsed = run.rules.goal_seconds - 0.05
	await wait_for_signal(run.goal_reached, 2.0)
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_physics_frames(3)
	assert_eq(banane.health, 100.0)
