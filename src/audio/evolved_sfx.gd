class_name EvolvedSfx
extends RefCounted
## Voices of the spec 11 evolutions (kept apart from SfxBank so it stays short). Their lengths are
## in `SfxBank.LENGTHS` like every other sound. Soft, each its own, a bit fuller than the weapon
## they evolved from.


## The voice of `sound`, or an empty Callable if it isn't one of these.
static func voice(sound: StringName) -> Callable:
	var voices: Dictionary[StringName, Callable] = {
		&"cradle": _cradle,
		&"bowling": _bowling,
		&"strike": _strike,
		&"sting_cradle": _sting_cradle,
		&"sting_bowling": _sting_bowling,
		&"comfy": _comfy,
		&"hopscotch": _hopscotch,
		&"sting_comfy": _sting_comfy,
		&"sting_hopscotch": _sting_hopscotch,
	}
	return voices.get(sound, Callable())


## Little bell notes (MIDI numbers) one after another, `gap` seconds apart.
static func bells(t: float, notes: PackedFloat32Array, gap: float, decay: float) -> float:
	var value: float = 0.0
	for i: int in notes.size():
		var start: float = i * gap
		if t >= start:
			var local: float = t - start
			var hz: float = Synth.midi_hz(notes[i])
			var bell: float = Synth.sine(hz * local) + 0.3 * Synth.sine(hz * 2.0 * local)
			value += bell * exp(-decay * local)
	return value


## Cat's Cradle: the yarn ball's "boing", rounder, with a soft string twang on top.
static func _cradle(t: float) -> float:
	var phase: float = Synth.sweep(t, 170.0, 400.0, 0.32) + 0.5 * sin(TAU * 16.0 * t)
	var boing: float = Synth.sine(phase) * Synth.pluck(t, 0.01, 7.5)
	var twang: float = Synth.sine(660.0 * t + 0.002 * sin(TAU * 7.0 * t)) * exp(-14.0 * t)
	return 0.27 * boing + 0.08 * twang


## Bowling Buttons: the button clatter with a low wooden roll under it.
static func _bowling(t: float) -> float:
	var value: float = 0.0
	for i: int in 5:
		var start: float = i * 0.03
		if t >= start:
			var local: float = t - start
			value += Synth.sine((1500.0 + 300.0 * i) * local) * exp(-80.0 * local)
	var roll: float = Synth.sine(Synth.sweep(t, 110.0, 80.0, 0.24)) * exp(-10.0 * t)
	return 0.17 * value + 0.2 * roll + 0.06 * Synth.noise(t) * exp(-35.0 * t)


## A tumble knocked over 3 or more: a soft wooden "clack" and a little clatter of pins.
static func _strike(t: float) -> float:
	var clack: float = Synth.sine(Synth.sweep(t, 900.0, 500.0, 0.05)) * exp(-60.0 * t)
	var clatter: float = 0.0
	for i: int in 4:
		var start: float = 0.05 + i * 0.045
		if t >= start:
			var local: float = t - start
			clatter += Synth.sine((1100.0 - 90.0 * i) * local) * exp(-50.0 * local)
	return 0.16 * clack + 0.09 * clatter + 0.04 * Synth.noise(t) * exp(-20.0 * t)


## Cat's Cradle: a harp-like run of string plucks, up and up.
static func _sting_cradle(t: float) -> float:
	var notes: PackedFloat32Array = PackedFloat32Array([67.0, 71.0, 74.0, 79.0, 83.0])
	var run: float = bells(t, notes, 0.09, 5.5)
	var hum: float = Synth.sine(Synth.midi_hz(55.0) * t) * exp(-3.0 * t)
	return 0.11 * run + 0.06 * hum


## Bowling Buttons: a ball rolling down the lane, a strike, then two happy notes.
static func _sting_bowling(t: float) -> float:
	var roll: float = Synth.sine(Synth.sweep(t, 70.0, 95.0, 0.4)) * minf(t / 0.3, 1.0)
	roll *= 1.0 if t < 0.4 else exp(-30.0 * (t - 0.4))
	var hit: float = 0.0
	if t >= 0.4:
		hit = _strike(t - 0.4) * 1.6
	var notes: float = 0.0
	if t >= 0.55:
		notes = bells(t - 0.55, PackedFloat32Array([72.0, 79.0]), 0.1, 5.0)
	return 0.2 * roll + hit + 0.1 * notes


## Comfy Cloud: the cloud's soft breath of fluff, rounder, with a warm low hum under it.
static func _comfy(t: float) -> float:
	var breath: float = Synth.noise(t) * Synth.sine(Synth.sweep(t, 240.0, 100.0, 0.4))
	breath *= sin(PI * minf(t / 0.4, 1.0))
	var hum: float = Synth.sine(Synth.midi_hz(52.0) * t) * sin(PI * minf(t / 0.4, 1.0))
	return 0.12 * breath + 0.05 * hum


## Hopscotch Mortar: the mortar's hollow "thoonk", then a light little hop note.
static func _hopscotch(t: float) -> float:
	var hollow: float = Synth.sine(Synth.sweep(t, 320.0, 190.0, 0.1)) * exp(-14.0 * t)
	hollow += 0.4 * Synth.sine(Synth.sweep(t, 780.0, 470.0, 0.1)) * exp(-20.0 * t)
	var hop: float = 0.0
	if t >= 0.12:
		var local: float = t - 0.12
		hop = Synth.sine(Synth.sweep(local, 500.0, 900.0, 0.12)) * exp(-18.0 * local)
	return 0.27 * hollow + 0.08 * hop


## Comfy Cloud: a warm, slow chord swelling in like a pillow, with a soft breath on top.
static func _sting_comfy(t: float) -> float:
	var swell: float = minf(t / 0.35, 1.0) * exp(-2.5 * maxf(t - 0.35, 0.0))
	var chord: float = 0.0
	for note: float in [60.0, 64.0, 67.0, 72.0]:
		chord += Synth.sine(Synth.midi_hz(note) * t)
	var breath: float = Synth.noise(t) * exp(-6.0 * t)
	return 0.05 * chord * swell + 0.04 * breath


## Hopscotch Mortar: three hops going up the squares, then a happy landing note.
static func _sting_hopscotch(t: float) -> float:
	var value: float = 0.0
	for i: int in 3:
		var start: float = i * 0.16
		if t >= start:
			var local: float = t - start
			var base: float = 400.0 + 120.0 * i
			value += Synth.sine(Synth.sweep(local, base, base * 1.6, 0.12)) * exp(-14.0 * local)
	var landing: float = 0.0
	if t >= 0.5:
		landing = bells(t - 0.5, PackedFloat32Array([76.0, 84.0]), 0.08, 5.0)
	return 0.1 * value + 0.1 * landing
