extends GutTest

const SCHEDULE: SpawnSchedule = preload("res://data/spawn_schedule.tres")
const GOAL: float = 300.0


## Runs the schedule like the spawner does, for `seconds`, and counts spawns per type name.
func _simulate(seconds: float, seed_value: int) -> Dictionary[String, int]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var counts: Dictionary[String, int] = {"Shambler": 0, "Runner": 0, "first_runner_at": -1}
	var owed: float = 0.0
	var step: float = 1.0 / 60.0
	var time: float = 0.0
	while time < seconds:
		time += step
		owed += SCHEDULE.rate_at(time, GOAL) * step
		while owed >= 1.0:
			owed -= 1.0
			var stats: EnemyStats = SCHEDULE.enemy_at(time, rng)
			counts[stats.display_name] += 1
			if stats.display_name == "Runner" and counts["first_runner_at"] < 0:
				counts["first_runner_at"] = floori(time)
	return counts


func test_phases_follow_the_minute_rhythm() -> void:
	assert_eq(SCHEDULE.phase_at(10.0, GOAL), SpawnSchedule.Phase.NORMAL)
	assert_eq(SCHEDULE.phase_at(35.0, GOAL), SpawnSchedule.Phase.SURGE, "surge ~20 s")
	assert_eq(SCHEDULE.phase_at(55.0, GOAL), SpawnSchedule.Phase.BREATHER, "then a breather")
	assert_eq(SCHEDULE.phase_at(70.0, GOAL), SpawnSchedule.Phase.NORMAL, "next minute")
	assert_eq(SCHEDULE.phase_at(95.0, GOAL), SpawnSchedule.Phase.SURGE)
	assert_eq(SCHEDULE.phase_at(285.0, GOAL), SpawnSchedule.Phase.FINAL_SURGE, "last 30 s")


func test_ac12_surges_spawn_clearly_more_than_breathers() -> void:
	for minute: int in 4:
		var start: float = minute * 60.0
		var surge: float = SCHEDULE.rate_at(start + 40.0, GOAL)
		var breather: float = SCHEDULE.rate_at(start + 55.0, GOAL)
		assert_gt(surge, breather * 5.0, "minute %d" % (minute + 1))


func test_ac12_the_last_30_seconds_are_the_biggest_surge() -> void:
	var final: float = SCHEDULE.rate_at(271.0, GOAL)
	var time: float = 0.0
	while time < 270.0:
		assert_lt(SCHEDULE.rate_at(time, GOAL), final, "at %.0f s" % time)
		time += 5.0


func test_ac12_spawning_ramps_up() -> void:
	assert_gt(SCHEDULE.rate_at(250.0, GOAL), SCHEDULE.rate_at(10.0, GOAL))


func test_ac11_no_runners_before_a_minute() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1
	for i: int in 500:
		var time: float = rng.randf_range(0.0, 59.9)
		assert_eq(SCHEDULE.enemy_at(time, rng).display_name, "Shambler")
	assert_eq(SCHEDULE.runner_chance(59.0), 0.0)
	assert_gt(SCHEDULE.runner_chance(61.0), 0.0)


func test_ac11_both_types_appear_in_a_full_run() -> void:
	var counts: Dictionary[String, int] = _simulate(GOAL, 7)
	assert_gt(counts["Shambler"], 100, "plenty of shamblers")
	assert_gt(counts["Runner"], 20, "runners join")
	assert_true(counts["first_runner_at"] >= 60, "first runner after 1:00")
	assert_lt(counts["first_runner_at"], 75, "... and soon after")


func test_same_seed_same_spawn_sequence() -> void:
	assert_eq(_simulate(120.0, 99), _simulate(120.0, 99))


func test_runner_stats_match_the_spec() -> void:
	var runner: EnemyStats = SCHEDULE.runner
	assert_eq(runner.max_health, 5.0)
	assert_eq(runner.move_speed, 125.0)
	assert_eq(runner.contact_damage, 4.0)
	assert_eq(runner.xp_button, EnemyStats.XpSize.MEDIUM)
	assert_lt(runner.move_speed, 150.0, "slightly slower than Banane")
