extends GutTest
## Rescued plushies at home (spec 03 §7, AC-45): the girlfriend's four plushies, Hospital beds
## per level, the coin bonus, and old saves keeping their plushies under the new ids.

const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
const HOSPITAL: BuildingDef = preload("res://data/town/buildings/plush_hospital.tres")
const PLUSHIE_RULES: PlushieTownRules = preload("res://data/town/plushie_town_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")


func test_the_four_plushies_from_the_photos() -> void:
	var names: PackedStringArray = []
	var shapes: Array[PlushieDef.Shape] = []
	for plushie: PlushieDef in RESCUE.plushies:
		names.append("%s:%s" % [plushie.id, plushie.display_name])
		assert_false(shapes.has(plushie.shape), "%s has its own shape" % plushie.id)
		shapes.append(plushie.shape)
	var expected: PackedStringArray = ["pip:Pip", "bobo:Böbö", "bambam:BamBam", "robbar:Robbar"]
	assert_eq(names, expected)


func test_hospital_beds_per_level_come_from_data() -> void:
	assert_eq(HOSPITAL.reached(1).plushie_beds, 2)
	assert_eq(HOSPITAL.reached(2).plushie_beds, 4)
	assert_eq(HOSPITAL.reached(3).plushie_beds, 6)


func test_plushies_in_town_and_waiting_first_come_first_served() -> void:
	var town: TownSave = TownSave.new()
	town.plushies = {"robbar": "waiting", "pip": "in_town", "bobo": "waiting"}
	assert_eq(town.plushies_in_town(), 1)
	assert_eq(town.waiting_plushies(), PackedStringArray(["robbar", "bobo"]))


func test_coins_get_the_plushie_bonus_on_top() -> void:
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 100)
	haul.add("stuffing", 10)
	var kept: Dictionary[String, int] = haul.kept(0.5, 0.1)
	assert_eq(kept["coins"], 55, "half, then +10%")
	assert_eq(kept["stuffing"], 5, "only coins get the bonus")
	assert_eq(haul.kept(1.0, 0.2)["coins"], 120, "4 plushies = +20%")
	var town: TownSave = TownSave.new()
	town.bank(haul, 0.5, 0.1)
	assert_eq(town.material("coins"), 55)
	assert_eq(PLUSHIE_RULES.coin_bonus_per_plushie, 0.05, "+5% per plushie (spec 03 §7)")


func test_the_brought_home_line_for_the_bonus() -> void:
	assert_eq(BroughtHomePanel.bonus_text(0.1), "Plushies in town: +10% coins")
	assert_eq(BroughtHomePanel.bonus_text(0.0), "", "no line without plushies")


func test_an_old_save_keeps_its_placeholder_plushies_under_the_new_ids() -> void:
	var old: Dictionary = {
		"version": 1,
		"plushies": {"bunny": "in_town", "kitty": "waiting"},
		"unfinished_run": {"materials": {"coins": 3}, "rescued": "bear"},
	}
	var save: TownSave = TownSave.from_dict(old)
	assert_eq(save.plushies.size(), 2)
	assert_eq(save.plushies.get("bambam", ""), "in_town", "bunny is now BamBam")
	assert_eq(save.plushies.get("pip", ""), "waiting", "kitty is now Pip")
	assert_eq(save.unfinished_run["rescued"], "bobo")


func test_a_new_save_keeps_its_ids() -> void:
	var town: TownSave = TownSave.new()
	town.plushies = {"robbar": "in_town"}
	var again: TownSave = TownSave.from_dict(town.to_dict())
	assert_eq(again.plushies.size(), 1)
	assert_eq(again.plushies.get("robbar", ""), "in_town")


func test_walkable_spots_keep_clear_of_buildings() -> void:
	var hospital: Rect2 = LAYOUT.spot(&"plush_hospital").rect
	assert_false(TownPlushie.is_walkable(LAYOUT, hospital.get_center(), 0.0), "not inside")
	assert_false(TownPlushie.is_walkable(LAYOUT, Vector2(-10, 300), 0.0), "not off the blanket")
	assert_true(TownPlushie.is_walkable(LAYOUT, Vector2(450, 1420), 40.0))
	var through: bool = TownPlushie.is_path_clear(
		LAYOUT, Vector2(1400, 1240), Vector2(1800, 1240), 0.0
	)
	assert_false(through, "a walk never crosses a building")
