class_name PlushieDef
extends Resource
## One plushie that can be rescued in a run (spec 03 §7) and later lives in town. The look is a
## simple placeholder until the product owner sends photos of the real plushies (M3-10).
## One file per plushie in data/town/plushies/.

enum Ears { ROUND, LONG, POINTY, NONE }

## Saved in the town (TownSave.plushies) and in the run log, e.g. "bunny". Never change it.
@export var id: String = ""
## The name tag, e.g. "Bunny".
@export var display_name: String = ""
@export var body_color: Color = Color("#d9c7b0")
## Belly patch, inner ears and muzzle.
@export var accent_color: Color = Color("#f2e6d6")
@export var ears: Ears = Ears.ROUND
