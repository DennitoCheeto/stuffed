extends "res://tests/scenarios/run_scenario.gd"
## M6-10 (spec 10 §6, §9, §10, AC-113): first-time hint notes in a run. Each shows once at its
## moment, goes away when the player does the thing (or after a while, then once more), never
## covers the hero, is remembered in the save; Hints off shows none; "Show hints again" brings
## them back; the run log lists the hints shown.

const RULES: HintRules = preload("res://data/ui/hints.tres")


## Every run hint except `id` counts as seen, so only `id` can show.
func _only(id: String) -> void:
	main.town.hints_seen.clear()
	main.town.hints_once.clear()
	for hint: HintDef in RULES.hints:
		if hint.id != id:
			main.town.hints_seen.append(hint.id)


## Starts a calm run (no spawns) and returns its hints.
func _calm_run() -> RunHints:
	var current: Run = await start_run()
	current.spawner.active = false
	return RunHints.of(current)


func _wait_for_note(hints: RunHints, id: String, seconds: float = 2.0) -> bool:
	for i: int in roundi(seconds * FPS):
		if hints.is_showing(id):
			return true
		await wait_physics_frames(1)
	return hints.is_showing(id)


func _wait_until_gone(hints: RunHints, seconds: float = 3.0) -> bool:
	for i: int in roundi(seconds * FPS):
		if hints.note == null:
			return true
		await wait_physics_frames(1)
	return hints.note == null


## A spot in the room away from the hero.
func _away(current: Run) -> Vector2:
	return (
		first_player().global_position
		+ Vector2(600, 0).limit_length(current.arena.play_rect().size.x / 3.0)
	)


func test_the_move_note_shows_at_the_start_and_goes_when_the_hero_walks() -> void:
	_only("move")
	var hints: RunHints = await _calm_run()
	assert_true(await _wait_for_note(hints, "move"), "the move note shows when the run starts")
	var note: HintNote = hints.note
	assert_true(note.shown_text().contains(KeyBindings.key_text("dash")), "it names the dash key")
	assert_eq(note.key_tags.size(), 2, "walk keys share one tag, dash has its own")
	var from: Vector2 = first_player().global_position
	await hold_action("p1_move_right", 40)
	assert_true(await _wait_until_gone(hints), "walking makes the note go away")
	assert_true(main.town.hints_seen.has("move"), "the save remembers it")
	assert_eq(hints.shown, PackedStringArray(["move"]))


func test_each_run_hint_shows_at_its_moment_and_goes_when_done() -> void:
	_only("xp")
	var hints: RunHints = await _calm_run()
	var current: Run = hints.run
	var player: Player = first_player()
	current.pickups.drop(EnemyStats.XpSize.SMALL, _away(current))
	assert_true(await _wait_for_note(hints, "xp"), "xp: the first XP button")
	player.add_xp(1)
	assert_true(await _wait_until_gone(hints), "xp: gone once the hero has XP")

	_only("gift_box")
	var box: GiftBox = current.drop_gift_box(_away(current))
	assert_true(await _wait_for_note(hints, "gift_box"), "gift_box: the first gift box")
	box.global_position = player.global_position
	assert_true(await _wait_until_gone(hints, 4.0), "gift_box: gone once it's opened")
	current.gift_screen.close()
	await wait_physics_frames(2)

	_only("floor_pickup")
	var toy: FloorPickup = current.drop_floor_pickup(&"magnet", _away(current))
	assert_true(await _wait_for_note(hints, "floor_pickup"), "floor_pickup: the first toy")
	toy.global_position = player.global_position
	assert_true(await _wait_until_gone(hints), "floor_pickup: gone once it's used")

	_only("evolution_ready")
	var evolution: EvolutionDef = current.upgrade_pool.evolutions[0]
	var base: UpgradeDef = current.upgrade_pool.find(evolution.weapon)
	var weapon: Weapon = player.weapon(evolution.weapon)
	if weapon == null:
		weapon = player.add_weapon(base.weapon)
	weapon.level = base.top_level()
	player.apply_upgrade(UpgradeOffer.new(current.upgrade_pool.find(evolution.partner), 1))
	assert_true(await _wait_for_note(hints, "evolution_ready"), "evolution_ready: maxed + partner")
	player.evolve(evolution)
	assert_true(await _wait_until_gone(hints, 6.0), "evolution_ready: gone once it evolved")

	_only("boss")
	var ted: Zombie = current.spawner.spawn_boss(current.spawner.schedule.mini_boss)
	assert_true(await _wait_for_note(hints, "boss"), "boss: the first boss")
	current.enemies.damage(ted, ted.max_health * 10.0)
	assert_true(await _wait_until_gone(hints, 4.0), "boss: gone once it's beaten")

	_only("way_home")
	if current.way_home == null:
		current.open_way_home(_away(current))
	assert_true(await _wait_for_note(hints, "way_home"), "way_home: the portal opened")
	current.way_home.global_position = player.global_position
	assert_true(await _wait_until_gone(hints, 4.0), "way_home: gone once a hero stands in it")
	for id: String in ["xp", "gift_box", "floor_pickup", "evolution_ready", "boss", "way_home"]:
		assert_true(main.town.hints_seen.has(id), "%s is remembered" % id)


## Player 1's `weapon_id` at its top level (no partner item).
func _max_weapon(current: Run, weapon_id: StringName) -> void:
	var base: UpgradeDef = current.upgrade_pool.find(weapon_id)
	var weapon: Weapon = first_player().weapon(weapon_id)
	if weapon == null:
		weapon = first_player().add_weapon(base.weapon)
	weapon.level = base.top_level()


