class_name MusicPlayer
extends AudioStreamPlayer
## Plays the background music, synthesized live (no music files): a calm music-box loop on the
## title screen, a bouncier toy-band loop during runs and a driving minor loop with drums for
## the boss fight. Muffled while the game is paused.

## Track name → [beats per minute, chord roots (MIDI, one per bar), lead octave shift].
const TRACKS: Dictionary[StringName, Array] = {
	&"title": [80.0, [60.0, 57.0, 53.0, 55.0], 12.0],
	&"run": [124.0, [57.0, 53.0, 48.0, 55.0], 0.0],
	&"boss": [148.0, [57.0, 57.0, 53.0, 52.0], -12.0],
}
## Chord shape on top of each root: minor for A (57), major otherwise.
const MAJOR: PackedFloat32Array = [0.0, 4.0, 7.0, 12.0]
const MINOR: PackedFloat32Array = [0.0, 3.0, 7.0, 12.0]
## Order the chord tones are played in (one per eighth note).
const ARPEGGIO: PackedInt32Array = [0, 1, 2, 3, 2, 1, 2, 1]
const LOUDNESS: float = 0.22
const MUFFLE_EFFECT: int = 0

var track: StringName = &""

var _playback: AudioStreamGeneratorPlayback
var _sample: int = 0
var _bpm: float = 120.0
var _roots: Array = []
var _lead_shift: float = 0.0


func _ready() -> void:
	bus = &"Music"
	process_mode = Node.PROCESS_MODE_ALWAYS


## Starts `track_name` ("title" or "run") from the beginning (keeps playing if already on it).
func play_track(track_name: StringName) -> void:
	if track_name == track and playing:
		return
	use_track(track_name)
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = Synth.RATE
	generator.buffer_length = 0.3
	stream = generator
	_sample = 0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback
	_fill()


## Picks the song `sample_at` plays, without starting playback.
func use_track(track_name: StringName) -> void:
	track = track_name
	var settings: Array = TRACKS[track_name]
	_bpm = settings[0]
	_roots = settings[1]
	_lead_shift = settings[2]


## Muffles the music (paused game) or makes it clear again.
static func set_muffled(muffled: bool) -> void:
	var index: int = AudioServer.get_bus_index(&"Music")
	if index >= 0 and AudioServer.get_bus_effect_count(index) > MUFFLE_EFFECT:
		AudioServer.set_bus_effect_enabled(index, MUFFLE_EFFECT, muffled)


func _process(_delta: float) -> void:
	_fill()


func _fill() -> void:
	if _playback == null or not playing:
		return
	var frames: int = _playback.get_frames_available()
	for i: int in frames:
		var value: float = sample_at(float(_sample) / Synth.RATE) * LOUDNESS
		_playback.push_frame(Vector2(value, value))
		_sample += 1


## The music at time t (seconds). A pure function of t, so the loop never drifts.
func sample_at(t: float) -> float:
	var beat: float = t * _bpm / 60.0
	var bar: int = floori(beat / 4.0) % _roots.size()
	var root: float = _roots[bar]
	var chord: PackedFloat32Array = MINOR if int(root) % 12 == 9 else MAJOR
	var eighth: float = beat * 2.0
	var step: int = floori(eighth)
	var since_step: float = (eighth - step) * 30.0 / _bpm
	var note: float = root + 12.0 + _lead_shift + chord[ARPEGGIO[step % ARPEGGIO.size()]]
	var hz: float = Synth.midi_hz(note)
	var lead: float = Synth.sine(hz * since_step) + 0.25 * Synth.sine(hz * 3.0 * since_step)
	lead *= Synth.pluck(since_step, 0.005, 6.0)
	var since_beat: float = (beat - floorf(beat)) * 60.0 / _bpm
	var bass_hz: float = Synth.midi_hz(root - 12.0)
	var bass: float = Synth.triangle(bass_hz * since_beat) * Synth.pluck(since_beat, 0.01, 3.0)
	var value: float = 0.55 * lead + 0.45 * bass
	if track == &"run" or track == &"boss":
		var off_beat: float = fposmod(beat + 0.5, 1.0) * 60.0 / _bpm
		value += 0.12 * Synth.noise(t) * exp(-60.0 * off_beat)
	if track == &"boss":
		# A soft felt kick on every beat.
		var kick: float = Synth.sine(Synth.sweep(since_beat, 120.0, 45.0, 0.12))
		value += 0.5 * kick * exp(-18.0 * since_beat)
	return value
