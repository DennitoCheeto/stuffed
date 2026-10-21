class_name SfxBank
extends RefCounted
## The game's sound effects (spec 01 §10), each made in code by Synth.

## Name → length in seconds.
const LENGTHS: Dictionary[StringName, float] = {
	&"throw": 0.18,
	&"pin": 0.25,
	&"hit": 0.12,
	&"pop": 0.3,
	&"pickup": 0.12,
	&"dash": 0.15,
	&"slip": 0.35,
	&"hurt": 0.25,
	&"quack": 0.45,
	&"death": 0.9,
	&"goal": 1.1,
}


static func make(sound: StringName) -> AudioStreamWAV:
	var voice: Callable
	match sound:
		&"throw":
			voice = _throw
		&"pin":
			voice = _pin
		&"hit":
			voice = _hit
		&"pop":
			voice = _pop
		&"pickup":
			voice = _pickup
		&"dash":
			voice = _dash
		&"slip":
			voice = _slip
		&"hurt":
			voice = _hurt
		&"quack":
			voice = _quack
		&"death":
			voice = _death
		_:
			voice = _goal
	return Synth.render(LENGTHS[sound], voice)


## Boomerang throw / return: soft "whff".
static func _throw(t: float) -> float:
	var swish: float = Synth.noise(t) * Synth.sine(Synth.sweep(t, 300.0, 900.0, 0.18))
	return 0.35 * swish * Synth.pluck(t, 0.03, 18.0)


## Pin shot: short "tsing".
static func _pin(t: float) -> float:
	var ring: float = Synth.sine(2400.0 * t) * exp(-18.0 * t)
	ring += 0.4 * Synth.sine(3600.0 * t) * exp(-25.0 * t)
	return 0.28 * ring


## Zombie hit: soft felt "thup".
static func _hit(t: float) -> float:
	var thump: float = Synth.sine(Synth.sweep(t, 160.0, 90.0, 0.12)) * exp(-30.0 * t)
	return 0.5 * thump + 0.15 * Synth.noise(t) * exp(-60.0 * t)


## Zombie pop: "plop" plus a little fabric rip.
static func _pop(t: float) -> float:
	var plop: float = Synth.sine(Synth.sweep(t, 520.0, 150.0, 0.15)) * exp(-12.0 * t)
	var rip: float = 0.0
	if t > 0.04:
		rip = Synth.noise(t) * exp(-22.0 * (t - 0.04)) * (0.5 + 0.5 * Synth.square(t * 90.0))
	return 0.45 * plop + 0.18 * rip


## XP button pickup: "plip" (played higher in a chain).
static func _pickup(t: float) -> float:
	var plip: float = Synth.sine(1300.0 * t) * exp(-30.0 * t)
	return 0.3 * (plip + 0.3 * Synth.sine(2600.0 * t) * exp(-40.0 * t))


## Dash: quick "fwip".
static func _dash(t: float) -> float:
	var air: float = Synth.noise(t) * Synth.sine(Synth.sweep(t, 400.0, 2400.0, 0.15))
	return 0.3 * air * sin(PI * minf(t / 0.15, 1.0))


## Peel slip: cartoon "zwiip".
static func _slip(t: float) -> float:
	var tone: float = Synth.sine(Synth.sweep(t, 300.0, 1600.0, 0.35))
	return 0.3 * tone * sin(PI * minf(t / 0.35, 1.0))


## Banane hurt: squeaky "honk".
static func _hurt(t: float) -> float:
	var wobble: float = 520.0 * t + 1.6 * sin(TAU * 25.0 * t)
	return 0.18 * Synth.square(wobble) * Synth.pluck(t, 0.01, 9.0)


## Level-up: deadpan "quack".
static func _quack(t: float) -> float:
	var phase: float = Synth.sweep(t, 330.0, 220.0, 0.35)
	var nasal: float = 0.6 * Synth.saw(phase) + 0.4 * Synth.saw(phase * 2.0)
	var shape: float = minf(t / 0.02, 1.0) * clampf((0.45 - t) / 0.15, 0.0, 1.0)
	return 0.25 * nasal * shape


## Death: sad deflating squeak.
static func _death(t: float) -> float:
	var vibrato: float = 0.06 * sin(TAU * 8.0 * t)
	var tone: float = Synth.sine(Synth.sweep(t, 800.0, 150.0, 0.9) + vibrato)
	return 0.3 * tone * clampf((0.9 - t) / 0.3, 0.0, 1.0) * minf(t / 0.03, 1.0)


## Goal reached: short happy jingle (C E G C).
static func _goal(t: float) -> float:
	var value: float = 0.0
	var notes: PackedFloat32Array = [72.0, 76.0, 79.0, 84.0]
	for i: int in notes.size():
		var start: float = i * 0.12
		if t >= start:
			var local: float = t - start
			var hz: float = Synth.midi_hz(notes[i])
			var bell: float = Synth.sine(hz * local) + 0.3 * Synth.sine(hz * 2.0 * local)
			value += bell * exp(-5.0 * local)
	return 0.16 * value
