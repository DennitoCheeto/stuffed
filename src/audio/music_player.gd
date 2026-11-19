class_name MusicPlayer
extends Node
## The background music, made in code (spec 10 §4.1): one looping track per place (title, town,
## run, boss, siege, endless) from data/audio/music/, built from instrument layers. Changing place
## crossfades (`MusicRules.crossfade_seconds`); layers join and leave with the intensity (the run
## grows over time and with the crowd, the siege with each wave). Stingers play once over the
## music. Every track is rendered once per game on worker threads (no frame hitches) and kept for
## all players. Muffled while the game is paused. Runs and sieges reach it through the `GROUP`.

const GROUP: StringName = &"music"
const RULES: MusicRules = preload("res://data/audio/music/music_rules.tres")
const MUFFLE_EFFECT: int = 0

## Rendered clips per track / stinger id, shared by every MusicPlayer.
static var _clips: Dictionary[StringName, Array] = {}
static var _jobs: Dictionary[StringName, MusicJob] = {}

## The place's track id (&"" = none yet).
var track: StringName = &""
## True while a track is on (its clips may still be rendering for a moment after the boot).
var playing: bool:
	get:
		return deck != null
## 0 = calm, 1 = drums, 2 = everything (see `MusicRules.run_level`).
var intensity: int = 0
## The track fading in or playing.
var deck: MusicDeck
## Tracks fading out after a change of place.
var fading_out: Array[MusicDeck] = []
## Every stinger asked for, in order (for tests).
var stingers_played: Array[StringName] = []
var stinger_player: AudioStreamPlayer = AudioStreamPlayer.new()


## Starts rendering every track and stinger (the title first).
static func prepare_all() -> void:
	for one: MusicTrack in RULES.tracks + RULES.stingers:
		_request(one)


## True once `id`'s clips are rendered.
static func is_ready(id: StringName) -> bool:
	_collect()
	return _clips.has(id)


## Muffles the music (paused game) or makes it clear again.
static func set_muffled(muffled: bool) -> void:
	var index: int = AudioServer.get_bus_index(&"Music")
	if index >= 0 and AudioServer.get_bus_effect_count(index) > MUFFLE_EFFECT:
		AudioServer.set_bus_effect_enabled(index, MUFFLE_EFFECT, muffled)


static func _request(one: MusicTrack) -> void:
	if one == null or _clips.has(one.id) or _jobs.has(one.id):
		return
	var job: MusicJob = MusicJob.new(one)
	_jobs[one.id] = job
	job.start()


## Moves finished renders into the clip cache.
static func _collect() -> void:
	for id: StringName in _jobs.keys():
		var job: MusicJob = _jobs[id]
		if job.collect():
			_clips[id] = job.clips
			_jobs.erase(id)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	stinger_player.bus = &"Music"
	add_child(stinger_player)
	prepare_all()


## Changes to `track_name`'s music with a crossfade (keeps playing if already on it).
func play_track(track_name: StringName) -> void:
	if track_name == track and deck != null:
		return
	var next: MusicTrack = RULES.track(track_name)
	if next == null:
		push_warning("No music track %s" % track_name)
		return
	track = track_name
	intensity = 0
	if deck != null:
		fading_out.append(deck)
	deck = MusicDeck.new(next)
	add_child(deck)
	_request(next)
	_start_when_ready()


## The intensity level for layers (0-2); layers fade in or out to match.
func set_intensity(level: int) -> void:
	intensity = clampi(level, 0, 2)


## Plays stinger `id` once over the music.
func play_stinger(id: StringName) -> void:
	stingers_played.append(id)
	if not is_ready(id):
		_request(RULES.stinger(id))
		return
	stinger_player.stream = _clips[id][0]
	stinger_player.volume_db = linear_to_db(RULES.stinger_loudness)
	stinger_player.play()


func _process(delta: float) -> void:
	_start_when_ready()
	var fade_step: float = delta / maxf(RULES.crossfade_seconds, 0.01)
	var layer_step: float = delta / maxf(RULES.layer_fade_seconds, 0.01)
	if deck != null and deck.is_started():
		deck.fade = minf(deck.fade + fade_step, 1.0)
		deck.update(intensity, layer_step, RULES.loudness)
	for old: MusicDeck in fading_out.duplicate():
		old.fade = maxf(old.fade - fade_step, 0.0)
		old.update(intensity, 0.0, RULES.loudness)
		if old.fade <= 0.0:
			fading_out.erase(old)
			old.queue_free()


func _start_when_ready() -> void:
	if deck != null and not deck.is_started() and is_ready(deck.track.id):
		deck.start(_clips_of(deck.track.id), intensity)


func _clips_of(id: StringName) -> Array[AudioStreamWAV]:
	var clips: Array[AudioStreamWAV] = []
	clips.assign(_clips[id])
	return clips
