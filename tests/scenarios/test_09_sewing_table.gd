extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §6, AC-98): E at a built Sewing Workshop opens the sewing table with the
## hero photo, its 3 slots and the 9 pieces. Sewing takes the right materials and puts the piece
## on (saved at once, with the needle and a pop), stitching makes it stronger, wearing another
## piece of the slot swaps it, R takes it off, Esc closes. Locked tiles say where their pattern
## comes from; the Charm row needs Workshop Lv 2. "Can sew!" floats over the Workshop while
## something can be sewn, and the table's button upgrades the Workshop.

const RICH: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 999}
const WORKSHOP: StringName = &"sewing_workshop"

var town: Town


func _rules() -> GearRules:
	return GearRules.current()


## A town with the Workshop at `level`, the patterns `found` and jars holding `materials`.
func _town_with(
	level: int, found: PackedStringArray, materials: Dictionary[String, int] = RICH
) -> void:
	main.town.building_levels[String(WORKSHOP)] = level
	main.town.revealed.append(String(WORKSHOP))
	main.town.materials = materials.duplicate()
	for id: String in found:
		main.town.gear.add_pattern(id)
	town = await go_to_town()
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			break
		await wait_physics_frames(1)


## Walks Banane right below the Workshop and presses E.
func _open_table() -> SewingTable:
	var rect: Rect2 = town.buildings[WORKSHOP].spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	await tap_action("p1_interact")
	await wait_physics_frames(1)
	return town.sewing.table


func _tile(id: StringName) -> GearTile:
	return town.sewing.table.tiles[id]


## Focuses `id`'s tile and presses `action` (E, R ...).
func _press_on(id: StringName, action: String) -> void:
	_tile(id).grab_focus()
	await tap_action(action)
	await wait_physics_frames(1)


func test_ac98_e_at_the_built_workshop_opens_the_table() -> void:
	await _town_with(1, PackedStringArray(["lookout_cap"]))
	var workshop: TownBuilding = town.buildings[WORKSHOP]
	var rect: Rect2 = workshop.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	assert_eq(town.prompt_label.text, "E   Open the sewing table", "the prompt says so")
	var table: SewingTable = await _open_table()
	assert_true(table.is_open(), "E opens the sewing table")
	assert_eq(town.process_mode, Node.PROCESS_MODE_DISABLED, "the town waits")
	assert_eq(workshop.level, 1, "E didn't upgrade the Workshop")
	assert_eq(table.tiles.size(), _rules().pieces.size(), "all 9 pieces")
	assert_eq(table.photo_frame.caption.text, "Banane", "the hero's photo")
	assert_eq(table.slot_labels.size(), 3, "Head, Body, Charm")
	assert_eq(table.slot_text(GearDef.Slot.HEAD), _rules().empty_slot)
	assert_eq(table.slot_text(GearDef.Slot.CHARM), "Needs Workshop Lv 2")
	assert_string_contains(table.hint_label.text, "R: take off")
	await tap_action("pause")
	await wait_physics_frames(1)
	assert_false(table.is_open(), "Esc closes it")
	assert_eq(town.process_mode, Node.PROCESS_MODE_INHERIT, "the town goes on")
	assert_false(town.menu.is_open(), "and Esc doesn't open the town menu too")


func test_ac98_locked_tiles_say_where_their_pattern_comes_from() -> void:
	await _town_with(1, PackedStringArray(["lookout_cap"]))
	await _open_table()
	assert_eq(_tile(&"lookout_cap").action, GearBook.Action.SEW, "found: Sew")
	assert_false(_tile(&"lookout_cap").picture.locked)
	var hat: GearTile = _tile(&"pin_cushion_hat")
	assert_true(hat.picture.locked, "not found: a silhouette")
	assert_eq(hat.name_label.text, "?")
	assert_eq(hat.note_label.text, "Build the Toy Box Armory to Lv 2")
	assert_false(hat.action_tag.visible, "nothing to do")
	assert_eq(_tile(&"propeller_cap").note_label.text, "Big Ted drops this")
	assert_eq(_tile(&"wind_up_key").note_label.text, "The Sock Puppet King drops this")
	assert_eq(_tile(&"raincoat").note_label.text, "Elites sometimes drop this")
	Sfx.history.clear()
	await _press_on(&"pin_cushion_hat", "p1_interact")
	assert_true(Sfx.history.has(&"ui_nope"), "locked: nope")
	for tile: GearTile in town.sewing.table.tiles.values():
		for label: Label in tile.find_children("*", "Label", true, false):
			var ink: Color = label.get_theme_color(&"font_color")
			assert_false(UiColors.is_danger(ink), "no danger colour on %s" % label.text)
		assert_false(UiColors.is_danger(tile.picture.fill_color()), "calm felt")


