extends GutTest

const SCHEDULE: SpawnSchedule = preload("res://data/spawn_schedule.tres")
const RULES: RunRules = preload("res://data/run_rules.tres")
## When each type first shows up (spec 02 §10), in seconds.
const FIRST_APPEARANCE: Dictionary[String, float] = {
	"Runner": 60.0, "Spitter": 90.0, "Bloater": 150.0, "Tank": 180.0
}


func _goal() -> float:
	return RULES.goal_seconds


## Runs the schedule like the spawner does, for `seconds`, and counts spawns per type name.
## "first <name>" holds the second each type first appeared.
func _simulate(seconds: float, seed_value: int) -> Dictionary[String, int]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var counts: Dictionary[String, int] = {}
	var owed: float = 0.0
	var step: float = 1.0 / 60.0
	var time: float = 0.0
	while time < seconds:
		time += step
		owed += SCHEDULE.rate_at(time, _goal()) * step
		while owed >= 1.0:
			owed -= 1.0
			var kind: String = SCHEDULE.enemy_at(time, rng).display_name
			counts[kind] = counts.get(kind, 0) + 1
			if not counts.has("first " + kind):
				counts["first " + kind] = floori(time)
	return counts


func test_the_run_is_8_minutes_to_the_boss() -> void:
	assert_eq(RULES.goal_seconds, 480.0)


func test_phases_follow_the_minute_rhythm() -> void:
	assert_eq(SCHEDULE.phase_at(10.0, _goal()), SpawnSchedule.Phase.NORMAL)
	assert_eq(SCHEDULE.phase_at(35.0, _goal()), SpawnSchedule.Phase.SURGE, "surge ~20 s")
	assert_eq(SCHEDULE.phase_at(55.0, _goal()), SpawnSchedule.Phase.BREATHER, "then a breather")
	assert_eq(SCHEDULE.phase_at(70.0, _goal()), SpawnSchedule.Phase.NORMAL, "next minute")
	assert_eq(SCHEDULE.phase_at(95.0, _goal()), SpawnSchedule.Phase.SURGE)
	assert_eq(SCHEDULE.phase_at(_goal() - 15.0, _goal()), SpawnSchedule.Phase.FINAL_SURGE)


func test_ac12_surges_spawn_clearly_more_than_breathers() -> void:
	for minute: int in 7:
		var start: float = minute * 60.0
		var surge: float = SCHEDULE.rate_at(start + 40.0, _goal())
		var breather: float = SCHEDULE.rate_at(start + 55.0, _goal())
		assert_gt(surge, breather * 5.0, "minute %d" % (minute + 1))


func test_ac12_the_last_30_seconds_are_the_biggest_surge() -> void:
	var final_start: float = _goal() - SCHEDULE.final_surge_seconds
	var final: float = SCHEDULE.rate_at(final_start + 1.0, _goal())
	var time: float = 0.0
	while time < final_start:
		assert_lt(SCHEDULE.rate_at(time, _goal()), final, "at %.0f s" % time)
		time += 5.0


func test_ac12_spawning_ramps_up() -> void:
	assert_gt(SCHEDULE.rate_at(_goal() - 60.0, _goal()), SCHEDULE.rate_at(10.0, _goal()))


func test_ac16_no_type_appears_before_its_time() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 1
	for kind: String in FIRST_APPEARANCE:
		var start: float = FIRST_APPEARANCE[kind]
		assert_eq(SCHEDULE.entry_named(kind).chance_at(start - 1.0), 0.0, kind)
		assert_gt(SCHEDULE.entry_named(kind).chance_at(start + 1.0), 0.0, kind)
	for i: int in 500:
		var time: float = rng.randf_range(0.0, 59.9)
		assert_eq(SCHEDULE.enemy_at(time, rng).display_name, "Shambler", "only shamblers at first")


func test_ac16_each_type_first_appears_around_its_time() -> void:
	for seed_value: int in [7, 8, 9]:
		var counts: Dictionary[String, int] = _simulate(_goal(), seed_value)
		assert_lt(counts["first Shambler"], 5, "shamblers from the start")
		for kind: String in FIRST_APPEARANCE:
			var first: int = counts.get("first " + kind, -1)
			var start: float = FIRST_APPEARANCE[kind]
			assert_gte(first, int(start), "%s not before %d s" % [kind, start])
			var message: String = "%s soon after %d s (seed %d)" % [kind, start, seed_value]
			assert_lt(first, int(start) + 45, message)


func test_all_types_appear_in_a_full_run_shamblers_most() -> void:
	var counts: Dictionary[String, int] = _simulate(_goal(), 7)
	assert_gt(counts["Shambler"], 300, "plenty of shamblers")
	assert_gt(counts["Runner"], 60, "runners join")
	assert_gt(counts["Spitter"], 20)
	assert_gt(counts["Bloater"], 15)
	assert_gt(counts["Tank"], 5, "a few tanks")
	for kind: String in FIRST_APPEARANCE:
		assert_gt(counts["Shambler"], counts[kind], "more shamblers than %ss" % kind)


func test_shares_never_crowd_out_the_shamblers() -> void:
	var total: float = 0.0
	for entry: SpawnEntry in SCHEDULE.entries:
		total += entry.chance_at(_goal() + 600.0)
	assert_lt(total, 0.8)


func test_same_seed_same_spawn_sequence() -> void:
	assert_eq(_simulate(200.0, 99), _simulate(200.0, 99))


func test_runner_stats_match_the_spec() -> void:
	var runner: EnemyStats = SCHEDULE.entry_named("Runner").enemy
	assert_eq(runner.max_health, 5.0)
	assert_eq(runner.move_speed, 125.0)
	assert_eq(runner.contact_damage, 4.0)
	assert_eq(runner.xp_button, EnemyStats.XpSize.MEDIUM)
	assert_lt(runner.move_speed, 150.0, "slightly slower than Banane")
