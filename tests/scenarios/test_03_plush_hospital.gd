extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §7, AC-45): rescued plushies wait in the tent until there is a bed in the
## Plush Hospital (2 / 4 / 6 per level), then they are stitched up and move into town: they walk
## around, sit, wave at Banane and wear a name tag. Each one adds +5% coins to every run.

const PLENTY: Dictionary[String, int] = {"coins": 9000, "stuffing": 300, "thread": 60}
const PLUSHIE_RULES: PlushieTownRules = preload("res://data/town/plushie_town_rules.tres")
const MATERIAL_RULES: MaterialRules = preload("res://data/town/material_rules.tres")
const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
## A free spot on the blanket, far from the door where Banane appears.
const QUIET_SPOT: Vector2 = Vector2(600, 1560)


## Waits until the rebuild moment, the fort growing and plushies moving in have played.
func _settle(town: Town) -> void:
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func _open_hospital() -> void:
	main.town.revealed.append("plush_hospital")


## A town whose Plush Hospital stands at `level` with `ids` already living there.
func _town_with(level: int, ids: Array[String]) -> Town:
	for id: String in ids:
		main.town.plushies[id] = "in_town"
	_open_hospital()
	main.town.building_levels["plush_hospital"] = level
	return await go_to_town()


## A plushie that already lives in town, put down at `at` (away from Banane).
func _plushie_at(town: Town, id: String, at: Vector2) -> TownPlushie:
	main.town.plushies[id] = "in_town"
	return town.spawn_plushie(RESCUE.find(id), at, true)


## Gives up a run that collected `coins` and returns what the end screen shows.
func _give_up_with(coins: int) -> EndScreen:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.haul.add("coins", coins)
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	return main.current_screen as EndScreen


func test_ac45_a_rescued_plushie_waits_in_the_tent_without_a_hospital() -> void:
	main.town.plushies["pip"] = "waiting"
	var town: Town = await go_to_town()
	await wait_seconds(Town.ARRIVAL_REVEAL_SECONDS + 0.3)
	assert_true(town.tent.visible, "the tent is up")
	assert_eq(town.tent.waiting.size(), 1)
	assert_eq(town.tent.waiting[0].id, "pip")
	assert_eq(town.tent.sign_label.text, PLUSHIE_RULES.waiting_text)
	assert_true(town.plushies.is_empty(), "nobody walks around yet: no bed")
	assert_eq(main.town.plushies["pip"], "waiting")


func test_ac45_no_tent_while_nobody_waits() -> void:
	var town: Town = await go_to_town()
	assert_false(town.tent.visible)


func test_ac45_the_hospital_moves_waiting_plushies_in_up_to_its_beds() -> void:
	for id: String in ["pip", "bobo", "bambam"]:
		main.town.plushies[id] = "waiting"
	_open_hospital()
	main.town.materials = PLENTY.duplicate()
	var town: Town = await go_to_town()
	var hospital: TownBuilding = town.buildings[&"plush_hospital"]
	Sfx.history.clear()
	assert_true(town.try_build(hospital), "rebuilt")
	await _settle(town)
	assert_eq(town.hospital_beds(), 2, "Lv 1 has 2 beds")
	assert_eq(main.town.plushies_in_town(), 2)
	assert_eq(main.town.plushies["pip"], "in_town", "first come, first served")
	assert_eq(main.town.plushies["bobo"], "in_town")
	assert_eq(main.town.plushies["bambam"], "waiting", "no bed left")
	assert_eq(town.plushies.size(), 2, "two plushies in town")
	assert_eq(town.tent.waiting.size(), 1, "one still in the tent")
	assert_eq(town.banner_title.text, "Pip and Böbö moved in!")
	assert_true(Sfx.history.has(PLUSHIE_RULES.moved_in_sound))
	assert_eq(SaveStore.read().plushies["pip"], "in_town", "saved")
	assert_true(town.try_build(hospital), "upgraded to Lv 2")
	await _settle(town)
	assert_eq(main.town.plushies["bambam"], "in_town", "Lv 2 has 4 beds")
	assert_false(town.tent.visible, "the tent is gone")


func test_ac45_a_new_plushie_is_stitched_up_at_the_hospital() -> void:
	main.town.plushies["robbar"] = "waiting"
	var town: Town = await _town_with(1, [])
	await wait_seconds(Town.ARRIVAL_REVEAL_SECONDS + 0.1)
	assert_true(town.plushies.has("robbar"), "moved in when you got home")
	var robbar: TownPlushie = town.plushies["robbar"]
	assert_true(robbar.is_stitching(), "the stitch-up moment")
	assert_almost_eq(robbar.position, town.hospital_door(), Vector2(30, 30), "at the Hospital")
	await wait_seconds(PLUSHIE_RULES.stitch_seconds)
	assert_false(robbar.is_stitching())


