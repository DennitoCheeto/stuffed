class_name MusicDeck
extends Node
## One track playing (spec 10 §4.1): a player per layer, all started in the same frame so they
## stay in step (every clip of a track is equally long). `fade` is the crossfade share; each
## layer's `gains` entry slides towards 1 when the intensity reaches its level, else towards 0.

const SILENT_DB: float = -60.0

var track: MusicTrack
var players: Array[AudioStreamPlayer] = []
## 0 (silent) .. 1 (full): rises while this deck fades in, falls while it fades out.
var fade: float = 0.0
## Each layer's own loudness 0..1 (same order as `track.layers`).
var gains: PackedFloat32Array = []


func _init(what: MusicTrack) -> void:
	track = what
	name = "Deck_%s" % what.id
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_started() -> bool:
	return not players.is_empty()


## Starts every layer at once; layers the intensity already allows start at full gain.
func start(clips: Array[AudioStreamWAV], intensity: int) -> void:
	gains.resize(track.layers.size())
	for i: int in track.layers.size():
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = &"Music"
		player.stream = clips[i]
		player.volume_db = SILENT_DB
		add_child(player)
		players.append(player)
		gains[i] = 1.0 if track.layers[i].level <= intensity else 0.0
	for player: AudioStreamPlayer in players:
		player.play()


## Moves every layer's gain `step` towards what `intensity` allows and sets the volumes.
func update(intensity: int, step: float, loudness: float) -> void:
	for i: int in players.size():
		var target: float = 1.0 if track.layers[i].level <= intensity else 0.0
		gains[i] = move_toward(gains[i], target, step)
		var linear: float = loudness * fade * gains[i]
		players[i].volume_db = linear_to_db(linear) if linear > 0.001 else SILENT_DB


## How loud layer `index` plays right now (0..1, before the master loudness).
func layer_volume(index: int) -> float:
	return fade * gains[index] if index < gains.size() else 0.0
