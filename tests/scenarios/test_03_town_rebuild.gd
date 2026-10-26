extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §5, §6, §11, AC-42): walk up to a ruin, press E, and it gets rebuilt if
## the jars hold enough (else it only shows what is missing); upgrades up to level 3; locked
## ruins lose their yarn after 1 and 3 rebuilds and after the first rescue; the fort grows every
## 3 levels.

const PLENTY: Dictionary[String, int] = {"coins": 9000, "stuffing": 300, "thread": 60}


## Puts Banane right below `id`'s spot (in reach) and returns its building.
func _stand_at(town: Town, id: StringName) -> TownBuilding:
	var building: TownBuilding = town.buildings[id]
	var rect: Rect2 = building.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	return building


func _press_e() -> void:
	await tap_action("p1_interact")
	await wait_physics_frames(1)


## Waits until the rebuild moment, the fort growing and any "New building!" have played.
func _settle(town: Town) -> void:
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func _rebuild(town: Town, id: StringName) -> void:
	await _stand_at(town, id)
	await _press_e()
	await _settle(town)


func test_ac42_e_at_a_ruin_rebuilds_it_when_the_jars_hold_enough() -> void:
	main.town.materials["coins"] = 500
	var town: Town = await go_to_town()
	var armory: TownBuilding = await _stand_at(town, &"toy_box_armory")
	var cost: int = armory.building.levels[0].coins
	assert_true(town.card.visible, "standing next to it shows the info card")
	assert_eq(town.card.building, armory)
	assert_eq(town.card.level_label.text, "Ruin")
	assert_string_contains(town.card.next_label.text, armory.building.levels[0].effect)
	assert_false(armory.is_short_of("coins"), "the price on the tag is not grey")
	assert_eq(town.prompt_label.text, "E   Rebuild")
	Sfx.history.clear()
	await _press_e()
	assert_eq(main.town.building_level("toy_box_armory"), 1, "rebuilt")
	assert_eq(main.town.material("coins"), 500 - cost, "the cost is taken")
	assert_eq(town.jars["coins"].shown, 500 - cost, "the jars show it")
	assert_eq(SaveStore.read().building_level("toy_box_armory"), 1, "saved right away")
	assert_true(Sfx.history.has(&"rebuild"), "with a fwump")
	assert_eq(armory.shown_level, 0, "the ruin shakes first")
	await _settle(town)
	assert_eq(armory.shown_level, 1, "then pops up as a building")
	assert_false(armory.price_tag.visible, "built: the price tag is gone")
	var effect: String = armory.building.levels[0].effect
	assert_string_contains(town.card.now_label.text, effect, "the card says what it does")
	assert_eq(town.card.level_label.text, "Level 1 of 3")


func test_ac42_without_enough_e_only_shows_the_missing_amount() -> void:
	main.town.materials["coins"] = 10
	var town: Town = await go_to_town()
	var armory: TownBuilding = await _stand_at(town, &"toy_box_armory")
	var cost: int = armory.building.levels[0].coins
	var missing: String = "Needs %d more coins" % (cost - 10)
	assert_true(armory.is_short_of("coins"), "the price on the tag is grey")
	assert_eq(town.prompt_label.text, missing)
	assert_eq(town.card.action_label.text, missing)
	assert_true(town.card.cost_counters.has("coins"), "the card shows the price")
	Sfx.history.clear()
	await _press_e()
	await wait_physics_frames(10)
	assert_eq(main.town.building_level("toy_box_armory"), 0, "still a ruin")
	assert_eq(main.town.material("coins"), 10, "nothing taken")
	assert_eq(armory.shown_level, 0)
	assert_false(armory.is_busy(), "no rebuild moment")
	assert_true(Sfx.history.has(&"nope"))
	assert_false(Sfx.history.has(&"rebuild"))


