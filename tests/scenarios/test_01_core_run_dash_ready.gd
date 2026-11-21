extends "res://tests/scenarios/run_scenario.gd"
## Scenario (#330): you can see when the dash is ready. The HUD has a dash patch with the dash key
## that fills while the dash recharges and pops when it is ready; every hero has a small dash pip
## under their own health bar that does the same. Calm colours, never danger.

const OVERLAY: GDScript = preload("res://src/player/player_overlay.gd")

var run: Run


func _quiet_run() -> Player:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	var hero: Player = first_player()
	disarm(hero)
	return hero


func _ready_again(hero: Player) -> bool:
	return hero.can_dash()


func test_330_the_hud_dash_patch_fills_and_pops_when_ready() -> void:
	var hero: Player = await _quiet_run()
	var patch: DashPatch = run.hud.dash
	assert_not_null(patch, "the HUD has a dash patch")
	assert_true(patch.is_visible_in_tree(), "always shown in a run")
	assert_eq(patch.key_label.text, hero.key_text("dash"), "with the dash key on it")
	assert_true(patch.is_ready(), "ready at the start")
	await tap_action("p1_dash")
	await wait_physics_frames(2)
	assert_false(patch.is_ready(), "used up by the dash")
	assert_between(patch.charge(), 0.0, 0.5, "it starts filling up again")
	assert_true(await wait_until(_ready_again.bind(hero), hero.stats.dash_cooldown + 0.5))
	await wait_physics_frames(1)
	assert_true(patch.is_ready(), "full again")
	assert_eq(patch.pops, 1, "it popped once when the dash got ready")
	assert_true(patch.is_popping(), "the pop shows right away")


func test_330_each_hero_has_a_dash_pip_under_their_bar() -> void:
	var hero: Player = await _quiet_run()
	var overlay: Node = hero.get_node("Overlay")
	await tap_action("p1_dash")
	assert_true(await wait_until(_ready_again.bind(hero), hero.stats.dash_cooldown + 0.5))
	await wait_physics_frames(1)
	assert_true(overlay.call(&"is_dash_popping"), "the hero's own pip pops when ready")


func test_330_dash_colours_are_calm() -> void:
	var colors: Array[Color] = [
		DashPatch.FILL,
		DashPatch.CHARGE_COLOR,
		DashPatch.READY_COLOR,
		DashPatch.WAITING_COLOR,
		OVERLAY.DASH_PIP_READY,
		OVERLAY.DASH_PIP_WAITING,
	]
	for color: Color in colors:
		assert_false(UiColors.is_danger(color), color.to_html())
