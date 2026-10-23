extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §6, AC-43): the Toy Box Armory reaches the next run. A new save offers only
## the 6 starting weapons on level-up cards; level 1 adds Bouncy Yarn Ball + Thimble Mortar,
## level 2 Thread Whip + Zipper Ray; level 3 lets you choose Banane's starting weapon in town.

const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const ARMORY: String = "toy_box_armory"
## The four weapons the Armory unlocks.
const UNLOCKS: Array[StringName] = [
	&"bouncy_yarn_ball",
	&"thimble_mortar",
	&"thread_whip",
	&"zipper_ray",
]

var run: Run


## A pool with only these upgrades (plus the snack), so a scenario knows which cards can appear.
func _only(ids: Array[StringName]) -> UpgradePool:
	var pool: UpgradePool = POOL.duplicate()
	pool.upgrades = []
	for upgrade: UpgradeDef in POOL.upgrades:
		if ids.has(upgrade.id):
			pool.upgrades.append(upgrade)
	return pool


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## Levels Banane up once and returns the ids on the cards.
func _level_up_cards() -> Array[StringName]:
	var banane: Player = first_player()
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	var ids: Array[StringName] = []
	for card: UpgradeCard in run.level_up_screen.cards:
		ids.append(card.offer.upgrade.id)
	return ids


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


func test_ac43_a_new_save_never_offers_the_armory_weapons() -> void:
	await _quiet_run()
	assert_eq(run.perks.locked_weapons.size(), 4, "4 weapons wait in the Armory")
	run.upgrade_pool = _only(UNLOCKS)
	var cards: Array[StringName] = await _level_up_cards()
	assert_eq(cards.count(&"banana_snack"), 3, "only snacks are left")
	var result: RunResult = run.make_result("died")
	assert_eq(result.unlocked_weapons.size(), 0, "the 4-weapon test pool has none open")
	run.upgrade_pool = POOL
	assert_eq(run.make_result("died").unlocked_weapons.size(), 6, "the run log names the 6")


func test_ac43_armory_level_1_adds_yarn_ball_and_mortar() -> void:
	main.town.building_levels[ARMORY] = 1
	await _quiet_run()
	run.upgrade_pool = _only(UNLOCKS)
	var cards: Array[StringName] = await _level_up_cards()
	assert_has(cards, &"bouncy_yarn_ball")
	assert_has(cards, &"thimble_mortar")
	assert_does_not_have(cards, &"thread_whip", "not before level 2")
	assert_does_not_have(cards, &"zipper_ray", "not before level 2")


func test_ac43_armory_level_2_adds_whip_and_ray() -> void:
	main.town.building_levels[ARMORY] = 2
	await _quiet_run()
	run.upgrade_pool = _only([&"thread_whip", &"zipper_ray"])
	var cards: Array[StringName] = await _level_up_cards()
	assert_has(cards, &"thread_whip")
	assert_has(cards, &"zipper_ray")
	assert_eq(run.perks.locked_weapons.size(), 0, "every weapon is open")


func test_ac43_rebuilding_the_armory_shows_the_new_weapons() -> void:
	main.town.materials["coins"] = 5000
	var town: Town = await go_to_town()
	await _stand_at(town, &"toy_box_armory")
	await _press_e()
	assert_eq(main.town.building_level(ARMORY), 1)
	assert_true(town.unlock_toast.is_showing(), "a New weapons! moment")
	assert_eq(town.unlock_toast.names, PackedStringArray(["Bouncy Yarn Ball", "Thimble Mortar"]))


func test_ac43_level_3_lets_you_choose_the_starting_weapon_for_the_next_run() -> void:
	main.town.building_levels[ARMORY] = 3
	var town: Town = await go_to_town()
	var armory: TownBuilding = await _stand_at(town, &"toy_box_armory")
	assert_eq(town.prompt_label.text, "E   Choose starting weapon")
	assert_eq(town.card.note_label.text, "Starting weapon: Peel Boomerang", "his own at first")
	await _press_e()
	assert_true(town.picker.is_open(), "E opens the choice")
	assert_eq(town.picker.tiles.size(), 10, "every unlocked weapon")
	assert_eq(town.picker.current, &"peel_boomerang")
	assert_eq(town.process_mode, Node.PROCESS_MODE_DISABLED, "the town waits")
	town.picker.tiles[&"thimble_mortar"].pressed.emit()
	assert_false(town.picker.is_open(), "closes after the choice")
	assert_eq(main.town.start_weapon, "thimble_mortar")
	assert_eq(SaveStore.read().start_weapon, "thimble_mortar", "saved right away")
	await wait_physics_frames(2)
	assert_eq(town.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(town.card.note_label.text, "Starting weapon: Thimble Mortar")
	assert_eq(armory.level, 3)
	run = await start_run()
	var weapons: Array[Weapon] = first_player().weapons()
	assert_eq(weapons.size(), 1, "one starting weapon")
	assert_eq(weapons[0].stats.id, &"thimble_mortar", "the chosen one")


func test_ac43_no_choice_before_level_3() -> void:
	main.town.building_levels[ARMORY] = 2
	main.town.start_weapon = "thimble_mortar"
	var town: Town = await go_to_town()
	await _stand_at(town, &"toy_box_armory")
	await _press_e()
	assert_false(town.picker.is_open(), "E upgrades (or shows what's missing) instead")
	assert_eq(town.card.note_label.text, "")
	run = await start_run()
	assert_eq(first_player().weapons()[0].stats.id, &"peel_boomerang", "Banane's own")


func test_esc_closes_the_choice_without_changing_it() -> void:
	main.town.building_levels[ARMORY] = 3
	var town: Town = await go_to_town()
	await _stand_at(town, &"toy_box_armory")
	await _press_e()
	await tap_action("pause")
	assert_false(town.picker.is_open())
	assert_false(town.menu.is_open(), "Esc only closes the choice")
	assert_eq(main.town.start_weapon, "")
