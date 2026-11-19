extends GutTest
## Sewing patterns (spec 09 §4, AC-95, AC-96): building Lv 2 patterns (old saves catch up), the
## boss / elite pattern sources, and patterns found in a run kept whole even from a lost run.

const RULES: GearRules = preload("res://data/gear/gear_rules.tres")
## Spec 09 §3: the building whose Lv 2 gives each building pattern.
const BUILDING_PATTERNS: Dictionary[String, String] = {
	"toy_box_armory": "pin_cushion_hat",
	"watchtower": "lookout_cap",
	"plush_hospital": "patch_vest",
	"snack_bar": "picnic_apron",
	"party_shop": "jingle_bell",
	"lucky_jar": "lucky_button",
}


func _ids(pieces: Array[GearDef]) -> PackedStringArray:
	var result: PackedStringArray = []
	for piece: GearDef in pieces:
		result.append(String(piece.id))
	return result


func test_ac95_each_building_gives_its_pattern_at_level_2() -> void:
	for building: String in BUILDING_PATTERNS:
		var save: TownSave = TownSave.new()
		save.building_levels[building] = 1
		assert_eq(GearBook.building_patterns_due(save, RULES).size(), 0, "Lv 1: %s" % building)
		save.building_levels[building] = 2
		var due: PackedStringArray = _ids(GearBook.building_patterns_due(save, RULES))
		assert_eq(due, PackedStringArray([BUILDING_PATTERNS[building]]), building)


func test_given_patterns_are_owned_and_never_given_twice() -> void:
	var save: TownSave = TownSave.new()
	save.building_levels["watchtower"] = 3
	save.building_levels["snack_bar"] = 2
	var given: PackedStringArray = _ids(GearBook.give_building_patterns(save, RULES))
	assert_eq(given, PackedStringArray(["lookout_cap", "picnic_apron"]))
	assert_true(save.gear.has_pattern("lookout_cap"))
	assert_true(save.gear.has_pattern("picnic_apron"))
	assert_eq(GearBook.give_building_patterns(save, RULES).size(), 0, "nothing new")
	assert_eq(save.gear.patterns.size(), 2)


func test_boss_and_elite_sources() -> void:
	var ted: PackedStringArray = _ids(RULES.pieces_from(GearDef.Source.BOSS, "big_ted"))
	assert_eq(ted, PackedStringArray(["propeller_cap"]))
	var king: PackedStringArray = _ids(RULES.pieces_from(GearDef.Source.BOSS, "sock_puppet_king"))
	assert_eq(king, PackedStringArray(["wind_up_key"]))
	var elite: PackedStringArray = _ids(RULES.pieces_from(GearDef.Source.ELITE))
	assert_eq(elite, PackedStringArray(["raincoat"]))
	assert_almost_eq(RULES.find("raincoat").drop_chance, 0.25, 0.001, "spec 09 §4: 25%")
	assert_eq(RULES.pieces_from(GearDef.Source.BUILDING).size(), BUILDING_PATTERNS.size())


func test_pattern_news_for_one_and_several() -> void:
	var one: Array[GearDef] = [RULES.find("lookout_cap")]
	assert_eq(RULES.pattern_news(one)[0], "New pattern: Lookout Cap!")
	var two: Array[GearDef] = [RULES.find("lookout_cap"), RULES.find("patch_vest")]
	var news: PackedStringArray = RULES.pattern_news(two)
	assert_eq(news[0], "New patterns!")
	assert_string_contains(news[1], "Lookout Cap, Patch Vest")


func test_ac96_patterns_from_a_lost_run_are_kept_whole() -> void:
	var save: TownSave = TownSave.new()
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 100)
	haul.patterns.append("propeller_cap")
	save.bank(haul, 0.0)
	assert_eq(save.material("coins"), 0, "a share of 0 keeps no coins ...")
	assert_true(save.gear.has_pattern("propeller_cap"), "... but the pattern")


func test_patterns_survive_an_unfinished_run() -> void:
	var haul: RunHaul = RunHaul.new()
	haul.patterns.append("raincoat")
	var save: TownSave = TownSave.new()
	save.unfinished_run = haul.to_dict()
	var loaded: TownSave = TownSave.from_dict(JSON.parse_string(JSON.stringify(save.to_dict())))
	assert_true(loaded.settle_unfinished_run(0.5))
	assert_true(loaded.gear.has_pattern("raincoat"), "closing the game mid-run keeps it")
	assert_eq(RunHaul.from_dict(haul.to_dict()).patterns, PackedStringArray(["raincoat"]))


func test_town_perks_list_owned_patterns() -> void:
	var save: TownSave = TownSave.new()
	save.gear.add_pattern("propeller_cap")
	var layout: TownLayout = load("res://data/town/pillow_fort.tres")
	var perks: TownPerks = TownPerks.from_save(save, layout)
	assert_eq(perks.patterns, PackedStringArray(["propeller_cap"]))
