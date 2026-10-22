class_name Sfx
extends RefCounted
## Plays the game's sound effects. Each sound has a few voices at most (100 pops at once stay a
## pleasant crackle, not noise) and a slightly different pitch every time.
## Main attaches it once; without a host (some tests) playing does nothing.

const MAX_VOICES: Dictionary[StringName, int] = {
	&"pop": 6, &"hit": 5, &"pickup": 4, &"boss_hit": 2, &"fluff": 2, &"evolution": 1
}
const DEFAULT_VOICES: int = 3
const PITCH_VARIATION: float = 0.08
const HISTORY_SIZE: int = 64

## The last sounds that started (newest last, at most HISTORY_SIZE), for tests.
static var history: Array[StringName] = []
static var _host: Node
static var _streams: Dictionary[StringName, AudioStreamWAV] = {}
static var _voices: Dictionary[StringName, Array] = {}


## Makes all sounds and keeps their players under `host`.
static func attach(host: Node) -> void:
	_host = host
	_voices.clear()
	if _streams.is_empty():
		for sound: StringName in SfxBank.LENGTHS:
			_streams[sound] = SfxBank.make(sound)


## Plays `sound`; `pitch` raises or lowers it (the pickup chain uses this). Returns false if all
## of its voices were busy.
static func play(sound: StringName, pitch: float = 1.0) -> bool:
	if _host == null or not is_instance_valid(_host) or not _streams.has(sound):
		return false
	var player: AudioStreamPlayer = _free_voice(sound)
	if player == null:
		return false
	player.pitch_scale = pitch * randf_range(1.0 - PITCH_VARIATION, 1.0 + PITCH_VARIATION)
	player.play()
	history.append(sound)
	if history.size() > HISTORY_SIZE:
		history.pop_front()
	return true


## How many voices of `sound` are playing right now.
static func playing_count(sound: StringName) -> int:
	var count: int = 0
	for player: AudioStreamPlayer in _voices.get(sound, []):
		if not is_instance_valid(player):
			continue
		if player.playing:
			count += 1
	return count


static func max_voices(sound: StringName) -> int:
	return MAX_VOICES.get(sound, DEFAULT_VOICES)


static func has_sound(sound: StringName) -> bool:
	return _streams.has(sound)


static func _free_voice(sound: StringName) -> AudioStreamPlayer:
	if not _voices.has(sound):
		_voices[sound] = []
	var voices: Array = _voices[sound]
	for player: AudioStreamPlayer in voices:
		if not player.playing:
			return player
	if voices.size() >= max_voices(sound):
		return null
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = _streams[sound]
	player.bus = &"Effects"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	_host.add_child(player)
	voices.append(player)
	return player
