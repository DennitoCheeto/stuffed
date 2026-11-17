extends GutTest
## Night siege turrets (spec 07 §4, AC-78): the Toy Box Armory fires the hero's starting weapon
## at Lv 1 / 3 / 5, the Watchtower a strong pin every 2 s → every second; numbers in data. A
## turret is a real weapon without a hero: it fires from its own spot and its damage gets the
## building's own row in the weapon tally.

const ARMORY_DEF: BuildingDef = preload("res://data/town/buildings/toy_box_armory.tres")
const TOWER_DEF: BuildingDef = preload("res://data/town/buildings/watchtower.tres")
const TOWER_PIN: WeaponStats = preload("res://data/siege/watchtower_pin.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")
const OTHER_DEFS: Array[String] = ["lucky_jar", "snack_bar", "party_shop", "plush_hospital"]


func _weapon_levels(def: BuildingDef) -> Array[int]:
	var result: Array[int] = []
	for level: BuildingLevel in def.levels:
		result.append(level.siege_weapon_level)
	return result


func test_the_armory_fires_the_starting_weapon_at_lv_1_3_5() -> void:
	assert_null(ARMORY_DEF.siege_weapon, "empty = the hero's starting weapon")
	assert_eq(_weapon_levels(ARMORY_DEF), [1, 3, 5] as Array[int])
	for level: BuildingLevel in ARMORY_DEF.levels:
		assert_gt(level.siege_range, 0.0)


func test_the_watchtower_fires_every_2_s_then_every_second() -> void:
	assert_eq(TOWER_DEF.siege_weapon, TOWER_PIN)
	assert_eq(_weapon_levels(TOWER_DEF), [1, 2, 3] as Array[int])
	assert_eq(TOWER_PIN.at_level(1).cooldown, 2.0)
	assert_eq(TOWER_PIN.at_level(3).cooldown, 1.0)
	assert_gt(TOWER_PIN.at_level(1).damage, SNIPER.at_level(1).damage * 2.0, "strong pins")
	assert_gt(TOWER_DEF.levels[0].siege_range, ARMORY_DEF.levels[0].siege_range, "long range")


func test_other_buildings_are_no_turrets() -> void:
	for id: String in OTHER_DEFS:
		var def: BuildingDef = load("res://data/town/buildings/%s.tres" % id) as BuildingDef
		assert_eq(_weapon_levels(def), [0, 0, 0] as Array[int], id)


func test_a_mounted_weapon_fires_from_its_own_spot() -> void:
	var weapon: Weapon = TOWER_PIN.behaviour.new() as Weapon
	weapon.mount(TOWER_PIN, 9, 800.0, WeaponTally.WATCHTOWER)
	add_child_autofree(weapon)
	weapon.position = Vector2(300, 200)
	assert_true(weapon.is_turret())
	assert_eq(weapon.level, TOWER_PIN.max_level(), "level kept inside the weapon's levels")
	assert_eq(weapon.origin(), Vector2(300, 200))
	assert_eq(weapon.damage_scale(), 1.0)
	assert_eq(weapon.current().damage, TOWER_PIN.at_level(3).damage, "no hero bonuses")


func test_turret_damage_gets_the_buildings_row() -> void:
	var tally: WeaponTally = WeaponTally.new()
	var weapon: Weapon = TOWER_PIN.behaviour.new() as Weapon
	add_child_autofree(weapon)
	weapon.mount(TOWER_PIN, 1, 800.0, WeaponTally.WATCHTOWER)
	tally.add_hit(weapon, 40.0, true)
	var row: WeaponTallyEntry = tally.find(-1, WeaponTally.WATCHTOWER)
	assert_not_null(row)
	if row == null:
		return
	assert_eq(row.display_name, "Watchtower")
	assert_eq(row.damage, 40.0)
	assert_eq(row.kills, 1)
	assert_false(row.is_weapon)
	assert_eq(tally.total_damage, 40.0)
