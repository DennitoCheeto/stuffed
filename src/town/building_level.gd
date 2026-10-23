class_name BuildingLevel
extends Resource
## One level of a town building (spec 03 §6): what it costs to reach it and what the building
## does at this level. Level 1 is the rebuild (coins), level 2 adds stuffing, level 3 thread.

@export var coins: int = 0
@export var stuffing: int = 0
@export var thread: int = 0
## What the building does at this level, in a few words ("+20% pickup range").
@export var effect: String = ""
## Weapons (upgrade pool ids) this level adds to the level-up cards (Toy Box Armory). Weapons
## listed on any building level stay off the cards until that level is reached.
@export var unlocks_weapons: Array[StringName] = []
## From this level on, the player can choose Banane's starting weapon (Toy Box Armory Lv 3).
@export var start_weapon_choice: bool = false
## Extra rerolls, skips and banishes per run at this level, in total (Lucky Jar).
@export var extra_card_uses: int = 0
## Extra pickup range at this level, in total, as a share of the hero's own (0.2 = +20%,
## Watchtower).
@export var pickup_range_bonus: float = 0.0
## Extra max health at this level, in total (Snack Bar).
@export var max_health_bonus: float = 0.0


## Material id -> amount, only the materials this level needs.
func cost() -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for pair: Array in [["coins", coins], ["stuffing", stuffing], ["thread", thread]]:
		if int(pair[1]) > 0:
			result[str(pair[0])] = int(pair[1])
	return result
