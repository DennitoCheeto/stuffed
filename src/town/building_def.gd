class_name BuildingDef
extends Resource
## A town building (spec 03 §6): its name, what it does, its 3 levels with costs, and its felt
## colours. Tune it in data/town/buildings/*.tres, not in code. What the levels actually change in
## a run comes with the building's own ticket (M3-06 ... M3-10).

@export var id: StringName = &""
@export var display_name: String = ""
## What it does, in one short line (on the sign).
@export var summary: String = ""
## Level 1 (the rebuild), 2 and 3.
@export var levels: Array[BuildingLevel] = []
@export var wall_color: Color = Color("#e6dcc8")
@export var roof_color: Color = Color("#6f8fb8")


func max_level() -> int:
	return levels.size()


## The level-up from `level` to `level + 1` (null when it's already at the top).
func next(level: int) -> BuildingLevel:
	if level < 0 or level >= levels.size():
		return null
	return levels[level]


## What it does at `level` (0 = still a ruin: nothing).
func effect_at(level: int) -> String:
	if level <= 0 or level > levels.size():
		return ""
	return levels[level - 1].effect
