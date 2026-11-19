extends GutTest
## Sewn-on gear data and rules (spec 09 §3-§5, §8, §9, AC-102): the 9 pieces, sewing and
## stitching at the Sewing Workshop, wearing per player (one copy per piece), hiding per slot,
## and the save (v7) keeping it all.

const RULES: GearRules = preload("res://data/gear/gear_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SAVE: String = "user://test_unit_gear_save.json"
## Spec 09 §3: each piece's number at stitch Lv 1, 2, 3.
const AMOUNTS: Dictionary[String, Array] = {
	"pin_cushion_hat": [1.0, 1.0, 2.0],
	"lookout_cap": [1.6, 1.8, 2.2],
	"propeller_cap": [0.3, 0.4, 0.5],
	"raincoat": [0.3, 0.4, 0.5],
	"patch_vest": [20.0, 16.0, 12.0],
	"picnic_apron": [60.0, 50.0, 40.0],
	"jingle_bell": [30.0, 25.0, 20.0],
	"lucky_button": [0.04, 0.06, 0.08],
	"wind_up_key": [0.4, 0.55, 0.7],
}
## Spec 09 §3: where each pattern comes from.
const SOURCES: Dictionary[String, String] = {
	"pin_cushion_hat": "toy_box_armory",
	"lookout_cap": "watchtower",
	"propeller_cap": "big_ted",
	"raincoat": "",
	"patch_vest": "plush_hospital",
	"picnic_apron": "snack_bar",
	"jingle_bell": "party_shop",
	"lucky_button": "lucky_jar",
	"wind_up_key": "sock_puppet_king",
}
const RICH: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 999}


func before_each() -> void:
	SaveStore.path = SAVE
	SaveStore.delete_all()


func after_all() -> void:
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH


func _piece(id: String) -> GearDef:
	var piece: GearDef = RULES.find(id)
	assert_not_null(piece, id)
	return piece


## A town with the Workshop at `workshop_level`, full jars and every pattern found.
func _town(workshop_level: int) -> TownSave:
	var save: TownSave = TownSave.new()
	save.building_levels[String(RULES.workshop)] = workshop_level
	save.add_materials(RICH)
	for piece: GearDef in RULES.pieces:
		save.gear.add_pattern(String(piece.id))
	return save


func test_nine_pieces_three_per_slot_with_the_spec_numbers() -> void:
	assert_eq(RULES, GearRules.current(), "the game reads the same rules")
	assert_eq(RULES.pieces.size(), 9)
	for slot: GearDef.Slot in [GearDef.Slot.HEAD, GearDef.Slot.BODY, GearDef.Slot.CHARM]:
		assert_eq(RULES.pieces_in(slot).size(), 3, "slot %d" % slot)
	var ids: PackedStringArray = []
	for piece: GearDef in RULES.pieces:
		var id: String = String(piece.id)
		assert_false(ids.has(id), "unique id " + id)
		ids.append(id)
		assert_false(piece.display_name.is_empty(), id)
		assert_false(piece.text.is_empty(), id)
		assert_eq(piece.max_level(), 3, id)
		assert_true(AMOUNTS.has(id), "a piece of the spec: " + id)
		for at: int in range(1, 4):
			assert_almost_eq(piece.amount(at), float(AMOUNTS[id][at - 1]), 0.0001, id)
			assert_false(piece.level(at).effect.is_empty(), id)
		assert_eq(piece.amount(0), 0.0, "not sewn = no effect")
		assert_null(piece.level(4))


func test_patterns_come_from_buildings_bosses_and_elites() -> void:
	var building_ids: PackedStringArray = []
	for spot: TownSpot in LAYOUT.spots:
		building_ids.append(String(spot.id))
	var elites: int = 0
	for piece: GearDef in RULES.pieces:
		var id: String = String(piece.id)
		assert_eq(String(piece.source), SOURCES[id], id)
		match piece.source_kind:
			GearDef.Source.BUILDING:
				assert_true(building_ids.has(String(piece.source)), "a real building: " + id)
				assert_eq(piece.source_level, 2, "building patterns at Lv 2")
			GearDef.Source.BOSS:
				var path: String = "res://data/bosses/%s.tres" % piece.source
				assert_true(ResourceLoader.exists(path), "a real boss: " + id)
			GearDef.Source.ELITE:
				elites += 1
				assert_almost_eq(piece.drop_chance, 0.25, 0.0001)
	assert_eq(elites, 1, "only the Raincoat drops from elites")


func test_prices_sewing_cheaper_than_stitching_and_all_about_ten_k() -> void:
	for piece: GearDef in RULES.pieces:
		var sew: int = piece.level(1).coins
		assert_between(sew, 300, 600, "sewing ~300-600 coins: %s" % piece.id)
		for at: int in range(2, 4):
			assert_gt(piece.level(at).coins, sew, "stitching costs more: %s" % piece.id)
			assert_gte(piece.level(at).coins, piece.level(at - 1).coins)
	assert_between(GearBook.total_cost(RULES)["coins"], 9000, 11000, "spec 09 §5")


