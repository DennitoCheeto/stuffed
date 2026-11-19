class_name MusicLayer
extends Resource
## One instrument part of a `MusicTrack` (spec 10 §4.1): which instrument, a step pattern and when
## it joins in. The pattern has 16 steps per bar (sixteenth notes); longer patterns cover more
## bars and repeat. Step characters: "." rest; drums: "x" hit, "X" accented hit; bass: "x" the
## bar's root, "0"-"7" a chord tone; chords: "x" the whole chord; lead and bell: "x" / "0"-"7" a
## chord tone (0 root, 1 third, 2 fifth, 3 octave, 4-7 the same an octave up).

enum Instrument { KICK, SNARE, HAT, BASS, CHORDS, LEAD, BELL }

@export var instrument: Instrument = Instrument.LEAD
@export var steps: String = "x..............."
## Semitones up (or down) from the bar's root, which sits around middle C.
@export var octave: int = 0
@export_range(0.0, 1.0) var volume: float = 0.5
## Intensity level at which this layer plays (0 = always, 1 = second level, 2 = full).
@export_range(0, 2) var level: int = 0


## The pattern character at step `step` of the whole track ("." past a short pattern's end).
func step_char(step: int) -> String:
	if steps.is_empty():
		return "."
	return steps[step % steps.length()]


func is_drum() -> bool:
	return instrument in [Instrument.KICK, Instrument.SNARE, Instrument.HAT]
