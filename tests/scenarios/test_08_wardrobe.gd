extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §2, §4, §5, AC-85, AC-86): the Wardrobe appears next to the fort door once a
## plushie was freed ("Pip wants to play!"), E there opens the hero picker (rescued heroes with
## their weapon, passive and tags, the others as silhouettes), and picking swaps the hero in the
## town at once. The hero swapped out (Banane too) lives in town; the played plushie doesn't.
## The next run uses the picked hero.

const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const RULES: WardrobeRules = preload("res://data/town/wardrobe_rules.tres")


func _hero(id: String) -> HeroStats:
	return HEROES.find(StringName(id))


## Arrives in town and waits until the arrival news (banners) has settled.
func _arrive() -> Town:
	var town: Town = await go_to_town()
	await wait_physics_frames(3)
	while town.is_settling():
		await wait_physics_frames(1)
	return town


## Player 1 walks up to the Wardrobe and presses E.
func _press_e_at_wardrobe(town: Town) -> void:
	first_player().position = town.wardrobe.door()
	await wait_physics_frames(2)
	await tap_action("p1_interact")
	await wait_physics_frames(1)


func test_ac85_no_wardrobe_before_a_rescue() -> void:
	var town: Town = await _arrive()
	assert_false(town.wardrobe.visible, "nothing to pick yet")
	first_player().position = town.wardrobe.door()
	await wait_physics_frames(2)
	assert_false(town.wardrobe.is_near(first_player()))
	assert_ne(town.prompt_label.text, RULES.prompt)


func test_ac85_the_wardrobe_appears_with_the_first_freed_plushie() -> void:
	main.town.plushies["pip"] = "waiting"
	var town: Town = await go_to_town()
	await wait_physics_frames(3)
	while town.wardrobe.has_news():
		await wait_physics_frames(1)
	assert_eq(town.banner_title.text, "Pip wants to play!")
	assert_eq(town.banner_subtitle.text, "Try her on at the Wardrobe.")
	assert_true(town.wardrobe.visible, "the Wardrobe stands by the door")
	assert_has(town.save.revealed, WardrobeRules.REVEALED_ID)
	# A later rescue gets its own short banner.
	while town.is_banner_showing():
		await wait_physics_frames(1)
	town.save.plushies["bobo"] = "waiting"
	town.settle()
	assert_eq(town.banner_title.text, "Böbö wants to play!")
	assert_eq(town.banner_subtitle.text, RULES.later_subtitle)
	assert_false(town.wardrobe.has_news(), "each hero is announced once")


func test_ac85_the_picker_shows_rescued_heroes_and_silhouettes() -> void:
	main.town.plushies["pip"] = "in_town"
	var town: Town = await _arrive()
	await _press_e_at_wardrobe(town)
	var picker: HeroPicker = town.wardrobe.picker
	assert_true(picker.is_open(), "E at the Wardrobe opens the hero picker")
	assert_eq(picker.tiles.size(), HEROES.heroes.size(), "one tile per hero")
	assert_eq(picker.tiles.keys()[0], &"banane", "Banane first")
	assert_true(picker.can_pick(_hero("banane")))
	assert_true(picker.can_pick(_hero("pip")))
	assert_false(picker.photos[&"pip"].is_silhouette())
	assert_string_contains(picker.notes[&"pip"].text, "Chilly Hug")
	for id: StringName in [&"bobo", &"bambam", &"robbar"]:
		assert_false(picker.can_pick(_hero(id)), String(id))
		assert_true(picker.photos[id].is_silhouette(), String(id))
		assert_eq(picker.notes[id].text, RULES.locked_text)
	picker.choose(_hero("bobo"))
	assert_true(picker.is_open(), "a locked hero can't be picked")
	await tap_action("pause")
	assert_false(picker.is_open(), "Esc closes it")


func test_ac86_picking_swaps_the_hero_and_banane_moves_into_town() -> void:
	main.town.plushies["pip"] = "in_town"
	var town: Town = await _arrive()
	assert_true(town.plushies.has("pip"), "Pip lives in town while Banane is played")
	assert_null(town.wardrobe.banane)
	await _press_e_at_wardrobe(town)
	var at: Vector2 = first_player().position
	await tap_action("pick_card_2")
	await wait_physics_frames(2)
	assert_false(town.wardrobe.picker.is_open())
	var players: Array[Player] = Players.all(get_tree())
	assert_eq(players.size(), 1, "swapped in place")
	assert_eq(first_player().stats, _hero("pip"), "you are Pip now")
	assert_eq(first_player().position, at)
	assert_eq(SaveStore.read().hero_id(0), "pip", "saved at once")
	assert_false(town.plushies.has("pip"), "the played plushie doesn't also wander around")
	assert_not_null(town.wardrobe.banane, "Banane lives in town now")
	assert_not_null(town.wardrobe.banane.puppet, "as his felt puppet")
	# Swapping back: Pip hops out of the Wardrobe, Banane is played again.
	town.wardrobe.swap(0, _hero("banane"))
	await wait_physics_frames(1)
	assert_true(town.plushies.has("pip"))
	assert_null(town.wardrobe.banane)


func test_ac86_a_played_plushie_waiting_for_a_bed_leaves_the_tent() -> void:
	main.town.plushies["robbar"] = "waiting"
	var town: Town = await _arrive()
	assert_eq(town.tent.waiting.size(), 1, "Robbar waits in the tent")
	town.wardrobe.swap(0, _hero("robbar"))
	assert_eq(town.tent.waiting.size(), 0, "played, so not in the tent")
	town.wardrobe.swap(0, _hero("banane"))
	assert_eq(town.tent.waiting.size(), 1, "back in the tent")


func test_ac86_the_next_run_uses_the_picked_hero() -> void:
	main.town.plushies["bambam"] = "in_town"
	var town: Town = await _arrive()
	town.wardrobe.swap(0, _hero("bambam"))
	var run: Run = await start_run()
	assert_not_null(run)
	assert_eq(first_player().stats, _hero("bambam"))
