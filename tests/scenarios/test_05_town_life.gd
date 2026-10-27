extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 05 §3.4, playtest P-22): the town feels alive. Rescued plushies hang out at
## spots (reading by the fort, sitting at the Snack Bar table, napping at the Hospital, waving
## from the Watchtower lookout) once those buildings stand; dust sparkles drift in the sunbeams;
## now and then a paper plane glides across the town.

const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
## Far from every spot, so Banane doesn't make plushies stop and wave.
const FAR_AWAY: Vector2 = Vector2(2350, 250)


func _ids(spots: Array[PlushieSpot]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for spot: PlushieSpot in spots:
		ids.append(spot.id)
	return ids


## A plushie that lives in town, put down near `at`, with Banane out of the way.
func _plushie_near(town: Town, id: String, at: Vector2) -> TownPlushie:
	first_player().global_position = FAR_AWAY
	main.town.plushies[id] = "in_town"
	return town.spawn_plushie(RESCUE.find(id), at, true)


## Waits up to `seconds` until `plushie` hangs out at its spot.
func _wait_hanging_out(plushie: TownPlushie, seconds: float) -> void:
	for i: int in roundi(seconds * FPS):
		if plushie.is_hanging_out():
			return
		await wait_physics_frames(1)


func _wait_planes(life: TownLife, count: int, seconds: float) -> void:
	for i: int in roundi(seconds * FPS):
		if life.planes_flown >= count:
			return
		await wait_physics_frames(1)


func test_p22_spots_open_when_their_building_stands() -> void:
	main.town.building_levels["snack_bar"] = 1
	var town: Town = await go_to_town()
	var open: Array[StringName] = _ids(town.hangouts.free_spots())
	assert_has(open, &"reading_by_the_fort", "the fort is always there")
	assert_does_not_have(open, &"snack_bar_table", "the table comes with the Snack Bar's Lv 2")
	assert_does_not_have(open, &"hospital_nap", "no Hospital yet")
	assert_does_not_have(open, &"watchtower_lookout", "no lookout yet")
	main.town.building_levels["snack_bar"] = 2
	main.town.building_levels["plush_hospital"] = 1
	main.town.building_levels["watchtower"] = 3
	open = _ids(town.hangouts.free_spots())
	for id: StringName in [&"snack_bar_table", &"hospital_nap", &"watchtower_lookout"]:
		assert_has(open, id, "%s opens once its building stands" % id)


func test_p22_a_plushie_reads_by_the_fort() -> void:
	var town: Town = await go_to_town()
	var spot: PlushieSpot = town.hangouts.find(&"reading_by_the_fort")
	var pip: TownPlushie = _plushie_near(town, "pip", spot.at + Vector2(-160.0, 60.0))
	assert_true(pip.visit(spot), "it walks over")
	await _wait_hanging_out(pip, 5.0)
	assert_true(pip.is_hanging_out(), "it arrived")
	assert_almost_eq(pip.position, spot.at, Vector2.ONE, "right at the spot")
	assert_eq(pip.pose(), PlushieSpot.Pose.READ)


func test_p22_a_plushie_climbs_the_watchtower_and_waves_from_the_lookout() -> void:
	main.town.building_levels["watchtower"] = 3
	main.town.revealed.append("watchtower")
	var town: Town = await go_to_town()
	var spot: PlushieSpot = town.hangouts.find(&"watchtower_lookout")
	var robbar: TownPlushie = _plushie_near(town, "robbar", spot.approach + Vector2(120.0, 40.0))
	assert_true(robbar.visit(spot))
	await _wait_hanging_out(robbar, 8.0)
	assert_true(robbar.is_hanging_out(), "it climbed up")
	assert_almost_eq(robbar.position, spot.at, Vector2.ONE, "up on the lookout")
	assert_eq(robbar.pose(), PlushieSpot.Pose.WAVE)
	assert_gt(robbar.wave_amount(), 0.0, "it waves from up there")


func test_p22_one_plushie_per_spot() -> void:
	var town: Town = await go_to_town()
	var spot: PlushieSpot = town.hangouts.find(&"reading_by_the_fort")
	var pip: TownPlushie = _plushie_near(town, "pip", spot.at + Vector2(-160.0, 60.0))
	var bobo: TownPlushie = _plushie_near(town, "bobo", spot.at + Vector2(-200.0, 120.0))
	assert_true(pip.visit(spot))
	assert_false(bobo.visit(spot), "taken")
	assert_does_not_have(_ids(town.hangouts.free_spots()), &"reading_by_the_fort")


func test_p22_a_napping_plushie_sleeps_through_a_visit() -> void:
	main.town.plushies["bambam"] = "in_town"
	main.town.building_levels["plush_hospital"] = 1
	main.town.revealed.append("plush_hospital")
	var town: Town = await go_to_town()
	var spot: PlushieSpot = town.hangouts.find(&"hospital_nap")
	var bambam: TownPlushie = _plushie_near(town, "bambam", spot.approach + Vector2(100.0, 40.0))
	assert_true(bambam.visit(spot))
	await _wait_hanging_out(bambam, 5.0)
	assert_eq(bambam.pose(), PlushieSpot.Pose.NAP)
	first_player().global_position = spot.approach + Vector2(60.0, 30.0)
	await wait_seconds(0.5)
	assert_eq(bambam.waves, 0, "no waving in its sleep")
	assert_true(bambam.is_hanging_out(), "still napping")


func test_p22_plushies_go_to_spots_by_themselves() -> void:
	var town: Town = await go_to_town()
	var spot: PlushieSpot = town.hangouts.find(&"reading_by_the_fort")
	var pip: TownPlushie = _plushie_near(town, "pip", spot.at + Vector2(-160.0, 60.0))
	var eager: PlushieTownRules = pip.rules.duplicate()
	eager.spot_chance = 1.0
	eager.idle_min_seconds = 0.1
	eager.idle_max_seconds = 0.1
	pip.rules = eager
	await _wait_hanging_out(pip, 6.0)
	assert_true(pip.is_hanging_out(), "it went to the only open spot on its own")
	assert_eq(pip.spot, spot)


func test_p22_dust_sparkles_drift_in_the_sunbeams() -> void:
	var town: Town = await go_to_town()
	var life: TownLife = town.life
	assert_gt(life.beam_count(), 0, "there are sunbeams")
	var before: PackedVector2Array = life.sparkle_positions()
	assert_eq(before.size(), life.beam_count() * life.rules.sparkles_per_beam)
	await wait_seconds(0.5)
	var after: PackedVector2Array = life.sparkle_positions()
	var moved: int = 0
	for i: int in after.size():
		var beam: PackedVector2Array = life.beam(floori(float(i) / life.rules.sparkles_per_beam))
		assert_true(Geometry2D.is_point_in_polygon(after[i], beam), "sparkle %d in its beam" % i)
		if after[i].distance_to(before[i]) > 0.5:
			moved += 1
	assert_eq(moved, after.size(), "they all drift")


func test_p22_a_paper_plane_glides_across_now_and_then() -> void:
	var town: Town = await go_to_town()
	var life: TownLife = town.life
	assert_false(life.plane_flying, "not right away")
	var quick: TownLifeRules = life.rules.duplicate()
	quick.plane_speed = 6000.0
	life.rules = quick
	life.next_plane_at = life.elapsed + 0.1
	await wait_seconds(0.25)
	assert_true(life.plane_flying, "a plane takes off")
	var start: Vector2 = life.plane_ground
	await wait_physics_frames(2)
	assert_ne(life.plane_ground.x, start.x, "it glides")
	await _wait_planes(life, 1, 3.0)
	assert_eq(life.planes_flown, 1, "it crossed the whole town")
	assert_false(life.plane_flying)
	var gap: float = life.next_plane_at - life.elapsed
	assert_between(gap, quick.plane_min_gap - 1.0, quick.plane_max_gap, "the next one comes later")
