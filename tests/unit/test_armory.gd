extends GutTest
## Toy Box Armory rules (spec 03 §6, AC-43): which weapons are on the level-up cards at each
## level, and the starting weapon choice at level 3. Numbers and ids come from data.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const ARMORY: String = "toy_box_armory"
const START_WEAPONS: Array[StringName] = [
	&"peel_boomerang",
	&"sewing_pin_sniper",
	&"orbiting_needles",
	&"button_shotgun",
	&"stuffing_cloud",
	&"yarn_cannon",
]
const LEVEL_1: Array[StringName] = [&"bouncy_yarn_ball", &"thimble_mortar"]
const LEVEL_2: Array[StringName] = [&"thread_whip", &"zipper_ray"]


func _open_ids(armory_level: int, start_weapon: String = "") -> Array[StringName]:
	var save: TownSave = TownSave.new()
	save.building_levels[ARMORY] = armory_level
	save.start_weapon = start_weapon
	var ids: Array[StringName] = []
	for weapon: UpgradeDef in TownPerks.from_save(save, LAYOUT).open_weapons(POOL):
		ids.append(weapon.id)
	return ids


func _perks(armory_level: int, start_weapon: String) -> TownPerks:
	var save: TownSave = TownSave.new()
	save.building_levels[ARMORY] = armory_level
	save.start_weapon = start_weapon
	return TownPerks.from_save(save, LAYOUT)


func test_ac43_a_new_save_has_the_6_starting_weapons_on_the_cards() -> void:
	var ids: Array[StringName] = _open_ids(0)
	assert_eq(ids.size(), 6)
	for id: StringName in START_WEAPONS:
		assert_has(ids, id)


func test_ac43_level_1_adds_yarn_ball_and_mortar_level_2_whip_and_ray() -> void:
	var one: Array[StringName] = _open_ids(1)
	assert_eq(one.size(), 8)
	for id: StringName in LEVEL_1:
		assert_has(one, id)
	for id: StringName in LEVEL_2:
		assert_does_not_have(one, id, "not before level 2")
	var two: Array[StringName] = _open_ids(2)
	assert_eq(two.size(), 10, "every weapon")
	for id: StringName in LEVEL_2:
		assert_has(two, id)
	assert_eq(_open_ids(3).size(), 10)


func test_every_unlock_names_a_weapon_in_the_pool() -> void:
	for spot: TownSpot in LAYOUT.spots:
		for level: BuildingLevel in spot.building.levels:
			for id: StringName in level.unlocks_weapons:
				var weapon: UpgradeDef = POOL.find(id)
				assert_not_null(weapon, "%s is in the pool" % id)
				if weapon != null:
					assert_eq(weapon.kind, UpgradeDef.Kind.WEAPON, "%s is a weapon" % id)


func test_a_fresh_run_without_a_town_has_every_weapon() -> void:
	assert_eq(TownPerks.new().open_weapons(POOL).size(), 10)


func test_locked_weapons_never_come_up_on_cards() -> void:
	var perks: TownPerks = _perks(0, "")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var levels: Dictionary[StringName, int] = {}
	for i: int in 300:
		for offer: UpgradeOffer in POOL.roll(levels, rng, perks.locked_weapons):
			assert_does_not_have(perks.locked_weapons, offer.upgrade.id)


func test_ac43_the_starting_weapon_choice_needs_level_3() -> void:
	var own: WeaponStats = POOL.find(&"peel_boomerang").weapon
	var mortar: WeaponStats = POOL.find(&"thimble_mortar").weapon
	assert_false(_perks(2, "thimble_mortar").can_choose_start_weapon)
	assert_eq(_perks(2, "thimble_mortar").starting_weapon(POOL, own), own, "not before level 3")
	assert_true(_perks(3, "thimble_mortar").can_choose_start_weapon)
	assert_eq(_perks(3, "thimble_mortar").starting_weapon(POOL, own), mortar)
	assert_eq(_perks(3, "").starting_weapon(POOL, own), own, "nothing chosen: his own")
	assert_eq(_perks(3, "quick_feet").starting_weapon(POOL, own), own, "items can't be chosen")
	assert_eq(_perks(3, "nonsense").starting_weapon(POOL, own), own)
