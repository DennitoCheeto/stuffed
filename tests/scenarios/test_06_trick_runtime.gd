extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 06 §2.5, §4, §6, §7, AC-70, AC-71): bought tricks reach the run and every hero
## in it; the first time a trick fires a small banner names it in the hero's colour; the run log
## lists the active tricks and when each one first fired; the run dev menu shows them.

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	disarm(first_player())
	return run


func _buy(ids: Array[String]) -> void:
	for id: String in ids:
		main.town.tricks.append(id)


func test_ac70_the_run_knows_the_bought_tricks() -> void:
	_buy(["picnic", "head_start"])
	await _quiet_run()
	assert_true(run.tricks.has(&"picnic"))
	assert_true(run.tricks.has(&"head_start"))
	assert_false(run.tricks.has(&"spare_stuffing"), "not bought")
	assert_true(first_player().has_trick(&"picnic"), "the hero has it too")


func test_ac70_first_fire_shows_a_banner_with_the_name_once() -> void:
	_buy(["picnic"])
	await _quiet_run()
	var banner: TrickBanner = run.hud.trick_banner
	assert_false(banner.visible, "nothing fired yet")
	run.elapsed = 42.0
	assert_true(run.tricks.note(&"picnic", first_player()), "first time")
	assert_true(banner.visible, "the banner shows")
	assert_eq(banner.title.text, "Picnic!")
	var color: Color = banner.title.get_theme_color(&"font_color")
	assert_eq(color, TrickBanner.color_for(0), "player 1's colour")
	assert_false(UiColors.is_danger(color), "never danger red/orange")
	assert_false(run.tricks.note(&"picnic", first_player()), "only the first time counts")
	assert_eq(run.tricks.moments.size(), 1)
	await wait_seconds(run.rules.trick_banner_seconds + 0.3)
	assert_false(banner.visible, "the banner went away")


func test_ac70_a_trick_that_was_not_bought_never_shows() -> void:
	await _quiet_run()
	assert_false(run.tricks.note(&"picnic", first_player()))
	assert_false(run.hud.trick_banner.visible)
	assert_eq(run.tricks.moments.size(), 0)


func test_ac70_the_run_log_lists_tricks_and_first_fires() -> void:
	_buy(["picnic", "confetti_rush"])
	await _quiet_run()
	run.elapsed = 12.34
	run.tricks.note(&"confetti_rush", first_player())
	run.pause_menu.quit_requested.emit()
	await wait_physics_frames(2)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_eq(entries.size(), 1, "one line in the log")
	if entries.is_empty():
		return
	var entry: Dictionary = entries[0]
	assert_eq(entry["tricks"], ["picnic", "confetti_rush"], "branch order (Snack Bar first)")
	assert_eq(entry["trick_moments"].size(), 1)
	assert_eq(entry["trick_moments"][0]["id"], "confetti_rush")
	assert_almost_eq(float(entry["trick_moments"][0]["time"]), 12.3, 0.01)
	assert_eq(int(entry["trick_moments"][0]["player"]), 0)


func test_ac71_in_coop_every_hero_gets_the_tricks() -> void:
	_buy(["picnic", "spare_stuffing"])
	main.player_count = 2
	await _quiet_run()
	var heroes: Array[Player] = Players.all(get_tree())
	assert_eq(heroes.size(), 2)
	for hero: Player in heroes:
		assert_true(hero.has_trick(&"picnic"), "hero %d has Picnic" % hero.player_index)
		assert_true(hero.has_trick(&"spare_stuffing"), "and Spare Stuffing")
	var second: Player = heroes[1]
	run.tricks.note(&"spare_stuffing", second)
	var title: Label = run.hud.trick_banner.title
	assert_eq(title.get_theme_color(&"font_color"), TrickBanner.color_for(1), "player 2's colour")
	assert_eq(int(run.tricks.moments[0]["player"]), 1)


func test_dev_menu_shows_which_tricks_are_on() -> void:
	_buy(["picnic", "head_start"])
	await _quiet_run()
	var text: String = run.dev_menu.tricks_label.text
	assert_string_contains(text, "Head Start")
	assert_string_contains(text, "Picnic")


func test_dev_menu_says_none_without_tricks() -> void:
	await _quiet_run()
	assert_eq(run.dev_menu.tricks_label.text, "Tricks on: none")