func test_sewing_needs_the_pattern_and_a_workshop() -> void:
	var save: TownSave = TownSave.new()
	var cap: GearDef = _piece("lookout_cap")
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.NO_PATTERN)
	save.gear.add_pattern("lookout_cap")
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.NO_WORKSHOP)
	save.building_levels[String(RULES.workshop)] = 1
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.MISSING, "empty jars")
	assert_false(GearBook.sew(save, cap, 0, RULES))
	save.add_materials(RICH)
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.CAN_SEW)
	save.damage(PackedStringArray([String(RULES.workshop)]))
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.NO_WORKSHOP, "damaged")
	assert_false(GearBook.sew(save, cap, 0, RULES))
	save.repair(String(RULES.workshop))
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.CAN_SEW, "repaired")


func test_sewing_pays_once_and_puts_the_piece_on_an_empty_slot() -> void:
	var save: TownSave = _town(1)
	var cap: GearDef = _piece("lookout_cap")
	assert_true(GearBook.sew(save, cap, 0, RULES))
	assert_eq(save.gear.stitch_level("lookout_cap"), 1)
	assert_eq(save.material("coins"), RICH["coins"] - cap.level(1).coins, "paid once")
	assert_eq(save.material("stuffing"), RICH["stuffing"] - cap.level(1).stuffing)
	assert_eq(save.gear.worn_in(0, "head"), "lookout_cap", "on at once")
	var hat: GearDef = _piece("pin_cushion_hat")
	assert_true(GearBook.sew(save, hat, 0, RULES))
	assert_eq(save.gear.worn_in(0, "head"), "lookout_cap", "a full slot keeps its piece")
	assert_eq(GearBook.worn_pieces(save, 0, RULES), [cap] as Array[GearDef])


func test_workshop_levels_cap_stitches_and_open_the_charm_slot() -> void:
	var save: TownSave = _town(1)
	var cap: GearDef = _piece("lookout_cap")
	var bell: GearDef = _piece("jingle_bell")
	assert_true(GearBook.sew(save, cap, 0, RULES))
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.NEEDS_LEVEL, "Lv 2 needs Lv 2")
	assert_eq(GearBook.step_of(save, bell, RULES), GearBook.Step.NEEDS_LEVEL, "charm needs Lv 2")
	assert_false(GearBook.slot_open(save, GearDef.Slot.CHARM, RULES))
	save.building_levels[String(RULES.workshop)] = 2
	assert_true(GearBook.slot_open(save, GearDef.Slot.CHARM, RULES))
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.CAN_STITCH)
	var coins: int = save.material("coins")
	assert_true(GearBook.sew(save, cap, 0, RULES))
	assert_eq(save.gear.stitch_level("lookout_cap"), 2)
	assert_eq(save.material("coins"), coins - cap.level(2).coins)
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.NEEDS_LEVEL, "Lv 3 needs Lv 3")
	assert_true(GearBook.sew(save, bell, 0, RULES))
	assert_eq(save.gear.worn_in(0, "charm"), "jingle_bell")
	save.building_levels[String(RULES.workshop)] = 3
	assert_true(GearBook.sew(save, cap, 0, RULES))
	assert_eq(save.gear.stitch_level("lookout_cap"), 3)
	assert_eq(GearBook.step_of(save, cap, RULES), GearBook.Step.MAXED)
	assert_false(GearBook.sew(save, cap, 0, RULES), "no Lv 4")
	assert_eq(save.gear.stitch_level("lookout_cap"), 3)


func test_each_piece_is_worn_by_one_player_and_swaps_in_its_slot() -> void:
	var save: TownSave = _town(2)
	var cap: GearDef = _piece("lookout_cap")
	var hat: GearDef = _piece("pin_cushion_hat")
	assert_eq(GearBook.wear_state(save, cap, 1, RULES), GearBook.Wear.NOT_SEWN)
	assert_false(GearBook.wear(save, cap, 1, RULES), "not sewn")
	GearBook.sew(save, cap, 0, RULES)
	GearBook.sew(save, hat, 0, RULES)
	assert_eq(GearBook.wear_state(save, cap, 0, RULES), GearBook.Wear.WORN)
	assert_eq(GearBook.wear_state(save, cap, 1, RULES), GearBook.Wear.TAKEN)
	assert_false(GearBook.wear(save, cap, 1, RULES), "player 1 wears it")
	assert_true(GearBook.wear(save, hat, 1, RULES), "player 2 takes the free one")
	assert_eq(save.gear.wearer_of("pin_cushion_hat"), 1)
	assert_true(GearBook.take_off(save, 0, GearDef.Slot.HEAD))
	assert_false(GearBook.take_off(save, 0, GearDef.Slot.HEAD), "already empty")
	assert_eq(save.gear.wearer_of("lookout_cap"), -1)
	assert_true(GearBook.wear(save, cap, 1, RULES), "swap in the same slot")
	assert_eq(save.gear.worn_in(1, "head"), "lookout_cap")
	assert_eq(save.gear.wearer_of("pin_cushion_hat"), -1, "the swapped-out piece is free")
	assert_eq(save.material("coins"), RICH["coins"] - cap.level(1).coins - hat.level(1).coins)


