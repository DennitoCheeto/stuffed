class_name GameSettings
extends RefCounted
## Player options changed in the pause menu. They take effect right away and are saved to
## user://settings.json (hard rule 10), so they survive closing the game.

const BUSES: Array[StringName] = [&"Master", &"Effects", &"Music"]
const DEFAULT_PATH: String = "user://settings.json"

## Tests point this at a scratch file.
static var path: String = DEFAULT_PATH
## Small damage numbers over hit zombies.
static var damage_numbers: bool = true
## "Menu animations: reduced" (spec 04 §3): no wobble, no drop-ins, instant count-ups.
static var reduced_motion: bool = false


## Volume of an audio bus, 0 (silent) to 1 (full).
static func volume(bus: StringName) -> float:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return 0.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


## Sets a bus volume right away (0 = silent, 1 = full).
static func set_volume(bus: StringName, amount: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	var clamped: float = clampf(amount, 0.0, 1.0)
	AudioServer.set_bus_mute(index, clamped <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(clamped, 0.001)))


## Every option as plain data (what goes into the settings file).
static func to_dict() -> Dictionary:
	var volumes: Dictionary = {}
	for bus: StringName in BUSES:
		volumes[String(bus)] = volume(bus)
	return {
		"damage_numbers": damage_numbers,
		"reduced_motion": reduced_motion,
		"volumes": volumes,
	}


## Applies saved options; anything missing keeps its default.
static func apply_dict(data: Dictionary) -> void:
	damage_numbers = bool(data.get("damage_numbers", true))
	reduced_motion = bool(data.get("reduced_motion", false))
	var volumes: Dictionary = data.get("volumes", {}) as Dictionary
	for bus: StringName in BUSES:
		if volumes.has(String(bus)):
			set_volume(bus, float(volumes[String(bus)]))


## Writes the options to the settings file. Returns false if it couldn't be written.
static func save() -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Settings not written: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return true


## Reads the settings file (if there is one); without one, the options go back to defaults.
static func load_saved() -> void:
	var data: Variant = null
	if FileAccess.file_exists(path):
		data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		apply_dict(data as Dictionary)
	else:
		damage_numbers = true
		reduced_motion = false
