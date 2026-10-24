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
	&"puff": 0.5,
	&"spit": 0.2,
	&"burst": 0.45,
	&"boss_banner": 1.2,
	&"stomp": 0.5,
	# Weapons (spec 02 §12): soft, each its own; evolved weapons a bit fuller.
	&"buttons": 0.2,
	&"boing": 0.3,
	&"whip": 0.22,
	&"cannon": 0.35,
	&"zip": 0.32,
	&"mortar": 0.3,
	&"needles": 0.4,
	&"fluff": 0.35,
	&"volley": 0.4,
	&"storm": 0.5,
	&"split": 0.4,
	&"sticky": 0.4,
	# Moments.
	&"elite": 0.7,
	&"gift_open": 0.8,
	&"evolution": 1.4,
	&"boss_hit": 0.16,
	&"boss_down": 1.6,
	# Floor pickups (spec 02b).
	&"magnet": 0.45,
	&"snow_globe": 0.7,
	&"ice_crack": 0.4,
	&"party_popper": 0.8,
	# Town (spec 03).
	&"way_home": 1.0,
	&"rebuild": 0.9,
	&"upgrade": 0.6,
	&"new_building": 0.9,
	&"nope": 0.25,
	&"help": 0.5,
	&"rescued": 0.9,
	# Town and Scrapbook (spec 03 §11): small and soft.
	&"coin": 0.14,
	&"page": 0.3,
	&"hello": 0.3,
	# Menus (spec 04 §7): soft, quieter than any enemy sound.
	&"ui_hover": 0.08,
	&"ui_press": 0.14,
	&"ui_nope": 0.22,
	&"ui_open": 0.3,
	&"sticker": 0.22,
	&"star": 0.9,
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
		&"puff":
			voice = _puff
		&"spit":
			voice = _spit
		&"boss_banner":
			voice = _boss_banner
		&"stomp":
			voice = _stomp
		&"burst":
			voice = _burst
		&"goal":
			voice = _goal
		_:
			voice = _weapon_or_moment(sound)
	return Synth.render(LENGTHS[sound], voice)


## The sounds added in spec 02 (kept apart so `make` stays short).
static func _weapon_or_moment(sound: StringName) -> Callable:
	var voices: Dictionary[StringName, Callable] = {
		&"buttons": _buttons,
		&"boing": _boing,
		&"whip": _whip,
		&"cannon": _cannon,
		&"zip": _zip,
		&"mortar": _mortar,
		&"needles": _needles,
		&"fluff": _fluff,
		&"volley": _volley,
		&"storm": _storm,
		&"split": _split,
		&"sticky": _sticky,
		&"elite": _elite,
		&"gift_open": _gift_open,
		&"evolution": _evolution,
		&"boss_hit": _boss_hit,
		&"boss_down": _boss_down,
		&"magnet": _magnet,
		&"snow_globe": _snow_globe,
		&"ice_crack": _ice_crack,
		&"party_popper": _party_popper,
		&"way_home": _way_home,
		&"rebuild": _rebuild,
		&"upgrade": _upgrade,
		&"new_building": _new_building,
		&"nope": _nope,
		&"help": _help,
		&"rescued": _rescued,
		&"coin": _coin,
		&"page": _page,
		&"hello": _hello,
		&"ui_hover": _ui_hover,
		&"ui_press": _ui_press,
		&"ui_nope": _ui_nope,
		&"ui_open": _ui_open,
		&"sticker": _sticker,
		&"star": _star,
	}
	return voices[sound]


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


## Spitter wind-up: a rising, wobbly "bwuuup" as the frog puffs up.
static func _puff(t: float) -> float:
	var wobble: float = 3.0 * sin(TAU * 14.0 * t)
	var tone: float = Synth.sine(Synth.sweep(t, 140.0, 420.0, 0.5) + wobble * t)
	return 0.3 * tone * minf(t / 0.05, 1.0) * clampf((0.5 - t) / 0.08, 0.0, 1.0)


## Spitter shot: a wet little "ptoo".
static func _spit(t: float) -> float:
	var pop: float = Synth.sine(Synth.sweep(t, 700.0, 220.0, 0.12)) * exp(-20.0 * t)
	return 0.4 * pop + 0.2 * Synth.noise(t) * exp(-45.0 * t)


