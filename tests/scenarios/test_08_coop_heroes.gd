extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §8, §9, §11, AC-91): in co-op every hero is played at most once (a player
## whose saved hero is taken gets the first free one, and the Wardrobe shows "Player 1 plays Pip");
## the siege helpers are the plushies nobody plays plus Banane when someone else plays him; the
## Scrapbook says what a plushie plays with; the run log and the end screen name the hero.

const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const RULES: WardrobeRules = preload("res://data/town/wardrobe_rules.tres")
const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")


func _hero(id: String) -> HeroStats:
	return HEROES.find(StringName(id))


func _player(index: int) -> Player:
	for player: Player in Players.all(get_tree()):
		if player.player_index == index:
			return player
	return null


func test_ac91_one_of_each_hero_in_co_op() -> void:
	main.town.plushies["pip"] = "in_town"
	main.town.set_hero(0, "pip")
	main.town.set_hero(1, "pip")
	main.player_count = 2
	var town: Town = await go_to_town()
	assert_eq(_player(0).stats, _hero("pip"))
	assert_eq(_player(1).stats, _hero("banane"), "Pip is taken: the first free hero")
	town.wardrobe.open(1)
	var picker: HeroPicker = town.wardrobe.picker
	assert_false(picker.can_pick(_hero("pip")), "player 1 has her")
	assert_eq(picker.notes[&"pip"].text, RULES.taken_text % [1, "Pip"])
	assert_true(picker.can_pick(_hero("banane")))
	picker.close()


func test_ac91_siege_helpers_are_the_plushies_nobody_plays_and_banane() -> void:
	main.town.plushies["pip"] = "in_town"
	main.town.plushies["bobo"] = "in_town"
	main.town.set_hero(0, "pip")
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	assert_not_null(siege)
	silence_turrets(siege)
	assert_false(siege.plushies.has("pip"), "Pip is played, so she doesn't also help")
	assert_true(siege.plushies.has("bobo"), "Böbö helps")
	assert_true(siege.plushies.has("banane"), "Banane helps while Pip is played")
	var banane: SiegePlushie = siege.plushies["banane"]
	var puppets: int = 0
	for child: Node in banane.get_children():
		if child is BananePuppet:
			puppets += 1
	assert_eq(puppets, 1, "drawn as his felt puppet")


func test_spec08_scrapbook_says_what_a_plushie_plays_with() -> void:
	var pip: PlushieDef = RESCUE.find("pip")
	assert_eq(ScrapbookRules.plays_with(pip), "Rescued · Plays with: Snowball Toss · Chilly Hug")


func test_spec08_the_run_log_and_end_screen_name_the_hero() -> void:
	main.town.plushies["robbar"] = "in_town"
	main.town.set_hero(0, "robbar")
	var run: Run = await start_run()
	run.rescue_plan = null
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_process_frames(2)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1)
	assert_eq(entries[0]["hero"], ["robbar"], "the run log names the hero")
	var end: EndScreen = main.current_screen as EndScreen
	assert_not_null(end)
	assert_eq(WeaponColumn.hero_name(end.result, 0), "Robbar")
