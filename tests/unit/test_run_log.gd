extends GutTest
## The run log saves, so it gets a save → reload → compare test (hard rule 10).

const LOG: String = "user://test_unit_run_log.jsonl"


func before_each() -> void:
	RunLog.path = LOG
	DirAccess.remove_absolute(LOG)


func after_all() -> void:
	DirAccess.remove_absolute(LOG)
	RunLog.path = RunLog.DEFAULT_PATH


func _result() -> RunResult:
	var result: RunResult = RunResult.new()
	result.won = true
	result.ending = "died"
	result.survived_seconds = 341.26
	result.endless_seconds = 41.26
	result.level = 9
	result.kills = 512
	result.killed_by = "Runner"
	result.upgrades = PackedStringArray(["Quick Feet 1", "Sewing-Pin Sniper 1"])
	result.seed_value = 777
	return result


func test_ac28_a_finished_run_is_saved_and_reads_back_the_same() -> void:
	assert_true(RunLog.append(_result()))
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1)
	var entry: Dictionary = entries[0]
	assert_eq(int(entry["seed"]), 777)
	assert_eq(entry["ending"], "died")
	assert_eq(entry["time_survived"], 341.3)
	assert_eq(entry["goal_reached"], true)
	assert_eq(entry["endless_time"], 41.3)
	assert_eq(int(entry["level"]), 9)
	assert_eq(int(entry["kills"]), 512)
	assert_eq(entry["killed_by"], "Runner")
	assert_eq(entry["upgrades"], ["Quick Feet 1", "Sewing-Pin Sniper 1"])
	assert_true(String(entry["date"]).length() >= 10, "has a date")


func test_ac28_each_run_adds_one_line_and_keeps_the_old_ones() -> void:
	RunLog.append(_result())
	var second: RunResult = _result()
	second.seed_value = 778
	RunLog.append(second)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 2)
	assert_eq(int(entries[0]["seed"]), 777, "oldest first")
	assert_eq(int(entries[1]["seed"]), 778)
	var file: FileAccess = FileAccess.open(LOG, FileAccess.READ)
	var lines: PackedStringArray = file.get_as_text().strip_edges().split("\n")
	assert_eq(lines.size(), 2, "one JSON line per run")


func test_ac23_m2_fields_are_saved_and_read_back_the_same() -> void:
	var result: RunResult = _result()
	result.evolutions = [{"weapon": "Banana Split", "time": 201.04, "player": 0}]
	result.rerolls_used = 2
	result.skips_used = 1
	result.banishes_used = 3
	result.mini_boss_defeated_at = 262.27
	result.boss_defeated_at = 515.56
	assert_true(RunLog.append(result))
	var entry: Dictionary = RunLog.read_all()[0]
	assert_eq(entry["evolutions"].size(), 1)
	assert_eq(entry["evolutions"][0]["weapon"], "Banana Split")
	assert_eq(entry["evolutions"][0]["time"], 201.0)
	assert_eq(int(entry["evolutions"][0]["player"]), 0)
	assert_eq(int(entry["rerolls_used"]), 2)
	assert_eq(int(entry["skips_used"]), 1)
	assert_eq(int(entry["banishes_used"]), 3)
	assert_eq(entry["mini_boss_defeated_at"], 262.3)
	assert_eq(entry["boss_defeated_at"], 515.6)


func test_ac23_bosses_not_beaten_are_null() -> void:
	RunLog.append(_result())
	var entry: Dictionary = RunLog.read_all()[0]
	assert_true(entry.has("mini_boss_defeated_at"))
	assert_eq(entry["mini_boss_defeated_at"], null)
	assert_eq(entry["boss_defeated_at"], null)
	assert_eq(entry["evolutions"], [])


func test_ac32_floor_pickups_are_saved_and_read_back_the_same() -> void:
	var result: RunResult = _result()
	result.floor_pickups = [{"name": "Big Magnet", "time": 61.27, "player": 1}]
	assert_true(RunLog.append(result))
	var entry: Dictionary = RunLog.read_all()[0]
	assert_eq(entry["floor_pickups"].size(), 1)
	assert_eq(entry["floor_pickups"][0]["name"], "Big Magnet")
	assert_eq(entry["floor_pickups"][0]["time"], 61.3)
	assert_eq(int(entry["floor_pickups"][0]["player"]), 1)


func test_default_path_is_the_user_folder() -> void:
	assert_eq(RunLog.DEFAULT_PATH, "user://run_log.jsonl")
