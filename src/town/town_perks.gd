class_name TownPerks
extends RefCounted
## What the town's buildings change in the next run (spec 03 §6, AC-43), worked out from the
## save and the buildings' data. Main hands it to every run. A run without a town (a fresh
## TownPerks) has every weapon on the cards and Banane's own starting weapon.

## Weapons (upgrade pool ids) that never come up on level-up cards yet (Toy Box Armory).
var locked_weapons: Array[StringName] = []
## The ones of them that wait for their hero (spec 08 §3): their recipes stay off the Recipes page
## too (spec 10 §3, AC-107).
var locked_hero_weapons: Array[StringName] = []
## True once the player may choose Banane's starting weapon (Toy Box Armory Lv 3).
var can_choose_start_weapon: bool = false
## The chosen starting weapon (an upgrade pool id; "" = the hero's own).
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
## The bought building tricks (spec 06), branch by branch. Town-wide: every hero gets them.
var tricks: Array[TrickDef] = []
## Plushie Buddy: the id of the plushie rescued last ("" = none yet).
var buddy: String = ""
## The hero each player slot plays (spec 08), slot 0 = player 1. Empty = the hero scene's own.
var heroes: Array[HeroStats] = []
## Sewing patterns the town owns (gear ids, spec 09 §4): they never drop in a run again.
var patterns: PackedStringArray = []
## What each player slot wears (spec 09 §8), by player index.
var worn: Array[WornGear] = []


## The perks of the town in `save`, with the buildings standing on the spots of `layout`.
static func from_save(save: TownSave, layout: TownLayout) -> TownPerks:
	var perks: TownPerks = TownPerks.new()
	for spot: TownSpot in layout.spots:
		var level: int = _working_level(save, spot)
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
	for spot: TownSpot in layout.spots:
		if save.is_damaged(String(spot.id)):
			continue
		for trick: TrickDef in spot.building.tricks:
			if save.has_trick(String(trick.id)):
				perks.tricks.append(trick)
	perks.buddy = save.last_rescued
	perks.patterns = save.gear.patterns.duplicate()
	perks.heroes = HeroRoster.current().heroes_for(save, HeroRoster.MAX_PLAYERS)
	for index: int in HeroRoster.MAX_PLAYERS:
		perks.worn.append(WornGear.of(save, index))
	# A hero's new weapon joins the cards once that hero is unlocked (spec 08 §3).
	for hero: HeroStats in HeroRoster.current().heroes:
		if hero.unlocks_weapon != null and not HeroRoster.current().is_unlocked(hero, save):
			perks.locked_weapons.append(hero.unlocks_weapon.id)
			perks.locked_hero_weapons.append(hero.unlocks_weapon.id)
	var chosen: StringName = StringName(save.start_weapon)
	if perks.can_choose_start_weapon and not perks.locked_weapons.has(chosen):
		perks.start_weapon = chosen
	return perks


## What player `index` wears (nothing in a run without a town).
func gear(index: int) -> WornGear:
	return worn[index] if index < worn.size() else WornGear.new()


## The hero player `index` plays (null = keep the hero scene's own, Banane).
func hero(index: int) -> HeroStats:
	return heroes[index] if index < heroes.size() else null


## The level whose bonuses work in runs: a building a lost siege damaged gives nothing until it
## is repaired (spec 07 §6, AC-80), as if it were still a ruin.
static func _working_level(save: TownSave, spot: TownSpot) -> int:
	if save.is_damaged(String(spot.id)):
		return 0
	return save.building_level(String(spot.id))


## The earlier of two first-drop times, where 0 means "not set".
static func _earliest(current: float, other: float) -> float:
	return other if current <= 0.0 else minf(current, other)


## For the night siege (spec 07 §4): only the tricks that make sense there stay on (Bedroom-only
## ones, `TrickDef.in_siege` false, are off), and no Plushie Buddy comes along.
func keep_siege_tricks() -> void:
	var kept: Array[TrickDef] = []
	for bought: TrickDef in tricks:
		if bought.in_siege:
			kept.append(bought)
	tricks = kept
	if not has_trick(&"plushie_buddy"):
		buddy = ""


## The bought trick `id` (null = not bought).
func trick(id: StringName) -> TrickDef:
	for bought: TrickDef in tricks:
		if bought.id == id:
			return bought
	return null


func has_trick(id: StringName) -> bool:
	return trick(id) != null


## The ids of the bought tricks (run log, dev menu).
func trick_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for bought: TrickDef in tricks:
		ids.append(String(bought.id))
	return ids


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