func test_ac128_a_maxed_weapon_without_its_partner_tells_how_to_evolve_once_per_save() -> void:
	_only("evolution_how")
	var hints: RunHints = await _calm_run()
	var current: Run = hints.run
	_max_weapon(current, &"button_shotgun")
	assert_true(await _wait_for_note(hints, "evolution_how"), "maxed without Quick Hands")
	assert_true(hints.note.shown_text().contains("partner"), hints.note.shown_text())
	var partner: UpgradeDef = current.upgrade_pool.find(&"quick_hands")
	first_player().apply_upgrade(UpgradeOffer.new(partner, 1))
	assert_true(await _wait_until_gone(hints), "gone once the partner item is owned")
	assert_true(main.town.hints_seen.has("evolution_how"), "the save remembers it")
	await _quit_run(current)
	await go_to_town()
	hints = await _calm_run()
	_max_weapon(hints.run, &"thimble_mortar")
	await wait_seconds(1.0)
	assert_null(hints.note, "once per save: another maxed weapon shows nothing")


func test_the_level_up_note_waits_while_the_cards_show() -> void:
	_only("level_up")
	var hints: RunHints = await _calm_run()
	var current: Run = hints.run
	first_player().add_xp(first_player().progress.xp_needed())
	assert_true(await _wait_for_note(hints, "level_up"), "the note shows with the cards")
	assert_true(current.level_up_screen.is_open())
	assert_true(hints.note.shown_text().contains(KeyBindings.key_text("reroll")))
	await wait_seconds(RULES.show_seconds + 1.0)
	assert_true(hints.is_showing("level_up"), "it stays while the player reads the cards")
	current.level_up_screen.choose(0)
	assert_true(await _wait_until_gone(hints), "picking a card makes it go")
	assert_true(main.town.hints_seen.has("level_up"))


func test_a_note_that_isnt_done_goes_and_shows_once_more_next_run() -> void:
	_only("xp")
	var hints: RunHints = await _calm_run()
	hints.run.pickups.drop(EnemyStats.XpSize.SMALL, _away(hints.run))
	assert_true(await _wait_for_note(hints, "xp"))
	hints.showing_for = RULES.show_seconds - 0.1
	assert_true(await _wait_until_gone(hints), "it goes away by itself")
	assert_true(main.town.hints_once.has("xp"), "it shows once more next time")
	assert_false(main.town.hints_seen.has("xp"))
	await wait_seconds(0.5)
	assert_null(hints.note, "not again in this run (the button is still there)")
	await _quit_run(hints.run)
	await go_to_town()
	hints = await _calm_run()
	hints.run.pickups.drop(EnemyStats.XpSize.SMALL, _away(hints.run))
	assert_true(await _wait_for_note(hints, "xp"), "next run: it shows again")
	hints.showing_for = RULES.show_seconds - 0.1
	assert_true(await _wait_until_gone(hints))
	assert_true(main.town.hints_seen.has("xp"), "after the second time it's seen for good")


func test_the_note_never_covers_the_hero() -> void:
	_only("move")
	var hints: RunHints = await _calm_run()
	var current: Run = hints.run
	var player: Player = first_player()
	var room: Rect2 = current.arena.play_rect()
	player.global_position = Vector2(room.get_center().x, room.end.y - 40.0)
	assert_true(await _wait_for_note(hints, "move"))
	var screen: Vector2 = hints.get_viewport().get_visible_rect().size
	for i: int in 30:
		await wait_physics_frames(1)
		for hero: Rect2 in hints.hero_rects():
			assert_false(hero.intersects(hints.note_rect()), "the note covers the hero")
			if hero.intersects(hints.note_rect()):
				return
	assert_gt(hints.hero_rects()[0].position.y, screen.y / 2.0, "the hero is low on screen")
	assert_lt(hints.note_rect().position.y, screen.y / 2.0, "so the note moved to the top")


func test_hints_off_shows_none_and_show_hints_again_brings_them_back() -> void:
	GameSettings.hints = false
	main.town.hints_seen.clear()
	var hints: RunHints = await _calm_run()
	await wait_seconds(1.0)
	assert_null(hints.note, "Hints off: no note")
	GameSettings.hints = true
	assert_true(await _wait_for_note(hints, "move"), "Hints on again: the note shows")
	main.town.hints_seen.append("xp")
	current_settings().show_hints_again()
	assert_true(main.town.hints_seen.is_empty(), "the save forgot every seen hint")
	var saved: TownSave = SaveStore.read()
	assert_true(saved.hints_seen.is_empty(), "and it's saved")


func test_seen_hints_survive_a_restart_and_the_log_lists_the_shown_ones() -> void:
	_only("move")
	var hints: RunHints = await _calm_run()
	assert_true(await _wait_for_note(hints, "move"))
	await hold_action("p1_move_right", 40)
	assert_true(await _wait_until_gone(hints))
	await _quit_run(hints.run)
	var saved: TownSave = SaveStore.read()
	assert_true(saved.hints_seen.has("move"), "seen hints are saved")
	var lines: Array[Dictionary] = RunLog.read_all()
	assert_eq(lines[-1].get("hints"), ["move"], "log field hints")


## The Settings panel, opened the way the player does (pause menu).
func current_settings() -> SettingsPanel:
	var run: Run = main.current_screen as Run
	return run.pause_menu.settings


## Gives up the run from the pause menu (the end screen shows).
func _quit_run(current: Run) -> void:
	current.pause()
	current.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
