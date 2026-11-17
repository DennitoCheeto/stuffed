extends GutTest
## Night siege helpers (spec 07 §4, §7, AC-78, AC-83): the Snack Bar heals heroes in its ring
## 3 / 5 / 8 health per second, the Party Shop pops confetti every 8 / 6 / 4 s. Numbers live in
## data; their rings and confetti never use an enemy danger colour.

const SNACK_BAR: BuildingDef = preload("res://data/town/buildings/snack_bar.tres")
const PARTY_SHOP: BuildingDef = preload("res://data/town/buildings/party_shop.tres")
const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const OTHER_DEFS: Array[String] = ["toy_box_armory", "lucky_jar", "watchtower", "plush_hospital"]


func _heals(def: BuildingDef) -> Array[float]:
	var result: Array[float] = []
	for level: BuildingLevel in def.levels:
		result.append(level.siege_heal)
	return result


func _trap_seconds(def: BuildingDef) -> Array[float]:
	var result: Array[float] = []
	for level: BuildingLevel in def.levels:
		result.append(level.siege_trap_seconds)
	return result


func _spot(id: StringName) -> TownSpot:
	for spot: TownSpot in LAYOUT.spots:
		if spot.id == id:
			return spot
	return null


func test_the_snack_bar_heals_3_5_8_per_second() -> void:
	assert_eq(_heals(SNACK_BAR), [3.0, 5.0, 8.0] as Array[float])
	assert_eq(_trap_seconds(SNACK_BAR), [0.0, 0.0, 0.0] as Array[float], "no trap")


func test_the_party_shop_pops_every_8_6_4_seconds() -> void:
	assert_eq(_trap_seconds(PARTY_SHOP), [8.0, 6.0, 4.0] as Array[float])
	assert_eq(_heals(PARTY_SHOP), [0.0, 0.0, 0.0] as Array[float], "no healing")
	var last: float = 0.0
	for level: BuildingLevel in PARTY_SHOP.levels:
		assert_gt(level.siege_trap_damage, last, "each level hits harder")
		last = level.siege_trap_damage


func test_the_rings_reach_beyond_the_building() -> void:
	for def: BuildingDef in [SNACK_BAR, PARTY_SHOP]:
		var spot: TownSpot = _spot(def.id)
		assert_not_null(spot, String(def.id))
		if spot == null:
			continue
		var half_diagonal: float = spot.rect.size.length() / 2.0
		for level: BuildingLevel in def.levels:
			assert_gt(level.siege_range, half_diagonal + 50.0, "room to stand in: %s" % def.id)


func test_other_buildings_have_no_ring() -> void:
	for id: String in OTHER_DEFS:
		var def: BuildingDef = load("res://data/town/buildings/%s.tres" % id) as BuildingDef
		assert_eq(_heals(def), [0.0, 0.0, 0.0] as Array[float], id)
		assert_eq(_trap_seconds(def), [0.0, 0.0, 0.0] as Array[float], id)


func test_ac83_rings_and_confetti_are_calm_colours() -> void:
	assert_false(UiColors.is_danger(RULES.heal_ring_color), "healing ring")
	assert_false(UiColors.is_danger(RULES.trap_ring_color), "trap ring")
	for color: Color in ConfettiBlast.COLORS:
		assert_false(UiColors.is_danger(color), "confetti %s" % color.to_html())


func test_the_trap_has_its_own_tally_row() -> void:
	var tally: WeaponTally = WeaponTally.new()
	tally.add_other(WeaponTally.PARTY_SHOP, 20.0, true)
	var row: WeaponTallyEntry = tally.find(-1, WeaponTally.PARTY_SHOP)
	assert_not_null(row)
	if row == null:
		return
	assert_eq(row.display_name, "Party Shop")
	assert_eq(row.kills, 1)