func test_ac98_sewing_takes_the_materials_puts_it_on_and_saves() -> void:
	await _town_with(1, PackedStringArray(["lookout_cap", "jingle_bell"]))
	var table: SewingTable = await _open_table()
	var cap: GearDef = _rules().find("lookout_cap")
	var tile: GearTile = _tile(&"lookout_cap")
	assert_eq(tile.cost_counters["coins"].shown, cap.level(1).coins, "the price")
	assert_eq(tile.action_tag.label.text, "Sew")
	var bell: GearTile = _tile(&"jingle_bell")
	assert_eq(bell.note_label.text, "Needs Workshop Lv 2", "the Charm slot isn't open yet")
	assert_false(bell.can_act)
	Sfx.history.clear()
	await _press_on(&"lookout_cap", "p1_interact")
	assert_eq(main.town.material("coins"), RICH["coins"] - cap.level(1).coins, "coins taken")
	assert_eq(main.town.material("stuffing"), RICH["stuffing"] - cap.level(1).stuffing)
	assert_eq(main.town.gear.stitch_level("lookout_cap"), 1, "sewn")
	assert_eq(main.town.gear.worn_in(0, "head"), "lookout_cap", "and put on")
	var saved: TownSave = SaveStore.read()
	assert_eq(saved.gear.stitch_level("lookout_cap"), 1, "saved at once")
	assert_eq(saved.gear.worn_in(0, "head"), "lookout_cap")
	assert_true(tile.is_sewing(), "the needle bobs")
	assert_eq(table.slot_text(GearDef.Slot.HEAD), "Lookout Cap ●○○", "on the photo")
	assert_true(tile.worn)
	assert_eq(tile.dots_label.text, "●○○")
	await wait_seconds(_rules().sewing_seconds + 0.2)
	assert_false(tile.is_sewing())
	assert_true(Sfx.history.has(&"pop"), "then a pop")
	assert_eq(table.find_children("*", "TownPuff", false, false).size(), 1, "and a small puff")
	assert_eq(tile.action_tag.label.text, "Take off", "Workshop Lv 1 can't stitch further")
	assert_eq(tile.note_label.text, "Needs Workshop Lv 2")


func test_ac98_stitching_swapping_and_taking_off() -> void:
	await _town_with(2, PackedStringArray(["lookout_cap", "pin_cushion_hat"]))
	main.town.gear.stitches["pin_cushion_hat"] = 1
	main.town.gear.stitches["lookout_cap"] = 1
	main.town.gear.put_on(0, "head", "lookout_cap")
	var table: SewingTable = await _open_table()
	var cap: GearDef = _rules().find("lookout_cap")
	assert_eq(_tile(&"lookout_cap").action_tag.label.text, "Stitch to Lv 2")
	var coins: int = main.town.material("coins")
	await _press_on(&"lookout_cap", "p1_interact")
	assert_eq(main.town.gear.stitch_level("lookout_cap"), 2, "stitched")
	assert_eq(main.town.material("coins"), coins - cap.level(2).coins, "Lv 2 price taken")
	assert_eq(SaveStore.read().gear.stitch_level("lookout_cap"), 2, "saved")
	assert_eq(_tile(&"pin_cushion_hat").action_tag.label.text, "Wear")
	coins = main.town.material("coins")
	_tile(&"pin_cushion_hat").pressed.emit()
	await wait_physics_frames(1)
	assert_eq(main.town.gear.worn_in(0, "head"), "pin_cushion_hat", "a click swaps it")
	assert_eq(main.town.material("coins"), coins, "free")
	assert_eq(table.slot_text(GearDef.Slot.HEAD), "Pin Cushion Hat ●○○")
	assert_eq(_tile(&"lookout_cap").action_tag.label.text, "Wear", "the cap is free again")
	await _press_on(&"pin_cushion_hat", "reroll_cards")
	assert_eq(main.town.gear.worn_in(0, "head"), "", "R takes it off")
	assert_eq(SaveStore.read().gear.worn_in(0, "head"), "", "saved")
	assert_eq(table.slot_text(GearDef.Slot.HEAD), _rules().empty_slot)
	Sfx.history.clear()
	await _press_on(&"pin_cushion_hat", "reroll_cards")
	assert_true(Sfx.history.has(&"ui_nope"), "nothing on: nope")


