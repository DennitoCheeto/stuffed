extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 05 §4.1, M3.6-07): the sunny Bedroom. A run starts on the patchwork rug; walking
## up to the top wall, the camera shows the wall with its windows but never past it, and the hero
## can't walk into it; the soft vignette lies over the room but under the HUD.

## Frames to let the camera's smoothing catch up with the hero.
const SETTLE_FRAMES: int = 90
## Rounding slack in px.
const SLACK: float = 1.0


## The part of the room the camera shows right now, in arena pixels.
func _shown(run: Run) -> Rect2:
	var viewport: Viewport = run.get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()


func test_a_run_starts_on_the_patchwork_rug() -> void:
	var run: Run = await start_run()
	var rug: Rect2 = run.arena.rug_rects()[0]
	assert_true(rug.has_point(first_player().global_position), "the hero starts on the rug")


func test_walking_up_shows_the_top_wall_with_its_windows() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	var hero: Player = first_player()
	hero.global_position = Vector2(run.arena.room.window_centers[0], 300.0)
	await hold_action("p1_move_up", SETTLE_FRAMES)
	assert_gt(hero.global_position.y, 0.0, "the hero can't walk into the top wall")
	var shown: Rect2 = _shown(run)
	var window: Rect2 = BedroomLook.window_rect(run.arena.room, 0)
	assert_true(shown.encloses(window), "the window is on screen (shown %s)" % shown)
	assert_true(run.arena.outer_rect().grow(SLACK).encloses(shown), "never past the wall")


func test_the_vignette_lies_over_the_room_but_under_the_hud() -> void:
	var run: Run = await start_run()
	var vignette: RoomVignette = run.vignette
	assert_not_null(vignette)
	assert_true(vignette.visible and vignette.shade.visible, "it shows")
	assert_eq(vignette.layer, run.hud.layer, "same layer as the HUD ...")
	assert_lt(vignette.get_index(), run.hud.get_index(), "... drawn before it")
	var screen: Vector2 = run.get_viewport().get_visible_rect().size
	assert_eq(vignette.shade.get_global_rect().size, screen, "it covers the whole screen")
	assert_eq(vignette.shade.mouse_filter, Control.MOUSE_FILTER_IGNORE, "clicks go through")
