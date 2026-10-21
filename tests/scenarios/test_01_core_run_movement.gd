extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01, AC-1 to AC-5): starting a run, walking and dashing as Banane.


func test_ac1_start_run_puts_banane_in_arena_centre_with_timer_at_zero() -> void:
	sender.key_down(KEY_ENTER)
	await wait_physics_frames(2)
	sender.key_up(KEY_ENTER)
	await wait_physics_frames(2)
	var run: Run = main.current_screen as Run
	assert_not_null(run, "Enter on the focused Start run button starts a run")
	if run == null:
		return
	var banane: Player = first_player()
	assert_eq(banane.stats.display_name, "Banane")
	assert_almost_eq(banane.global_position, run.arena.center(), Vector2.ONE * 1.0)
	assert_string_starts_with(run.hud.timer_label.text, "0:00 / 5:00")


func test_ac2_holding_d_moves_banane_right() -> void:
	await start_run()
	var banane: Player = first_player()
	var start: Vector2 = banane.global_position
	await hold_action("p1_move_right", 30)
	var moved: Vector2 = banane.global_position - start
	var expected: float = banane.stats.move_speed * 30.0 / FPS
	assert_almost_eq(moved.x, expected, 6.0)
	assert_almost_eq(moved.y, 0.0, 0.01)


func test_ac2_diagonal_is_not_faster_than_straight() -> void:
	await start_run()
	var banane: Player = first_player()
	var start: Vector2 = banane.global_position
	sender.action_down("p1_move_up").action_down("p1_move_right")
	await wait_physics_frames(30)
	sender.action_up("p1_move_up").action_up("p1_move_right")
	var moved: Vector2 = banane.global_position - start
	var straight: float = banane.stats.move_speed * 30.0 / FPS
	assert_gt(moved.x, 0.0, "moves right")
	assert_lt(moved.y, 0.0, "moves up")
	assert_almost_eq(moved.x, -moved.y, 0.5, "both axes equally")
	assert_almost_eq(moved.length(), straight, 6.0, "same speed as straight")


func test_ac3_banane_cannot_walk_through_the_wall() -> void:
	var run: Run = await start_run()
	var banane: Player = first_player()
	banane.global_position = Vector2(40.0, run.arena.center().y)
	await hold_action("p1_move_left", 60)
	var radius: float = banane.stats.hitbox_radius
	assert_almost_eq(banane.global_position.x, radius, 1.0, "stops at the left wall")


func test_ac3_banane_cannot_dash_through_the_wall() -> void:
	var run: Run = await start_run()
	var banane: Player = first_player()
	banane.global_position = Vector2(run.arena.size.x - 30.0, 30.0)
	await hold_action("p1_move_right", 2)
	await tap_action("p1_dash")
	await wait_physics_frames(15)
	assert_lt(banane.global_position.x, run.arena.size.x, "stays inside on the right")
	assert_gt(banane.global_position.y, 0.0, "stays inside at the top")


func test_ac4_space_dashes_about_the_dash_distance() -> void:
	await start_run()
	var banane: Player = first_player()
	var start: Vector2 = banane.global_position
	await tap_action("p1_dash")
	await wait_physics_frames(15)
	var moved: Vector2 = banane.global_position - start
	assert_almost_eq(moved.x, banane.stats.dash_distance, 1.0, "dashes in facing direction")
	assert_almost_eq(moved.y, 0.0, 0.01)


func test_ac4_space_during_cooldown_does_nothing() -> void:
	await start_run()
	var banane: Player = first_player()
	await tap_action("p1_dash")
	await wait_physics_frames(15)
	var after_first: Vector2 = banane.global_position
	await tap_action("p1_dash")
	await wait_physics_frames(15)
	assert_eq(banane.global_position, after_first, "second dash during cooldown is ignored")
	await wait_physics_frames(roundi(banane.stats.dash_cooldown * FPS))
	await tap_action("p1_dash")
	await wait_physics_frames(15)
	var moved: float = banane.global_position.x - after_first.x
	assert_almost_eq(moved, banane.stats.dash_distance, 1.0, "dash works again after cooldown")


func test_ac4_dash_goes_in_the_move_direction() -> void:
	await start_run()
	var banane: Player = first_player()
	var start: Vector2 = banane.global_position
	sender.action_down("p1_move_down")
	await wait_physics_frames(2)
	await tap_action("p1_dash")
	sender.action_up("p1_move_down")
	await wait_physics_frames(15)
	var moved: Vector2 = banane.global_position - start
	assert_gt(moved.y, banane.stats.dash_distance, "dash plus a few steps downwards")
	assert_almost_eq(moved.x, 0.0, 0.01)


func test_ac5_no_contact_damage_during_dash() -> void:
	await start_run()
	var banane: Player = first_player()
	await tap_action("p1_dash")
	assert_true(banane.is_dashing(), "still dashing")
	assert_false(banane.take_hit(10.0, "Shambler"), "hit during dash is ignored")
	assert_eq(banane.health, banane.max_health)
	await wait_physics_frames(15)
	assert_false(banane.is_dashing())
	assert_true(banane.take_hit(10.0, "Shambler"), "hit after the dash hurts")
	assert_eq(banane.health, banane.max_health - 10.0)
