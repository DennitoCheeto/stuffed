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
## Extra rerolls, skips and banishes per run (Lucky Jar).
var extra_card_uses: int = 0
## Extra pickup range as a share of the hero's own (0.2 = +20%, Watchtower).
var pickup_range_bonus: float = 0.0
## Extra max health (Snack Bar).
var max_health_bonus: float = 0.0
## How much shorter the wait between floor pickups is, as a share (Party Shop).
var pickup_gap_cut: float = 0.0
## Run time the first floor pickup is due (0 = the normal first drop time, Party Shop Lv 3).
var first_pickup_at: float = 0.0


## The perks of the town in `save`, with the buildings standing on the spots of `layout`.
static func from_save(save: TownSave, layout: TownLayout) -> TownPerks:
	var perks: TownPerks = TownPerks.new()
	for spot: TownSpot in layout.spots:
		var level: int = save.building_level(String(spot.id))
		perks.locked_weapons.append_array(spot.building.locked_weapons_at(level))
		if spot.building.chooses_start_weapon(level):
			perks.can_choose_start_weapon = true
		var reached: BuildingLevel = spot.building.reached(level)
		if reached != null:
			perks.extra_card_uses += reached.extra_card_uses
			perks.pickup_range_bonus += reached.pickup_range_bonus
			perks.max_health_bonus += reached.max_health_bonus
			perks.pickup_gap_cut += reached.pickup_gap_cut
			if reached.first_pickup_at > 0.0:
				perks.first_pickup_at = _earliest(perks.first_pickup_at, reached.first_pickup_at)
	var chosen: StringName = StringName(save.start_weapon)
	if perks.can_choose_start_weapon and not perks.locked_weapons.has(chosen):
		perks.start_weapon = chosen
	return perks


## The earlier of two first-drop times, where 0 means "not set".
static func _earliest(current: float, other: float) -> float:
	return other if current <= 0.0 else minf(current, other)


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
