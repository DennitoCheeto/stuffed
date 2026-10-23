class_name TownPerks
extends RefCounted
## What the town's buildings change in the next run (spec 03 §6, AC-43), worked out from the
## save and the buildings' data. Main hands it to every run. A run without a town (a fresh
## TownPerks) has every weapon on the cards and Banane's own starting weapon.

## Weapons (upgrade pool ids) that never come up on level-up cards yet (Toy Box Armory).
var locked_weapons: Array[StringName] = []
## True once the player may choose Banane's starting weapon (Toy Box Armory Lv 3).
var can_choose_start_weapon: bool = false
## The chosen starting weapon (an upgrade pool id; "" = Banane's own).
var start_weapon: StringName = &""


## The perks of the town in `save`, with the buildings standing on the spots of `layout`.
static func from_save(save: TownSave, layout: TownLayout) -> TownPerks:
	var perks: TownPerks = TownPerks.new()
	for spot: TownSpot in layout.spots:
		var level: int = save.building_level(String(spot.id))
		perks.locked_weapons.append_array(spot.building.locked_weapons_at(level))
		if spot.building.chooses_start_weapon(level):
			perks.can_choose_start_weapon = true
	var chosen: StringName = StringName(save.start_weapon)
	if perks.can_choose_start_weapon and not perks.locked_weapons.has(chosen):
		perks.start_weapon = chosen
	return perks


## The weapons of `pool` that can come up on cards (in pool order).
func open_weapons(pool: UpgradePool) -> Array[UpgradeDef]:
	var result: Array[UpgradeDef] = []
	for upgrade: UpgradeDef in pool.upgrades:
		if upgrade.kind == UpgradeDef.Kind.WEAPON and not locked_weapons.has(upgrade.id):
			result.append(upgrade)
	return result


## The weapon Banane starts with: the chosen one, or `own` (his hero's) if none is chosen.
func starting_weapon(pool: UpgradePool, own: WeaponStats) -> WeaponStats:
	if start_weapon == &"":
		return own
	var chosen: UpgradeDef = pool.find(start_weapon)
	if chosen == null or chosen.kind != UpgradeDef.Kind.WEAPON:
		return own
	return chosen.weapon
