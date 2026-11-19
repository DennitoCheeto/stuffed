class_name GameSettings
extends RefCounted
## Player options changed in Settings. They take effect right away and are saved to
## user://settings.json (hard rule 10), so they survive closing the game. A broken or old file
## never crashes: whatever is missing or wrong keeps its default.

## Screen tab (spec 10 §5): Fullscreen = the game owns the monitor, Borderless = a window
## without a frame that covers the screen (quick Alt+Tab).
enum WindowMode { WINDOWED, FULLSCREEN, BORDERLESS }

const BUSES: Array[StringName] = [&"Master", &"Effects", &"Music"]
const DEFAULT_PATH: String = "user://settings.json"
## How a window mode is written in the settings file (index = `WindowMode`).
const WINDOW_MODE_IDS: PackedStringArray = ["windowed", "fullscreen", "borderless"]
const READABILITY: ReadabilityRules = preload("res://data/ui/readability.tres")

## Tests point this at a scratch file.
static var path: String = DEFAULT_PATH
## Small damage numbers over hit zombies.
static var damage_numbers: bool = true
## "Menu animations: reduced" (spec 04 §3): no wobble, no drop-ins, instant count-ups.
static var reduced_motion: bool = false
static var window_mode: WindowMode = WindowMode.WINDOWED
static var vsync: bool = true
## Readability tab (spec 10 §5): camera shake 0 (none) to 1 (full).
static var screen_shake: float = 1.0
## Off: no white hit flashes on zombies or big hits; the hero's own hit flash gets softer.
static var flashes: bool = true
## Opacity of the players' own shots and effects (READABILITY.own_effects_min to 1).
static var own_effects: float = 1.0
## First-time hint notes (spec 10 §6).
static var hints: bool = true
## What `apply_screen` last asked the display for (the headless test display ignores it).
static var applied_window: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
static var applied_vsync: bool = true


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


## How strong a hero's white hit flash is (softer with Flashes off).
static func hero_flash() -> float:
	return 1.0 if flashes else READABILITY.hero_flash_soft


## The display's window mode for one of ours.
static func display_mode(mode: WindowMode) -> DisplayServer.WindowMode:
	match mode:
		WindowMode.FULLSCREEN:
			return DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		WindowMode.BORDERLESS:
			return DisplayServer.WINDOW_MODE_FULLSCREEN
	return DisplayServer.WINDOW_MODE_WINDOWED


## F11 / Alt+Enter: a window goes fullscreen, any full screen goes back to a window.
static func toggled_mode(mode: WindowMode) -> WindowMode:
	return WindowMode.FULLSCREEN if mode == WindowMode.WINDOWED else WindowMode.WINDOWED


## Puts the window mode and V-Sync on the screen.
static func apply_screen() -> void:
	applied_window = display_mode(window_mode)
	applied_vsync = vsync
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() != applied_window:
		DisplayServer.window_set_mode(applied_window)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)


## Every option as plain data (what goes into the settings file).
static func to_dict() -> Dictionary:
	var volumes: Dictionary = {}
	for bus: StringName in BUSES:
		volumes[String(bus)] = volume(bus)
	return {
		"damage_numbers": damage_numbers,
		"reduced_motion": reduced_motion,
		"window_mode": WINDOW_MODE_IDS[window_mode],
		"vsync": vsync,
		"screen_shake": screen_shake,
		"flashes": flashes,
		"own_effects": own_effects,
		"hints": hints,
		"volumes": volumes,
	}


## Applies saved options; anything missing or of the wrong kind keeps its default.
static func apply_dict(data: Dictionary) -> void:
	damage_numbers = _flag(data, "damage_numbers", true)
	reduced_motion = _flag(data, "reduced_motion", false)
	vsync = _flag(data, "vsync", true)
	flashes = _flag(data, "flashes", true)
	hints = _flag(data, "hints", true)
	screen_shake = _number(data, "screen_shake", 1.0, 0.0, 1.0)
	own_effects = _number(data, "own_effects", 1.0, READABILITY.own_effects_min, 1.0)
	var mode: Variant = data.get("window_mode", "")
	var index: int = WINDOW_MODE_IDS.find(mode) if mode is String else -1
	window_mode = WindowMode.WINDOWED if index < 0 else index as WindowMode
	var volumes: Variant = data.get("volumes", {})
	if not volumes is Dictionary:
		return
	for bus: StringName in BUSES:
		var amount: Variant = (volumes as Dictionary).get(String(bus))
		if amount is float or amount is int:
			set_volume(bus, float(amount))


## Back to how a fresh install starts (volumes are left alone).
static func reset() -> void:
	apply_dict({})


## Writes the options to the settings file. Returns false if it couldn't be written.
static func save() -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Settings not written: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	file.close()
	return true


## Reads the settings file (if there is one); without one (or a broken one), the options go
## back to defaults.
static func load_saved() -> void:
	var data: Variant = null
	if FileAccess.file_exists(path):
		# JSON.new().parse stays quiet on a broken file (parse_string logs an error).
		var json: JSON = JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK:
			data = json.data
	if data is Dictionary:
		apply_dict(data as Dictionary)
	else:
		reset()


static func _flag(data: Dictionary, key: String, fallback: bool) -> bool:
	var value: Variant = data.get(key, fallback)
	return value if value is bool else fallback


## A number option, kept inside `lo` .. `hi`; missing or not a number = `fallback`.
static func _number(data: Dictionary, key: String, fallback: float, lo: float, hi: float) -> float:
	var value: Variant = data.get(key, fallback)
	if not (value is float or value is int):
		return fallback
	return clampf(float(value), lo, hi)
