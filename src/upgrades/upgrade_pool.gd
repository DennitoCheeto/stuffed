class_name UpgradePool
extends Resource
## Everything that can be offered on level-up cards, and the rules for picking the cards.
## Tune it in data/upgrade_pool.tres.

@export var upgrades: Array[UpgradeDef] = []
## Fills empty card slots when fewer upgrades are left than cards.
@export var snack: UpgradeDef
@export var cards_per_level_up: int = 3


## Picks the cards for one level-up. `levels` maps upgrade id → current level (0 or missing =
## not owned). Cards are all different, maxed upgrades are left out, and missing slots become
## the snack.
func roll(levels: Dictionary[StringName, int], rng: RandomNumberGenerator) -> Array[UpgradeOffer]:
	var open: Array[UpgradeDef] = []
	for upgrade: UpgradeDef in upgrades:
		if levels.get(upgrade.id, 0) < upgrade.top_level():
			open.append(upgrade)
	var offers: Array[UpgradeOffer] = []
	while offers.size() < cards_per_level_up and not open.is_empty():
		var picked: UpgradeDef = open.pop_at(rng.randi_range(0, open.size() - 1))
		offers.append(UpgradeOffer.new(picked, int(levels.get(picked.id, 0)) + 1))
	while offers.size() < cards_per_level_up:
		offers.append(UpgradeOffer.new(snack, 1))
	return offers
