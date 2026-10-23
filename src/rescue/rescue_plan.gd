class_name RescuePlan
extends RefCounted
## The rescue of one run (spec 03 §7): which plushie waits in the Bedroom and when it shows up.

var plushie: PlushieDef
## Run time (seconds) the tangled plushie appears.
var at_seconds: float = 0.0


func _init(who: PlushieDef, at: float) -> void:
	plushie = who
	at_seconds = at
