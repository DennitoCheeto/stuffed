extends GutTest
## Unit (spec 04 §4.2, AC-54): which run titles a run earns. Every condition in
## data/ui/run_titles.tres, at most 2, rarest first, never two "bad" ones, the fallback when
## nothing nice fits, and "New!" only the first time (remembered in the save).

const RULES: RunTitleRules = preload("res://data/ui/run_titles.tres")
const WEAPONS_DIR: String = "res://data/weapons/"
## The titles spec 04 §4.2 lists (the fallback aside).
const SPEC_TITLES: Array[String] = [
	"weapon_star",
	"untouchable",
	"close_call",
	"speedy_stitcher",
	"evolution_expert",
	"gift_grabber",
	"party_animal",
	"hero_of_the_fort",
	"endless_explorer",
	"collector",
	"stuffed_already",
]


## A plain lost run that earns nothing special: 3:00, no damage dealt, hurt just now.
func _plain() -> RunResult:
	var result: RunResult = RunResult.new()
	result.ending = "died"
	result.survived_seconds = 180.0
	result.kills = 1234
	result.longest_unhurt_seconds = 30.0
	return result


func _won(seconds: float) -> RunResult:
	var result: RunResult = _plain()
	result.won = true
	result.ending = "ended"
	result.survived_seconds = seconds
	result.boss_defeated_at = seconds
	result.lowest_health_at_goal = 0.8
	return result


func _row(id: String, player: int, damage: float) -> Dictionary:
	return {
		"id": id,
		"name": id.capitalize(),
		"player": player,
		"weapon": player >= 0,
		"damage": damage,
	}


func _ids(titles: Array[RunTitle]) -> PackedStringArray:
	var ids: PackedStringArray = []
	for title: RunTitle in titles:
		ids.append(title.id)
	return ids


func _def(id: String) -> RunTitleDef:
	for def: RunTitleDef in RULES.titles:
		if String(def.id) == id:
			return def
	return null


func _earns(result: RunResult, id: String) -> bool:
	return RULES.earned(_def(id), result) != null


func test_ac54_every_title_of_the_spec_is_in_the_data() -> void:
	var ids: PackedStringArray = []
	for def: RunTitleDef in RULES.titles:
		ids.append(String(def.id))
		assert_ne(def.text, "", "%s has words" % def.id)
	for id: String in SPEC_TITLES:
		assert_has(ids, id)
	assert_eq(String(RULES.fallback.id), "steady_paws")
	assert_eq(RULES.max_titles, 2)


func test_ac54_every_weapon_has_its_own_title() -> void:
	var seen: PackedStringArray = []
	for file: String in DirAccess.get_files_at(WEAPONS_DIR):
		if not file.ends_with(".tres"):
			continue
		var weapon: WeaponStats = load(WEAPONS_DIR + file) as WeaponStats
		assert_ne(weapon.run_title, "", "%s has a run title" % weapon.id)
		assert_does_not_have(seen, weapon.run_title, "%s's title is its own" % weapon.id)
		seen.append(weapon.run_title)


func test_ac54_a_plain_run_gets_the_fallback_with_its_kills() -> void:
	var titles: Array[RunTitle] = RULES.pick(_plain())
	assert_eq(_ids(titles), PackedStringArray(["steady_paws"]))
	assert_eq(titles[0].text, "Steady Paws: 1,234 stuffed")


func test_ac54_weapon_title_needs_60_percent_of_all_damage() -> void:
	var result: RunResult = _plain()
	result.weapons = [_row("thimble_mortar", 0, 600.0), _row("peel_boomerang", 0, 400.0)]
	result.total_damage = 1000.0
	result.weapon_titles = {"thimble_mortar": "Mortar Maniac"}
	var titles: Array[RunTitle] = RULES.pick(result)
	assert_eq(_ids(titles), PackedStringArray(["weapon_star:thimble_mortar"]))
	assert_eq(titles[0].text, "Mortar Maniac")
	result.weapons = [_row("thimble_mortar", 0, 590.0), _row("peel_boomerang", 0, 410.0)]
	assert_false(_earns(result, "weapon_star"), "59% is not enough")


func test_ac54_co_op_damage_of_one_weapon_adds_up() -> void:
	var result: RunResult = _plain()
	result.weapons = [
		_row("zipper_ray", 0, 350.0),
		_row("zipper_ray", 1, 300.0),
		_row("peel_boomerang", 0, 250.0),
		_row("party_popper", -1, 100.0),
	]
	result.total_damage = 1000.0
	assert_eq(RunTitleRules.top_weapon(result, 0.6), "zipper_ray")
	var title: RunTitle = RULES.earned(_def("weapon_star"), result)
	assert_eq(title.text, "Zipper Ray Fan", "no title in the result: a friendly fallback")


