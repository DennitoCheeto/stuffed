extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §6, §7, AC-11, AC-12, AC-23): runners, surges and breathers, the goal
## (since spec 02: beating the Sock Puppet King, who comes at 8:00).

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")

var run: Run
## Filled by the run's signals (no signal watchers: the run is freed when it ends).
var finished_results: Array[RunResult] = []
var endless_starts: int = 0


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
			var kind: String = zombie.stats.display_name
			counts[kind] = counts.get(kind, 0) + 1
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
	var runner_stats: EnemyStats = RUNNER
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
	finished_results.clear()
	endless_starts = 0
	run.finished.connect(func(result: RunResult) -> void: finished_results.append(result))
	run.endless_started.connect(func() -> void: endless_starts += 1)
	beat_the_boss(run)


func test_ac23_goal_stops_spawning_and_pops_every_zombie() -> void:
	await _reach_goal_with_zombies()
	assert_false(run.spawner.active, "spawning stopped")
	assert_true(run.goal_done, "beating the boss is the goal")
	await wait_seconds(Run.POP_CHAIN_TIME + 0.2)
	assert_eq(run.enemies.alive_count(), 0, "every zombie popped")
	assert_eq(run.pickups.buttons.size(), 1, "only the King drops XP, the goal pops drop none")


func test_ac23_then_pauses_and_offers_end_run_or_keep_going() -> void:
	await _reach_goal_with_zombies()
	await wait_for_goal_screen(run)
	assert_true(run.goal_screen.is_open(), "the choice is shown")
	assert_true(run.is_frozen(), "the run is paused")
	assert_eq(run.goal_screen.end_button.text, "[1]  End run")
	assert_eq(run.goal_screen.endless_button.text, "[2]  Keep going (endless)")


func test_ac23_key_1_ends_the_run_with_a_win() -> void:
	await _reach_goal_with_zombies()
	await wait_for_goal_screen(run)
	sender.action_down("pick_card_1")
	await wait_process_frames(2)
	sender.action_up("pick_card_1")
	assert_eq(finished_results.size(), 1, "the run finished")
	var result: RunResult = finished_results[0]
	assert_true(result.won, "a win")
	assert_eq(result.ending, "ended")


func test_ac23_click_keep_going_continues_the_run() -> void:
	await _reach_goal_with_zombies()
	await wait_for_goal_screen(run)
	run.goal_screen.endless_button.pressed.emit()
	assert_eq(endless_starts, 1, "endless started")
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
	beat_the_boss(run)
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_physics_frames(3)
	assert_eq(banane.health, 100.0)
