class_name MaterialRules
extends Resource
## Which kills, boxes and wins give coins, stuffing and thread, and how much of a run's haul goes
## home (spec 03 §3). Tune it in data/town/material_rules.tres, not in code.

## Share kept after beating the King (endless included).
@export var keep_share_won: float = 1.0
## Share kept when going home through the Way Home portal.
@export var keep_share_way_home: float = 1.0
## Share kept after getting stuffed or giving up (also a run the game closed during).
@export var keep_share_lost: float = 0.5
## One reward per zombie type or boss, matched by its base name (`MaterialReward.source`).
@export var kills: Array[MaterialReward] = []
## For a zombie type without its own entry.
@export var other_kill: MaterialReward
## Added on top of the type's reward when the zombie was an elite.
@export var elite_extra: MaterialReward
@export var gift_box: MaterialReward
## The beaten boss's big gift box.
@export var big_gift_box: MaterialReward
## Added to the haul when the King is beaten.
@export var victory_bonus: MaterialReward


## The share of the haul a finished run takes home.
func keep_share(result: RunResult) -> float:
	if result.won:
		return keep_share_won
	if result.ending == "way_home":
		return keep_share_way_home
	return keep_share_lost


## The reward for killing a zombie of base type `type_name` (falls back to `other_kill`).
func kill_reward(type_name: String) -> MaterialReward:
	for reward: MaterialReward in kills:
		if reward.source == type_name:
			return reward
	return other_kill


## Material id -> amount for one kill (an `elite` gets `elite_extra` on top).
func for_kill(
	type_name: String, elite: bool, rng: RandomNumberGenerator
) -> Dictionary[String, int]:
	var amounts: Dictionary[String, int] = kill_reward(type_name).roll(rng)
	if elite:
		var extra: Dictionary[String, int] = elite_extra.roll(rng)
		for material: String in extra:
			amounts[material] = amounts.get(material, 0) + extra[material]
	return amounts


## Material id -> amount for opening a gift box.
func for_gift_box(big: bool, rng: RandomNumberGenerator) -> Dictionary[String, int]:
	return (big_gift_box if big else gift_box).roll(rng)