func test_ac54_each_condition() -> void:
	var result: RunResult = _plain()
	result.longest_unhurt_seconds = 180.0
	assert_true(_earns(result, "untouchable"), "3 minutes unhurt")
	result.longest_unhurt_seconds = 179.0
	assert_false(_earns(result, "untouchable"))

	result = _won(500.0)
	assert_true(_earns(result, "speedy_stitcher"), "King down before 9:00")
	result.lowest_health_at_goal = 0.1
	assert_true(_earns(result, "close_call"), "under 15% health")
	result.lowest_health_at_goal = 0.15
	assert_false(_earns(result, "close_call"))
	result = _won(560.0)
	assert_false(_earns(result, "speedy_stitcher"))
	assert_false(_earns(_plain(), "close_call"), "only when the King was beaten")

	result = _plain()
	result.evolutions = [{"weapon": "A"}, {"weapon": "B"}]
	result.gift_boxes_opened = 3
	result.rescue = {"plushie": "pip", "freed": true}
	result.new_scrapbook_entries = 3
	for i: int in 3:
		result.floor_pickups.append({"id": "party_popper", "name": "Party Popper"})
	result.floor_pickups.append({"id": "magnet", "name": "Big Magnet"})
	for id: String in ["evolution_expert", "gift_grabber", "party_animal"]:
		assert_true(_earns(result, id), id)
	for id: String in ["hero_of_the_fort", "collector"]:
		assert_true(_earns(result, id), id)
	result.evolutions.pop_back()
	result.gift_boxes_opened = 2
	result.rescue = {"plushie": "pip", "freed": false}
	result.new_scrapbook_entries = 2
	result.floor_pickups.pop_front()
	for id: String in ["evolution_expert", "gift_grabber", "party_animal"]:
		assert_false(_earns(result, id), id)
	for id: String in ["hero_of_the_fort", "collector"]:
		assert_false(_earns(result, id), id)

	result = _won(480.0 + 300.0)
	result.endless_seconds = 300.0
	assert_true(_earns(result, "endless_explorer"))
	result.endless_seconds = 299.0
	assert_false(_earns(result, "endless_explorer"))

	result = _plain()
	result.survived_seconds = 100.0
	assert_true(_earns(result, "stuffed_already"), "stuffed before 2:00")
	result.ending = "quit"
	assert_false(_earns(result, "stuffed_already"), "giving up is not getting stuffed")
	result.ending = "died"
	result.survived_seconds = 125.0
	assert_false(_earns(result, "stuffed_already"))


func test_ac54_at_most_two_rarest_first() -> void:
	var result: RunResult = _won(500.0)
	result.lowest_health_at_goal = 0.1
	result.gift_boxes_opened = 5
	result.evolutions = [{"weapon": "A"}, {"weapon": "B"}]
	result.longest_unhurt_seconds = 200.0
	var titles: Array[RunTitle] = RULES.pick(result)
	assert_eq(titles.size(), 2)
	# Untouchable and Close Call are the rarest (5); Untouchable is listed first.
	assert_eq(_ids(titles), PackedStringArray(["untouchable", "close_call"]))


## A "bad" title that always fits, with rarity `rare`.
func _joke(id: StringName, rare: int) -> RunTitleDef:
	var joke: RunTitleDef = RunTitleDef.new()
	joke.id = id
	joke.text = String(id).capitalize()
	joke.check = RunTitleDef.Check.ALWAYS
	joke.rarity = rare
	joke.bad = true
	return joke


func test_ac54_never_two_bad_titles_and_always_something_nice() -> void:
	var rules: RunTitleRules = RULES.duplicate()
	rules.titles = RULES.titles.duplicate()
	rules.titles.append(_joke(&"oops", 9))
	rules.titles.append(_joke(&"whoops", 8))
	var result: RunResult = _plain()
	result.survived_seconds = 60.0
	var titles: Array[RunTitle] = rules.pick(result)
	assert_eq(_ids(titles), PackedStringArray(["oops", "steady_paws"]), "one joke + the nice one")
	result.gift_boxes_opened = 3
	titles = rules.pick(result)
	assert_eq(_ids(titles), PackedStringArray(["oops", "gift_grabber"]), "the 2nd joke is skipped")


func test_ac54_new_only_the_first_time_and_it_is_saved() -> void:
	var town: TownSave = TownSave.new()
	assert_true(town.note_title("collector"), "first time")
	assert_false(town.note_title("collector"), "seen before")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(town.to_dict())) as Dictionary
	var loaded: TownSave = TownSave.from_dict(saved)
	assert_false(loaded.note_title("collector"), "still seen after a reload")


func test_new_scrapbook_entries_count_only_what_the_book_lacks() -> void:
	var town: TownSave = TownSave.new()
	town.mark_seen("weapons", "peel_boomerang")
	var haul: RunHaul = RunHaul.new()
	haul.see("weapons", "peel_boomerang")
	haul.see("weapons", "zipper_ray")
	haul.see("enemies", "runner")
	haul.rescued = "pip"
	assert_eq(town.new_entries(haul), 3)