func test_ac98_short_of_materials_shows_what_is_missing_and_takes_nothing() -> void:
	var poor: Dictionary[String, int] = {"coins": 100, "stuffing": 0, "thread": 0}
	await _town_with(1, PackedStringArray(["lookout_cap"]), poor)
	await _open_table()
	var cap: GearDef = _rules().find("lookout_cap")
	var tile: GearTile = _tile(&"lookout_cap")
	assert_false(tile.can_act)
	var short: Array = [cap.level(1).coins - 100, cap.level(1).stuffing]
	var missing: String = "Needs %d more coins and %d more stuffing" % short
	assert_eq(tile.note_label.text, missing)
	assert_eq(tile.cost_counters["coins"].modulate, TownBuilding.SHORT_TINT, "grey price")
	Sfx.history.clear()
	await _press_on(&"lookout_cap", "p1_interact")
	assert_true(Sfx.history.has(&"ui_nope"))
	assert_eq(main.town.material("coins"), 100, "nothing taken")
	assert_eq(main.town.gear.stitch_level("lookout_cap"), 0)


func test_ac98_can_sew_floats_over_the_workshop() -> void:
	await _town_with(1, PackedStringArray(["lookout_cap"]))
	var workshop: TownBuilding = town.buildings[WORKSHOP]
	await wait_physics_frames(2)
	assert_eq(workshop.new_trick_tag.label.text, "Can sew!")
	main.town.materials = {"coins": 300, "stuffing": 10, "thread": 0}
	town.refresh()
	await wait_physics_frames(2)
	assert_true(workshop.shows_new_trick(), "Can sew! while a piece can be sewn")
	main.town.materials = {"coins": 0, "stuffing": 0, "thread": 0}
	town.refresh()
	await wait_physics_frames(2)
	assert_false(workshop.shows_new_trick(), "gone when nothing can be sewn")


func test_ac98_the_tables_button_upgrades_the_workshop() -> void:
	await _town_with(1, PackedStringArray(["jingle_bell"]))
	var table: SewingTable = await _open_table()
	var workshop: TownBuilding = town.buildings[WORKSHOP]
	var next: BuildingLevel = workshop.building.next(1)
	assert_true(table.upgrade_button.visible)
	assert_eq(table.upgrade_button.text, "Upgrade the Workshop to Lv 2")
	table.upgrade_button.pressed.emit()
	await wait_physics_frames(2)
	assert_false(table.is_open(), "the table steps aside for the build moment")
	assert_eq(workshop.level, 2, "upgraded")
	assert_eq(main.town.material("coins"), RICH["coins"] - next.coins, "paid")
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			break
		await wait_physics_frames(1)
	table = await _open_table()
	assert_true(table.is_open(), "E opens it again")
	assert_eq(_tile(&"jingle_bell").action, GearBook.Action.SEW, "the Charm slot is open now")
	assert_eq(table.slot_text(GearDef.Slot.CHARM), _rules().empty_slot)
	table.close()


func test_338_banane_on_the_photo_is_sharp_once_the_table_has_opened() -> void:
	await _town_with(1, PackedStringArray(["lookout_cap"]))
	var table: SewingTable = await _open_table()
	await wait_seconds(UiFeel.STYLE.open_seconds + 0.5)
	assert_not_null(table.photo.puppet, "Banane's felt puppet is on the photo")
	assert_eq(blurry_felt_pieces(table.photo.puppet), [] as Array[String], "drawn for its size")
	table.close()
