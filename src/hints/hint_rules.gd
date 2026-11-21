class_name HintRules
extends Resource
## All first-time hints and how their notes behave (spec 10 §6, `data/ui/hints.tres`).

## Every hint, run and town ones.
@export var hints: Array[HintDef] = []
## A note that isn't done goes away after this many seconds (and shows once more next time).
@export var show_seconds: float = 8.0
## A note stays this long after the player did the thing, so it doesn't vanish mid-read.
@export var done_seconds: float = 0.6
## Seconds the note takes to fade in and out.
@export var fade_seconds: float = 0.25
## Distance of the note from the top or bottom edge of the screen, in px.
@export var edge_margin: float = 150.0
## The note keeps at least this far away from every hero on screen, in px.
@export var hero_margin: float = 90.0
## A save from before hints existed that already has a town knows these (spec 10 §9).
@export var basics: PackedStringArray = []
## The note's tilt in degrees (it alternates sides); notes wider than `tilt_width` px tilt less, so
## their far ends stay put.
@export var tilt_degrees: float = 1.5
@export var tilt_width: float = 400.0
@export var font_size: int = 30


## The hint with this id, null if there is none.
func find(id: String) -> HintDef:
	for hint: HintDef in hints:
		if hint.id == id:
			return hint
	return null
