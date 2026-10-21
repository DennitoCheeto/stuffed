class_name UpgradePool
extends Resource
## Everything that can be offered on level-up cards, and the rules for picking the cards.
## Tune it in data/upgrade_pool.tres.

@export var upgrades: Array[UpgradeDef] = []
## Fills empty card slots when fewer upgrades are left than cards.
@export var snack: UpgradeDef
@export var cards_per_level_up: int = 3
## Weapon slots per player. With all of them used, only owned weapons are offered.
@export var max_weapons: int = 6
## Item slots per player. With all of them used, only owned items are offered.
@export var max_items: int = 6


## Picks the cards for one level-up. `levels` maps upgrade id → current level (0 or missing =
## not owned). Cards are all different, maxed upgrades are left out, new ones only while a slot
## is free, the chance of each card follows its weight, and missing slots become the snack.
func roll(levels: Dictionary[StringName, int], rng: RandomNumberGenerator) -> Array[UpgradeOffer]:
	var weapons_full: bool = owned_count(levels, UpgradeDef.Kind.WEAPON) >= max_weapons
	var items_full: bool = owned_count(levels, UpgradeDef.Kind.ITEM) >= max_items
	var open: Array[UpgradeDef] = []
	for upgrade: UpgradeDef in upgrades:
		var level: int = levels.get(upgrade.id, 0)
		if level >= upgrade.top_level() or upgrade.weight <= 0.0:
			continue
		var full: bool = weapons_full if upgrade.kind == UpgradeDef.Kind.WEAPON else items_full
		if level == 0 and full:
			continue
		open.append(upgrade)
	var offers: Array[UpgradeOffer] = []
	while offers.size() < cards_per_level_up and not open.is_empty():
		var picked: UpgradeDef = open.pop_at(_weighted_index(open, rng))
		offers.append(UpgradeOffer.new(picked, int(levels.get(picked.id, 0)) + 1))
	while offers.size() < cards_per_level_up:
		offers.append(UpgradeOffer.new(snack, 1))
	return offers


## How many upgrades of `kind` are owned (level 1 or more) in `levels`.
func owned_count(levels: Dictionary[StringName, int], kind: UpgradeDef.Kind) -> int:
	var count: int = 0
	for upgrade: UpgradeDef in upgrades:
		if upgrade.kind == kind and levels.get(upgrade.id, 0) > 0:
			count += 1
	return count


## The upgrade with this id, or null.
func find(id: StringName) -> UpgradeDef:
	for upgrade: UpgradeDef in upgrades:
		if upgrade.id == id:
			return upgrade
	return null


func _weighted_index(choices: Array[UpgradeDef], rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for choice: UpgradeDef in choices:
		total += choice.weight
	var roll_at: float = rng.randf() * total
	for index: int in choices.size():
		roll_at -= choices[index].weight
		if roll_at < 0.0:
			return index
	return choices.size() - 1
