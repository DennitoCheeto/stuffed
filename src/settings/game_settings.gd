class_name GameSettings
extends RefCounted
## Player options changed in the pause menu. They last for the session (not saved to disk yet).

const BUSES: Array[StringName] = [&"Master", &"Effects", &"Music"]

## Small damage numbers over hit zombies.
static var damage_numbers: bool = true


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
