class_name Synth
extends RefCounted
## Tiny sound synthesizer: builds short sounds sample by sample, so the game needs no audio files.

const RATE: int = 22050


## Renders `seconds` of sound; `voice` returns the sample (-1..1) at time t (seconds).
static func render(seconds: float, voice: Callable) -> AudioStreamWAV:
	var count: int = int(seconds * RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in count:
		var t: float = float(i) / RATE
		var value: float = voice.call(t)
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32000.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


static func sine(phase: float) -> float:
	return sin(TAU * phase)


static func triangle(phase: float) -> float:
	return 4.0 * absf(fposmod(phase, 1.0) - 0.5) - 1.0


static func saw(phase: float) -> float:
	return 2.0 * fposmod(phase, 1.0) - 1.0


static func square(phase: float) -> float:
	return 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0


## Repeatable white noise (the same t gives the same value).
static func noise(t: float) -> float:
	return fposmod(sin(t * 12_989.8 + 78.233) * 43_758.545, 1.0) * 2.0 - 1.0


## Phase of a tone that slides from `from_hz` to `to_hz` over `length` seconds.
static func sweep(t: float, from_hz: float, to_hz: float, length: float) -> float:
	var k: float = minf(t, length)
	var phase: float = from_hz * k + (to_hz - from_hz) * k * k / (2.0 * length)
	return phase + to_hz * maxf(t - length, 0.0)


## A short fade-in, then exponential decay.
static func pluck(t: float, attack: float, decay: float) -> float:
	if t < attack:
		return t / attack
	return exp(-(t - attack) * decay)


static func midi_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)
