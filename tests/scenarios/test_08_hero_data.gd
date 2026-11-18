extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §3, §4, §12, AC-85, AC-87, AC-92): the town developer menu unlocks every
## plushie hero and switches player 1's hero at once; the choice is saved, and the next run and
## the night siege start with that hero's numbers and own weapon.

const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")


func _hero(id: String) -> HeroStats:
	return HEROES.find(StringName(id))


func test_ac85_without_rescues_the_dev_menu_keeps_banane() -> void:
	var town: Town = await go_to_town()
	assert_eq(first_player().stats, HEROES.starter())
	assert_eq(town.dev_menu.next_hero(), HEROES.starter(), "nobody else is unlocked")
	await wait_physics_frames(1)
	assert_eq(first_player().stats, HEROES.starter())


func test_ac92_dev_menu_switches_the_hero_in_town_and_saves_it() -> void:
	var town: Town = await go_to_town()
	town.dev_menu.press(TownDevMenu.UNLOCK_HEROES)
	for hero: HeroStats in HEROES.heroes:
		assert_true(HEROES.is_unlocked(hero, main.town), String(hero.id))
	var at: Vector2 = first_player().position
	town.dev_menu.press(TownDevMenu.NEXT_HERO)
	await wait_physics_frames(1)
	var players: Array[Player] = Players.all(get_tree())
	assert_eq(players.size(), 1, "one hero, swapped in place")
	assert_eq(players[0].stats, _hero("pip"))
	assert_eq(players[0].position, at)
	assert_eq(SaveStore.read().hero_id(0), "pip", "saved at once")


func test_ac87_a_run_starts_with_the_picked_hero() -> void:
	main.town.plushies["robbar"] = "in_town"
	main.town.set_hero(0, "robbar")
	var run: Run = await start_run()
	var robbar: Player = first_player()
	var stats: HeroStats = _hero("robbar")
	assert_eq(robbar.stats, stats)
	assert_eq(robbar.max_health, stats.max_health)
	assert_eq(robbar.pickup_range, stats.pickup_range)
	assert_not_null(robbar.weapon(&"bouncy_yarn_ball"), "Robbar's own weapon")
	assert_null(robbar.weapon(&"peel_boomerang"), "no Banane boomerang")
	assert_eq(run.perks.hero(0), stats)


func test_ac87_the_siege_uses_the_picked_hero() -> void:
	main.town.plushies["bobo"] = "waiting"
	main.town.set_hero(0, "bobo")
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	assert_eq(first_player().stats, _hero("bobo"), "Böbö in town too")
	town.enter_bedroom()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	assert_not_null(siege)
	silence_turrets(siege)
	assert_eq(first_player().stats, _hero("bobo"))
	assert_eq(first_player().max_health, _hero("bobo").max_health)