func test_a_locked_slot_cant_be_worn_but_a_damaged_workshop_still_lets_you_wear() -> void:
	var save: TownSave = _town(2)
	var bell: GearDef = _piece("jingle_bell")
	GearBook.sew(save, bell, 0, RULES)
	GearBook.take_off(save, 0, GearDef.Slot.CHARM)
	save.building_levels[String(RULES.workshop)] = 1
	assert_eq(GearBook.wear_state(save, bell, 0, RULES), GearBook.Wear.SLOT_LOCKED)
	save.building_levels[String(RULES.workshop)] = 2
	save.damage(PackedStringArray([String(RULES.workshop)]))
	assert_true(GearBook.wear(save, bell, 0, RULES), "spec 09 §5: wearing still works")


func test_hiding_is_per_player_and_slot() -> void:
	var gear: TownGear = TownGear.new()
	gear.set_hidden(1, "head", true)
	assert_true(gear.is_hidden(1, "head"))
	assert_false(gear.is_hidden(0, "head"), "player 1 isn't touched")
	assert_false(gear.is_hidden(1, "body"))
	gear.set_hidden(1, "head", true)
	assert_eq(gear.hidden[1].size(), 1, "no doubles")
	gear.set_all_hidden(0, true)
	for slot: String in GearDef.SLOT_NAMES:
		assert_true(gear.is_hidden(0, slot))
	gear.set_all_hidden(0, false)
	assert_false(gear.is_hidden(0, "charm"))
	gear.set_hidden(1, "head", false)
	assert_false(gear.is_hidden(1, "head"))


func test_ac102_gear_survives_save_and_reload() -> void:
	var save: TownSave = _town(3)
	GearBook.sew(save, _piece("lookout_cap"), 0, RULES)
	GearBook.sew(save, _piece("lookout_cap"), 0, RULES)
	GearBook.sew(save, _piece("raincoat"), 1, RULES)
	GearBook.sew(save, _piece("wind_up_key"), 1, RULES)
	save.gear.set_hidden(1, "charm", true)
	save.gear.patterns.remove_at(save.gear.patterns.find("propeller_cap"))
	assert_true(SaveStore.write(save))
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.to_dict(), save.to_dict(), "same town after reloading")
	assert_eq(int(loaded.to_dict()["version"]), 7)
	assert_true(loaded.gear.has_pattern("raincoat"))
	assert_false(loaded.gear.has_pattern("propeller_cap"))
	assert_eq(loaded.gear.stitch_level("lookout_cap"), 2)
	assert_eq(loaded.gear.stitch_level("raincoat"), 1)
	assert_eq(loaded.gear.stitch_level("patch_vest"), 0)
	assert_eq(loaded.gear.worn_in(0, "head"), "lookout_cap")
	assert_eq(loaded.gear.worn_in(1, "body"), "raincoat")
	assert_eq(loaded.gear.worn_in(1, "charm"), "wind_up_key")
	assert_eq(loaded.gear.worn_in(0, "body"), "")
	assert_true(loaded.gear.is_hidden(1, "charm"))
	assert_false(loaded.gear.is_hidden(0, "charm"))


func test_ac102_a_v6_save_loads_with_no_gear() -> void:
	var town: TownSave = TownSave.new()
	town.building_levels["watchtower"] = 2
	town.set_hero(0, "pip")
	var data: Dictionary = town.to_dict()
	data["version"] = 6
	for field: String in ["patterns", "gear", "worn", "hidden"]:
		data.erase(field)
	var loaded: TownSave = TownSave.from_dict(JSON.parse_string(JSON.stringify(data)) as Dictionary)
	assert_eq(loaded.building_level("watchtower"), 2)
	assert_eq(loaded.hero_id(0), "pip")
	assert_eq(loaded.gear.patterns.size(), 0)
	assert_eq(loaded.gear.stitches.size(), 0)
	assert_eq(loaded.gear.worn_in(0, "head"), "")
	assert_false(loaded.gear.is_hidden(0, "head"))
	assert_eq(loaded.to_dict()["version"], TownSave.VERSION, "written back as v7")


func test_broken_gear_fields_load_empty() -> void:
	var data: Dictionary = TownSave.new().to_dict()
	data["patterns"] = "oops"
	data["gear"] = {"lookout_cap": 0, "raincoat": 2}
	data["worn"] = ["nope", {"head": "lookout_cap"}]
	data["hidden"] = [5]
	var loaded: TownSave = TownSave.from_dict(data)
	assert_eq(loaded.gear.patterns.size(), 0)
	assert_false(loaded.gear.is_sewn("lookout_cap"), "level 0 = not sewn")
	assert_eq(loaded.gear.stitch_level("raincoat"), 2)
	assert_eq(loaded.gear.worn_in(0, "head"), "")
	assert_eq(loaded.gear.worn_in(1, "head"), "lookout_cap")
	assert_false(loaded.gear.is_hidden(0, "head"))
