extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §2, §4, §7, AC-67): T at a built building opens its Tricks panel with the 3
## tricks and their state (bought / can buy / needs level / missing materials); buying sews the
## patch on, pops and saves at once; the first panel shows the hint; built buildings float a
## "New trick!" tag ("Can build!" wins) and reaching level 1 shows "New: <Building> tricks!".

var town: Town


func _settle() -> void:
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


## Puts Banane right below `id`'s spot (in reach) and returns its building.
func _stand_at(id: StringName) -> TownBuilding:
	var building: TownBuilding = town.buildings[id]
	var rect: Rect2 = building.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	return building


func _press(action: String) -> void:
	await tap_action(action)
	await wait_physics_frames(1)


func _states() -> Array[TrickBook.State]:
	var result: Array[TrickBook.State] = []
	for patch: TrickPatch in town.tricks.panel.patches:
		result.append(patch.state)
	return result


func test_ac67_t_at_a_built_building_opens_its_tricks_with_their_state() -> void:
	main.town.building_levels["snack_bar"] = 2
	main.town.tricks.append("picnic")
	main.town.materials = {"coins": 5000, "stuffing": 100, "thread": 0}
	town = await go_to_town()
	var bar: TownBuilding = await _stand_at(&"snack_bar")
	assert_eq(town.card.tricks_label.text, "T   Tricks (1 of 3)", "the card says T opens them")
	assert_true(town.card.tricks_label.visible)
	await _press("p1_tricks")
	var panel: TricksPanel = town.tricks.panel
	assert_true(panel.is_open(), "T opens the Tricks panel")
	assert_eq(panel.building, bar)
	assert_eq(town.process_mode, Node.PROCESS_MODE_DISABLED, "the town waits")
	assert_eq(panel.patches.size(), 3, "all 3 tricks")
	var wanted: Array[TrickBook.State] = [
		TrickBook.State.BOUGHT, TrickBook.State.CAN_BUY, TrickBook.State.NEEDS_LEVEL
	]
	assert_eq(_states(), wanted)
	for index: int in 3:
		var patch: TrickPatch = panel.patches[index]
		var trick: TrickDef = bar.building.tricks[index]
		assert_eq(patch.name_label.text, trick.display_name, "name")
		assert_eq(patch.text_label.text, trick.text, "one line of text")
		assert_eq(patch.badge.is_star(), index == 2, "the 3rd is the star trick")
	assert_true(panel.patches[0].check.visible, "bought: the check stitch")
	assert_eq(panel.patches[0].state_label.text, TrickPatch.BOUGHT_TEXT)
	assert_false(panel.patches[1].disabled, "can buy")
	assert_eq(panel.patches[1].cost_counters["coins"].shown, bar.building.tricks[1].coins, "price")
	assert_true(panel.patches[2].disabled, "greyed")
	assert_eq(panel.patches[2].state_label.text, "Needs Lv 3")
	await _press("pause")
	assert_false(panel.is_open(), "Esc closes it")
	assert_eq(town.process_mode, Node.PROCESS_MODE_INHERIT, "the town goes on")
	assert_false(town.menu.is_open(), "and Esc doesn't open the town menu too")


func test_ac67_missing_materials_and_the_trick_before_it_are_shown() -> void:
	main.town.building_levels["snack_bar"] = 3
	main.town.materials = {"coins": 100, "stuffing": 0, "thread": 0}
	town = await go_to_town()
	await _stand_at(&"snack_bar")
	await _press("p1_tricks")
	var panel: TricksPanel = town.tricks.panel
	var wanted: Array[TrickBook.State] = [
		TrickBook.State.MISSING, TrickBook.State.NEEDS_EARLIER, TrickBook.State.NEEDS_EARLIER
	]
	assert_eq(_states(), wanted)
	var first: TrickDef = panel.building.building.tricks[0]
	var coins_short: int = first.coins - 100
	var missing: String = "Needs %d more coins and %d more stuffing" % [coins_short, first.stuffing]
	assert_eq(panel.patches[0].state_label.text, missing, "the missing materials")
	assert_eq(panel.patches[0].cost_counters["coins"].modulate, TownBuilding.SHORT_TINT, "grey")
	assert_eq(panel.patches[1].state_label.text, TrickPatch.EARLIER_TEXT)
	for patch: TrickPatch in panel.patches:
		for label: Label in patch.find_children("*", "Label", true, false):
			var ink: Color = label.get_theme_color(&"font_color")
			assert_false(UiColors.is_danger(ink), "no danger colour on %s" % label.text)
	Sfx.history.clear()
	await _press("pick_card_1")
	assert_true(Sfx.history.has(&"ui_nope"), "can't buy: nope")
	assert_eq(main.town.material("coins"), 100, "nothing taken")
	panel.close()