func test_ac45_plushies_in_town_walk_around_with_a_name_tag() -> void:
	var town: Town = await _town_with(1, [])
	var bambam: TownPlushie = _plushie_at(town, "bambam", QUIET_SPOT)
	assert_false(bambam.is_stitching(), "it already lives here")
	assert_eq(bambam.name_tag.text, "BamBam")
	assert_true(bambam.name_tag.visible)
	var walked: bool = false
	for i: int in roundi(6.0 * FPS):
		await wait_physics_frames(1)
		if bambam.state == TownPlushie.State.WALKING:
			walked = true
	assert_true(walked, "it went for a walk")
	assert_gt(bambam.position.distance_to(QUIET_SPOT), 20.0, "and got somewhere")
	assert_true(TownPlushie.is_walkable(town.layout, bambam.position, 0.0), "never in a building")


func test_ac45_plushies_sit_on_cushions() -> void:
	var town: Town = await _town_with(1, [])
	var bobo: TownPlushie = _plushie_at(town, "bobo", town.layout.cushions[0] + Vector2(0, 160))
	var rules: PlushieTownRules = PLUSHIE_RULES.duplicate()
	rules.sit_chance = 1.0
	rules.idle_max_seconds = rules.idle_min_seconds
	rules.walk_speed = 600.0
	bobo.rules = rules
	var sat: bool = false
	for i: int in roundi(8.0 * FPS):
		await wait_physics_frames(1)
		if bobo.state == TownPlushie.State.SITTING:
			sat = true
			break
	assert_true(sat, "it sat down")
	var on_cushion: bool = false
	for cushion: Vector2 in town.layout.cushions:
		if bobo.position.distance_to(cushion) < 60.0:
			on_cushion = true
	assert_true(on_cushion, "on a cushion")


func test_ac45_a_plushie_waves_when_banane_comes_close() -> void:
	var town: Town = await _town_with(1, [])
	var pip: TownPlushie = _plushie_at(town, "pip", QUIET_SPOT)
	await wait_physics_frames(2)
	assert_eq(pip.waves, 0, "Banane is far away")
	first_player().global_position = QUIET_SPOT + Vector2(PLUSHIE_RULES.wave_radius - 40.0, 0)
	await wait_physics_frames(3)
	assert_eq(pip.state, TownPlushie.State.WAVING, "it stops and waves")
	assert_eq(pip.waves, 1)
	assert_gt(pip.wave_amount(), 0.0, "the arm is up")


func test_ac45_each_plushie_in_town_adds_5_percent_coins() -> void:
	await _town_with(1, ["pip", "bobo"])
	var end: EndScreen = await _give_up_with(100)
	var share: float = MATERIAL_RULES.keep_share_lost
	var bonus: float = 2.0 * PLUSHIE_RULES.coin_bonus_per_plushie
	assert_almost_eq(main.coin_bonus(), 0.1, 0.0001)
	assert_eq(end.brought_home.amount("coins"), ceili(100 * share * (1.0 + bonus) - 0.0001))
	assert_eq(main.town.material("coins"), 55, "half of 100, +10%")
	assert_eq(end.brought_home.bonus_label.text, "Plushies in town: +10% coins")
	assert_true(end.brought_home.bonus_label.visible)


func test_ac45_waiting_plushies_add_no_coins() -> void:
	main.town.plushies["pip"] = "waiting"
	await go_to_town()
	var end: EndScreen = await _give_up_with(100)
	assert_eq(main.town.material("coins"), 50, "only plushies living in town count")
	assert_false(end.brought_home.bonus_label.visible)


func test_ac45_a_plushie_rescued_in_a_run_moves_in_when_you_get_home() -> void:
	await _town_with(1, ["pip"])
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.haul.rescued = "bobo"
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	assert_eq(main.town.plushies["bobo"], "waiting", "home, in the tent")
	var town: Town = await go_to_town()
	await wait_seconds(Town.ARRIVAL_REVEAL_SECONDS + 0.2)
	assert_eq(main.town.plushies["bobo"], "in_town", "a free bed: it moves in")
	assert_true(town.plushies.has("bobo"))
	assert_true(town.plushies.has("pip"))
	assert_string_contains(town.banner_title.text, "Böbö")
	assert_eq(SaveStore.read().plushies["bobo"], "in_town", "saved")
