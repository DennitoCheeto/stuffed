extends GutTest
## The Scrapbook's pages and counts (spec 03 §8, AC-46), how a run's finds reach the saved book
## (always all of them, whatever share of the haul is kept), and the Recipes page remembering
## evolutions across sessions.

const RULES: ScrapbookRules = preload("res://data/scrapbook.tres")
const SAVE: String = "user://test_unit_scrapbook.json"


func before_each() -> void:
	SaveStore.path = SAVE
	SaveStore.delete_all()


func after_all() -> void:
	SaveStore.delete_all()
	SaveStore.path = SaveStore.DEFAULT_PATH
	RecipeBook.seen.clear()


func _page(id: String) -> ScrapbookPage:
	for page: ScrapbookPage in RULES.pages():
		if page.id == id:
			return page
	return null


func _ids(page: ScrapbookPage) -> Array[String]:
	var ids: Array[String] = []
	for entry: ScrapbookEntry in page.entries:
		ids.append(entry.id)
	return ids


func test_ac46_five_pages_in_book_order() -> void:
	var titles: Array[String] = []
	for page: ScrapbookPage in RULES.pages():
		titles.append(page.title)
	assert_eq(titles, ["Weapons", "Items", "Enemies", "Floor pickups", "Plushies"])


func test_ac46_weapons_page_has_every_weapon_then_every_evolution() -> void:
	var page: ScrapbookPage = _page(ScrapbookRules.WEAPONS)
	assert_eq(page.entries.size(), 14, "10 weapons + 4 evolutions")
	assert_eq(page.entries[0].id, "peel_boomerang")
	assert_eq(page.entries[0].icon, &"boomerang")
	assert_eq(page.entries[10].id, "banana_split", "evolutions come after the weapons")
	assert_eq(page.entries[10].icon, &"split")


func test_ac46_weapons_show_their_evolution_partner() -> void:
	var page: ScrapbookPage = _page(ScrapbookRules.WEAPONS)
	assert_eq(page.find("peel_boomerang").note, "Evolves with Quick Feet")
	assert_eq(page.find("banana_split").note, "Evolution: Peel Boomerang + Quick Feet")
	assert_eq(page.find("zipper_ray").note, "", "no evolution yet")


func test_ac46_other_pages_list_items_enemies_pickups_and_plushies() -> void:
	assert_eq(_page(ScrapbookRules.ITEMS).entries.size(), 8)
	var enemies: Array[String] = [
		"shambler", "runner", "spitter", "bloater", "tank", "elite", "big_ted", "sock_puppet_king"
	]
	assert_eq(_ids(_page(ScrapbookRules.ENEMIES)), enemies)
	assert_eq(_ids(_page(ScrapbookRules.FLOOR_PICKUPS)), ["magnet", "snow_globe", "party_popper"])
	assert_eq(_ids(_page(ScrapbookRules.PLUSHIES)), ["pip", "bobo", "bambam", "robbar"])


func test_ac46_every_entry_has_a_name_and_a_text() -> void:
	for page: ScrapbookPage in RULES.pages():
		for entry: ScrapbookEntry in page.entries:
			assert_ne(entry.display_name, "", "%s/%s has a name" % [page.id, entry.id])
			assert_ne(entry.text, "", "%s/%s has a text" % [page.id, entry.id])


func test_ac46_elites_and_bosses_are_drawn_bigger() -> void:
	var page: ScrapbookPage = _page(ScrapbookRules.ENEMIES)
	assert_true(page.find("elite").elite, "the elite wears its marks")
	assert_gt(page.find("elite").size, 1.0)
	assert_gt(page.find("big_ted").size, 1.0)
	assert_eq(page.find("sock_puppet_king").look, EnemyStats.Look.SOCK_KING)


func test_ac46_counts_follow_the_save() -> void:
	var save: TownSave = TownSave.new()
	var page: ScrapbookPage = _page(ScrapbookRules.WEAPONS)
	assert_eq(page.count_text(save), "Weapons 0 / 14")
	save.mark_seen(ScrapbookRules.WEAPONS, "peel_boomerang")
	save.mark_seen(ScrapbookRules.WEAPONS, "banana_split")
	save.mark_seen(ScrapbookRules.WEAPONS, "peel_boomerang")
	save.mark_seen(ScrapbookRules.ITEMS, "quick_feet")
	assert_eq(page.count_text(save), "Weapons 2 / 14", "each entry counts once, per page")
	assert_true(page.is_seen(page.find("banana_split"), save))
	assert_false(page.is_seen(page.find("zipper_ray"), save))


