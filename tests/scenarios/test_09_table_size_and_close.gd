extends "res://tests/scenarios/run_scenario.gd"
## Scenario (#325, PO playtest 2026-11-21): the sewing table keeps its size when gear is hidden
## ("Hide all" or one slot's eye), and so does the hero picker's gear row. Every town panel
## (sewing table, Tricks, hero picker, Armory picker, Scrapbook) has a sewn X in its top right
## corner that closes it with a mouse click; Esc still works.

const WORKSHOP: StringName = &"sewing_workshop"
## Room the X may keep from the panel's top right corner (the felt padding plus a little).
const CORNER: float = 60.0

var town: Town


func before_each() -> void:
	super()
	main.town.building_levels[String(WORKSHOP)] = 2
	main.town.revealed.append(String(WORKSHOP))
	main.town.materials = {"coins": 99999, "stuffing": 999, "thread": 999}
	for id: String in ["lookout_cap", "patch_vest", "jingle_bell"]:
		main.town.gear.add_pattern(id)
		main.town.gear.stitches[id] = 1
	main.town.gear.put_on(0, "head", "lookout_cap")
	main.town.gear.put_on(0, "body", "patch_vest")
	main.town.plushies["pip"] = "in_town"
	main.town.revealed.append("wardrobe")
	main.town.revealed.append("hero:pip")
	town = await go_to_town()
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			break
		await wait_physics_frames(1)
	# Panels rest at once, so the X is where the player sees it.
	GameSettings.reduced_motion = true


func after_each() -> void:
	GameSettings.reduced_motion = false
	super()


func _open_table() -> SewingTable:
	town.sewing.open(town.buildings[WORKSHOP])
	await wait_process_frames(3)
	return town.sewing.table


func _press(button: BaseButton) -> void:
	button.pressed.emit()
	await wait_process_frames(3)


## Clicks the middle of `control` with the mouse. GUT's own output panel lies over the top
## right of the test window (where the X is): it is hidden while the mouse is there.
func _click(control: Control) -> void:
	var canvas: Vector2 = control.get_global_transform_with_canvas() * (control.size / 2.0)
	var window: Vector2 = control.get_viewport().get_screen_transform() * canvas
	sender.mouse_motion(window)
	await wait_process_frames(2)
	var hidden: Array[CanvasItem] = []
	var over: Control = control.get_viewport().gui_get_hovered_control()
	while over != null and over != control and not town.is_ancestor_of(over):
		var top: CanvasItem = _top_item(over)
		top.visible = false
		hidden.append(top)
		sender.mouse_motion(window)
		await wait_process_frames(2)
		over = control.get_viewport().gui_get_hovered_control()
	assert_eq(over, control, "the mouse is on the X")
	sender.mouse_left_button_down(window)
	await wait_process_frames(2)
	sender.mouse_left_button_up(window)
	await wait_process_frames(3)
	for item: CanvasItem in hidden:
		item.visible = true


## The outermost canvas item `item` belongs to (GUT's whole panel).
func _top_item(item: CanvasItem) -> CanvasItem:
	var top: CanvasItem = item
	while top.get_parent() is CanvasItem:
		top = top.get_parent() as CanvasItem
	return top


func test_hide_all_keeps_the_table_size() -> void:
	var table: SewingTable = await _open_table()
	var before: Vector2 = table.panel.content.size
	await _press(table.hide_all_toggle)
	assert_true(table.hide_all_toggle.hidden_now, "Hide all is on")
	assert_eq(table.panel.content.size, before, "the table keeps its size after Hide all")
	await _press(table.hide_all_toggle)
	assert_eq(table.panel.content.size, before, "and after Show all")
	await _press(table.eye_toggles[GearDef.Slot.HEAD])
	assert_true(table.eye_toggles[GearDef.Slot.HEAD].hidden_now, "the cap is hidden")
	assert_eq(table.panel.content.size, before, "and after hiding one slot")


func test_hide_all_keeps_the_picker_gear_row_size() -> void:
	town.wardrobe.open(0)
	await wait_process_frames(3)
	var picker: HeroPicker = town.wardrobe.picker
	assert_true(picker.gear_row.visible, "the gear row shows while gear is worn")
	var before: Vector2 = picker.gear_row.get_combined_minimum_size()
	await _press(picker.hide_all_toggle)
	assert_true(picker.hide_all_toggle.hidden_now, "Hide all is on")
	assert_eq(picker.gear_row.get_combined_minimum_size(), before, "the gear row keeps its size")
	await _press(picker.eye_toggles[GearDef.Slot.HEAD])
	assert_eq(picker.gear_row.get_combined_minimum_size(), before, "also after one slot's eye")


## `close_button` sits in the top right corner of `panel` and a click on it closes the screen.
func _check_close(
	screen: String, panel: FeltPanel, close_button: CloseStitch, open: Callable
) -> void:
	assert_true(open.call(), "%s is open" % screen)
	assert_true(close_button.is_visible_in_tree(), "%s shows an X" % screen)
	var box: Rect2 = panel.content.get_global_rect()
	var x: Rect2 = close_button.get_global_rect()
	assert_true(box.encloses(x), "%s: the X is on the panel" % screen)
	assert_lt(box.end.x - x.end.x, CORNER, "%s: the X is at the right edge" % screen)
	assert_lt(x.position.y - box.position.y, CORNER, "%s: the X is at the top" % screen)
	await _click(close_button)
	assert_false(open.call(), "%s: clicking the X closes it" % screen)
	assert_eq(town.process_mode, Node.PROCESS_MODE_INHERIT, "%s: the town goes on" % screen)


func test_every_town_panel_closes_with_its_x() -> void:
	var table: SewingTable = await _open_table()
	await _check_close("sewing table", table.panel, table.close_button, table.is_open)
	var armory: TownBuilding = town.buildings[&"toy_box_armory"]
	while town.dev_build(armory):
		pass
	await wait_physics_frames(3)
	assert_true(town.tricks.open(armory), "the Tricks panel opens")
	await wait_process_frames(3)
	var tricks: TricksPanel = town.tricks.panel
	await _check_close("tricks panel", tricks.panel, tricks.close_button, tricks.is_open)
	town.open_weapon_picker()
	await wait_process_frames(3)
	var picker: StartWeaponPicker = town.picker
	await _check_close("armory picker", picker.panel, picker.close_button, picker.is_visible)
	town.wardrobe.open(0)
	await wait_process_frames(3)
	var heroes: HeroPicker = town.wardrobe.picker
	await _check_close("hero picker", heroes.panel, heroes.close_button, heroes.is_visible)
	town.open_scrapbook()
	await wait_process_frames(3)
	var book: ScrapbookBook = town.book
	await _check_close("scrapbook", book.cover, book.close_button, book.is_visible)


func test_esc_still_closes_the_table() -> void:
	var table: SewingTable = await _open_table()
	await tap_action("pause")
	await wait_process_frames(2)
	assert_false(table.is_open(), "Esc closes it")