## Bloater burst: a balloon "pop" and a soft hiss of stuffing.
static func _burst(t: float) -> float:
	var bang: float = Synth.noise(t) * exp(-30.0 * t)
	var thump: float = Synth.sine(Synth.sweep(t, 220.0, 60.0, 0.2)) * exp(-10.0 * t)
	var hiss: float = Synth.noise(t) * 0.25 * clampf((0.45 - t) / 0.3, 0.0, 1.0)
	return 0.35 * bang + 0.4 * thump + 0.12 * hiss


## Boss arrives: a low, wobbly felt horn, two notes going down.
static func _boss_banner(t: float) -> float:
	var hz: float = Synth.midi_hz(45.0) if t < 0.45 else Synth.midi_hz(40.0)
	var local: float = t if t < 0.45 else t - 0.45
	var phase: float = hz * local + 0.8 * sin(TAU * 5.0 * t)
	var horn: float = 0.6 * Synth.saw(phase) + 0.4 * Synth.square(phase * 0.5)
	var shape: float = minf(local / 0.04, 1.0) * clampf((1.2 - t) / 0.4, 0.0, 1.0)
	return 0.22 * horn * shape


## Big Ted's stomp: a heavy, soft "thoom".
static func _stomp(t: float) -> float:
	var thump: float = Synth.sine(Synth.sweep(t, 110.0, 35.0, 0.4)) * exp(-7.0 * t)
	return 0.6 * thump + 0.2 * Synth.noise(t) * exp(-25.0 * t)


## Button Shotgun: a little clatter of buttons ("tk-tk-tk").
static func _buttons(t: float) -> float:
	var value: float = 0.0
	for i: int in 4:
		var start: float = i * 0.035
		if t >= start:
			var local: float = t - start
			value += Synth.sine((1800.0 + 350.0 * i) * local) * exp(-90.0 * local)
	return 0.17 * value + 0.06 * Synth.noise(t) * exp(-40.0 * t)


## Bouncy Yarn Ball: a soft spring "boing".
static func _boing(t: float) -> float:
	var phase: float = Synth.sweep(t, 180.0, 420.0, 0.3) + 0.5 * sin(TAU * 18.0 * t)
	return 0.24 * Synth.sine(phase) * Synth.pluck(t, 0.01, 9.0)


## Thread Whip: a swish that ends in a small snap.
static func _whip(t: float) -> float:
	var swish: float = Synth.noise(t) * Synth.sine(Synth.sweep(t, 600.0, 2600.0, 0.14))
	swish *= sin(PI * minf(t / 0.16, 1.0))
	var snap: float = 0.0
	if t > 0.14:
		snap = Synth.noise(t) * exp(-80.0 * (t - 0.14))
	return 0.2 * swish + 0.22 * snap


## Yarn Cannon: a padded "whump".
static func _cannon(t: float) -> float:
	var thump: float = Synth.sine(Synth.sweep(t, 150.0, 55.0, 0.25)) * exp(-11.0 * t)
	return 0.32 * thump + 0.08 * Synth.noise(t) * exp(-30.0 * t)


## Zipper Ray: a zipper being pulled ("zrrrip"), clicks getting faster.
static func _zip(t: float) -> float:
	var clicks: float = 0.5 + 0.5 * Synth.square(Synth.sweep(t, 60.0, 160.0, 0.32))
	var shape: float = minf(t / 0.02, 1.0) * clampf((0.32 - t) / 0.06, 0.0, 1.0)
	return 0.2 * Synth.noise(t) * clicks * shape


## Thimble Mortar: a hollow "thoonk" as the thimble is launched.
static func _mortar(t: float) -> float:
	var hollow: float = Synth.sine(Synth.sweep(t, 300.0, 180.0, 0.1)) * exp(-14.0 * t)
	hollow += 0.4 * Synth.sine(Synth.sweep(t, 750.0, 450.0, 0.1)) * exp(-20.0 * t)
	return 0.25 * hollow


