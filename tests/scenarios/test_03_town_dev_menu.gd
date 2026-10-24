extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §10, §11): the developer menu in town (F1) gives materials, builds any
## building for free, adds a plushie, fills and clears the Scrapbook and resets the town, and
## everything it changes is saved. Plus the town's small sounds: page turns, waving plushies.

const SCRAPBOOK: ScrapbookRules = preload("res://data/scrapbook.tres")
const PIP: PlushieDef = preload("res://data/town/plushies/pip.tres")

var town: Town


func _menu() -> TownDevMenu:
	return town.dev_menu


func _settle() -> void:
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func _press_f1() -> void:
	sender.key_down(KEY_F1)
	await wait_process_frames(2)
	sender.key_up(KEY_F1)
	await wait_process_frames(1)


func test_f1_opens_and_closes_the_menu() -> void:
	town = await go_to_town()
	assert_false(_menu().visible)
	await _press_f1()
	assert_true(_menu().visible, "F1 opens it")
	await _press_f1()
	assert_false(_menu().visible, "F1 closes it")


func test_give_materials_fills_the_jars_and_saves() -> void:
	town = await go_to_town()
	_menu().press(TownDevMenu.GIVE_MATERIALS)
	for material: String in TownDevMenu.GIFT:
		assert_eq(main.town.material(material), TownDevMenu.GIFT[material], material)
		assert_eq(town.jars[material].shown, TownDevMenu.GIFT[material], "the jar shows it")
	assert_eq(SaveStore.read().material("coins"), TownDevMenu.GIFT["coins"], "saved")
	_menu().press(TownDevMenu.EMPTY_JARS)
	assert_eq(main.town.material("coins"), 0, "and empties them again")


func test_build_raises_any_building_for_free_even_a_locked_one() -> void:
	town = await go_to_town()
	var party_shop: TownBuilding = town.buildings[&"party_shop"]
	assert_false(party_shop.unlocked, "still tangled in yarn")
	_menu().press(TownDevMenu.build_label(party_shop))
	assert_eq(main.town.building_level("party_shop"), 1, "built")
	assert_eq(main.town.material("coins"), 0, "for free")
	assert_eq(SaveStore.read().building_level("party_shop"), 1, "saved")
	await _settle()
	_menu().press(TownDevMenu.build_label(party_shop))
	await _settle()
	assert_eq(party_shop.shown_level, 2, "upgrades with the moment")


func test_build_everything_puts_every_building_at_its_top_level() -> void:
	town = await go_to_town()
	_menu().press(TownDevMenu.BUILD_ALL)
	for spot: TownSpot in town.layout.spots:
		var top: int = spot.building.levels.size()
		assert_eq(main.town.building_level(String(spot.id)), top, String(spot.id))
		assert_eq(town.buildings[spot.id].shown_level, top)


func test_add_plushie_waits_in_the_tent_then_moves_in_with_a_bed() -> void:
	town = await go_to_town()
	var who: PlushieDef = _menu().add_plushie()
	assert_not_null(who)
	assert_eq(main.town.plushies.get(who.id, ""), "waiting", "no Hospital yet: waits in the tent")
	_menu().press(TownDevMenu.build_label(town.buildings[&"plush_hospital"]))
	await _settle()
	assert_eq(main.town.plushies[who.id], "in_town", "moves in once there's a bed")
	assert_true(town.plushies.has(who.id), "and walks around")


func test_fill_and_clear_the_scrapbook() -> void:
	town = await go_to_town()
	_menu().press(TownDevMenu.FILL_BOOK)
	for page: ScrapbookPage in SCRAPBOOK.pages():
		assert_eq(page.seen_count(main.town), page.entries.size(), "%s full" % page.id)
	assert_true(SaveStore.read().has_seen(ScrapbookRules.PLUSHIES, PIP.id), "saved")
	_menu().press(TownDevMenu.CLEAR_BOOK)
	for page: ScrapbookPage in SCRAPBOOK.pages():
		assert_eq(page.seen_count(main.town), 0, "%s empty" % page.id)


func test_reset_town_asks_once_then_starts_a_fresh_town() -> void:
	main.town.materials["coins"] = 500
	main.town.building_levels["toy_box_armory"] = 2
	town = await go_to_town()
	_menu().press(TownDevMenu.RESET)
	await wait_physics_frames(1)
	assert_eq(main.current_screen, town, "the first press only asks")
	assert_eq(main.town.material("coins"), 500)
	_menu().press(TownDevMenu.RESET)
	await wait_physics_frames(2)
	var fresh: Town = main.current_screen as Town
	assert_not_null(fresh, "back in a town")
	assert_ne(fresh, town, "a new one")
	assert_eq(main.town.material("coins"), 0, "jars empty")
	assert_eq(main.town.building_level("toy_box_armory"), 0, "all ruins again")
	assert_eq(fresh.buildings[&"toy_box_armory"].level, 0)


func test_turning_a_scrapbook_page_rustles() -> void:
	town = await go_to_town()
	town.open_scrapbook()
	Sfx.history.clear()
	town.book.turn(1)
	assert_true(Sfx.history.has(&"page"))


func test_a_plushie_squeaks_when_it_waves() -> void:
	town = await go_to_town()
	var player: Player = first_player()
	var at: Vector2 = player.global_position + Vector2(0, 120)
	var plushie: TownPlushie = town.spawn_plushie(PIP, at, true)
	Sfx.history.clear()
	for i: int in roundi(2.0 * FPS):
		if plushie.waves > 0:
			break
		await wait_physics_frames(1)
	assert_gt(plushie.waves, 0, "it waves at the player")
	assert_true(Sfx.history.has(&"hello"), "with a small squeak")
