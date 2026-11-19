class_name MusicRules
extends Resource
## Every piece of music and how it behaves (spec 10 §4.1): one looping track per place, the
## stingers, the crossfade and when the run's layers grow. Lives in
## data/audio/music/music_rules.tres.

## Looping tracks: title, town, run, boss, siege, endless.
@export var tracks: Array[MusicTrack] = []
## One-shot stingers: goal, hero_died, siege_won, siege_lost, evolution.
@export var stingers: Array[MusicTrack] = []
## A change of place fades the old track out and the new one in over this long.
@export var crossfade_seconds: float = 1.0
## A layer joining or leaving fades over this long.
@export var layer_fade_seconds: float = 2.0
## The whole music's loudness (before the Music slider).
@export_range(0.0, 1.0) var loudness: float = 0.5
@export_range(0.0, 1.0) var stinger_loudness: float = 0.6
## Run: the second layer level (drums) joins after this many seconds ...
@export var run_drums_seconds: float = 120.0
## ... or as soon as this many zombies are on screen.
@export var run_drums_crowd: int = 150
## Run: everything plays after this many seconds.
@export var run_full_seconds: float = 300.0
## How often the run checks time and crowd.
@export var check_seconds: float = 0.5


func track(id: StringName) -> MusicTrack:
	for one: MusicTrack in tracks:
		if one.id == id:
			return one
	return null


func stinger(id: StringName) -> MusicTrack:
	for one: MusicTrack in stingers:
		if one.id == id:
			return one
	return null


## The run's intensity level at `seconds` with `crowd` zombies on screen (0, 1 or 2).
func run_level(seconds: float, crowd: int) -> int:
	if seconds >= run_full_seconds:
		return 2
	if seconds >= run_drums_seconds or crowd >= run_drums_crowd:
		return 1
	return 0


## The siege's intensity level during wave `wave` (0 = the first): busier each wave.
func siege_level(wave: int) -> int:
	return clampi(wave, 0, 2)
