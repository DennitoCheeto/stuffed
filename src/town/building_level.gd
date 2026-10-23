class_name BuildingLevel
extends Resource
## One level of a town building (spec 03 §6): what it costs to reach it and what the building
## does at this level. Level 1 is the rebuild (coins), level 2 adds stuffing, level 3 thread.

@export var coins: int = 0
@export var stuffing: int = 0
@export var thread: int = 0
## What the building does at this level, in a few words ("+20% pickup range").
@export var effect: String = ""


## Material id -> amount, only the materials this level needs.
func cost() -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for pair: Array in [["coins", coins], ["stuffing", stuffing], ["thread", thread]]:
		if int(pair[1]) > 0:
			result[str(pair[0])] = int(pair[1])
	return result