func test_ac46_unknown_ids_do_not_count() -> void:
	var save: TownSave = TownSave.new()
	save.mark_seen(ScrapbookRules.ENEMIES, "moth_queen")
	assert_eq(_page(ScrapbookRules.ENEMIES).seen_count(save), 0)


func test_ac46_enemy_ids_come_from_their_names() -> void:
	var king: EnemyStats = EnemyStats.new()
	king.display_name = "Sock Puppet King"
	assert_eq(ScrapbookRules.enemy_id(king), "sock_puppet_king")


func test_ac46_a_haul_keeps_its_finds_through_a_checkpoint() -> void:
	var haul: RunHaul = RunHaul.new()
	haul.see(ScrapbookRules.ENEMIES, "runner")
	haul.see(ScrapbookRules.ENEMIES, "runner")
	haul.see(ScrapbookRules.WEAPONS, "yarn_cannon")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(haul.to_dict()))
	var again: RunHaul = RunHaul.from_dict(saved)
	assert_eq(again.seen[ScrapbookRules.ENEMIES], PackedStringArray(["runner"]))
	assert_eq(again.seen[ScrapbookRules.WEAPONS], PackedStringArray(["yarn_cannon"]))


func test_ac46_banking_puts_every_find_in_the_book_even_after_dying() -> void:
	var town: TownSave = TownSave.new()
	var haul: RunHaul = RunHaul.new()
	haul.add("coins", 10)
	haul.see(ScrapbookRules.ENEMIES, "tank")
	haul.see(ScrapbookRules.FLOOR_PICKUPS, "magnet")
	haul.rescued = "robbar"
	town.bank(haul, 0.5)
	assert_eq(town.material("coins"), 5, "half the coins")
	assert_true(town.has_seen(ScrapbookRules.ENEMIES, "tank"), "but all of the book")
	assert_true(town.has_seen(ScrapbookRules.FLOOR_PICKUPS, "magnet"))
	assert_true(town.has_seen(ScrapbookRules.PLUSHIES, "robbar"), "the rescued plushie")


func test_ac46_a_run_that_never_finished_still_fills_the_book() -> void:
	var town: TownSave = TownSave.new()
	var haul: RunHaul = RunHaul.new()
	haul.see(ScrapbookRules.ITEMS, "big_spool")
	town.unfinished_run = haul.to_dict()
	assert_true(town.settle_unfinished_run(0.5))
	assert_true(town.has_seen(ScrapbookRules.ITEMS, "big_spool"))


func test_ac47_the_book_survives_save_and_reload() -> void:
	var town: TownSave = TownSave.new()
	town.mark_seen(ScrapbookRules.ENEMIES, "elite")
	town.mark_seen(ScrapbookRules.PLUSHIES, "pip")
	assert_true(SaveStore.write(town))
	var loaded: TownSave = SaveStore.read()
	assert_eq(loaded.to_dict(), town.to_dict())
	assert_true(loaded.has_seen(ScrapbookRules.ENEMIES, "elite"))
	assert_eq(_page(ScrapbookRules.PLUSHIES).count_text(loaded), "Plushies 1 / 4")


func test_ac46_plushies_rescued_before_the_book_are_in_it() -> void:
	var old: Dictionary = {"version": 2, "plushies": {"pip": "in_town", "robbar": "waiting"}}
	var save: TownSave = TownSave.from_dict(old)
	assert_true(save.has_seen(ScrapbookRules.PLUSHIES, "pip"))
	assert_true(save.has_seen(ScrapbookRules.PLUSHIES, "robbar"))


func test_ac46_recipes_come_from_the_saved_book() -> void:
	RecipeBook.mark_seen(&"yarn_bomb")
	var save: TownSave = TownSave.new()
	save.mark_seen(ScrapbookRules.WEAPONS, "banana_split")
	RecipeBook.load_from(save)
	assert_true(RecipeBook.is_seen(&"banana_split"))
	assert_false(RecipeBook.is_seen(&"yarn_bomb"), "only what this town has seen")
