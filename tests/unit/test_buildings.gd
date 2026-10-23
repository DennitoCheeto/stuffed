extends GutTest
## The town buildings' data and the rules for paying for them (spec 03 §5, §6, AC-42).

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const BUILDINGS_DIR: String = "res://data/town/buildings/"
## A first run brings home a few hundred coins (a long one ~1.2k, PO 2026-10-23): it pays for
## the first building, but not for several (prices raised on the PO's request).
const FIRST_RUN_COINS: int = 300


func _defs() -> Array[BuildingDef]:
	var result: Array[BuildingDef] = []
	for spot: TownSpot in LAYOUT.spots:
		result.append(spot.building)
	return result


func test_every_spot_has_its_building_from_the_buildings_folder() -> void:
	var files: int = 0
	for file: String in DirAccess.get_files_at(BUILDINGS_DIR):
		if file.ends_with(".tres"):
			files += 1
	assert_eq(files, 6, "one data file per building")
	for spot: TownSpot in LAYOUT.spots:
		assert_not_null(spot.building, "%s has a building" % spot.id)
		if spot.building == null:
			continue
		assert_eq(spot.building.id, spot.id)
		assert_true(spot.building.resource_path.begins_with(BUILDINGS_DIR), "%s in data" % spot.id)
		assert_ne(spot.building.summary, "", "%s says what it does" % spot.id)


func test_three_levels_coins_then_stuffing_then_thread() -> void:
	for def: BuildingDef in _defs():
		assert_eq(def.max_level(), 3, "%s has 3 levels" % def.id)
		var rebuild: BuildingLevel = def.levels[0]
		assert_gt(rebuild.coins, 0, "%s rebuild costs coins" % def.id)
		assert_eq(rebuild.cost().keys(), ["coins"], "%s rebuild costs only coins" % def.id)
		assert_gt(def.levels[1].stuffing, 0, "%s level 2 adds stuffing" % def.id)
		assert_eq(def.levels[1].thread, 0, "%s level 2 needs no thread yet" % def.id)
		assert_gt(def.levels[2].thread, 0, "%s level 3 adds thread" % def.id)
		for i: int in 3:
			assert_ne(def.levels[i].effect, "", "%s level %d says what it does" % [def.id, i + 1])
			if i > 0:
				assert_gt(def.levels[i].coins, def.levels[i - 1].coins, "%s costs rise" % def.id)


func test_the_first_building_comes_after_one_short_run() -> void:
	var cheapest: int = 1 << 30
	for spot: TownSpot in LAYOUT.spots:
		if not spot.starts_locked():
			cheapest = mini(cheapest, spot.building.levels[0].coins)
	assert_lte(cheapest, FIRST_RUN_COINS, "a first run pays for one (P-16)")
	assert_gte(cheapest, 150, "but not for several at once")


func test_the_jars_pay_only_when_they_hold_enough() -> void:
	var town: TownSave = TownSave.new()
	town.materials = {"coins": 150, "stuffing": 4}
	var cost: Dictionary[String, int] = {"coins": 100, "stuffing": 10}
	assert_false(town.can_afford(cost))
	assert_eq(town.missing(cost), {"stuffing": 6} as Dictionary[String, int])
	assert_false(town.spend(cost), "not enough stuffing")
	assert_eq(town.material("coins"), 150, "nothing taken")
	town.materials["stuffing"] = 10
	assert_true(town.spend(cost))
	assert_eq(town.material("coins"), 50)
	assert_eq(town.material("stuffing"), 0)


func test_missing_amounts_read_naturally() -> void:
	var one: Dictionary[String, int] = {"stuffing": 40}
	assert_eq(BuildingCard.missing_text(one), "Needs 40 more stuffing")
	var two: Dictionary[String, int] = {"thread": 5, "coins": 40}
	assert_eq(BuildingCard.missing_text(two), "Needs 40 more coins and 5 more thread")


func test_level_names() -> void:
	assert_eq(BuildingCard.level_text(0, 3), "Ruin")
	assert_eq(BuildingCard.level_text(2, 3), "Level 2 of 3")
	assert_eq(BuildingCard.level_text(3, 3), "Level 3 of 3 (max)")


func test_the_fort_grows_every_3_rebuilds_or_upgrades() -> void:
	assert_eq(LAYOUT.fort_piece_every, 3)
	var town: TownSave = TownSave.new()
	assert_eq(TownFort.pieces_for(town.total_levels(), 3), 0)
	town.building_levels = {"toy_box_armory": 2, "lucky_jar": 1}
	assert_eq(town.total_levels(), 3)
	assert_eq(TownFort.pieces_for(town.total_levels(), 3), 1)
	assert_eq(TownFort.pieces_for(17, 3), 5)
	assert_eq(TownFort.pieces_for(18, 3), TownFort.PIECES.size(), "all 6 buildings at level 3")
	assert_eq(TownFort.pieces_for(99, 3), TownFort.PIECES.size(), "capped")
