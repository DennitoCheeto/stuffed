extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §4, AC-6): Slippery, Banane's passive. Every dash drops a banana peel.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


func _peels() -> Array[BananaPeel]:
	var result: Array[BananaPeel] = []
	for child: Node in run.get_node("FloorItems").get_children():
		if child is BananaPeel and not child.is_queued_for_deletion():
			result.append(child as BananaPeel)
	return result


## Lets Banane dash again right away (on a copy of his stats, so other scenarios keep theirs).
func _quick_dashes(banane: Player) -> void:
	banane.stats = banane.stats.duplicate()
	banane.stats.dash_cooldown = 0.1


func test_ac6_a_dash_drops_a_peel_where_it_started() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var start: Vector2 = banane.global_position
	await tap_action("p1_dash")
	await wait_physics_frames(2)
	var peels: Array[BananaPeel] = _peels()
	assert_eq(peels.size(), 1, "one peel")
	assert_almost_eq(peels[0].position, start, Vector2.ONE * 3.0, "at the dash start")


func test_ac6_zombie_on_the_peel_is_stunned_then_moves_again() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var peel_spot: Vector2 = banane.global_position
	await tap_action("p1_dash")
	await wait_physics_frames(15)
	# A shambler walks towards Banane right across the peel.
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, peel_spot + Vector2(-60, 0))
	var stun: float = banane.stats.peel_stun
	var slipped: bool = false
	for frame: int in 120:
		await wait_physics_frames(1)
		if zombie.is_stunned():
			slipped = true
			break
	assert_true(slipped, "the zombie slipped on the peel")
	assert_eq(_peels().size(), 0, "the peel is used up")
	var stuck_at: Vector2 = zombie.position
	await wait_physics_frames(roundi(stun * FPS) - 10)
	assert_almost_eq(zombie.position, stuck_at, Vector2.ONE * 1.0, "stays put while stunned")
	await wait_physics_frames(30)
	assert_false(zombie.is_stunned())
	assert_gt(zombie.position.distance_to(stuck_at), 5.0, "moves again afterwards")


func test_ac6_at_most_three_peels() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_quick_dashes(banane)
	for i: int in 5:
		await tap_action("p1_dash")
		await wait_physics_frames(15)
	assert_eq(_peels().size(), banane.stats.peel_max)
	assert_eq(banane.stats.peel_max, 3)


func test_ac6_unused_peel_disappears_after_its_lifetime() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.stats = banane.stats.duplicate()
	banane.stats.peel_lifetime = 0.5
	await tap_action("p1_dash")
	await wait_physics_frames(5)
	assert_eq(_peels().size(), 1)
	await wait_seconds(0.6)
	assert_eq(_peels().size(), 0, "gone after its lifetime")


func test_ac6_peel_numbers_come_from_banane_data() -> void:
	var stats: HeroStats = load("res://data/heroes/banane.tres")
	assert_true(stats.slippery)
	assert_eq(stats.peel_lifetime, 4.0)
	assert_eq(stats.peel_stun, 1.0)
	assert_eq(stats.peel_max, 3)
