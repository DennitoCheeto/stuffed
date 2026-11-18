extends "res://tests/scenarios/run_scenario.gd"
## Scenario (issue #147, spec 03 §7): plushies in town walk like little puppets instead of
## sliding. While one walks, its feet, arms and body move; when it stops, it eases back to
## standing still.

const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
## Far from the plushie, so Banane doesn't make it stop and wave.
const FAR_AWAY: Vector2 = Vector2(2350, 250)
## A clear stretch of quilt by the fort's reading spot.
const WALK: Vector2 = Vector2(240.0, 0.0)


func _plushie(town: Town, id: String) -> TownPlushie:
	first_player().global_position = FAR_AWAY
	main.town.plushies[id] = "in_town"
	var start: Vector2 = town.hangouts.find(&"reading_by_the_fort").at + Vector2(-160.0, 60.0)
	var plushie: TownPlushie = town.spawn_plushie(RESCUE.find(id), start, true)
	plushie.hangouts = null
	return plushie


## Sends `plushie` on a walk `by` pixels and records whether its pose moved on each frame.
func _walk(plushie: TownPlushie, by: Vector2, frames: int) -> Array[PlushiePose]:
	plushie.target = plushie.position + by
	plushie.state = TownPlushie.State.WALKING
	var poses: Array[PlushiePose] = []
	for i: int in frames:
		await wait_physics_frames(1)
		if plushie.is_moving():
			poses.append(plushie.walk_pose())
	return poses


func test_bears_take_steps_while_they_walk() -> void:
	var town: Town = await go_to_town()
	for id: String in ["pip", "bobo", "bambam"]:
		var bear: TownPlushie = _plushie(town, id)
		var poses: Array[PlushiePose] = await _walk(bear, WALK, 50)
		var lifted: Array[bool] = [false, false]
		for pose: PlushiePose in poses:
			lifted[0] = lifted[0] or pose.foot(-1.0).y < -0.01
			lifted[1] = lifted[1] or pose.foot(1.0).y < -0.01
		assert_true(lifted[0] and lifted[1], "%s lifts its left and right foot" % id)
		bear.queue_free()


func test_robbar_hops_along() -> void:
	var town: Town = await go_to_town()
	var robbar: TownPlushie = _plushie(town, "robbar")
	var poses: Array[PlushiePose] = await _walk(robbar, WALK, 50)
	var highest: float = 0.0
	for pose: PlushiePose in poses:
		highest = maxf(highest, pose.hop)
	assert_gt(highest, robbar.plushie.gait.hop_height * 0.5, "the seal hops instead of sliding")


func test_it_stands_still_again_after_the_walk() -> void:
	var town: Town = await go_to_town()
	var bobo: TownPlushie = _plushie(town, "bobo")
	await _walk(bobo, Vector2(30.0, 0.0), 40)
	assert_false(bobo.is_moving(), "the short walk is over")
	# It rests at least `idle_min_seconds` before the next walk; the walk eases out much faster.
	await wait_physics_frames(30)
	assert_false(bobo.is_moving(), "still resting")
	assert_true(bobo.walk_pose().is_rest(), "feet down, arms still, no waddle")
