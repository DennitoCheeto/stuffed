class_name RunLog
extends RefCounted
## Appends one JSON line per finished run to a local file, for tuning (spec 01 §9).
## On Windows: %APPDATA%\Godot\app_userdata\Stuffed\run_log.jsonl. Not shown in the game.

const DEFAULT_PATH: String = "user://run_log.jsonl"

## Tests point this at a scratch file.
static var path: String = DEFAULT_PATH


## The fields of one log line (a night siege gets its own, see `siege_entry`).
static func to_entry(result: RunResult) -> Dictionary:
	if result.is_siege():
		return siege_entry(result)
	return {
		"date": Time.get_datetime_string_from_system(true),
		"kind": "run",
		"hero": Array(result.heroes),
		"gear": result.gear_log(),
		"seed": result.seed_value,
		"ending": result.ending,
		"time_survived": snappedf(result.survived_seconds, 0.1),
		"goal_reached": result.won,
		"endless_time": snappedf(result.endless_seconds, 0.1),
		"level": result.level,
		"kills": result.kills,
		"killed_by": result.killed_by,
		"upgrades": Array(result.upgrades),
		"evolutions": _timed(result.evolutions),
		"rerolls_used": result.rerolls_used,
		"skips_used": result.skips_used,
		"banishes_used": result.banishes_used,
		"mini_boss_defeated_at": _time_or_null(result.mini_boss_defeated_at),
		"boss_defeated_at": _time_or_null(result.boss_defeated_at),
		"floor_pickups": _timed(result.floor_pickups),
		"materials_collected": result.materials_collected.duplicate(),
		"materials_kept": result.materials_kept.duplicate(),
		"run_end": result.run_end(),
		"unlocked_weapons": Array(result.unlocked_weapons),
		"rescue": _rescue_or_null(result.rescue),
		"weapons": result.weapons.duplicate(true),
		"titles": Array(result.titles),
		"tricks": Array(result.tricks),
		"trick_moments": _timed(result.trick_moments),
		"patterns_found": _timed(result.patterns_found),
	}


## One night siege (spec 07 §10): which one, won, waves held, the fort's health left, what was
## knocked down and damaged, the reward, and the fight's stats.
static func siege_entry(result: RunResult) -> Dictionary:
	return {
		"date": Time.get_datetime_string_from_system(true),
		"kind": "siege",
		"hero": Array(result.heroes),
		"gear": result.gear_log(),
		"number": result.siege_number,
		"won": result.won,
		"ending": result.ending,
		"waves_held": result.waves_held,
		"wave_count": result.wave_count,
		"fort_health_left": snappedf(result.fort_health_left, 0.1),
		"knocked_down": Array(result.knocked_down),
		"damaged": Array(result.damaged),
		"reward": result.materials_kept.duplicate(),
		"time": snappedf(result.survived_seconds, 0.1),
		"level": result.level,
		"kills": result.kills,
		"weapons": result.weapons.duplicate(true),
		"tricks": Array(result.tricks),
		"trick_moments": _timed(result.trick_moments),
	}


## Each event (evolution, floor pickup) with its time rounded to 0.1 s.
static func _timed(events: Array[Dictionary]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for event: Dictionary in events:
		var entry: Dictionary = event.duplicate()
		entry["time"] = snappedf(float(event["time"]), 0.1)
		entries.append(entry)
	return entries


## Null in the log for "didn't happen" (-1 in the result).
static func _time_or_null(seconds: float) -> Variant:
	return null if seconds < 0.0 else snappedf(seconds, 0.1)


## The rescue with its times rounded to 0.1 s (null = no rescue appeared).
static func _rescue_or_null(rescue: Dictionary) -> Variant:
	if rescue.is_empty():
		return null
	var entry: Dictionary = rescue.duplicate()
	entry["time"] = snappedf(float(rescue["time"]), 0.1)
	entry["freed_at"] = _time_or_null(float(rescue["freed_at"]))
	return entry


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
