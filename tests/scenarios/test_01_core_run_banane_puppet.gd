extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §4, M1-02): Banane's puppet animation follows what he is doing.


func _puppet() -> BananePuppet:
	return first_player().get_node("Puppet") as BananePuppet


func test_standing_still_is_idle() -> void:
	await start_run()
	await wait_physics_frames(3)
	assert_eq(_puppet().state, BananePuppet.State.IDLE)


func test_walking_switches_to_walk_and_back_to_idle() -> void:
	await start_run()
	sender.action_down("p1_move_right")
	await wait_physics_frames(6)
	assert_eq(_puppet().state, BananePuppet.State.WALK, "walking")
	sender.action_up("p1_move_right")
	await wait_physics_frames(6)
	assert_eq(_puppet().state, BananePuppet.State.IDLE, "stopped")


func test_dash_switches_to_dash() -> void:
	await start_run()
	await tap_action("p1_dash")
	assert_eq(_puppet().state, BananePuppet.State.DASH)
	await wait_physics_frames(40)
	assert_eq(_puppet().state, BananePuppet.State.IDLE, "back to idle after the dash")


func test_hit_switches_to_hit_and_blinks() -> void:
	await start_run()
	var banane: Player = first_player()
	banane.take_hit(5.0, "Shambler")
	await wait_physics_frames(1)
	var puppet: BananePuppet = _puppet()
	assert_eq(puppet.state, BananePuppet.State.HIT)
	var alphas: Dictionary = {}
	for i: int in 20:
		alphas[snappedf(puppet.modulate.a, 0.01)] = true
		await wait_process_frames(1)
	assert_gt(alphas.size(), 1, "blinks while invulnerable after the hit")
	await wait_physics_frames(45)
	assert_eq(puppet.state, BananePuppet.State.IDLE, "recovers")
	assert_eq(puppet.modulate.a, 1.0, "fully visible again")


func test_puppet_faces_the_walking_direction() -> void:
	await start_run()
	var origin: Node2D = _puppet().get_child(0) as Node2D
	assert_gt(origin.scale.x, 0.0, "faces right at the start")
	await hold_action("p1_move_left", 4)
	await wait_process_frames(1)
	assert_lt(origin.scale.x, 0.0, "faces left after walking left")
