extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §8, §10, AC-101, AC-103): in co-op each player opens the sewing table with
## their own keys and wears their own pieces; a piece player 1 wears says "Player 1 wears it" on
## player 2's table and can't be worn twice. In a run every hero wears their own gear; the end
## screen tags it in each player's column (stitch level, hidden pieces too) and the run log has
## a `gear` field per player. The Scrapbook's Gear tab shows the 9 pieces: silhouettes until the
## pattern is found, then the effect and where the pattern comes from.

const WORKSHOP: StringName = &"sewing_workshop"
const SCRAPBOOK: ScrapbookRules = preload("res://data/scrapbook.tres")

var town: Town


func _rules() -> GearRules:
	return GearRules.current()


func _player(index: int) -> Player:
	for player: Player in Players.all(get_tree()):
		if player.player_index == index:
			return player
	return null


## Sews `id` at stitch level `level` (and finds its pattern).
func _sewn(id: String, level: int) -> void:
	main.town.gear.add_pattern(id)
	main.town.gear.stitches[id] = level


## Two players, the Workshop at `level`; the cap and the hat sewn, player 1 wears the cap.
func _coop_town(level: int) -> void:
	main.town.building_levels[String(WORKSHOP)] = level
	main.town.revealed.append(String(WORKSHOP))
	_sewn("lookout_cap", 1)
	_sewn("pin_cushion_hat", 1)
	main.town.gear.put_on(0, "head", "lookout_cap")
	main.player_count = 2
	add_controls(1)
	town = await go_to_town()
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			break
		await wait_physics_frames(1)


func _press_on(id: StringName, action: String) -> void:
	town.sewing.table.tiles[id].grab_focus()
	await tap_action(action)
	await wait_physics_frames(1)


func test_ac101_player_2_opens_their_own_table_and_cant_take_player_1s_piece() -> void:
	await _coop_town(1)
	var rect: Rect2 = town.buildings[WORKSHOP].spot.rect
	_player(1).global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	await tap_action("p2_interact")
	await wait_physics_frames(1)
	var table: SewingTable = town.sewing.table
	assert_true(table.is_open(), "player 2's E opens the table")
	assert_eq(table.opener, 1, "for player 2")
	var cap: GearTile = table.tiles[&"lookout_cap"]
	assert_eq(cap.note_label.text, "Player 1 wears it")
	assert_false(cap.can_act, "one copy per piece")
	Sfx.history.clear()
	await _press_on(&"lookout_cap", "p2_interact")
	assert_true(Sfx.history.has(&"ui_nope"), "nope")
	assert_eq(main.town.gear.wearer_of("lookout_cap"), 0, "player 1 still wears it")
	await _press_on(&"pin_cushion_hat", "p2_interact")
	assert_eq(main.town.gear.worn_in(1, "head"), "pin_cushion_hat", "player 2 wears the hat")
	assert_eq(main.town.gear.worn_in(0, "head"), "lookout_cap", "player 1 keeps the cap")
	assert_true(_player(1).gear.has(&"pin_cushion_hat"), "player 2's hero is dressed")
	assert_false(_player(1).gear.has(&"lookout_cap"))
	assert_true(_player(0).gear.has(&"lookout_cap"), "player 1's hero keeps the cap")
	assert_false(_player(0).gear.has(&"pin_cushion_hat"))
	await tap_action("pause")
	await wait_physics_frames(1)
	assert_false(table.is_open())
	var saved: TownSave = SaveStore.read()
	assert_eq(saved.gear.worn_in(1, "head"), "pin_cushion_hat", "saved per player")
	assert_eq(saved.gear.worn_in(0, "head"), "lookout_cap")


func test_ac101_player_1s_table_says_player_2_wears_it_and_r_takes_off_only_your_own() -> void:
	await _coop_town(1)
	main.town.gear.take_off(0, "head")
	main.town.gear.put_on(1, "head", "lookout_cap")
	town.refresh()
	town.sewing.open(town.buildings[WORKSHOP], 0)
	var table: SewingTable = town.sewing.table
	assert_eq(table.tiles[&"lookout_cap"].note_label.text, "Player 2 wears it")
	await _press_on(&"lookout_cap", "reroll_cards")
	assert_eq(main.town.gear.worn_in(1, "head"), "lookout_cap", "R doesn't undress player 2")
	table.close()


func test_ac101_ac103_a_coop_run_wears_tags_and_logs_each_players_gear() -> void:
	main.town.building_levels[String(WORKSHOP)] = 2
	_sewn("lookout_cap", 2)
	_sewn("jingle_bell", 1)
	_sewn("pin_cushion_hat", 3)
	main.town.gear.put_on(0, "head", "lookout_cap")
	main.town.gear.put_on(0, "charm", "jingle_bell")
	main.town.gear.set_hidden(0, "charm", true)
	main.town.gear.put_on(1, "head", "pin_cushion_hat")
	main.player_count = 2
	add_controls(1)
	var run: Run = await start_run()
	run.rescue_plan = null
	assert_eq(_player(0).gear.level_of(_rules().find("lookout_cap")), 2)
	assert_true(_player(0).gear.has(&"jingle_bell"), "a hidden piece is still worn")
	assert_eq(_player(1).gear.level_of(_rules().find("pin_cushion_hat")), 3)
	assert_false(_player(1).gear.has(&"lookout_cap"))
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_process_frames(2)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1)
	var gear: Array = entries[0]["gear"]
	assert_eq(gear.size(), 2, "one entry per player")
	assert_eq(gear[0], {"head": "lookout_cap:2", "charm": "jingle_bell:1"})
	assert_eq(gear[1], {"head": "pin_cushion_hat:3"})
	var end: EndScreen = main.current_screen as EndScreen
	assert_not_null(end)
	assert_eq(end.columns.size(), 2)
	assert_eq(_texts(end.columns[0].gear_tags), ["Lookout Cap Lv 2", "Jingle Bell Lv 1"])
	assert_eq(_texts(end.columns[1].gear_tags), ["Pin Cushion Hat Lv 3"])
	for tag: FabricTag in end.columns[0].gear_tags:
		assert_false(UiColors.is_danger(tag.box.fill), "calm tag")


func test_ac103_the_scrapbook_gear_tab() -> void:
	main.town.gear.add_pattern("lookout_cap")
	town = await go_to_town()
	town.open_scrapbook()
	var book: ScrapbookBook = town.book
	var index: int = book.pages.size() - 1
	assert_eq(book.pages[index].id, ScrapbookRules.GEAR, "the last tab")
	assert_eq(book.tabs[index].text, "Gear 1 / 9")
	book.show_page(index)
	assert_eq(book.tiles.size(), 9, "9 pieces")
	var cap: ScrapbookTile = book.tile_for("lookout_cap")
	assert_false(cap.picture.is_silhouette(), "its pattern was found")
	book.show_details(cap)
	assert_eq(book.detail_name.text, "Lookout Cap")
	assert_eq(book.detail_text.text, _rules().find("lookout_cap").text, "the effect")
	assert_eq(book.detail_note.text, "Build the Watchtower to Lv 2", "where it comes from")
	var coat: ScrapbookTile = book.tile_for("raincoat")
	assert_true(coat.picture.is_silhouette(), "not found: a silhouette")
	book.show_details(coat)
	assert_eq(book.detail_name.text, ScrapbookTile.UNSEEN_NAME)
	assert_eq(book.detail_note.text, "Elites sometimes drop this", "says where to find it")
	book.close()


func _texts(tags: Array[FabricTag]) -> Array[String]:
	var result: Array[String] = []
	for tag: FabricTag in tags:
		result.append(tag.label.text)
	return result
