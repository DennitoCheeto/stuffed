class_name MaterialReward
extends Resource
## Materials one source gives (spec 03 §3): a zombie type, elites, a boss, a gift box or the
## victory bonus. Tune them in data/town/material_rules.tres, not in code.

## What gives it: a zombie's base name ("Tank", "Big Ted", ...) or a label for the rest.
@export var source: String = ""
@export var coins: int = 0
@export var stuffing: int = 0
## Chance (0-1) that the stuffing comes with it; 1 = always.
@export_range(0.0, 1.0) var stuffing_chance: float = 1.0
@export var thread: int = 0


## Material id -> amount for one kill / box / win (only materials above 0).
func roll(rng: RandomNumberGenerator) -> Dictionary[String, int]:
	var amounts: Dictionary[String, int] = {}
	if coins > 0:
		amounts["coins"] = coins
	if stuffing > 0 and (stuffing_chance >= 1.0 or rng.randf() < stuffing_chance):
		amounts["stuffing"] = stuffing
	if thread > 0:
		amounts["thread"] = thread
	return amounts
