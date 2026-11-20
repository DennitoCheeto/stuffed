extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §4, §7, §9, §10, AC-82, AC-84): the siege HUD shows the fort's bar, the wave
## counter and the hero's usual bar; in co-op every hero fights and stands back up; the tricks
## that make sense work in the siege (Bedroom-only ones don't); every siege writes one
## `kind: "siege"` line to the run log.

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")

var siege: Siege


## Presses E at the door of a town with the horde due; returns the siege.
func _start_siege() -> Siege:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var started: Siege = main.current_screen as Siege
	if started != null:
		silence_turrets(started)
	return started


## Waits until the siege ended and Main showed its end screen (the log line is written then).
func _wait_for_end_screen() -> EndScreen:
	for i: int in roundi((RULES.end_pause_seconds + 2.0) * FPS):
		if main.current_screen is EndScreen:
			break
		await wait_physics_frames(1)
	return main.current_screen as EndScreen


func _last_log_line() -> Dictionary:
	var entries: Array[Dictionary] = RunLog.read_all()
	return entries[-1] if not entries.is_empty() else {}


func test_the_siege_hud_shows_the_fort_the_waves_and_the_hero() -> void:
	siege = await _start_siege()
	assert_not_null(siege)
	if siege == null:
		return
	assert_true(siege.fort_bar.is_visible_in_tree(), "the fort's bar")
	assert_true(siege.wave_counter.is_visible_in_tree(), "the wave counter")
	assert_eq(siege.wave_counter.text, "Wave 1 of 3")
	assert_true(siege.hud.health_bar.is_visible_in_tree(), "the hero's usual bar")
	siege.dev_menu.press(DevMenu.NEXT_WAVE)
	await wait_physics_frames(2)
	# The label copies `shown_text()` in `_process`: on a slow machine two physics ticks can pass
	# before the next process frame, so read the counter itself.
	assert_eq(siege.wave_counter.shown_text(), "Wave 2 of 3")
	var bar: Rect2 = siege.fort_bar.get_global_rect()
	var counter: Rect2 = siege.wave_counter.get_global_rect()
	assert_false(bar.intersects(counter), "side by side")
	assert_eq(siege.pickup_arrows.fort, siege.fort, "the edge arrows watch the fort")
	assert_false(siege.hud.jars.visible, "no empty material jars: the reward comes at the end")


func test_ac82_in_co_op_every_hero_fights_and_stands_back_up() -> void:
	add_controls(1)
	main.player_count = 2
	siege = await _start_siege()
	var heroes: Array[Player] = Players.all(get_tree())
	assert_eq(heroes.size(), 2, "both heroes are in the siege")
	for hero: Player in heroes:
		assert_true(hero.armed, "player %d fights" % (hero.player_index + 1))
		assert_gte(hero.weapons().size(), 1, "with a weapon")
		hero.global_position = Vector2(300 + 80 * hero.player_index, 300)
		hero.take_hit(hero.max_health * 10.0, "test")
	assert_true(heroes[0].is_dead() and heroes[1].is_dead(), "both down")
	await wait_physics_frames(5)
	assert_false(siege.over, "fallen heroes don't lose the siege")
	await wait_seconds(RULES.stand_up_seconds + 0.5)
	for hero: Player in heroes:
		assert_false(hero.is_dead(), "player %d stood back up" % (hero.player_index + 1))
		var fort_door: float = hero.global_position.distance_to(siege.layout.spawn_position)
		assert_lt(fort_door, 200.0, "at the fort")


func test_tricks_that_make_sense_work_in_the_siege() -> void:
	for id: String in ["head_start", "second_helping", "treasure_map", "picnic", "plushie_buddy"]:
		main.town.tricks.append(id)
	main.town.plushies["pip"] = "in_town"
	main.town.last_rescued = "pip"
	siege = await _start_siege()
	var hero: Player = first_player()
	assert_eq(hero.weapons()[0].level, 2, "Head Start: the starting weapon at level 2")
	assert_gt(hero.max_shield, 0.0, "Second Helping")
	assert_true(siege.tricks.fired(&"head_start"), "its banner showed")
	assert_null(siege.tricks.treasure, "no Treasure Map box in the siege")
	assert_null(siege.tricks.buddy, "no Plushie Buddy")
	assert_false(siege.perks.has_trick(&"picnic"), "no Picnic")
	assert_eq(siege.floor_pickups().size(), 0, "no floor pickups")
	assert_eq(siege.floor_pickup_drops.next_drop_at, INF, "and none will drop")


func test_a_won_siege_writes_a_siege_line_to_the_run_log() -> void:
	main.town.tricks.append("head_start")
	siege = await _start_siege()
	var full: float = siege.fort.max_health
	siege.dev_menu.press(DevMenu.WIN_SIEGE)
	var end: EndScreen = await _wait_for_end_screen()
	assert_not_null(end)
	var entry: Dictionary = _last_log_line()
	assert_eq(entry.get("kind"), "siege")
	assert_eq(int(entry.get("number", 0)), 1)
	assert_eq(entry.get("won"), true)
	assert_eq(int(entry.get("waves_held", 0)), 3)
	assert_eq(int(entry.get("wave_count", 0)), 3)
	assert_almost_eq(float(entry.get("fort_health_left", 0.0)), full, 0.1)
	assert_eq(entry.get("knocked_down"), [])
	assert_eq(entry.get("damaged"), [])
	var reward: Dictionary = entry.get("reward", {})
	assert_eq(int(reward.get("coins", 0)), RULES.reward["coins"])
	assert_eq(entry.get("tricks"), ["head_start"])


func test_a_lost_siege_logs_what_was_knocked_down_and_damaged() -> void:
	siege = await _start_siege()
	first_player().invincible = true
	siege.targets.building(&"lucky_jar").hurt(1000000.0)
	for i: int in 4:
		siege.dev_menu.press(DevMenu.HURT_FORT)
	assert_true(siege.fort.is_fallen())
	await _wait_for_end_screen()
	var entry: Dictionary = _last_log_line()
	assert_eq(entry.get("kind"), "siege")
	assert_eq(entry.get("won"), false)
	assert_eq(float(entry.get("fort_health_left", -1.0)), 0.0)
	assert_eq(entry.get("knocked_down"), ["lucky_jar"])
	assert_eq(entry.get("damaged"), ["lucky_jar"])
	var reward: Dictionary = entry.get("reward", {})
	assert_gt(int(reward.get("coins", 0)), 0, "the consolation haul")
	assert_lt(int(reward.get("coins", 0)), RULES.reward["coins"])
