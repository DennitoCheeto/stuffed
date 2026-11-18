extends GutTest
## Plushies in the night siege (spec 07 §4, AC-77, AC-79): every plushie living in town stands by
## the fort and throws a small stuffing ball every ~2 s; zombies close by turn to it and can
## knock it out; only a standing Plush Hospital stands it back up (12 / 8 / 5 s). Numbers in
## data, calm colours only.

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const RESCUE: RescueRules = preload("res://data/town/rescue_rules.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const HOSPITAL: StringName = &"plush_hospital"
const ARMORY: StringName = &"toy_box_armory"
## A plushie spot by the fort's left side (from the layout).
const SPOT: Vector2 = Vector2(990, 700)


func _spot(id: StringName) -> TownSpot:
	return LAYOUT.spot(id)


func _zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = Zombie.new()
	zombie.position = at
	zombie.setup(SHAMBLER, 1.0, 1.0, 0.0, null, null)
	autofree(zombie)
	return zombie


func _helper(at: Vector2) -> SiegePlushie:
	var helper: SiegePlushie = SiegePlushie.new()
	helper.setup(RESCUE.plushies[0], at, RULES)
	add_child_autofree(helper)
	return helper


func _targets_with(helper: SiegePlushie) -> SiegeTargets:
	var fort: SiegeFort = SiegeFort.new(LAYOUT.fort_rect, 500.0, RULES.hero_reach, 0.5)
	var targets: SiegeTargets = SiegeTargets.new(fort)
	targets.buildings.append(SiegeBuilding.new(_spot(ARMORY), 1, RULES))
	targets.plushies.append(helper.target)
	return targets


func test_the_plush_hospital_revives_after_12_8_5_seconds() -> void:
	var expected: Array[float] = [12.0, 8.0, 5.0]
	var levels: Array[BuildingLevel] = _spot(HOSPITAL).building.levels
	for i: int in levels.size():
		assert_almost_eq(levels[i].siege_revive_seconds, expected[i], 0.001, "Lv %d" % (i + 1))
	for spot: TownSpot in LAYOUT.spots:
		if spot.id == HOSPITAL:
			continue
		for level: BuildingLevel in spot.building.levels:
			assert_eq(level.siege_revive_seconds, 0.0, "only the Hospital revives (%s)" % spot.id)


func test_the_stuffing_ball_is_weak_and_thrown_every_2_seconds() -> void:
	var ball: WeaponStats = RULES.plushie_ball
	assert_not_null(ball, "the plushies' weapon is in the siege rules")
	var numbers: WeaponLevel = ball.at_level(1)
	assert_almost_eq(numbers.cooldown, 2.0, 0.001, "every ~2 s")
	assert_lt(numbers.damage, 15.0, "weak: a bit of help, mostly charm")
	assert_eq(ball.behaviour, PlushieThrow)
	assert_gt(RULES.plushie_health, 0.0)
	assert_gt(RULES.plushie_reach, 0.0)


func test_plushie_spots_stand_free_by_the_fort() -> void:
	assert_gte(LAYOUT.siege_plushie_spots.size(), 6, "a spot for every Hospital bed")
	for at: Vector2 in LAYOUT.siege_plushie_spots:
		assert_true(LAYOUT.play_rect().has_point(at), "%s is in the room" % at)
		for rect: Rect2 in LAYOUT.blocking_rects():
			var gap: float = TownLayout.distance_to(rect, at)
			assert_gt(gap, RULES.plushie_footprint + 20.0, "%s stands free of %s" % [at, rect])
		var to_fort: float = TownLayout.distance_to(LAYOUT.fort_rect, at)
		assert_lt(to_fort, 200.0, "%s stands by the fort" % at)


func test_zombies_close_by_turn_to_a_plushie() -> void:
	var helper: SiegePlushie = _helper(SPOT)
	var targets: SiegeTargets = _targets_with(helper)
	var close: Zombie = _zombie(SPOT + Vector2(-70, 0))
	assert_eq(targets.goal_for(close, null), helper.target, "a zombie 70 px away goes for it")
	var far: Zombie = _zombie(SPOT + Vector2(0, -400))
	assert_ne(targets.goal_for(far, null), helper.target, "a zombie far away doesn't")


func test_touching_zombies_knock_a_plushie_out_and_then_ignore_it() -> void:
	var helper: SiegePlushie = _helper(SPOT)
	var targets: SiegeTargets = _targets_with(helper)
	var zombie: Zombie = _zombie(SPOT + Vector2(-20, 0))
	targets.touch(zombie, 1.0)
	assert_lt(helper.target.health, helper.target.max_health, "a touching zombie hurts it")
	helper.target.hurt(helper.target.max_health)
	assert_true(helper.is_out(), "knocked out at 0 health")
	assert_false(helper.is_throwing(), "a knocked-out plushie doesn't throw")
	assert_eq(helper.times_knocked_out, 1)
	assert_ne(targets.goal_for(zombie, null), helper.target, "the horde leaves it alone")


func test_without_a_hospital_a_plushie_stays_out() -> void:
	var helper: SiegePlushie = _helper(SPOT)
	helper.target.hurt(helper.target.max_health)
	for i: int in 60:
		helper._physics_process(0.5)
	assert_true(helper.is_out(), "30 s later it is still out")
	assert_false(helper.can_revive())


func test_a_standing_hospital_stands_it_back_up() -> void:
	var helper: SiegePlushie = _helper(SPOT)
	var hospital: SiegeBuilding = SiegeBuilding.new(_spot(HOSPITAL), 2, RULES)
	helper.set_hospital(hospital, 8.0)
	helper.target.hurt(helper.target.max_health)
	for i: int in 15:
		helper._physics_process(0.5)
	assert_true(helper.is_out(), "7.5 s: still out")
	helper._physics_process(0.6)
	assert_false(helper.is_out(), "8 s: it stands back up")
	assert_almost_eq(helper.target.health, helper.target.max_health, 0.001, "full health")
	assert_true(helper.is_throwing(), "and throws again")


func test_a_knocked_down_hospital_stops_reviving() -> void:
	var helper: SiegePlushie = _helper(SPOT)
	var hospital: SiegeBuilding = SiegeBuilding.new(_spot(HOSPITAL), 3, RULES)
	helper.set_hospital(hospital, 5.0)
	helper.target.hurt(helper.target.max_health)
	hospital.hurt(hospital.max_health)
	for i: int in 30:
		helper._physics_process(0.5)
	assert_true(helper.is_out(), "the Hospital fell: nobody stands it up")


func test_revive_only_works_on_a_fallen_target() -> void:
	var target: SiegeTarget = SiegeTarget.new(Rect2(0, 0, 10, 10), 50.0, 1.0)
	var revived: Array[int] = []
	target.revived.connect(func() -> void: revived.append(1))
	target.hurt(20.0)
	target.revive()
	assert_eq(target.health, 30.0, "a standing target isn't healed by revive")
	target.hurt(30.0)
	target.revive()
	assert_eq(target.health, 50.0)
	assert_eq(revived.size(), 1)


func test_plushie_looks_use_no_danger_colour() -> void:
	assert_false(UiColors.is_danger(RULES.dizzy_color), "dizzy stars")
	assert_false(UiColors.is_danger(RULES.plushie_halo), "halo")
	assert_false(UiColors.is_danger(ProjectileLook.CLOUD_COLOR), "stuffing ball")
	for who: PlushieDef in RESCUE.plushies:
		var calm: PlushieDef = who.calmed()
		for color: Color in [calm.body_color, calm.accent_color, calm.detail_color]:
			assert_false(UiColors.is_danger(color), "%s is calmed" % who.id)
