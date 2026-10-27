extends GutTest
## Building tricks (spec 06 §3, §5, AC-66, AC-68): 3 tricks per building in data, the rules for
## buying them in order, and that the save keeps them.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const TRICKS_DIR: String = "res://data/town/tricks/"
const SAVE: String = "user://test_unit_tricks_save.json"


func after_all() -> void:
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _building(id: StringName) -> BuildingDef:
	for spot: TownSpot in LAYOUT.spots:
		if spot.id == id:
			return spot.building
	return null


## A town where the Snack Bar stands at `level` and the jars hold plenty.
func _rich_town(level: int) -> TownSave:
	var town: TownSave = TownSave.new()
	town.building_levels = {"snack_bar": level}
	town.materials = {"coins": 10000, "stuffing": 500, "thread": 100}
	return town


func test_ac66_every_building_has_a_branch_of_3_tricks_in_data() -> void:
	var files: int = 0
	for file: String in DirAccess.get_files_at(TRICKS_DIR):
		if file.ends_with(".tres"):
			files += 1
	assert_eq(files, 18, "one data file per trick")
	var ids: Dictionary[StringName, bool] = {}
	for spot: TownSpot in LAYOUT.spots:
		var def: BuildingDef = spot.building
		assert_eq(def.tricks.size(), 3, "%s has 3 tricks" % def.id)
		for i: int in def.tricks.size():
			var trick: TrickDef = def.tricks[i]
			assert_eq(trick.needs_level, i + 1, "%s needs Lv %d" % [trick.id, i + 1])
			assert_eq(trick.is_star(), i == 2, "%s: only the last one is the star" % trick.id)
			assert_true(trick.resource_path.begins_with(TRICKS_DIR), "%s in data" % trick.id)
			assert_ne(trick.display_name, "", "%s has a name" % trick.id)
			assert_ne(trick.text, "", "%s says what it does" % trick.id)
			assert_false(ids.has(trick.id), "%s is unique" % trick.id)
			ids[trick.id] = true
	assert_eq(TrickBook.all_tricks(LAYOUT).size(), 18)


func test_prices_rise_and_a_trick_is_cheaper_than_the_next_building_level() -> void:
	var total: int = 0
	for spot: TownSpot in LAYOUT.spots:
		var def: BuildingDef = spot.building
		for i: int in def.tricks.size():
			var trick: TrickDef = def.tricks[i]
			total += trick.coins
			assert_gt(trick.coins, 0, "%s costs coins" % trick.id)
			if i > 0:
				assert_gt(trick.coins, def.tricks[i - 1].coins, "%s costs more" % trick.id)
			if i + 1 < def.levels.size():
				var next: BuildingLevel = def.levels[i + 1]
				assert_lt(trick.coins, next.coins, "%s is cheaper than Lv %d" % [trick.id, i + 2])
		assert_gt(def.tricks[2].thread, 0, "%s star trick needs thread" % def.id)
	assert_between(total, 9000, 13000, "all 18 ≈ 11k coins (spec 06 §3)")


func test_ac66_tricks_need_the_building_level() -> void:
	var bar: BuildingDef = _building(&"snack_bar")
	var town: TownSave = _rich_town(0)
	assert_eq(TrickBook.state_of(town, bar, 0), TrickBook.State.NEEDS_LEVEL, "a ruin has none")
	assert_false(TrickBook.buy(town, bar, 0))
	town.building_levels["snack_bar"] = 1
	assert_eq(TrickBook.state_of(town, bar, 0), TrickBook.State.CAN_BUY)
	assert_eq(TrickBook.state_of(town, bar, 1), TrickBook.State.NEEDS_LEVEL, "trick 2 needs Lv 2")
	assert_eq(TrickBook.state_of(town, bar, 2), TrickBook.State.NEEDS_LEVEL, "the star needs Lv 3")


func test_ac66_tricks_are_bought_in_order() -> void:
	var bar: BuildingDef = _building(&"snack_bar")
	var town: TownSave = _rich_town(3)
	assert_eq(TrickBook.state_of(town, bar, 1), TrickBook.State.NEEDS_EARLIER)
	assert_false(TrickBook.buy(town, bar, 2), "not the star first")
	assert_eq(TrickBook.buyable(town, bar), 0, "trick 1 is next")
	assert_true(TrickBook.buy(town, bar, 0))
	assert_eq(TrickBook.state_of(town, bar, 0), TrickBook.State.BOUGHT)
	assert_eq(TrickBook.buyable(town, bar), 1, "then trick 2")
	assert_true(TrickBook.buy(town, bar, 1))
	assert_true(TrickBook.buy(town, bar, 2))
	assert_eq(TrickBook.buyable(town, bar), -1, "the branch is done")
	assert_eq(town.tricks, PackedStringArray(["picnic", "second_helping", "spare_stuffing"]))


func test_ac66_branches_are_independent() -> void:
	var town: TownSave = _rich_town(1)
	town.building_levels["watchtower"] = 1
	assert_true(TrickBook.buy(town, _building(&"watchtower"), 0), "no Snack Bar trick needed")


func test_ac66_buying_takes_the_price_once() -> void:
	var bar: BuildingDef = _building(&"snack_bar")
	var trick: TrickDef = bar.tricks[0]
	var town: TownSave = TownSave.new()
	town.building_levels = {"snack_bar": 1}
	town.materials = {"coins": trick.coins - 1, "stuffing": trick.stuffing}
	assert_eq(TrickBook.state_of(town, bar, 0), TrickBook.State.MISSING)
	assert_false(TrickBook.buy(town, bar, 0), "one coin short")
	assert_eq(town.material("coins"), trick.coins - 1, "nothing taken")
	town.materials["coins"] = trick.coins + 5
	assert_true(TrickBook.buy(town, bar, 0))
	assert_eq(town.material("coins"), 5)
	assert_eq(town.material("stuffing"), 0)
	assert_false(TrickBook.buy(town, bar, 0), "can't buy it twice")
	assert_eq(town.material("coins"), 5, "and pays only once")
	assert_eq(town.tricks.size(), 1)


func test_ac68_bought_tricks_survive_save_and_reload() -> void:
	SaveStore.path = SAVE
	SaveStore.delete_all()
	var town: TownSave = _rich_town(2)
	var bar: BuildingDef = _building(&"snack_bar")
	TrickBook.buy(town, bar, 0)
	TrickBook.buy(town, bar, 1)
	assert_true(SaveStore.write(town))
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.to_dict(), town.to_dict())
	assert_true(loaded.has_trick("second_helping"))
	assert_false(loaded.has_trick("spare_stuffing"))
	assert_eq(TrickBook.state_of(loaded, bar, 1), TrickBook.State.BOUGHT)


func test_ac68_a_save_from_before_tricks_loads_with_none() -> void:
	var old: Dictionary = {"version": 3, "materials": {"coins": 40}, "building_levels": {"jar": 2}}
	var town: TownSave = TownSave.from_dict(old)
	assert_eq(town.tricks.size(), 0)
	assert_eq(town.material("coins"), 40)
	assert_eq(int(town.to_dict()["version"]), TownSave.VERSION)
	assert_eq(TownSave.VERSION, 4)
