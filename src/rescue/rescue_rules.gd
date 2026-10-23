class_name RescueRules
extends Resource
## Rescued plushies in the run (spec 03 §7): which runs have one, when it appears, where, and how
## long freeing it takes. Tune it in data/town/rescue_rules.tres, not in code.

## Every plushie that can be rescued, in the order they are offered.
@export var plushies: Array[PlushieDef] = []
## Runs before this one never have a rescue (run 1 = the first run of a town).
@export var first_run: int = 2
## How likely a run from `first_run` on has a rescue (0.5 = about one run in two).
@export var chance: float = 0.5
## The tangled plushie appears at a random run time between these two (seconds).
@export var earliest_seconds: float = 120.0
@export var latest_seconds: float = 360.0
## Standing next to it this long (seconds) frees it.
@export var fill_seconds: float = 3.0
## A player whose middle is this close to the plushie's middle stands next to it (pixels).
@export var stand_radius: float = 72.0
## It appears this far from the players (pixels, picked at random in between), usually off screen.
@export var min_distance: float = 900.0
@export var max_distance: float = 1500.0
## It keeps at least this far from the walls (pixels).
@export var wall_margin: float = 140.0
## Banner when it appears and when it is freed ("%s" = the plushie's name).
@export var help_banner: String = "A plushie needs help!"
@export var help_subtitle: String = "Follow the arrow and stand next to it"
@export var freed_banner: String = "%s is safe!"
@export var freed_subtitle: String = "In your backpack: it comes home even if you fall"
@export var banner_seconds: float = 2.5
## The one "help!" squeak when it appears, and the happy sound when it is freed.
@export var help_sound: StringName = &"help"
@export var freed_sound: StringName = &"rescued"


## The rescue for run number `run_number`, or null if this run has none. Plushies in
## `already_rescued` (ids) never come again; once all are home there are no more rescues.
func plan(
	run_number: int, already_rescued: PackedStringArray, rng: RandomNumberGenerator
) -> RescuePlan:
	if run_number < first_run:
		return null
	if rng.randf() >= chance:
		return null
	var who: PlushieDef = pick_plushie(already_rescued, rng)
	if who == null:
		return null
	return RescuePlan.new(who, rng.randf_range(earliest_seconds, latest_seconds))


## A random plushie not in `already_rescued`, or null when all of them are home.
func pick_plushie(already_rescued: PackedStringArray, rng: RandomNumberGenerator) -> PlushieDef:
	var left: Array[PlushieDef] = []
	for plushie: PlushieDef in plushies:
		if not already_rescued.has(plushie.id):
			left.append(plushie)
	if left.is_empty():
		return null
	return left[rng.randi_range(0, left.size() - 1)]


func find(id: String) -> PlushieDef:
	for plushie: PlushieDef in plushies:
		if plushie.id == id:
			return plushie
	return null