## Orbiting Needles: a quick glassy shimmer going up.
static func _needles(t: float) -> float:
	var value: float = 0.0
	var notes: PackedFloat32Array = [88.0, 91.0, 95.0]
	for i: int in notes.size():
		var start: float = i * 0.06
		if t >= start:
			var local: float = t - start
			value += Synth.sine(Synth.midi_hz(notes[i]) * local) * exp(-14.0 * local)
	return 0.11 * value


## Stuffing Cloud: a soft, low breath of fluff ("fffh"), the quietest weapon (it puffs often, so
## it only sounds every `sound_gap` seconds).
static func _fluff(t: float) -> float:
	var breath: float = Synth.noise(t) * Synth.sine(Synth.sweep(t, 220.0, 90.0, 0.35))
	return 0.12 * breath * sin(PI * minf(t / 0.35, 1.0))


## Pincushion Volley (evolved): three pins at once, a bright chord with a little ring.
static func _volley(t: float) -> float:
	var ring: float = 0.0
	for hz: float in [2100.0, 2650.0, 3150.0]:
		ring += Synth.sine(hz * t) * exp(-11.0 * t)
	return 0.17 * ring + 0.1 * Synth.noise(t) * exp(-50.0 * t)


## Sewing Storm (evolved): a whirl of air with glassy sparkles in it.
static func _storm(t: float) -> float:
	var whirl: float = Synth.noise(t) * Synth.sine(Synth.sweep(t, 500.0, 1400.0, 0.5))
	whirl *= 0.5 + 0.5 * sin(TAU * 12.0 * t)
	var sparkle: float = Synth.sine(Synth.midi_hz(93.0 + 3.0 * floorf(t * 10.0)) * t)
	var shape: float = sin(PI * minf(t / 0.5, 1.0))
	return (0.18 * whirl + 0.1 * sparkle) * shape


## Banana Split (evolved): two whooshes, one after the other, and a bright "ting".
static func _split(t: float) -> float:
	var value: float = 0.0
	for start: float in [0.0, 0.1]:
		if t >= start:
			var local: float = t - start
			var swish: float = Synth.noise(t) * Synth.sine(Synth.sweep(local, 300.0, 1000.0, 0.2))
			value += swish * Synth.pluck(local, 0.03, 14.0)
	var ting: float = Synth.sine(1900.0 * t) * exp(-10.0 * t)
	return 0.38 * value + 0.12 * ting


## Yarn Bomb (evolved): a fat "splotch" of sticky yarn.
static func _sticky(t: float) -> float:
	var splat: float = Synth.sine(Synth.sweep(t, 260.0, 70.0, 0.3)) * exp(-8.0 * t)
	var wet: float = Synth.noise(t) * exp(-18.0 * t) * (0.5 + 0.5 * Synth.square(t * 60.0))
	return 0.3 * splat + 0.14 * wet


## An elite appears: a bright, slightly sour warning bell (two notes, the second higher).
static func _elite(t: float) -> float:
	var value: float = 0.0
	for i: int in 2:
		var start: float = i * 0.16
		if t >= start:
			var local: float = t - start
			var hz: float = Synth.midi_hz(76.0 + 6.0 * i)
			var bell: float = Synth.sine(hz * local) + 0.5 * Synth.sine(hz * 2.76 * local)
			value += bell * exp(-6.0 * local)
	return 0.3 * value * clampf((0.7 - t) / 0.15, 0.0, 1.0)


## The gift box opens: a cork "pop", then a little sparkle going up.
static func _gift_open(t: float) -> float:
	var pop: float = Synth.sine(Synth.sweep(t, 900.0, 300.0, 0.06)) * exp(-35.0 * t)
	var sparkle: float = 0.0
	var notes: PackedFloat32Array = [79.0, 83.0, 86.0, 91.0]
	for i: int in notes.size():
		var start: float = 0.12 + i * 0.08
		if t >= start:
			var local: float = t - start
			sparkle += Synth.sine(Synth.midi_hz(notes[i]) * local) * exp(-7.0 * local)
	return 0.4 * pop + 0.16 * sparkle


