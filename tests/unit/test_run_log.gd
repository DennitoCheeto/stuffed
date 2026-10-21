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


func test_default_path_is_the_user_folder() -> void:
	assert_eq(RunLog.DEFAULT_PATH, "user://run_log.jsonl")
