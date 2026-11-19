class_name SfxRules
extends Resource
## How sound effects play (spec 10 §4.2): voice limits and variation. Tune them in
## data/audio/sfx_rules.tres. The sounds themselves are made in code by SfxBank.

## Sounds that may play at the same time, per sound (the rest are skipped).
@export var voices: Dictionary[StringName, int] = {}
## Voice limit for sounds not listed in `voices`.
@export var default_voices: int = 3
## New starts of one sound in a single frame: 300 deaths at once stay one big "pop", not a
## crackle of 300 stacked voices.
@export var starts_per_frame: int = 2
## Random pitch change of every sound (0.08 = up to 8% higher or lower).
@export var pitch_variation: float = 0.08
## The frequent sounds (hit, death, XP, level-up voices, dash, coin, own shots, hurt): they vary
## more, in pitch and in volume, so a hundred of them never sound like a machine gun.
@export var varied: Array[StringName] = []
@export var varied_pitch: float = 0.12
## Own pitch range for a few sounds (the XP chain climbs in small steps, so it varies less).
@export var pitch_overrides: Dictionary[StringName, float] = {}
## The frequent sounds play up to this many dB quieter (never louder).
@export var varied_volume_db: float = 3.0


func max_voices(sound: StringName) -> int:
	return voices.get(sound, default_voices)


func pitch_range(sound: StringName) -> float:
	if pitch_overrides.has(sound):
		return pitch_overrides[sound]
	return varied_pitch if varied.has(sound) else pitch_variation


func volume_drop(sound: StringName) -> float:
	return varied_volume_db if varied.has(sound) else 0.0
