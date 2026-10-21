class_name RunLog
extends RefCounted
## Appends one JSON line per finished run to a local file, for tuning (spec 01 §9).
## On Windows: %APPDATA%\Godot\app_userdata\Stuffed\run_log.jsonl. Not shown in the game.

const DEFAULT_PATH: String = "user://run_log.jsonl"

## Tests point this at a scratch file.
static var path: String = DEFAULT_PATH


## The fields of one log line.
static func to_entry(result: RunResult) -> Dictionary:
	return {
		"date": Time.get_datetime_string_from_system(true),
		"seed": result.seed_value,
		"ending": result.ending,
		"time_survived": snappedf(result.survived_seconds, 0.1),
		"goal_reached": result.won,
		"endless_time": snappedf(result.endless_seconds, 0.1),
		"level": result.level,
		"kills": result.kills,
		"killed_by": result.killed_by,
		"upgrades": Array(result.upgrades),
	}


## Adds one line for `result`. Returns false if the file couldn't be written.
static func append(result: RunResult) -> bool:
	var file: FileAccess
	if FileAccess.file_exists(path):
		file = FileAccess.open(path, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	else:
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Run log not written: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_line(JSON.stringify(to_entry(result)))
	file.close()
	return true


## Every logged run, oldest first.
static func read_all() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		return entries
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return entries
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			entries.append(parsed as Dictionary)
	return entries
