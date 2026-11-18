extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §3, AC-87, AC-88): Robbar starts with the Bouncy Yarn Ball; he is the
## fastest hero with a tiny hitbox and the least health. Belly Slide: his dash is a long slide
## (farther than Banane's) that hits every zombie on the way once and leaves a short wet streak.

const ROBBAR: HeroStats = preload("res://data/heroes/robbar.tres")
const BANANE: HeroStats = preload("res://data/heroes/banane.tres")


func _start_as_robbar() -> Run:
	main.town.plushies["robbar"] = "in_town"
	main.town.set_hero(0, "robbar")
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	return run


func test_ac87_robbar_is_fast_tiny_and_fragile() -> void:
	await _start_as_robbar()
	var robbar: Player = first_player()
	assert_not_null(robbar.weapon(&"bouncy_yarn_ball"))
	assert_gt(ROBBAR.move_speed, BANANE.move_speed, "fastest")
	assert_lt(ROBBAR.hitbox_radius, BANANE.hitbox_radius, "tiny hitbox")
	assert_lt(robbar.max_health, BANANE.max_health, "least health")
	assert_lt(ROBBAR.dash_cooldown, BANANE.dash_cooldown, "shorter dash cooldown")
	assert_gt(ROBBAR.dash_distance, BANANE.dash_distance, "a long slide")


func test_ac88_the_belly_slide_hits_every_zombie_on_the_way_once() -> void:
	var run: Run = await _start_as_robbar()
	var robbar: Player = first_player()
	disarm(robbar)
	var slide: BellySlide = robbar.get_node("BellySlide") as BellySlide
	var on_the_way: Array[Zombie] = []
	for x: float in [60.0, 120.0]:
		var zombie: Zombie = run.enemies.spawn(
			run.spawner.schedule.entries[0].enemy, robbar.global_position + Vector2(x, 4)
		)
		zombie.max_health = 1000.0
		zombie.health = 1000.0
		on_the_way.append(zombie)
	var start: Vector2 = robbar.global_position
	sender.action_down("p1_move_right")
	await wait_physics_frames(1)
	await tap_action("p1_dash")
	sender.action_up("p1_move_right")
	var streak: int = 0
	for i: int in 30:
		await wait_physics_frames(1)
		streak = maxi(streak, slide.trail_size())
	assert_eq(slide.hits, 2, "both zombies on the way, once each")
	for zombie: Zombie in on_the_way:
		assert_almost_eq(zombie.health, 1000.0 - ROBBAR.belly_slide_damage, 0.01)
	assert_gt(robbar.global_position.x - start.x, BANANE.dash_distance, "slid farther than a dash")
	assert_gt(streak, 3, "a wet streak behind him")