func test_ac67_buying_sews_the_patch_on_and_saves_at_once() -> void:
	main.town.building_levels["lucky_jar"] = 1
	main.town.materials = {"coins": 5000, "stuffing": 100, "thread": 20}
	town = await go_to_town()
	var jar: TownBuilding = await _stand_at(&"lucky_jar")
	var first: TrickDef = jar.building.tricks[0]
	await _press("p1_tricks")
	var panel: TricksPanel = town.tricks.panel
	assert_true(panel.shows_first_hint(), "the very first panel: the hint")
	assert_eq(panel.hint_label.text, "Tricks work in every run. Buy them in order.")
	Sfx.history.clear()
	await _press("pick_card_1")
	assert_true(main.town.has_trick(String(first.id)), "bought")
	assert_eq(main.town.material("coins"), 5000 - first.coins, "paid once")
	assert_true(SaveStore.read().has_trick(String(first.id)), "saved at once")
	assert_true(Sfx.history.has(&"pop"), "with a pop")
	assert_eq(panel.patches[0].state, TrickBook.State.BOUGHT)
	assert_true(panel.patches[0].check.visible, "the check stitch is sewn on")
	assert_eq(panel.find_children("*", "TownPuff", false, false).size(), 1, "a small puff")
	assert_eq(panel.patches[1].state, TrickBook.State.NEEDS_LEVEL, "trick 2 still needs Lv 2")
	assert_eq(town.jars["coins"].shown, 5000 - first.coins, "the jars show it")
	assert_false(panel.shows_first_hint(), "the hint was for the first time only")
	await _press("pick_card_1")
	assert_eq(main.town.material("coins"), 5000 - first.coins, "a bought trick isn't paid twice")
	await _press("p1_tricks")
	assert_false(panel.is_open(), "T closes it again")
	await _press("p1_tricks")
	assert_true(panel.is_open(), "and opens it again")
	assert_false(panel.shows_first_hint(), "no hint any more")
	panel.close()


func test_ac67_clicking_a_patch_buys_it() -> void:
	main.town.building_levels["watchtower"] = 1
	main.town.revealed.append("watchtower")
	main.town.building_levels["toy_box_armory"] = 1
	main.town.materials = {"coins": 5000, "stuffing": 100, "thread": 20}
	town = await go_to_town()
	var tower: TownBuilding = town.buildings[&"watchtower"]
	assert_true(town.tricks.open(tower))
	await wait_seconds(UiFeel.STYLE.open_seconds + 0.1)
	town.tricks.panel.patches[0].pressed.emit()
	assert_true(main.town.has_trick(String(tower.building.tricks[0].id)), "a click buys it too")
	town.tricks.panel.close()


func test_ac67_ruins_have_no_tricks_and_keep_their_price_tag() -> void:
	main.town.materials = {"coins": 5000, "stuffing": 100, "thread": 20}
	town = await go_to_town()
	var armory: TownBuilding = await _stand_at(&"toy_box_armory")
	assert_false(town.card.tricks_label.visible, "no tricks line on a ruin")
	assert_true(armory.price_tag.visible, "the price tag stays (AC-61)")
	await _press("p1_tricks")
	assert_false(town.tricks.panel.is_open(), "T does nothing at a ruin")
	assert_eq(main.town.building_level("toy_box_armory"), 0, "and builds nothing")


