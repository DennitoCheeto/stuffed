extends "res://tests/scenarios/run_scenario.gd"
## M6-11 (spec 10 §6, AC-113): first-time hint notes in the town and the siege: town,
## can_build, tricks, siege_warning, siege, wardrobe, sewing. Each shows once at its moment,
## goes away when done, waits for banners and menus, never covers the hero.

const RULES: HintRules = preload("res://data/ui/hints.tres")


## Every hint except `id` counts as seen, so only `id` can show.
func _only(id: String) -> void:
	main.town.hints_seen.clear()
	main.town.hints_once.clear()
	for hint: HintDef in RULES.hints:
		if hint.id != id:
			main.town.hints_seen.append(hint.id)


func _wait_for_note(hints: HintBoard, id: String, seconds: float = 4.0) -> bool:
	for i: int in roundi(seconds * FPS):
		if hints.is_showing(id):
			return true
		await wait_physics_frames(1)
	return hints.is_showing(id)


func _wait_until_gone(hints: HintBoard, seconds: float = 3.0) -> bool:
	for i: int in roundi(seconds * FPS):
		if hints.note == null:
			return true
		await wait_physics_frames(1)
	return hints.note == null


func _wait_for_calm(town: Town, seconds: float = 8.0) -> void:
	for i: int in roundi(seconds * FPS):
		if not town.is_banner_showing() and not town.is_settling():
			return
		await wait_physics_frames(1)


func _building(town: Town, id: String) -> TownBuilding:
	return town.buildings[id]


func test_the_town_note_shows_on_the_first_visit_and_goes_after_the_first_build() -> void:
	_only("town")
	var town: Town = await go_to_town()
	var hints: TownHints = TownHints.of(town)
	assert_true(await _wait_for_note(hints, "town"), "the town note on the first visit")
	assert_true(hints.note.shown_text().contains(KeyBindings.key_text("interact")))
	for hero: Rect2 in hints.hero_rects():
		assert_false(hero.intersects(hints.note_rect()), "it never covers the hero")
	town.dev_build(_building(town, "lucky_jar"))
	assert_true(await _wait_until_gone(hints), "gone once something is built")
	assert_true(main.town.hints_seen.has("town"))


func test_can_build_shows_when_a_ruin_is_affordable_and_goes_after_building() -> void:
	_only("can_build")
	var town: Town = await go_to_town()
	var hints: TownHints = TownHints.of(town)
	await wait_seconds(0.5)
	assert_null(hints.note, "nothing affordable: no note")
	town.dev_menu.press(TownDevMenu.GIVE_MATERIALS)
	town.refresh()
	assert_true(await _wait_for_note(hints, "can_build"), "enough materials: the note shows")
	var ready: TownBuilding = null
	for building: TownBuilding in town.buildings.values():
		if building.shows_can_build():
			ready = building
	town.try_build(ready)
	assert_true(await _wait_until_gone(hints, 5.0), "gone once one more level stands")
	assert_true(main.town.hints_seen.has("can_build"))


func test_the_tricks_note_shows_after_the_first_build_and_goes_when_the_panel_opens() -> void:
	_only("tricks")
	var town: Town = await go_to_town()
	var hints: TownHints = TownHints.of(town)
	var jar: TownBuilding = _building(town, "lucky_jar")
	town.dev_build(jar)
	await _wait_for_calm(town)
	assert_true(await _wait_for_note(hints, "tricks"), "a building with tricks stands")
	assert_true(hints.note.shown_text().contains(KeyBindings.key_text("tricks")))
	town.tricks.open(jar, 0)
	await wait_physics_frames(2)
	assert_false(hints.note != null and hints.note.visible, "the note hides while the panel shows")
	town.tricks.panel.close()
	assert_true(await _wait_until_gone(hints), "gone once the tricks were opened")
	assert_true(main.town.hints_seen.has("tricks"))


func test_the_siege_warning_waits_for_the_banner_then_shows() -> void:
	_only("siege_warning")
	var town: Town = await go_to_town()
	var hints: TownHints = TownHints.of(town)
	town.show_banner("Banner", "on screen")
	main.town.siege_nights = 3
	town.refresh()
	await wait_seconds(0.5)
	assert_null(hints.note, "no note while a banner shows")
	await _wait_for_calm(town)
	assert_true(
		await _wait_for_note(hints, "siege_warning"), "the calendar shows: the note follows"
	)
	hints.showing_for = RULES.show_seconds - 0.1
	assert_true(await _wait_until_gone(hints), "it goes after a while")
	assert_true(main.town.hints_once.has("siege_warning"), "and shows once more next time")


func test_the_wardrobe_note_shows_when_it_appears_and_goes_when_it_opens() -> void:
	_only("wardrobe")
	var town: Town = await go_to_town()
	var hints: TownHints = TownHints.of(town)
	town.dev_menu.press(TownDevMenu.UNLOCK_HEROES)
	town.settle()
	await _wait_for_calm(town)
	assert_true(town.wardrobe.visible)
	assert_true(await _wait_for_note(hints, "wardrobe"), "the Wardrobe appeared")
	town.wardrobe.open(0)
	await wait_physics_frames(2)
	town.wardrobe.picker.close()
	assert_true(await _wait_until_gone(hints), "gone once it was opened")
	assert_true(main.town.hints_seen.has("wardrobe"))


func test_the_sewing_note_shows_when_the_workshop_appears_and_goes_at_the_table() -> void:
	_only("sewing")
	var town: Town = await go_to_town()
	var hints: TownHints = TownHints.of(town)
	town.dev_menu.press(TownDevMenu.GIVE_PATTERNS)
	town.settle()
	await _wait_for_calm(town, 12.0)
	var workshop: TownBuilding = _building(town, GearRules.current().workshop)
	assert_false(workshop.waiting_for_reveal, "the Workshop was revealed")
	assert_true(await _wait_for_note(hints, "sewing"), "the Workshop is there")
	town.dev_build(workshop)
	await _wait_for_calm(town)
	town.interact(workshop, 0)
	await wait_physics_frames(2)
	assert_true(town.sewing.table.visible, "the table opened")
	town.sewing.table.close()
	assert_true(await _wait_until_gone(hints), "gone once the table was opened")
	assert_true(main.town.hints_seen.has("sewing"))


func test_the_siege_note_shows_at_the_start_and_goes_with_the_second_wave() -> void:
	_only("siege")
	await go_to_town()
	main.start_siege()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	var hints: RunHints = RunHints.of(siege)
	assert_true(await _wait_for_note(hints, "siege"), "the first siege starts")
	siege.next_wave()
	assert_true(await _wait_until_gone(hints), "gone once the next wave comes")
	assert_true(main.town.hints_seen.has("siege"))


func test_no_town_note_with_hints_off() -> void:
	main.town.hints_seen.clear()
	GameSettings.hints = false
	var town: Town = await go_to_town()
	await wait_seconds(1.0)
	assert_null(TownHints.of(town).note, "Hints off: no note")
	GameSettings.hints = true
