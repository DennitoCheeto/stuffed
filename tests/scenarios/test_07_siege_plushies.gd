extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §4, AC-79, AC-78 Plush Hospital, AC-77 plushies): every plushie living in
## town stands by the fort in the siege and throws stuffing balls at zombies in reach (its own
## row in the weapon tally). Zombies close by walk to a plushie and knock it out: it sits
## dizzy and stops throwing. Without a Plush Hospital it stays out; a built Hospital stands it
## back up (5 s at Lv 3), a knocked-down one doesn't.

const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const HOSPITAL: StringName = &"plush_hospital"
## Health that no stuffing ball pops in these tests.
const VERY_TOUGH: float = 100000.0
## A corner far from the fort, the plushies and the heroes.
const KEEPER_SPOT: Vector2 = Vector2(2350.0, 1400.0)

var siege: Siege


## Presses E at the door of a town with `levels`, `plushies` living in it and the horde due;
## returns the siege with no waves coming and every hero unarmed (one still zombie far away
## keeps the night going).
func _start_siege(levels: Dictionary[String, int], plushies: Array[String]) -> Siege:
	main.town.building_levels = levels
	for id: String in plushies:
		main.town.plushies[id] = "in_town"
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var started: Siege = main.current_screen as Siege
	for hero: Player in Players.all(get_tree()):
		disarm(hero)
	started.waves.finished = true
	started.enemies.kill_all()
	_tough(started, KEEPER_SPOT, 0.0)
	return started


func _tough(where: Siege, at: Vector2, speed: float) -> Zombie:
	var zombie: Zombie = where.enemies.spawn(TANK, at)
	zombie.max_health = VERY_TOUGH
	zombie.health = VERY_TOUGH
	zombie.move_speed = speed
	return zombie


func _helper(id: String) -> SiegePlushie:
	return siege.plushies.get(id) as SiegePlushie


func test_ac79_every_plushie_in_town_helps_by_the_fort() -> void:
	main.town.plushies["robbar"] = "waiting"
	siege = await _start_siege({"lucky_jar": 1, "snack_bar": 1}, ["pip", "bobo"])
	assert_eq(siege.plushies.size(), 2, "the two plushies living in town help")
	assert_false(siege.plushies.has("robbar"), "one still waiting in the tent doesn't")
	assert_eq(siege.targets.plushies.size(), 2, "the horde can go for them")
	for helper: SiegePlushie in siege.plushies.values():
		var to_fort: float = TownLayout.distance_to(siege.layout.fort_rect, helper.position)
		assert_lt(to_fort, 200.0, "%s stands by the fort" % helper.name)
		assert_true(helper.is_throwing())


func test_ac79_plushies_throw_stuffing_balls_at_zombies_in_reach() -> void:
	siege = await _start_siege({"lucky_jar": 1, "snack_bar": 1}, ["pip"])
	var pip: SiegePlushie = _helper("pip")
	assert_not_null(pip)
	if pip == null:
		return
	var zombie: Zombie = _tough(siege, pip.position + Vector2(0.0, 250.0), 0.0)
	var throws: Array[float] = []
	pip.throw.fired.connect(func() -> void: throws.append(siege.elapsed))
	await wait_seconds(4.8)
	assert_between(throws.size(), 2, 3, "a stuffing ball about every 2 s")
	if throws.size() >= 2:
		assert_almost_eq(throws[1] - throws[0], 2.0, 0.1, "every 2 s")
	assert_lt(zombie.health, VERY_TOUGH, "the balls hit the zombie")
	var row: WeaponTallyEntry = siege.enemies.tally.find(-1, WeaponTally.PLUSHIES)
	assert_not_null(row, "the plushies have their own row in the weapon tally")
	if row != null:
		assert_gt(row.damage, 0.0)


func test_ac77_zombies_close_by_knock_a_plushie_out() -> void:
	siege = await _start_siege({"lucky_jar": 1, "snack_bar": 1}, ["pip"])
	silence_turrets(siege)
	var pip: SiegePlushie = _helper("pip")
	var outs: Array[int] = []
	pip.knocked_out.connect(func() -> void: outs.append(1))
	var tank: Zombie = _tough(siege, pip.position + Vector2(-80.0, 0.0), 60.0)
	assert_eq(siege.targets.goal_for(tank, null), pip.target, "the tank turns to the plushie")
	await wait_seconds(7.0)
	assert_eq(outs.size(), 1, "knocked out")
	assert_true(pip.is_out(), "it sits dizzy")
	assert_false(pip.is_throwing(), "and stops throwing")
	await wait_physics_frames(2)
	assert_ne(pip.star_position(0), pip.star_position(1), "dizzy stars circle its head")


func test_ac79_without_the_plush_hospital_a_plushie_stays_out() -> void:
	siege = await _start_siege({"lucky_jar": 1, "snack_bar": 1}, ["pip"])
	var pip: SiegePlushie = _helper("pip")
	pip.target.hurt(pip.target.max_health)
	await wait_seconds(14.0)
	assert_true(pip.is_out(), "still out after 14 s: nobody stands it up")


func test_ac78_the_plush_hospital_stands_a_plushie_back_up() -> void:
	siege = await _start_siege({"lucky_jar": 1, "plush_hospital": 3}, ["pip"])
	var pip: SiegePlushie = _helper("pip")
	assert_eq(pip.hospital, siege.targets.building(HOSPITAL), "the built Hospital revives")
	var ups: Array[float] = []
	pip.stood_up.connect(func() -> void: ups.append(siege.elapsed))
	var start: float = siege.elapsed
	pip.target.hurt(pip.target.max_health)
	await wait_seconds(4.5)
	assert_true(pip.is_out(), "still out after 4.5 s")
	await wait_seconds(1.0)
	assert_false(pip.is_out(), "Lv 3: back up after 5 s")
	if ups.size() == 1:
		assert_almost_eq(ups[0] - start, 5.0, 0.1)
	assert_true(pip.is_throwing(), "and throwing again")


func test_ac78_a_knocked_down_hospital_revives_nobody() -> void:
	siege = await _start_siege({"lucky_jar": 1, "plush_hospital": 3}, ["pip"])
	var pip: SiegePlushie = _helper("pip")
	var hospital: SiegeBuilding = siege.targets.building(HOSPITAL)
	hospital.hurt(hospital.max_health)
	pip.target.hurt(pip.target.max_health)
	await wait_seconds(7.0)
	assert_true(pip.is_out(), "the Hospital fell: the plushie stays out")


func test_ac78_a_damaged_hospital_revives_nobody() -> void:
	main.town.damaged.append(String(HOSPITAL))
	siege = await _start_siege({"lucky_jar": 1, "plush_hospital": 3}, ["pip"])
	var pip: SiegePlushie = _helper("pip")
	assert_null(pip.hospital, "a damaged Hospital doesn't fight along")
	pip.target.hurt(pip.target.max_health)
	await wait_seconds(6.0)
	assert_true(pip.is_out())


func test_ac79_plushies_stop_when_the_siege_ends() -> void:
	siege = await _start_siege({"lucky_jar": 1, "snack_bar": 1}, ["pip"])
	var pip: SiegePlushie = _helper("pip")
	siege.win()
	await wait_physics_frames(1)
	assert_false(pip.is_throwing(), "no more throws once the night is defended")