func test_new_trick_tag_shows_when_a_trick_can_be_bought_and_can_build_wins() -> void:
	main.town.building_levels["snack_bar"] = 1
	main.town.materials = {"coins": 0, "stuffing": 0, "thread": 0}
	town = await go_to_town()
	var bar: TownBuilding = town.buildings[&"snack_bar"]
	var first: TrickDef = bar.building.tricks[0]
	await wait_physics_frames(2)
	assert_false(bar.shows_new_trick(), "empty jars: no tag")
	main.town.materials = first.cost().duplicate()
	town.refresh()
	await wait_physics_frames(2)
	assert_true(bar.shows_new_trick(), "a trick can be bought: New trick!")
	assert_false(bar.shows_can_build(), "the next level is too dear")
	assert_true(bar.shown_texts().has(TownBuilding.NEW_TRICK_TEXT))
	var tag_top: float = bar.new_trick_tag.position.y + bar.new_trick_tag.size.y
	assert_lt(tag_top, bar.spot.rect.end.y + bar.shown_look().bounds().position.y, "over it")
	main.town.materials = {"coins": 9000, "stuffing": 300, "thread": 60}
	town.refresh()
	await wait_physics_frames(2)
	assert_true(bar.shows_can_build(), "the next level can be paid too")
	assert_false(bar.shows_new_trick(), "Can build! wins: one tag at a time")
	assert_false(UiColors.is_danger(bar.new_trick_tag.box.fill), "no danger colour")


func test_reaching_level_1_shows_new_building_tricks() -> void:
	main.town.materials = {"coins": 9000, "stuffing": 300, "thread": 60}
	town = await go_to_town()
	var jar: TownBuilding = await _stand_at(&"lucky_jar")
	await _press("p1_interact")
	assert_eq(main.town.building_level("lucky_jar"), 1, "rebuilt")
	assert_true(town.tricks.toast.is_showing(), "the toast")
	assert_eq(town.tricks.toast.title_label.text, "New: Lucky Jar tricks!")
	await _settle()
	await _stand_at(&"lucky_jar")
	assert_eq(town.card.tricks_label.text, "T   Tricks (0 of 3)")
	town.tricks.toast.visible = false
	await _press("p1_interact")
	await _settle()
	assert_eq(jar.level, 2)
	assert_false(town.tricks.toast.is_showing(), "only at level 1")


func test_the_armory_toast_waits_for_the_new_weapons_toast() -> void:
	main.town.materials = {"coins": 9000, "stuffing": 300, "thread": 60}
	town = await go_to_town()
	await _stand_at(&"toy_box_armory")
	await _press("p1_interact")
	assert_true(town.unlock_toast.is_showing(), "New weapons first")
	assert_false(town.tricks.toast.is_showing(), "the tricks toast waits")
	assert_true(town.tricks.toast.is_pending())
	await wait_seconds(WeaponUnlockToast.SHOW_SECONDS + 0.3)
	assert_true(town.tricks.toast.is_showing(), "then New: Toy Box Armory tricks!")


func test_player_2_opens_the_panel_with_their_own_key() -> void:
	main.town.building_levels["snack_bar"] = 1
	main.player_count = 2
	add_controls(1)
	town = await go_to_town()
	var bar: TownBuilding = town.buildings[&"snack_bar"]
	var rect: Rect2 = bar.spot.rect
	_player(0).global_position = town.layout.spawn_position
	_player(1).global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	await _press("p2_tricks")
	assert_true(town.tricks.panel.is_open(), "player 2 at the Snack Bar")
	assert_eq(town.tricks.panel.opener, 1)
	await _press("p2_tricks")
	assert_false(town.tricks.panel.is_open(), "and closes it with their key")


func _player(index: int) -> Player:
	for player: Player in Players.all(get_tree()):
		if player.player_index == index:
			return player
	return null