func test_ac42_upgrading_works_the_same_up_to_level_3() -> void:
	main.town.building_levels["lucky_jar"] = 1
	main.town.materials = PLENTY.duplicate()
	var town: Town = await go_to_town()
	var jar: TownBuilding = await _stand_at(town, &"lucky_jar")
	assert_eq(jar.shown_level, 1, "a rebuilt building stays rebuilt")
	assert_eq(town.prompt_label.text, "E   Upgrade to level 2")
	assert_string_contains(town.card.now_label.text, jar.building.levels[0].effect)
	assert_string_contains(town.card.next_label.text, jar.building.levels[1].effect)
	Sfx.history.clear()
	await _press_e()
	assert_eq(main.town.building_level("lucky_jar"), 2)
	var stuffing: int = PLENTY["stuffing"] - jar.building.levels[1].stuffing
	assert_eq(main.town.material("stuffing"), stuffing, "level 2 takes stuffing")
	assert_true(Sfx.history.has(&"upgrade"))
	await _settle(town)
	assert_eq(jar.shown_level, 2)
	await _press_e()
	assert_eq(main.town.building_level("lucky_jar"), 3)
	var thread: int = PLENTY["thread"] - jar.building.levels[2].thread
	assert_eq(main.town.material("thread"), thread, "level 3 takes thread")
	await _settle(town)
	var before: Dictionary[String, int] = main.town.materials.duplicate()
	await _press_e()
	await _settle(town)
	assert_eq(main.town.building_level("lucky_jar"), 3, "level 3 is the top")
	assert_eq(main.town.materials, before, "nothing taken at the top")
	assert_eq(town.prompt_label.text, "Fully upgraded!")
	assert_eq(town.card.level_label.text, "Level 3 of 3 (max)")
	assert_eq(SaveStore.read().building_level("lucky_jar"), 3, "saved")


func test_ac42_locked_ruins_open_after_1_and_3_rebuilds() -> void:
	main.town.materials = PLENTY.duplicate()
	var town: Town = await go_to_town()
	var tower: TownBuilding = await _stand_at(town, &"watchtower")
	assert_false(tower.unlocked)
	assert_eq(town.prompt_label.text, "Rebuild 1 building first")
	await _press_e()
	assert_eq(main.town.building_level("watchtower"), 0, "a tangled ruin can't be rebuilt")
	assert_eq(main.town.material("coins"), PLENTY["coins"])
	Sfx.history.clear()
	await _rebuild(town, &"toy_box_armory")
	assert_true(tower.unlocked, "the Watchtower after 1 rebuild")
	assert_true(town.buildings[&"snack_bar"].unlocked, "and the Snack Bar")
	assert_false(town.buildings[&"party_shop"].unlocked, "the Party Shop needs 3")
	assert_true(town.is_banner_showing(), "a New building! moment")
	assert_eq(town.banner_title.text, "New buildings!")
	assert_string_contains(town.banner_subtitle.text, "Watchtower")
	assert_true(Sfx.history.has(&"new_building"))
	assert_true(SaveStore.read().revealed.has("watchtower"), "saved")
	await _rebuild(town, &"watchtower")
	assert_eq(main.town.building_level("watchtower"), 1, "and now it can be rebuilt")
	assert_false(town.buildings[&"party_shop"].unlocked)
	await _rebuild(town, &"lucky_jar")
	assert_true(town.buildings[&"party_shop"].unlocked, "the Party Shop after 3 rebuilds")
	assert_eq(town.banner_title.text, "New building!")
	assert_false(town.buildings[&"plush_hospital"].unlocked, "the Hospital needs a rescue")


func test_ac42_the_first_rescue_opens_the_hospital_when_you_get_home() -> void:
	main.town.plushies["bambam"] = "waiting"
	var town: Town = await go_to_town()
	var hospital: TownBuilding = town.buildings[&"plush_hospital"]
	assert_false(hospital.unlocked, "still tangled the moment you arrive")
	await wait_seconds(Town.ARRIVAL_REVEAL_SECONDS + 0.3)
	assert_true(hospital.unlocked, "then the yarn falls away")
	assert_true(town.is_banner_showing())
	assert_string_contains(town.banner_subtitle.text, "Plush Hospital")
	assert_true(SaveStore.read().revealed.has("plush_hospital"))
	main.show_town()
	await wait_physics_frames(2)
	var again: Town = main.current_screen as Town
	assert_true(again.buildings[&"plush_hospital"].unlocked, "open next time")
	assert_true(again.pending_reveals().is_empty(), "the moment plays once")
	assert_false(again.is_banner_showing())


func test_ac42_the_fort_grows_every_3_rebuilds_or_upgrades() -> void:
	main.town.materials = PLENTY.duplicate()
	var town: Town = await go_to_town()
	assert_eq(town.fort.pieces, 0)
	await _rebuild(town, &"toy_box_armory")
	await _rebuild(town, &"lucky_jar")
	assert_eq(town.fort.pieces, 0, "not yet after 2")
	await _rebuild(town, &"toy_box_armory")
	assert_eq(town.fort.pieces, 1, "a new piece after 3 rebuilds/upgrades")
	assert_true(town.fort.has_piece("flag"))
	main.show_town()
	await wait_physics_frames(2)
	assert_eq((main.current_screen as Town).fort.pieces, 1, "it stays")