## An evolution: a bigger fanfare than any other moment. A rising run, then a full chord that
## rings out with a shimmer.
static func _evolution(t: float) -> float:
	var value: float = 0.0
	var run_notes: PackedFloat32Array = [60.0, 64.0, 67.0, 72.0, 76.0]
	for i: int in run_notes.size():
		var start: float = i * 0.07
		if t >= start:
			var local: float = t - start
			value += 0.6 * Synth.triangle(Synth.midi_hz(run_notes[i]) * local) * exp(-9.0 * local)
	if t >= 0.4:
		var local: float = t - 0.4
		var fade: float = minf(local / 0.02, 1.0) * clampf((1.4 - t) / 0.6, 0.0, 1.0)
		for note: float in [72.0, 76.0, 79.0, 84.0]:
			var hz: float = Synth.midi_hz(note) * (1.0 + 0.004 * sin(TAU * 6.0 * t))
			value += 0.45 * Synth.sine(hz * local) * fade
	return 0.2 * value


## A boss is hit: a deeper, heavier "thud" than a normal hit.
static func _boss_hit(t: float) -> float:
	var thud: float = Synth.sine(Synth.sweep(t, 110.0, 55.0, 0.16)) * exp(-20.0 * t)
	return 0.5 * thud + 0.12 * Synth.noise(t) * exp(-50.0 * t)


## A boss is beaten: a long deflating wobble going down, then a warm chord.
static func _boss_down(t: float) -> float:
	var deflate: float = 0.0
	if t < 0.9:
		var phase: float = Synth.sweep(t, 500.0, 90.0, 0.9) + 0.6 * sin(TAU * 9.0 * t)
		deflate = Synth.saw(phase) * minf(t / 0.03, 1.0) * clampf((0.9 - t) / 0.2, 0.0, 1.0)
	var chord: float = 0.0
	if t >= 0.85:
		var local: float = t - 0.85
		var fade: float = minf(local / 0.03, 1.0) * clampf((1.6 - t) / 0.5, 0.0, 1.0)
		for note: float in [55.0, 59.0, 62.0, 67.0]:
			chord += Synth.sine(Synth.midi_hz(note) * local) * fade
	return 0.2 * deflate + 0.12 * chord


## Big Magnet grabbed: a rising, wobbly "zwoop".
static func _magnet(t: float) -> float:
	var phase: float = Synth.sweep(t, 220.0, 1100.0, 0.35) + 0.8 * sin(TAU * 14.0 * t)
	var tone: float = Synth.sine(phase) + 0.35 * Synth.triangle(phase * 2.0)
	var envelope: float = minf(t / 0.02, 1.0) * clampf((0.45 - t) / 0.12, 0.0, 1.0)
	return 0.3 * tone * envelope


## Snow Globe grabbed: a bright music-box tinkle going up, over a soft icy crackle.
static func _snow_globe(t: float) -> float:
	var tinkle: float = 0.0
	var notes: PackedFloat32Array = [84.0, 88.0, 91.0, 96.0]
	for i: int in notes.size():
		var start: float = i * 0.08
		if t >= start:
			var local: float = t - start
			tinkle += Synth.sine(Synth.midi_hz(notes[i]) * local) * exp(-7.0 * local)
	return 0.18 * tinkle + 0.08 * _crackle(t, 0.7)


## The ice of a freeze cracks (it ends soon): a few sharp snaps.
static func _ice_crack(t: float) -> float:
	var snap: float = Synth.sine(Synth.sweep(t, 2400.0, 900.0, 0.4)) * exp(-14.0 * t)
	return 0.12 * snap + 0.2 * _crackle(t, 0.4)


## Short noise ticks that come and go, like ice or frost crackling, fading out over `length`.
static func _crackle(t: float, length: float) -> float:
	var tick_phase: float = fmod(t * 23.0, 1.0)
	var ticks: float = exp(-40.0 * tick_phase) * absf(sin(t * 61.0))
	return Synth.noise(t) * ticks * clampf((length - t) / (length * 0.5), 0.0, 1.0)


## Party Popper pulled: a bright "pop" with a soft thump, then a rustle of confetti floating down.
static func _party_popper(t: float) -> float:
	var pop: float = Synth.sine(Synth.sweep(t, 900.0, 300.0, 0.06)) * exp(-45.0 * t)
	var thump: float = Synth.sine(Synth.sweep(t, 160.0, 70.0, 0.1)) * exp(-25.0 * t)
	var crack: float = Synth.noise(t) * exp(-60.0 * t)
	var rustle: float = 0.0
	if t >= 0.05:
		rustle = _crackle(t * 1.7, 1.3) * minf((t - 0.05) / 0.1, 1.0)
	return 0.3 * pop + 0.25 * thump + 0.2 * crack + 0.12 * rustle


