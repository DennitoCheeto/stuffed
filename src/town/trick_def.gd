class_name TrickDef
extends Resource
## One building trick (spec 06 §3): a small skill bought with materials that changes how every
## run plays. Each building lists its 3 tricks in order (BuildingDef.tricks); tune them in
## data/town/tricks/*.tres, not in code. What a trick does in a run is keyed by its `id`.

@export var id: StringName = &""
@export var display_name: String = ""
## What it does, in one short line (on its patch in the Tricks panel).
@export var text: String = ""
## The building level it needs (1, 2 or 3; the 3rd trick of a branch is the star trick).
@export var needs_level: int = 1
## The trick's number, if it has one (its meaning is per trick: Head Start = the starting
## weapon's level, Second Toy = how many extra weapons). Tune it here, not in code.
@export var amount: float = 0.0
@export var coins: int = 0
@export var stuffing: int = 0
@export var thread: int = 0


## True for the last trick of a branch (needs the building at its top level).
func is_star() -> bool:
	return needs_level >= 3


## Material id -> amount, only the materials this trick needs.
func cost() -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for pair: Array in [["coins", coins], ["stuffing", stuffing], ["thread", thread]]:
		if int(pair[1]) > 0:
			result[str(pair[0])] = int(pair[1])
	return result
