extends GutTest

const RULES: XpRules = preload("res://data/xp_rules.tres")


func test_ac20_curve_starts_at_five_and_grows_forty_percent_rounded() -> void:
	assert_eq(RULES.xp_to_next(1), 5)
	assert_eq(RULES.xp_to_next(2), 7)
	assert_eq(RULES.xp_to_next(3), 10)
	assert_eq(RULES.xp_to_next(4), 14)
	assert_eq(RULES.xp_to_next(5), 19)


func test_ac20_curve_reads_its_numbers_from_the_data() -> void:
	var custom: XpRules = XpRules.new()
	custom.first_level_xp = 10
	custom.growth_per_level = 1.0
	assert_eq(custom.xp_to_next(1), 10)
	assert_eq(custom.xp_to_next(3), 40)


func test_button_values_by_size() -> void:
	assert_eq(RULES.button_value(EnemyStats.XpSize.SMALL), 1)
	assert_eq(RULES.button_value(EnemyStats.XpSize.MEDIUM), 3)
	assert_eq(RULES.button_value(EnemyStats.XpSize.BIG), 10)


func test_progress_levels_up_and_keeps_the_rest() -> void:
	var progress: LevelProgress = LevelProgress.new(RULES)
	assert_eq(progress.add_xp(4), 0)
	assert_eq(progress.level, 1)
	assert_eq(progress.add_xp(3), 1, "5 needed, 7 collected")
	assert_eq(progress.level, 2)
	assert_eq(progress.xp, 2, "the rest counts towards level 3")


func test_progress_one_big_pickup_gives_several_levels() -> void:
	var progress: LevelProgress = LevelProgress.new(RULES)
	watch_signals(progress)
	assert_eq(progress.add_xp(5 + 7 + 1), 2)
	assert_eq(progress.level, 3)
	assert_signal_emit_count(progress, "leveled_up", 2)


func test_level_up_now_fills_the_bar() -> void:
	var progress: LevelProgress = LevelProgress.new(RULES)
	progress.add_xp(2)
	progress.level_up_now()
	assert_eq(progress.level, 2)
	assert_eq(progress.xp, 0)
