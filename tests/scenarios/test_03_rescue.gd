extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §7, AC-44): from run 2, a run can have a rescue: a plushie tangled in yarn
## appears with an edge arrow, a banner and one "help!" squeak; standing next to it fills the
## ring in 3 s (moving away pauses it); a freed plushie comes home even if Banane dies later.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const RULES: RescueRules = preload("res://data/town/rescue_rules.tres")
const BAMBAM: PlushieDef = preload("res://data/town/plushies/bambam.tres")

var run: Run


## A quiet run: no spawns, no weapons, no floor pickups, so the test decides what happens.
func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.floor_pickup_drops.next_drop_at = INF
	run.rescue_plan = null
	disarm(first_player())
	first_player().invincible = true
	return run


func _step_to(player: Player, at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO


func _plushies_on_floor() -> Array[TangledPlushie]:
	var found: Array[TangledPlushie] = []
	for child: Node in run.floor_items.get_children():
		if child is TangledPlushie and not child.is_queued_for_deletion():
			found.append(child as TangledPlushie)
	return found


func _die() -> void:
	var banane: Player = first_player()
	banane.invincible = false
	banane.health = 1.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_seconds(Run.DEATH_PAUSE + 0.3)


func test_ac44_the_first_run_never_has_a_rescue() -> void:
	run = await start_run()
	assert_eq(run.run_number, 1, "Main tells the run its number")
	assert_null(run.rescue_plan, "no rescue in run 1")


func test_ac44_later_runs_know_their_number_and_who_is_already_home() -> void:
	main.town.runs_started = 1
	main.town.plushies["bobo"] = "in_town"
	run = await start_run()
	assert_eq(run.run_number, 2)
	assert_eq(run.rescued_before, PackedStringArray(["bobo"]))
	if run.rescue_plan != null:
		assert_ne(run.rescue_plan.plushie.id, "bobo", "a plushie at home is never offered again")
		assert_between(run.rescue_plan.at_seconds, RULES.earliest_seconds, RULES.latest_seconds)


func test_ac44_the_rescue_appears_at_its_planned_time() -> void:
	await _quiet_run()
	run.rescue_plan = RescuePlan.new(BAMBAM, run.elapsed + 0.5)
	await wait_seconds(0.2)
	assert_eq(_plushies_on_floor().size(), 0, "not yet")
	await wait_seconds(0.5)
	assert_eq(_plushies_on_floor().size(), 1, "it appeared")
	assert_eq(run.rescue.plushie, BAMBAM, "the planned plushie")


func test_ac44_it_appears_away_from_banane_with_a_banner_a_squeak_and_an_edge_arrow() -> void:
	await _quiet_run()
	Sfx.history.clear()
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	await wait_physics_frames(2)
	assert_eq(run.hud.banner_title.text, RULES.help_banner)
	assert_eq(Sfx.history.count(RULES.help_sound), 1, "one help squeak")
	var away: float = plushie.position.distance_to(first_player().global_position)
	assert_between(away, RULES.min_distance - 1.0, RULES.max_distance + 1.0, "some way off")
	assert_true(run.arena.play_rect().has_point(plushie.position), "inside the Bedroom")
	assert_false(run.enemies.obstacles.blocks(plushie.position), "not inside furniture")
	plushie.position = first_player().global_position + Vector2(3000, 0)
	await wait_physics_frames(2)
	var arrows: PickupArrows = run.pickup_arrows
	assert_eq(arrows.points.size(), 1, "an arrow points to it")
	assert_eq(arrows.colors[0], TangledPlushie.GLOW_COLOR, "in its soft lilac")
	assert_gt(arrows.directions[0].x, 0.95, "pointing at it")


func test_ac44_it_is_soft_lilac_not_danger_red() -> void:
	var lilac: Color = TangledPlushie.GLOW_COLOR
	assert_between(lilac.h, 0.65, 0.85, "a lilac hue")
	assert_gt(lilac.b, lilac.g, "more blue than green")


func test_ac44_standing_next_to_it_fills_the_ring_in_3_s_and_moving_away_pauses_it() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var outside: Vector2 = banane.global_position
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	_step_to(banane, plushie.middle())
	await wait_seconds(RULES.fill_seconds * 0.5)
	var half: float = plushie.fill
	assert_between(half, 0.4, 0.6, "half full after half the time")
	_step_to(banane, outside)
	await wait_seconds(1.0)
	assert_almost_eq(plushie.fill, half, 0.03, "moving away pauses the ring (it doesn't empty)")
	assert_eq(run.haul.rescued, "", "not free yet")
	Sfx.history.clear()
	_step_to(banane, plushie.middle())
	await wait_seconds(RULES.fill_seconds * 0.5 + 0.2)
	assert_eq(run.haul.rescued, "bambam", "in the backpack")
	assert_eq(run.hud.banner_title.text, RULES.freed_banner % "BamBam")
	assert_has(Sfx.history, RULES.freed_sound, "the happy sound plays")
	await wait_seconds(TangledPlushie.HOP_SECONDS + 0.2)
	assert_eq(_plushies_on_floor().size(), 0, "it hopped into the backpack")
	assert_eq(run.pickup_arrows.points.size(), 0, "no more arrow")


func test_ac44_a_freed_plushie_comes_home_even_if_banane_dies() -> void:
	main.town.runs_started = 1
	await _quiet_run()
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	_step_to(first_player(), plushie.middle())
	await wait_seconds(RULES.fill_seconds + 0.2)
	await _die()
	assert_true(main.current_screen is EndScreen, "Banane got stuffed")
	assert_eq(main.town.plushies.get("bambam", ""), "waiting", "the plushie came home")
	var end: EndScreen = main.current_screen as EndScreen
	assert_true(end.brought_home.rescue_label.visible, "the end screen says so")
	assert_string_contains(end.brought_home.rescue_label.text, "BamBam")
	var entry: Dictionary = RunLog.read_all().back()
	assert_eq(entry["rescue"]["plushie"], "bambam")
	assert_true(entry["rescue"]["freed"], "logged as freed")
	var saved: TownSave = SaveStore.read()
	assert_eq(saved.plushies.get("bambam", ""), "waiting", "and it is saved")


func test_ac44_a_plushie_not_freed_in_time_stays_behind() -> void:
	await _quiet_run()
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	_step_to(first_player(), plushie.middle())
	await wait_seconds(RULES.fill_seconds * 0.5)
	await _die()
	assert_false(main.town.plushies.has("bambam"), "not brought home")
	var end: EndScreen = main.current_screen as EndScreen
	assert_false(end.brought_home.rescue_label.visible)
	var entry: Dictionary = RunLog.read_all().back()
	assert_false(entry["rescue"]["freed"], "logged as not freed")


func test_ac44_freeing_saves_at_once_so_closing_the_game_keeps_it() -> void:
	await _quiet_run()
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	_step_to(first_player(), plushie.middle())
	await wait_seconds(RULES.fill_seconds + 0.2)
	var saved: TownSave = SaveStore.read()
	assert_eq(saved.unfinished_run.get("rescued", ""), "bambam", "the run in progress has it")


func test_ac44_the_second_player_can_free_it() -> void:
	await _quiet_run()
	var second: Player = run.spawn_player(1, first_player().global_position + Vector2(-200, 0))
	second.invincible = true
	var plushie: TangledPlushie = run.start_rescue(BAMBAM)
	_step_to(second, plushie.middle())
	await wait_seconds(RULES.fill_seconds + 0.2)
	assert_eq(run.haul.rescued, "bambam")


func test_ac44_only_one_rescue_per_run_and_the_dev_menu_starts_one() -> void:
	await _quiet_run()
	run.dev_menu.press("Start rescue now")
	await wait_physics_frames(1)
	assert_eq(_plushies_on_floor().size(), 1, "the dev menu started a rescue")
	run.dev_menu.press("Start rescue now")
	await wait_physics_frames(1)
	assert_eq(_plushies_on_floor().size(), 1, "still just one")
