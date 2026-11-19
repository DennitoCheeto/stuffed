extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §9, §11, AC-102): the town developer menu gives all patterns, sews every
## piece, maxes every stitch and clears the gear, each saved at once; gear comes back after the
## game is opened again, and "Reset town" clears it.

var town: Town


func _rules() -> GearRules:
	return GearRules.current()


func test_dev_menu_gives_sews_maxes_and_clears_gear() -> void:
	town = await go_to_town()
	var count: int = _rules().pieces.size()
	town.dev_menu.press(TownDevMenu.GIVE_PATTERNS)
	assert_eq(main.town.gear.patterns.size(), count, "every pattern")
	assert_eq(main.town.gear.stitches.size(), 0, "nothing sewn yet")
	assert_eq(SaveStore.read().gear.patterns.size(), count, "saved")
	town.dev_menu.press(TownDevMenu.GIVE_PATTERNS)
	assert_eq(main.town.gear.patterns.size(), count, "no doubles")
	town.dev_menu.press(TownDevMenu.SEW_ALL)
	for piece: GearDef in _rules().pieces:
		assert_eq(main.town.gear.stitch_level(String(piece.id)), 1, "sewn: %s" % piece.id)
	town.dev_menu.press(TownDevMenu.MAX_STITCHES)
	for piece: GearDef in _rules().pieces:
		assert_eq(SaveStore.read().gear.stitch_level(String(piece.id)), piece.max_level())
	town.dev_menu.press(TownDevMenu.SEW_ALL)
	assert_eq(main.town.gear.stitch_level("lookout_cap"), 3, "Sew all never lowers a stitch")
	town.dev_menu.press(TownDevMenu.CLEAR_GEAR)
	assert_eq(main.town.gear.patterns.size(), 0)
	assert_eq(main.town.gear.stitches.size(), 0)
	assert_eq(SaveStore.read().gear.stitches.size(), 0, "saved")


func test_ac102_gear_comes_back_after_reopening_the_game() -> void:
	town = await go_to_town()
	town.dev_menu.press(TownDevMenu.MAX_STITCHES)
	main.town.building_levels[String(_rules().workshop)] = 2
	assert_true(GearBook.wear(main.town, _rules().find("lookout_cap"), 0))
	assert_true(GearBook.wear(main.town, _rules().find("jingle_bell"), 0))
	main.town.gear.set_hidden(0, "charm", true)
	main.save_now()
	var before: Dictionary = main.town.to_dict()
	main.load_town()
	assert_eq(main.town.to_dict(), before, "same town after loading it again")
	assert_eq(main.town.gear.worn_in(0, "head"), "lookout_cap")
	assert_eq(main.town.gear.worn_in(0, "charm"), "jingle_bell")
	assert_true(main.town.gear.is_hidden(0, "charm"))
	assert_eq(main.town.gear.stitch_level("wind_up_key"), 3)


func test_reset_town_clears_the_gear() -> void:
	town = await go_to_town()
	town.dev_menu.press(TownDevMenu.SEW_ALL)
	town.dev_menu.press(TownDevMenu.RESET)
	town.dev_menu.press(TownDevMenu.RESET)
	await wait_process_frames(2)
	assert_eq(main.town.gear.stitches.size(), 0, "a fresh town has no gear")
	assert_false(SaveStore.exists() and SaveStore.read().gear.patterns.size() > 0, "not on disk")