## The Way Home portal opens: a soft airy whoosh under a calm chime going up (no alarm).
static func _way_home(t: float) -> float:
	var chime: float = 0.0
	var notes: PackedFloat32Array = [72.0, 76.0, 79.0, 84.0]
	for i: int in notes.size():
		var start: float = i * 0.12
		if t >= start:
			var local: float = t - start
			chime += Synth.sine(Synth.midi_hz(notes[i]) * local) * exp(-4.0 * local)
	var air: float = Synth.noise(t) * sin(PI * clampf(t / 1.0, 0.0, 1.0))
	return 0.14 * chime + 0.05 * air


## A ruin is rebuilt: a rustle while it shakes, then a big soft felt "fwump" and a warm chime.
static func _rebuild(t: float) -> float:
	var flutter: float = 0.5 * (1.0 + sin(TAU * 18.0 * t))
	var rustle: float = Synth.noise(t) * flutter * clampf(t / 0.3, 0.0, 1.0)
	if t < 0.32:
		return 0.12 * rustle
	var local: float = t - 0.32
	var fwump: float = Synth.sine(Synth.sweep(local, 150.0, 55.0, 0.2)) * exp(-9.0 * local)
	var air: float = Synth.noise(t) * exp(-18.0 * local)
	var chime: float = 0.0
	for note: float in [72.0, 79.0]:
		chime += Synth.sine(Synth.midi_hz(note) * local) * exp(-6.0 * local)
	return 0.45 * fwump + 0.12 * air + 0.07 * chime


## A building gets a new level: a smaller "fwump" with a bright little ding.
static func _upgrade(t: float) -> float:
	var fwump: float = Synth.sine(Synth.sweep(t, 190.0, 80.0, 0.15)) * exp(-12.0 * t)
	var ding: float = Synth.sine(Synth.midi_hz(84.0) * t) * exp(-7.0 * t) * minf(t / 0.01, 1.0)
	return 0.35 * fwump + 0.08 * ding


## The zombie yarn falls off a ruin ("New building!"): a soft unravel and a rising chime.
static func _new_building(t: float) -> float:
	var unravel: float = Synth.noise(t) * absf(sin(TAU * 9.0 * t)) * exp(-5.0 * t)
	var chime: float = 0.0
	var notes: PackedFloat32Array = [67.0, 71.0, 74.0, 79.0]
	for i: int in notes.size():
		var start: float = 0.15 + i * 0.1
		if t >= start:
			var local: float = t - start
			chime += Synth.sine(Synth.midi_hz(notes[i]) * local) * exp(-5.0 * local)
	return 0.08 * unravel + 0.13 * chime


## Not enough in the jars: a short, soft low "bmm" (calm, not an alarm).
static func _nope(t: float) -> float:
	var tone: float = Synth.triangle(Synth.midi_hz(50.0) * t) * sin(PI * clampf(t / 0.25, 0.0, 1.0))
	return 0.2 * tone


## A tangled plushie calls for help: two small rubber-toy squeaks going up ("hel-p!"), soft.
static func _help(t: float) -> float:
	var squeak: float = 0.0
	var starts: PackedFloat32Array = [0.0, 0.2]
	for i: int in starts.size():
		var local: float = t - starts[i]
		if local < 0.0 or local > 0.22:
			continue
		var pitch: float = Synth.midi_hz(81.0 + 4.0 * i) * (1.0 + 0.25 * local / 0.22)
		var wobble: float = 1.0 + 0.03 * sin(TAU * 30.0 * local)
		var shape: float = sin(PI * local / 0.22)
		squeak += Synth.triangle(pitch * wobble * local) * shape
	return 0.22 * squeak


