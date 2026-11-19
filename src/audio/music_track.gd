class_name MusicTrack
extends Resource
## A piece of music made in code (spec 10 §4.1): tempo, one chord root per bar and the instrument
## layers (`MusicLayer`). A looping track is rendered once into one clip per layer that loops
## seamlessly; a stinger (`loops` false) plays once over the music.

const STEPS_PER_BAR: int = 16
## Chord tones above the root for a chord tone index 0-7 (major / minor third).
const MAJOR_TONES: PackedInt32Array = [0, 4, 7, 12, 16, 19, 24, 28]
const MINOR_TONES: PackedInt32Array = [0, 3, 7, 12, 15, 19, 24, 27]

@export var id: StringName = &""
@export var bpm: float = 120.0
## One chord root per bar (MIDI note numbers, 60 = middle C).
@export var roots: PackedInt32Array = [60, 57, 53, 55]
## Pitch classes whose chords are minor (9 = A, 2 = D, 4 = E: the minor chords of C major).
@export var minor_roots: PackedInt32Array = [9, 2, 4]
@export var layers: Array[MusicLayer] = []
## False for a stinger: it plays once.
@export var loops: bool = true


func step_seconds() -> float:
	return 15.0 / bpm


func step_count() -> int:
	return roots.size() * STEPS_PER_BAR


## How long one pass of the track takes (a stinger rings a bit longer, see `MusicRender`).
func seconds() -> float:
	return step_count() * step_seconds()


## The MIDI notes `layer` plays for pattern character `symbol` in bar `bar` (empty = none).
func notes_for(layer: MusicLayer, bar: int, symbol: String) -> PackedInt32Array:
	var bar_root: int = roots[bar % roots.size()]
	var tones: PackedInt32Array = MINOR_TONES if minor_roots.has(bar_root % 12) else MAJOR_TONES
	var root: int = bar_root + layer.octave
	if symbol == "." or symbol == " ":
		return PackedInt32Array()
	if layer.is_drum():
		return PackedInt32Array([root])
	if layer.instrument == MusicLayer.Instrument.CHORDS:
		return PackedInt32Array([root + tones[0], root + tones[1], root + tones[2]])
	var index: int = int(symbol) if symbol.is_valid_int() else 0
	return PackedInt32Array([root + tones[clampi(index, 0, tones.size() - 1)]])


## The highest intensity level any layer waits for.
func top_level() -> int:
	var top: int = 0
	for layer: MusicLayer in layers:
		top = maxi(top, layer.level)
	return top
