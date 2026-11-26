extends "res://tests/scenarios/run_scenario.gd"
## Spec 04b §3 (AC-118): the corkboard by the door (E) and the town Esc menu's "My loadout" open
## the town page: hero, starting weapon with level and source, worn gear per slot, bought tricks
## by building (Bedroom-only marked) and the building bonuses, for every player in town.

const TEXTS: LoadoutTexts = preload("res://data/ui/loadout_view.tres")


func _arrive() -> Town:
	var town: Town = await go_to_town()
	await wait_physics_frames(3)
	while town.is_settling():
		await wait_physics_frames(1)
	town.welcome_banner = []
	return town


func _press_e_at_board(town: Town) -> void:
	var board: Rect2 = town.layout.loadout_board_rect
	first_player().global_position = Vector2(board.get_center().x, board.end.y + 30.0)
	await wait_physics_frames(3)
	await tap_action("p1_interact")
	await wait_physics_frames(2)


func test_ac118_the_corkboard_opens_the_page() -> void:
	main.town.gear.add_pattern("lookout_cap")
	main.town.gear.stitches["lookout_cap"] = 2
	main.town.gear.put_on(0, "head", "lookout_cap")
	main.town.revealed.append("sewing_workshop")
	main.town.building_levels["lucky_jar"] = 2
	main.town.building_levels["party_shop"] = 3
	main.town.tricks.append("head_start")
	main.town.tricks.append("treasure_map")
	var town: Town = await _arrive()
	var board: Rect2 = town.layout.loadout_board_rect
	first_player().global_position = Vector2(board.get_center().x, board.end.y + 30.0)
	await wait_physics_frames(3)
	assert_eq(town.prompt_label.text, KeyBindings.fill(TEXTS.board_prompt), "the board's prompt")
	await _press_e_at_board(town)
	var page: TownLoadoutPage = town.menu.loadout_page
	assert_true(page.is_visible_in_tree(), "E at the corkboard opens the page")
	assert_false(town.menu.panel.visible, "straight onto the page, not the menu")
	assert_eq(town.process_mode, Node.PROCESS_MODE_DISABLED, "the town waits")
	assert_eq(page.columns.size(), 1)
	var column: TownLoadoutColumn = page.columns[0]
	var hero: HeroStats = first_player().stats
	assert_eq(column.hero_id, hero.id)
	assert_eq(column.passive_text, hero.passive_text)
	assert_eq(column.start_weapon, hero.starting_weapon.id, "the hero's own weapon")
	assert_eq(column.start_source, TEXTS.own_weapon)
	assert_eq(column.start_level, 2, "Head Start: Lv 2")
	assert_eq(column.gear_rows.size(), 3, "Head, Body, Charm")
	assert_eq(column.gear_rows[0]["id"], &"lookout_cap")
	assert_eq(column.gear_rows[0]["level"], 2)
	assert_ne(column.gear_rows[0]["effect"], "", "the effect text shows")
	assert_eq(column.gear_rows[1]["empty"], TEXTS.empty_gear, "where to sew one")
	var armory: String = town.buildings[&"toy_box_armory"].spot.building.display_name
	assert_eq(page.bonuses.shown_tricks[armory], PackedStringArray(["Head Start"]))
	var map: FabricTag = page.bonuses.trick_tags[&"treasure_map"]
	assert_string_contains(map.label.text, TEXTS.bedroom_only, "Bedroom-only trick is marked")
	assert_ne(map.tooltip_text, "", "the trick text shows on hover")
	assert_false(page.bonuses.trick_tags[&"head_start"].label.text.contains(TEXTS.bedroom_only))
	var lines: PackedStringArray = page.bonuses.bonus_lines
	assert_has(lines, TEXTS.card_uses_bonus % 2, "Lucky Jar Lv 2 total")
	assert_has(lines, TEXTS.pickup_sooner % 45, "Party Shop Lv 3 total")
	assert_has(lines, TEXTS.first_pickup % "0:15")
	# Read it a moment (a screen open for under ~15 frames lets the closing key through, #336).
	await wait_physics_frames(20)
	await tap_action("p1_interact")
	await wait_physics_frames(2)
	assert_false(town.menu.is_open(), "E closes it again")
	assert_eq(town.process_mode, Node.PROCESS_MODE_INHERIT, "the town goes on")


func test_ac118_the_esc_menu_opens_it_and_esc_goes_back() -> void:
	var town: Town = await _arrive()
	await tap_action("pause")
	assert_true(town.menu.is_open())
	town.menu.loadout_button.pressed.emit()
	await wait_process_frames(2)
	var page: TownLoadoutPage = town.menu.loadout_page
	assert_true(page.is_visible_in_tree(), "My loadout opens the page")
	assert_eq(page.columns[0].gear_rows[0]["id"], &"", "nothing worn")
	assert_eq(page.columns[0].gear_rows[0]["empty"], "", "no Workshop hint before it shows")
	assert_true(page.bonuses.bonus_lines.is_empty(), "a fresh town has no bonuses")
	await tap_action("pause")
	assert_false(page.visible, "Esc goes back")
	assert_true(town.menu.is_open(), "to the menu")
	assert_true(town.menu.panel.visible)
	assert_true(town.menu.loadout_button.has_focus(), "back on My loadout")


func test_ac118_co_op_shows_every_player_with_the_armory_pick() -> void:
	main.town.plushies["pip"] = "in_town"
	main.town.building_levels["toy_box_armory"] = 3
	main.town.start_weapon = "yarn_cannon"
	main.player_count = 2
	add_controls(1)
	var town: Town = await _arrive()
	var players: Array[Player] = Players.all(town.get_tree())
	assert_eq(players.size(), 2)
	var second: Player = players[1] if players[1].player_index == 1 else players[0]
	second.global_position = Vector2(
		town.layout.loadout_board_rect.get_center().x, town.layout.loadout_board_rect.end.y + 30.0
	)
	await wait_physics_frames(3)
	await tap_action("p2_interact")
	await wait_physics_frames(2)
	var page: TownLoadoutPage = town.menu.loadout_page
	assert_true(page.is_visible_in_tree(), "player 2 opens it with their own key")
	assert_eq(page.columns.size(), 2, "one column per player")
	for index: int in 2:
		var column: TownLoadoutColumn = page.columns[index]
		assert_eq(column.player_index, index, "in player order")
		assert_eq(column.start_weapon, &"yarn_cannon", "the Armory pick")
		assert_eq(column.start_source, TEXTS.armory_weapon)
	assert_eq(page.columns[1].hero_id, second.stats.id, "player 2's own hero")
	await wait_physics_frames(20)
	await tap_action("p2_interact")
	await wait_physics_frames(2)
	assert_false(town.menu.is_open(), "their key closes it too")
