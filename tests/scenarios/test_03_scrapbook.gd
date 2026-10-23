extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §8, AC-46): E at the Scrapbook stand (or the title's Scrapbook button) opens
## the book. Seen entries show their felt picture, name and text, unseen ones a silhouette and
## "?", and every page counts what was found. What you meet in a run is in the book afterwards,
## and the Recipes page remembers evolutions across sessions.

const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")


func _town() -> Town:
	return main.current_screen as Town


## Puts Banane right below the Scrapbook stand.
func _walk_to_stand(town: Town) -> void:
	var stand: Rect2 = town.layout.scrapbook_rect
	first_player().global_position = Vector2(stand.get_center().x, stand.end.y + 40.0)
	await wait_physics_frames(2)


## Opens the book the way the player does: E next to the stand.
func _open_book() -> ScrapbookBook:
	var town: Town = _town()
	await _walk_to_stand(town)
	await tap_action("p1_interact")
	await wait_physics_frames(1)
	return town.book


func _press_key(key: Key) -> void:
	sender.key_down(key)
	await wait_physics_frames(2)
	sender.key_up(key)
	await wait_physics_frames(1)


func _turn_to(book: ScrapbookBook, page_id: String) -> void:
	for i: int in book.pages.size():
		if book.current_page().id == page_id:
			return
		await _press_key(KEY_E)


func _restart_game() -> void:
	remove_child(main)
	main.free()
	main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	add_child_autofree(main)
	await wait_physics_frames(1)


func test_ac46_e_at_the_stand_opens_the_book_and_esc_closes_it() -> void:
	var town: Town = await go_to_town()
	await _walk_to_stand(town)
	assert_eq(town.prompt_label.text, "E   Open the Scrapbook")
	var book: ScrapbookBook = await _open_book()
	assert_true(book.is_open(), "the book opens")
	assert_eq(town.process_mode, Node.PROCESS_MODE_DISABLED, "the town waits")
	assert_eq(book.current_page().title, "Weapons", "it opens on the first page")
	assert_eq(book.tiles.size(), 14)
	await tap_action("pause")
	assert_false(book.is_open(), "Esc closes it")
	assert_eq(town.process_mode, Node.PROCESS_MODE_INHERIT, "the town goes on")
	assert_false(town.menu.is_open(), "Esc doesn't also open the town menu")


func test_ac46_seen_entries_show_picture_name_and_text_unseen_ones_a_question_mark() -> void:
	main.town.mark_seen(ScrapbookRules.WEAPONS, "peel_boomerang")
	await go_to_town()
	var book: ScrapbookBook = await _open_book()
	var boomerang: ScrapbookTile = book.tile_for("peel_boomerang")
	assert_eq(boomerang.name_label.text, "Peel Boomerang")
	assert_false(boomerang.picture.is_silhouette(), "in felt")
	assert_eq(book.detail_name.text, "Peel Boomerang", "the first entry is in focus")
	assert_string_contains(book.detail_text.text, "Throws a peel")
	assert_eq(book.detail_note.text, "Evolves with Quick Feet", "its evolution partner")
	var ray: ScrapbookTile = book.tile_for("zipper_ray")
	assert_eq(ray.name_label.text, "?")
	assert_true(ray.picture.is_silhouette(), "a silhouette")
	assert_not_null(ray.picture.mark, "with a ?")
	ray.grab_focus()
	await wait_physics_frames(1)
	assert_eq(book.detail_name.text, "?")
	assert_eq(book.detail_text.text, ScrapbookBook.UNSEEN_TEXT, "no spoilers")
	assert_false(book.detail_text.text.contains("Zipper"), "no name either")


func test_ac46_every_page_counts_what_was_found_and_q_e_turn_the_pages() -> void:
	main.town.mark_seen(ScrapbookRules.WEAPONS, "peel_boomerang")
	main.town.mark_seen(ScrapbookRules.WEAPONS, "banana_split")
	main.town.mark_seen(ScrapbookRules.ITEMS, "quick_feet")
	main.town.mark_seen(ScrapbookRules.ENEMIES, "shambler")
	main.town.mark_seen(ScrapbookRules.ENEMIES, "elite")
	main.town.mark_seen(ScrapbookRules.ENEMIES, "big_ted")
	main.town.plushies["pip"] = "in_town"
	main.town.mark_seen(ScrapbookRules.PLUSHIES, "pip")
	await go_to_town()
	var book: ScrapbookBook = await _open_book()
	var counts: Array[String] = []
	for tab: Button in book.tabs:
		counts.append(tab.text)
	var expected: Array[String] = [
		"Weapons 2 / 14", "Items 1 / 8", "Enemies 3 / 8", "Floor pickups 0 / 3", "Plushies 1 / 4"
	]
	assert_eq(counts, expected)
	await _press_key(KEY_E)
	assert_eq(book.current_page().title, "Items", "E turns forward")
	await _press_key(KEY_E)
	assert_eq(book.current_page().title, "Enemies")
	assert_eq(book.tiles.size(), 8)
	assert_false(book.tile_for("elite").picture.is_silhouette())
	assert_true(book.tile_for("tank").picture.is_silhouette())
	await _press_key(KEY_Q)
	assert_eq(book.current_page().title, "Items", "Q turns back")
	book.tabs[4].pressed.emit()
	assert_eq(book.current_page().title, "Plushies", "the tabs work with the mouse")
	assert_eq(book.tile_for("pip").name_label.text, "Pip")
	assert_true(book.tabs[4].button_pressed, "the open page's tab is marked")


func test_ac46_what_you_meet_in_a_run_is_in_the_book_afterwards() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	var banane: Player = first_player()
	var away: Vector2 = banane.global_position + Vector2(500, 0)
	run.enemies.spawn(RUNNER, away)
	run.enemies.spawn(TANK, away + Vector2(0, 120), ELITE)
	banane.apply_upgrade(UpgradeOffer.new(run.upgrade_pool.find(&"big_spool"), 1))
	banane.evolve(run.upgrade_pool.evolution_of(&"peel_boomerang"))
	run.drop_floor_pickup(&"snow_globe", banane.global_position)
	await wait_physics_frames(3)
	assert_false(main.town.has_seen(ScrapbookRules.ENEMIES, "runner"), "not before the run ends")
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	await go_to_town()
	var book: ScrapbookBook = await _open_book()
	assert_false(book.tile_for("peel_boomerang").picture.is_silhouette(), "the starting weapon")
	assert_false(book.tile_for("banana_split").picture.is_silhouette(), "the evolution")
	assert_true(book.tile_for("zipper_ray").picture.is_silhouette(), "not used")
	await _turn_to(book, ScrapbookRules.ITEMS)
	assert_eq(book.tile_for("big_spool").name_label.text, "Big Spool")
	await _turn_to(book, ScrapbookRules.ENEMIES)
	for id: String in ["runner", "tank", "elite"]:
		assert_false(book.tile_for(id).picture.is_silhouette(), "%s was met" % id)
	assert_true(book.tile_for("spitter").picture.is_silhouette(), "never showed up")
	await _turn_to(book, ScrapbookRules.FLOOR_PICKUPS)
	assert_eq(book.tile_for("snow_globe").name_label.text, "Snow Globe")
	assert_eq(book.tile_for("magnet").name_label.text, "?")


func test_ac46_the_title_screen_opens_the_scrapbook() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	assert_false(title.scrapbook_button.visible, "nothing to show without a town")
	main.town.mark_seen(ScrapbookRules.ENEMIES, "runner")
	await go_to_town()
	await _restart_game()
	title = main.current_screen as TitleScreen
	assert_true(title.scrapbook_button.visible, "with a saved town")
	title.scrapbook_button.pressed.emit()
	await wait_physics_frames(1)
	assert_true(title.book.is_open())
	await _turn_to(title.book, ScrapbookRules.ENEMIES)
	assert_eq(title.book.tile_for("runner").name_label.text, "Runner", "from the saved town")
	await tap_action("pause")
	assert_false(title.book.is_open())
	assert_true(title.start_button.is_visible_in_tree(), "back to the title menu")


func test_ac46_the_recipes_page_remembers_evolutions_after_a_restart() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	first_player().evolve(run.upgrade_pool.evolution_of(&"peel_boomerang"))
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	# A new session: nothing in memory, only the save.
	RecipeBook.seen.clear()
	await _restart_game()
	assert_true(RecipeBook.is_seen(&"banana_split"), "loaded from the save")
	run = await start_run()
	run.pause()
	run.pause_menu.recipes_button.pressed.emit()
	await wait_physics_frames(1)
	var shown: Array[String] = []
	for row: RecipeRow in run.pause_menu.recipes_page.rows:
		shown.append(row.result_label.text)
	assert_has(shown, "Banana Split")
