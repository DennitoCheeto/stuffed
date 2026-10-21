extends GutTest

const RULES: RunRules = preload("res://data/run_rules.tres")


func test_ac25_endless_scaling_per_minute_from_data() -> void:
	assert_eq(RULES.endless_health_scale(0), 1.0)
	assert_almost_eq(RULES.endless_health_scale(1), 1.15, 0.0001, "+15% health per minute")
	assert_almost_eq(RULES.endless_damage_scale(2), 1.3, 0.0001, "+15% damage per minute")
	assert_almost_eq(RULES.endless_spawn_scale(3), 1.3, 0.0001, "+10% spawns per minute")


func test_ac25_scaling_reads_the_data() -> void:
	var custom: RunRules = RunRules.new()
	custom.endless_health_growth_per_minute = 1.0
	assert_eq(custom.endless_health_scale(2), 3.0)


func test_endless_timer_text() -> void:
	assert_eq(TimeFormat.endless(161.0), "Endless +2:41")


func _result(won: bool) -> RunResult:
	var result: RunResult = RunResult.new()
	result.won = won
	result.survived_seconds = 361.0
	result.endless_seconds = 61.0 if won else 0.0
	result.level = 12
	result.kills = 834
	result.killed_by = "Runner"
	result.upgrades = PackedStringArray(["Quick Feet 1", "Peel Boomerang 2"])
	result.seed_value = 4242
	return result


func test_end_screen_lines_for_a_win_in_endless() -> void:
	var lines: PackedStringArray = EndScreen.stat_lines(_result(true))
	assert_eq(_result(true).title(), "You survived!")
	assert_has(lines, "Time survived: 6:01")
	assert_has(lines, "Endless: +1:01")
	assert_has(lines, "Level: 12")
	assert_has(lines, "Zombies stuffed: 834")
	assert_has(lines, "Got stuffed by: Runner")


func test_end_screen_lines_for_a_loss() -> void:
	var loss: RunResult = _result(false)
	assert_eq(loss.title(), "Banane got stuffed")
	for line: String in EndScreen.stat_lines(loss):
		assert_false(line.begins_with("Endless"), "no endless line without endless")
	assert_eq(EndScreen.upgrades_text(loss), "Upgrades: Quick Feet 1, Peel Boomerang 2")
	assert_eq(EndScreen.upgrades_text(RunResult.new()), "Upgrades: none")
