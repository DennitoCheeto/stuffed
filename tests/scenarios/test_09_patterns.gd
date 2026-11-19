extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §4, §10, §11, AC-95, AC-96): reaching Lv 2 of a building gives its pattern
## with a banner and old saves catch up on arrival; the first Big Ted kill drops his pattern
## envelope with an edge arrow, touching it saves at once and the pattern is kept even when the
## run is given up; elites drop the Raincoat pattern at its data chance until it is owned; the
## run developer menu drops the next pattern.

const RICH: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 999}

var run: Run
var _raincoat_chance: float = 0.0


func before_each() -> void:
	await super()
	_raincoat_chance = _rules().find("raincoat").drop_chance


func after_each() -> void:
	_rules().find("raincoat").drop_chance = _raincoat_chance
	super()


func _rules() -> GearRules:
	return GearRules.current()


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.floor_pickup_drops.next_drop_at = INF
	run.rescue_plan = null
	disarm(first_player())
	first_player().invincible = true
	return run


func _kill(zombie: Zombie) -> void:
	run.enemies.damage(zombie, zombie.max_health * 10.0)


func _envelopes_on_floor() -> Array[PatternEnvelope]:
	var found: Array[PatternEnvelope] = []
	for child: Node in run.floor_items.get_children():
		if child is PatternEnvelope and not child.is_queued_for_deletion():
			found.append(child as PatternEnvelope)
	return found


func _wait_for_pattern(id: String, seconds: float) -> void:
	for i: int in roundi(seconds * FPS):
		if main.town.gear.has_pattern(id):
			return
		await wait_physics_frames(1)


func test_ac95_building_level_2_gives_its_pattern_with_a_banner() -> void:
	main.town.materials = RICH.duplicate()
	main.town.building_levels["toy_box_armory"] = 1
	var town: Town = await go_to_town()
	var armory: TownBuilding = town.buildings[&"toy_box_armory"]
	Sfx.history.clear()
	assert_true(town.try_build(armory), "Armory to Lv 2")
	assert_false(main.town.gear.has_pattern("pin_cushion_hat"), "after the build moment")
	await _wait_for_pattern("pin_cushion_hat", 6.0)
	assert_true(main.town.gear.has_pattern("pin_cushion_hat"), "the Armory's pattern")
	assert_eq(town.banner_title.text, "New pattern: Pin Cushion Hat!")
	assert_has(Sfx.history, _rules().pattern_sound)
	assert_true(SaveStore.read().gear.has_pattern("pin_cushion_hat"), "saved at once")
	assert_eq(main.town.gear.patterns.size(), 1, "only that one")


func test_ac95_an_old_save_gets_the_patterns_of_buildings_already_at_level_2() -> void:
	main.town.building_levels["watchtower"] = 2
	main.town.building_levels["snack_bar"] = 3
	main.town.building_levels["lucky_jar"] = 1
	var town: Town = await go_to_town()
	await _wait_for_pattern("lookout_cap", 6.0)
	assert_true(main.town.gear.has_pattern("lookout_cap"))
	assert_true(main.town.gear.has_pattern("picnic_apron"))
	assert_false(main.town.gear.has_pattern("lucky_button"), "the Lucky Jar is only Lv 1")
	assert_eq(town.banner_title.text, "New patterns!", "one banner for both")
	assert_string_contains(town.banner_subtitle.text, "Lookout Cap, Picnic Apron")


func test_ac96_big_ted_drops_his_pattern_and_it_is_kept_after_giving_up() -> void:
	await _quiet_run()
	var ted: Zombie = run.spawner.spawn_boss(run.spawner.schedule.mini_boss)
	_kill(ted)
	await wait_physics_frames(2)
	var envelopes: Array[PatternEnvelope] = _envelopes_on_floor()
	assert_eq(envelopes.size(), 1, "one envelope where he fell")
	var envelope: PatternEnvelope = envelopes[0]
	assert_eq(String(envelope.piece.id), "propeller_cap")
	envelope.position = first_player().global_position + Vector2(1500.0, 0.0)
	await wait_process_frames(2)
	assert_has(run.pickup_arrows.colors, PatternEnvelope.GLOW_COLOR, "an edge arrow points to it")
	Sfx.history.clear()
	envelope.position = first_player().global_position
	await wait_physics_frames(3)
	assert_eq(run.haul.patterns, PackedStringArray(["propeller_cap"]), "found")
	assert_eq(run.hud.banner_title.text, "New pattern: Propeller Cap!")
	assert_has(Sfx.history, _rules().pattern_sound)
	assert_eq(_envelopes_on_floor().size(), 0, "picked up")
	var saved: Array = SaveStore.read().unfinished_run.get("patterns", [])
	assert_has(saved, "propeller_cap", "saved at once")
	run.pause_menu.quit_requested.emit()
	await wait_physics_frames(2)
	assert_true(main.current_screen is EndScreen, "given up")
	assert_true(main.town.gear.has_pattern("propeller_cap"), "kept although the run was lost")
	assert_true(SaveStore.read().gear.has_pattern("propeller_cap"), "and saved")
	var entry: Dictionary = RunLog.read_all().back()
	assert_eq(entry["patterns_found"].size(), 1, "run log")
	assert_eq(entry["patterns_found"][0]["pattern"], "propeller_cap")


func test_ac96_an_owned_boss_pattern_never_drops_again() -> void:
	main.town.gear.add_pattern("propeller_cap")
	await _quiet_run()
	_kill(run.spawner.spawn_boss(run.spawner.schedule.mini_boss))
	await wait_physics_frames(2)
	assert_eq(_envelopes_on_floor().size(), 0, "the town owns it already")


func test_ac96_elites_drop_the_raincoat_at_its_chance_until_owned() -> void:
	await _quiet_run()
	var elite_type: EnemyStats = run.spawner.schedule.entry_named("Runner").enemy
	var raincoat: GearDef = _rules().find("raincoat")
	raincoat.drop_chance = 0.0
	for i: int in 20:
		_kill(run.spawner.spawn_elite(elite_type))
	await wait_physics_frames(2)
	assert_eq(_envelopes_on_floor().size(), 0, "chance 0: never")
	raincoat.drop_chance = 1.0
	_kill(run.spawner.spawn_elite(elite_type))
	_kill(run.spawner.spawn_elite(elite_type))
	await wait_physics_frames(2)
	var envelopes: Array[PatternEnvelope] = _envelopes_on_floor()
	assert_eq(envelopes.size(), 1, "chance 1: it drops, but only one lies on the floor")
	assert_eq(String(envelopes[0].piece.id), "raincoat")
	envelopes[0].position = first_player().global_position
	await wait_physics_frames(3)
	assert_has(run.haul.patterns, "raincoat")
	_kill(run.spawner.spawn_elite(elite_type))
	await wait_physics_frames(2)
	assert_eq(_envelopes_on_floor().size(), 0, "found: no more drops")


func test_run_dev_menu_drops_the_next_pattern() -> void:
	main.town.gear.add_pattern("propeller_cap")
	await _quiet_run()
	run.dev_menu.press(DevMenu.DROP_PATTERN)
	await wait_physics_frames(1)
	var envelopes: Array[PatternEnvelope] = _envelopes_on_floor()
	assert_eq(envelopes.size(), 1)
	assert_eq(String(envelopes[0].piece.id), "wind_up_key", "the next one the town lacks")
	run.dev_menu.press(DevMenu.DROP_PATTERN)
	run.dev_menu.press(DevMenu.DROP_PATTERN)
	await wait_physics_frames(1)
	assert_eq(_envelopes_on_floor().size(), 2, "then the Raincoat, then nothing left")
