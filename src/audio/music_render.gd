class_name MusicRender
extends RefCounted
## Turns a `MusicTrack` into sound (spec 10 §4.1): each layer becomes one clip of samples, note by
## note. A looping track's notes that ring past the end wrap around to the start, so the clip
## loops without a click. Pure functions: safe to run on a worker thread.

## How long each instrument's note rings (seconds).
const RING: Dictionary[MusicLayer.Instrument, float] = {
	MusicLayer.Instrument.KICK: 0.3,
	MusicLayer.Instrument.SNARE: 0.22,
	MusicLayer.Instrument.HAT: 0.07,
	MusicLayer.Instrument.BASS: 0.45,
	MusicLayer.Instrument.CHORDS: 1.4,
	MusicLayer.Instrument.LEAD: 0.5,
	MusicLayer.Instrument.BELL: 1.1,
}
## A drum hit marked "x" is this much quieter than an accented "X".
const SOFT_HIT: float = 0.6
## A stinger's clip lasts its steps plus this much ring-out (longer than any note rings, so
## nothing wraps round to its start).
const STINGER_TAIL: float = 1.5


## Every layer of `track` as samples (-1..1 each), same order as `track.layers`.
static func render_track(track: MusicTrack) -> Array[PackedFloat32Array]:
	var stems: Array[PackedFloat32Array] = []
	for layer: MusicLayer in track.layers:
		stems.append(render_layer(track, layer))
	return stems


## One clip length in samples for `track`.
static func length_of(track: MusicTrack) -> int:
	var seconds: float = track.seconds() + (0.0 if track.loops else STINGER_TAIL)
	return roundi(seconds * Synth.RATE)


static func render_layer(track: MusicTrack, layer: MusicLayer) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(length_of(track))
	out.fill(0.0)
	var step_seconds: float = track.step_seconds()
	for step: int in track.step_count():
		var symbol: String = layer.step_char(step)
		var bar: int = floori(float(step) / MusicTrack.STEPS_PER_BAR)
		var notes: PackedInt32Array = track.notes_for(layer, bar, symbol)
		if notes.is_empty():
			continue
		var gain: float = layer.volume
		if layer.is_drum() and symbol != "X":
			gain *= SOFT_HIT
		var start: int = roundi(step * step_seconds * Synth.RATE)
		for note: int in notes:
			_add_note(out, start, layer.instrument, note, gain / notes.size())
	return out


## Every stem added together (a stinger is one clip).
static func mix(stems: Array[PackedFloat32Array]) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	for stem: PackedFloat32Array in stems:
		if out.size() < stem.size():
			out.resize(stem.size())
		for i: int in stem.size():
			out[i] += stem[i]
	return out


## Samples as a 16-bit clip; a looping one loops over its whole length.
static func to_wav(samples: PackedFloat32Array, loops: bool) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	data.resize(samples.size() * 2)
	for i: int in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = Synth.RATE
	wav.stereo = false
	wav.data = data
	if loops:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav


## One instrument voice at `t` seconds after the note starts.
static func voice(instrument: MusicLayer.Instrument, hz: float, t: float) -> float:
	match instrument:
		MusicLayer.Instrument.KICK:
			return Synth.sine(Synth.sweep(t, 120.0, 45.0, 0.12)) * exp(-14.0 * t)
		MusicLayer.Instrument.SNARE:
			var body: float = 0.4 * Synth.sine(190.0 * t) + 0.6 * Synth.noise(t)
			return body * exp(-22.0 * t)
		MusicLayer.Instrument.HAT:
			return 0.6 * Synth.noise(t + 0.37) * exp(-70.0 * t)
		MusicLayer.Instrument.BASS:
			return Synth.triangle(hz * t) * Synth.pluck(t, 0.01, 4.5)
		MusicLayer.Instrument.CHORDS:
			var organ: float = Synth.sine(hz * t) + 0.15 * Synth.sine(2.0 * hz * t)
			return organ * Synth.pluck(t, 0.05, 2.2)
		MusicLayer.Instrument.BELL:
			var bell: float = Synth.sine(hz * t) + 0.35 * Synth.sine(2.76 * hz * t) * exp(-4.0 * t)
			return bell * Synth.pluck(t, 0.003, 3.5)
	return (Synth.sine(hz * t) + 0.25 * Synth.sine(3.0 * hz * t)) * Synth.pluck(t, 0.005, 6.0)


static func _add_note(out: PackedFloat32Array, at: int, kind: int, note: int, gain: float) -> void:
	var hz: float = Synth.midi_hz(note)
	var instrument: MusicLayer.Instrument = kind as MusicLayer.Instrument
	var count: int = roundi(RING[instrument] * Synth.RATE)
	var size: int = out.size()
	for i: int in count:
		out[(at + i) % size] += gain * voice(instrument, hz, float(i) / Synth.RATE)
