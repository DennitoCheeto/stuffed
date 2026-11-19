class_name Sfx
extends RefCounted
## Plays the game's sound effects. Each sound has a few voices at most and only a couple of new
## starts per frame (100 pops at once stay a pleasant crackle, not noise), and a slightly
## different pitch every time; the frequent ones vary in volume too (spec 10 §4.2, numbers in
## data/audio/sfx_rules.tres). A limiter on the Master bus keeps the mix from clipping.
## Main attaches it once; without a host (some tests) playing does nothing.

const RULES: SfxRules = preload("res://data/audio/sfx_rules.tres")
const HISTORY_SIZE: int = 64

## The last sounds that started (newest last, at most HISTORY_SIZE), for tests.
static var history: Array[StringName] = []
## Pitch of the last sound that started (tests check the variation).
static var last_pitch: float = 1.0
static var _host: Node
static var _streams: Dictionary[StringName, AudioStreamWAV] = {}
static var _voices: Dictionary[StringName, Array] = {}
## Player instance id → time (usec) its sound ends, so a voice counts as busy from the moment
## it starts (even before the audio thread picks it up).
static var _busy_until: Dictionary[int, int] = {}
## Sound → (frame, starts in that frame).
static var _frame_starts: Dictionary[StringName, Vector2i] = {}


## Makes all sounds and keeps their players under `host`.
static func attach(host: Node) -> void:
	_host = host
	_voices.clear()
	_busy_until.clear()
	_frame_starts.clear()
	if _streams.is_empty():
		for sound: StringName in SfxBank.LENGTHS:
			_streams[sound] = SfxBank.make(sound)


## Plays `sound`; `pitch` raises or lowers it (the pickup chain uses this). Returns false if it
## was skipped (all of its voices busy, or enough of it started this frame).
static func play(sound: StringName, pitch: float = 1.0) -> bool:
	if _host == null or not is_instance_valid(_host) or not _streams.has(sound):
		return false
	if not _may_start(sound):
		return false
	var player: AudioStreamPlayer = _free_voice(sound)
	if player == null:
		return false
	var spread: float = RULES.pitch_range(sound)
	player.pitch_scale = pitch * randf_range(1.0 - spread, 1.0 + spread)
	player.volume_db = -randf() * RULES.volume_drop(sound)
	last_pitch = player.pitch_scale
	player.play()
	var seconds: float = SfxBank.LENGTHS[sound] / player.pitch_scale
	_busy_until[player.get_instance_id()] = Time.get_ticks_usec() + int(seconds * 1_000_000.0)
	_note_start(sound)
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
		if _is_busy(player):
			count += 1
	return count


static func max_voices(sound: StringName) -> int:
	return RULES.max_voices(sound)


static func has_sound(sound: StringName) -> bool:
	return _streams.has(sound)


static func _may_start(sound: StringName) -> bool:
	var frame: int = Engine.get_process_frames()
	var seen: Vector2i = _frame_starts.get(sound, Vector2i(-1, 0))
	return seen.x != frame or seen.y < RULES.starts_per_frame


static func _note_start(sound: StringName) -> void:
	var frame: int = Engine.get_process_frames()
	var seen: Vector2i = _frame_starts.get(sound, Vector2i(-1, 0))
	_frame_starts[sound] = Vector2i(frame, seen.y + 1 if seen.x == frame else 1)


static func _is_busy(player: AudioStreamPlayer) -> bool:
	return player.playing or _busy_until.get(player.get_instance_id(), 0) > Time.get_ticks_usec()


static func _free_voice(sound: StringName) -> AudioStreamPlayer:
	if not _voices.has(sound):
		_voices[sound] = []
	var voices: Array = _voices[sound]
	for player: AudioStreamPlayer in voices:
		if not _is_busy(player):
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
