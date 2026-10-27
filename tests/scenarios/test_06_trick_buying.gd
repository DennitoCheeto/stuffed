extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §2, §5, §6, AC-66, AC-68): buying a building trick in town pays once and
## saves at once; the developer menu gives and clears all tricks; "Reset town" clears them too.

var town: Town


func _settle() -> void:
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func _armory() -> TownBuilding:
	return town.buildings[&"toy_box_armory"]


func test_ac66_buying_a_trick_pays_once_and_saves_at_once() -> void:
	town = await go_to_town()
	var armory: TownBuilding = _armory()
	var first: TrickDef = armory.building.tricks[0]
	assert_false(town.tricks.try_buy(armory, 0), "a ruin has no tricks")
	town.dev_menu.press(TownDevMenu.build_label(armory))
	await _settle()
	assert_false(town.tricks.try_buy(armory, 0), "the jars are empty")
	assert_false(SaveStore.read().has_trick(String(first.id)))
	town.dev_menu.press(TownDevMenu.GIVE_MATERIALS)
	var coins: int = main.town.material("coins")
	assert_true(town.tricks.try_buy(armory, 0), "built + paid: bought")
	assert_eq(main.town.material("coins"), coins - first.coins, "paid once")
	assert_false(town.tricks.try_buy(armory, 0), "not twice")
	assert_eq(main.town.material("coins"), coins - first.coins)
	assert_false(town.tricks.try_buy(armory, 1), "trick 2 needs Lv 2")
	var saved: TownSave = SaveStore.read()
	assert_true(saved.has_trick(String(first.id)), "saved at once")
	assert_eq(saved.material("coins"), coins - first.coins)


func test_ac68_tricks_come_back_after_reopening_the_game() -> void:
	town = await go_to_town()
	town.dev_menu.press(TownDevMenu.build_label(_armory()))
	await _settle()
	town.dev_menu.press(TownDevMenu.GIVE_MATERIALS)
	assert_true(town.tricks.try_buy(_armory(), 0))
	var before: Dictionary = main.town.to_dict()
	main.load_town()
	assert_eq(main.town.to_dict(), before, "same town after loading it again")
	assert_true(main.town.has_trick(String(_armory().building.tricks[0].id)))


func test_dev_menu_gives_and_clears_all_tricks() -> void:
	town = await go_to_town()
	town.dev_menu.press(TownDevMenu.GIVE_TRICKS)
	var all: Array[TrickDef] = TrickBook.all_tricks(town.layout)
	assert_eq(main.town.tricks.size(), all.size(), "every trick")
	assert_eq(SaveStore.read().tricks.size(), all.size(), "saved")
	town.dev_menu.press(TownDevMenu.GIVE_TRICKS)
	assert_eq(main.town.tricks.size(), all.size(), "no doubles")
	town.dev_menu.press(TownDevMenu.CLEAR_TRICKS)
	assert_eq(main.town.tricks.size(), 0)
	assert_eq(SaveStore.read().tricks.size(), 0, "saved")


func test_reset_town_clears_the_tricks() -> void:
	town = await go_to_town()
	town.dev_menu.press(TownDevMenu.GIVE_TRICKS)
	town.dev_menu.press(TownDevMenu.RESET)
	town.dev_menu.press(TownDevMenu.RESET)
	await wait_process_frames(2)
	assert_eq(main.town.tricks.size(), 0, "a fresh town has no tricks")
	assert_false(SaveStore.exists() and SaveStore.read().tricks.size() > 0, "not on disk either")
