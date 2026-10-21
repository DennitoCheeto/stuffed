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
## Weapon + partner item pairs that evolve at a gift box (spec 02 §5).
@export var evolutions: Array[EvolutionDef] = []

@export_group("Control over bad luck (per run)")
## Reroll (R): 3 new cards.
@export var rerolls_per_run: int = 3
## Skip (S): no card, a small heal instead.
@export var skips_per_run: int = 3
## Banish (B, then 1/2/3): that card never shows up again this run.
@export var banishes_per_run: int = 2
## A skip heals this share of max health (0.1 = 10%).
@export var skip_heal: float = 0.1


## Picks `count` cards (-1 = a full level-up) for one level-up. `levels` maps upgrade id →
## current level (0 or missing = not owned). Cards are all different, maxed upgrades are left
## out, new ones only while a slot is free, the chance of each card follows its weight, and
## missing slots become the snack. Upgrades in `excluded` never come up (banished cards);
## those in `avoid` only when nothing else is left (a reroll avoids the cards it replaces).
func roll(
	levels: Dictionary[StringName, int],
	rng: RandomNumberGenerator,
	excluded: Array[StringName] = [],
	avoid: Array[StringName] = [],
	count: int = -1
) -> Array[UpgradeOffer]:
	var wanted: int = cards_per_level_up if count < 0 else count
	var fresh: Array[UpgradeDef] = []
	var repeats: Array[UpgradeDef] = []
	for upgrade: UpgradeDef in _open(levels):
		if excluded.has(upgrade.id):
			continue
		if avoid.has(upgrade.id):
			repeats.append(upgrade)
		else:
			fresh.append(upgrade)
	var offers: Array[UpgradeOffer] = []
	for choices: Array[UpgradeDef] in [fresh, repeats]:
		while offers.size() < wanted and not choices.is_empty():
			var picked: UpgradeDef = choices.pop_at(_weighted_index(choices, rng))
			var offer: UpgradeOffer = UpgradeOffer.new(picked, int(levels.get(picked.id, 0)) + 1)
			offer.partner = partner_of(picked)
			offers.append(offer)
	while offers.size() < wanted:
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


## The evolution of weapon `weapon_id`, or null.
func evolution_of(weapon_id: StringName) -> EvolutionDef:
	for evolution: EvolutionDef in evolutions:
		if evolution.weapon == weapon_id:
			return evolution
	return null


## The evolution that makes the weapon `evolved_id`, or null.
func evolution_into(evolved_id: StringName) -> EvolutionDef:
	for evolution: EvolutionDef in evolutions:
		if evolution.evolved.id == evolved_id:
			return evolution
	return null


## The item a weapon card shows as its evolution partner, or null (items, the snack, weapons
## without an evolution yet).
func partner_of(upgrade: UpgradeDef) -> UpgradeDef:
	if upgrade.kind != UpgradeDef.Kind.WEAPON:
		return null
	var evolution: EvolutionDef = evolution_of(upgrade.id)
	return find(evolution.partner) if evolution != null else null


## The first evolution that is ready at `levels`: its weapon at the top level, its partner item
## owned, and not evolved yet. Null if none is.
func ready_evolution(levels: Dictionary[StringName, int]) -> EvolutionDef:
	for evolution: EvolutionDef in evolutions:
		var base: UpgradeDef = find(evolution.weapon)
		if base == null or levels.has(evolution.evolved.id):
			continue
		var weapon_level: int = levels.get(evolution.weapon, 0)
		if weapon_level >= base.top_level() and levels.get(evolution.partner, 0) > 0:
			return evolution
	return null


## Upgrades that could be offered at `levels`: not maxed, weighted, and new ones only while a
## slot of their kind is free.
func _open(levels: Dictionary[StringName, int]) -> Array[UpgradeDef]:
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
	return open


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
