class_name BuildingDef
extends Resource
## A town building (spec 03 §6): its name, what it does, its 3 levels with costs, and its felt
## colours. Tune it in data/town/buildings/*.tres, not in code. What the levels change in a run
## is gathered in TownPerks.

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


## Weapons this building still keeps off the cards at `level` (those of the levels above it).
func locked_weapons_at(level: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for index: int in range(maxi(level, 0), levels.size()):
		result.append_array(levels[index].unlocks_weapons)
	return result


## True when the building at `level` lets the player choose Banane's starting weapon.
func chooses_start_weapon(level: int) -> bool:
	for index: int in mini(level, levels.size()):
		if levels[index].start_weapon_choice:
			return true
	return false
