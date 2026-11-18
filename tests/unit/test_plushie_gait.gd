extends GutTest
## Plushie walks (issue #147): every plushie has its own little puppet walk in data. Bears step
## (feet take turns, Böbö waddles), Robbar the seal hops and squashes.

const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
## Moments spread over a few walk cycles.
const SAMPLES: int = 60
const SAMPLE_SECONDS: float = 0.023


func _find(id: String) -> PlushieDef:
	return RESCUE.find(id)


func test_every_plushie_has_a_walk() -> void:
	for plushie: PlushieDef in RESCUE.plushies:
		assert_not_null(plushie.gait, "%s has a gait" % plushie.id)
		assert_gt(plushie.gait.steps_per_second, 0.0, "%s steps" % plushie.id)


func test_standing_still_is_the_rest_pose() -> void:
	for plushie: PlushieDef in RESCUE.plushies:
		assert_true(plushie.gait.pose(1.3, 0.0).is_rest(), "%s stands still" % plushie.id)


func test_bears_lift_their_feet_in_turn_and_never_both() -> void:
	for id: String in ["pip", "bobo", "bambam"]:
		var gait: PlushieGait = _find(id).gait
		assert_eq(gait.kind, PlushieGait.Kind.STEP, "%s steps" % id)
		var left_up: bool = false
		var right_up: bool = false
		for i: int in SAMPLES:
			var pose: PlushiePose = gait.pose(i * SAMPLE_SECONDS, 1.0)
			var left: bool = pose.foot(-1.0).y < -0.01
			var right: bool = pose.foot(1.0).y < -0.01
			assert_false(left and right, "%s keeps one foot down" % id)
			left_up = left_up or left
			right_up = right_up or right
		assert_true(left_up and right_up, "%s lifts both feet in turn" % id)


func test_the_body_bobs_and_the_arms_swing_while_walking() -> void:
	var gait: PlushieGait = _find("bambam").gait
	var pose: PlushiePose = gait.pose(0.5 / gait.steps_per_second, 1.0)
	assert_gt(pose.body_lift, 0.0, "the body bobs up mid-step")
	assert_ne(pose.arm(-1.0), 0.0, "the arms swing")


func test_bobo_waddles_more_than_the_others() -> void:
	var bobo: PlushieGait = _find("bobo").gait
	for id: String in ["pip", "bambam"]:
		var other: PlushieGait = _find(id).gait
		assert_gt(bobo.tilt, other.tilt * 2.0, "Böbö rocks side to side more than %s" % id)
		assert_lt(bobo.steps_per_second, other.steps_per_second, "and walks slower than %s" % id)


func test_robbar_hops_stretches_in_the_air_and_squashes_on_landing() -> void:
	var gait: PlushieGait = _find("robbar").gait
	assert_eq(gait.kind, PlushieGait.Kind.HOP)
	var landing: PlushiePose = gait.pose(0.0001, 1.0)
	assert_lt(landing.hop, 0.01, "on the ground at the start of a hop")
	assert_gt(landing.squash.x, 1.0, "squashed wide on landing")
	assert_lt(landing.squash.y, 1.0, "and flat")
	var top: PlushiePose = gait.pose(0.5 / gait.steps_per_second, 1.0)
	assert_almost_eq(top.hop, gait.hop_height, 0.001, "the top of the hop")
	assert_lt(top.squash.x, 1.0, "stretched thin in the air")
	assert_gt(top.squash.y, 1.0, "and tall")
	var paddle: PlushiePose = gait.pose(0.25 / gait.steps_per_second, 1.0)
	assert_ne(paddle.arm(1.0), 0.0, "the flippers paddle")


func test_half_a_stride_is_half_the_walk() -> void:
	var gait: PlushieGait = _find("pip").gait
	var seconds: float = 0.5 / gait.steps_per_second
	var full: PlushiePose = gait.pose(seconds, 1.0)
	var half: PlushiePose = gait.pose(seconds, 0.5)
	assert_almost_eq(half.foot(-1.0).y, full.foot(-1.0).y / 2.0, 0.0001)
	assert_almost_eq(half.body_lift, full.body_lift / 2.0, 0.0001)