## A plushie is freed: a happy squeak, then a warm chime going up (it hops into the backpack).
static func _rescued(t: float) -> float:
	var squeak: float = 0.0
	if t < 0.18:
		var pitch: float = Synth.midi_hz(84.0) * (1.0 + 0.4 * t / 0.18)
		squeak = Synth.triangle(pitch * t) * sin(PI * t / 0.18)
	var chime: float = 0.0
	var notes: PackedFloat32Array = [72.0, 76.0, 79.0, 84.0]
	for i: int in notes.size():
		var start: float = 0.15 + i * 0.09
		if t >= start:
			var local: float = t - start
			chime += Synth.sine(Synth.midi_hz(notes[i]) * local) * exp(-5.0 * local)
	return 0.18 * squeak + 0.12 * chime


## A burst piece lands in its jar: a tiny felt "tink", much softer than an XP plip.
static func _coin(t: float) -> float:
	var tink: float = Synth.sine(2100.0 * t) * exp(-45.0 * t)
	return 0.16 * (tink + 0.3 * Synth.sine(3150.0 * t) * exp(-60.0 * t))


## A Scrapbook page turns: a quick papery "fffp".
static func _page(t: float) -> float:
	var flutter: float = 0.5 * (1.0 + sin(TAU * 40.0 * t))
	var paper: float = Synth.noise(t) * flutter * sin(PI * clampf(t / 0.3, 0.0, 1.0))
	var flap: float = Synth.sine(Synth.sweep(t, 220.0, 120.0, 0.3)) * exp(-14.0 * t)
	return 0.16 * paper + 0.1 * flap


## A plushie in town waves at a player: one small, happy rubber squeak.
static func _hello(t: float) -> float:
	var length: float = 0.26
	if t > length:
		return 0.0
	var pitch: float = Synth.midi_hz(86.0) * (1.0 + 0.2 * t / length)
	return 0.14 * Synth.triangle(pitch * t) * sin(PI * t / length)


## Hover / focus on a menu button: a tiny muffled felt "pat".
static func _ui_hover(t: float) -> float:
	var thump: float = Synth.sine(Synth.sweep(t, 260.0, 170.0, 0.08)) * Synth.pluck(t, 0.004, 45.0)
	return 0.16 * thump + 0.03 * Synth.noise(t) * exp(-80.0 * t)


## Pressing a menu button: a soft rubbery "boop".
static func _ui_press(t: float) -> float:
	var boop: float = Synth.sine(Synth.sweep(t, 540.0, 330.0, 0.12)) * Synth.pluck(t, 0.006, 24.0)
	return 0.22 * boop


## Pressing a disabled button: two low blips going down ("nuh-uh").
static func _ui_nope(t: float) -> float:
	var blip: float = 0.0
	var starts: PackedFloat32Array = [0.0, 0.11]
	for i: int in starts.size():
		var local: float = t - starts[i]
		if local < 0.0 or local > 0.1:
			continue
		blip += Synth.triangle(Synth.midi_hz(52.0 - 3.0 * i) * local) * sin(PI * local / 0.1)
	return 0.17 * blip


## A menu opens: a short, soft cloth "whoosh".
static func _ui_open(t: float) -> float:
	var shape: float = sin(PI * clampf(t / 0.3, 0.0, 1.0))
	var air: float = Synth.noise(t) * shape * shape
	var tone: float = Synth.sine(Synth.sweep(t, 180.0, 360.0, 0.3)) * shape
	return 0.1 * air + 0.06 * tone


## A sticker slaps on: a quick papery "thwap".
static func _sticker(t: float) -> float:
	var slap: float = Synth.noise(t) * exp(-38.0 * t)
	var thump: float = Synth.sine(Synth.sweep(t, 300.0, 140.0, 0.1)) * exp(-22.0 * t)
	return 0.16 * slap + 0.14 * thump


## The Star of the run: a little fanfare going up (C, E, G, high C).
static func _star(t: float) -> float:
	var notes: PackedFloat32Array = [72.0, 76.0, 79.0, 84.0]
	var music: float = 0.0
	for i: int in notes.size():
		var local: float = t - i * 0.12
		if local < 0.0:
			continue
		var decay: float = 9.0 if i < notes.size() - 1 else 4.0
		music += Synth.triangle(Synth.midi_hz(notes[i]) * local) * Synth.pluck(local, 0.01, decay)
	return 0.13 * music
