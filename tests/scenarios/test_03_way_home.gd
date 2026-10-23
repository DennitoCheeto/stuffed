extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §4, AC-41): beating Big Ted opens the Way Home portal with a banner, a sound
## and an edge arrow; standing in it for 2 s (stepping out pauses the ring) ends the run and goes
## home with the whole haul; it is not there before Big Ted is beaten and closes after the King.

const BIG_TED: BigTedDef = preload("res://data/bosses/big_ted.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const RULES: WayHomeRules = preload("res://data/town/way_home_rules.tres")

var run: Run


## A quiet run: no spawns, no weapons, no floor pickups, so the test decides what happens.
func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.floor_pickup_drops.next_drop_at = INF
	disarm(first_player())
	first_player().invincible = true
	return run


func _portals() -> Array[WayHomePortal]:
	var portals: Array[WayHomePortal] = []
	for child: Node in run.floor_items.get_children():
		if child is WayHomePortal and not child.is_queued_for_deletion():
			portals.append(child as WayHomePortal)
	return portals


func _beat_big_ted() -> void:
	var at: Vector2 = first_player().global_position + Vector2(500, 0)
	var ted: Zombie = run.enemies.spawn_boss(BIG_TED, at)
	run.enemies.damage(ted, ted.max_health * 10.0)
	await wait_physics_frames(1)
	# His XP button stays out of the way (a level-up would freeze the run).
	for button: XpButton in run.pickups.buttons:
		button.queue_free()
	run.pickups.buttons.clear()


func _step_to(player: Player, at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO


func test_ac41_no_portal_before_big_ted_is_beaten() -> void:
	await _quiet_run()
	run.enemies.damage(run.enemies.spawn(SHAMBLER, first_player().global_position, ELITE), 1e6)
	await wait_physics_frames(roundi(0.5 * FPS))
	assert_null(run.way_home, "an elite doesn't open it")
	assert_eq(_portals().size(), 0, "nothing on the floor")


func test_ac41_beating_big_ted_opens_the_portal_with_a_banner_and_a_sound() -> void:
	await _quiet_run()
	Sfx.history.clear()
	await _beat_big_ted()
	assert_eq(_portals().size(), 1, "the portal is open")
	var portal: WayHomePortal = run.way_home
	assert_eq(run.hud.banner_title.text, RULES.banner)
	assert_true(run.hud.banner.visible, "the banner shows")
	assert_has(Sfx.history, RULES.sound, "its sound plays")
	var away: float = portal.position.distance_to(first_player().global_position)
	assert_almost_eq(away, RULES.open_distance, 1.0, "a few steps from the player")
	assert_eq(portal.fill, 0.0, "the ring starts empty")


func test_ac41_the_portal_is_soft_blue_not_danger_red() -> void:
	var blue: Color = WayHomePortal.GLOW_COLOR
	assert_between(blue.h, 0.5, 0.7, "a blue hue")
	assert_gt(blue.b, blue.r, "more blue than red")
	assert_eq(RULES.sound, &"way_home")


func test_ac41_an_edge_arrow_points_to_the_portal_off_screen() -> void:
	await _quiet_run()
	var portal: WayHomePortal = run.open_way_home(first_player().global_position)
	await wait_physics_frames(2)
	assert_eq(run.pickup_arrows.points.size(), 0, "no arrow while it is on screen")
	portal.position = first_player().global_position + Vector2(3000, 0)
	await wait_physics_frames(2)
	var arrows: PickupArrows = run.pickup_arrows
	assert_eq(arrows.points.size(), 1, "an arrow shows")
	assert_eq(arrows.colors[0], WayHomePortal.GLOW_COLOR, "in the portal's soft blue")
	assert_gt(arrows.directions[0].x, 0.95, "pointing at the portal")


func test_ac41_standing_in_it_for_2_s_goes_home_and_stepping_out_pauses_the_ring() -> void:
	await _quiet_run()
	var coins_before: int = main.town.material("coins")
	run.collect({"coins": 7}, Vector2.ZERO)
	var banane: Player = first_player()
	var outside: Vector2 = banane.global_position
	var portal: WayHomePortal = run.open_way_home(outside)
	_step_to(banane, portal.position)
	await wait_seconds(RULES.fill_seconds * 0.5)
	var half: float = portal.fill
	assert_between(half, 0.35, 0.65, "the ring fills while Banane stands in it")
	_step_to(banane, outside)
	await wait_seconds(RULES.fill_seconds * 0.5)
	assert_almost_eq(portal.fill, half, 0.05, "stepping out pauses the ring (it doesn't empty)")
	assert_false(run.over, "still in the run")
	_step_to(banane, portal.position)
	await wait_seconds(RULES.fill_seconds * 0.5 + 0.3)
	assert_true(main.current_screen is EndScreen, "the run ended")
	assert_eq(main.town.material("coins"), coins_before + 7, "100% of the haul, no bonus")
	var entry: Dictionary = RunLog.read_all().back()
	assert_eq(entry["run_end"], "way_home")


func test_ac41_the_portal_closes_when_the_king_is_beaten() -> void:
	await _quiet_run()
	run.open_way_home(first_player().global_position)
	beat_the_boss(run)
	await wait_physics_frames(2)
	assert_null(run.way_home, "closed")
	assert_eq(_portals().size(), 0, "gone from the floor")
	assert_null(run.open_way_home(first_player().global_position), "and it doesn't open again")


func test_ac41_one_player_in_the_portal_takes_everybody_home() -> void:
	await _quiet_run()
	var second: Player = run.spawn_player(1, first_player().global_position + Vector2(-200, 0))
	second.invincible = true
	var portal: WayHomePortal = run.open_way_home(first_player().global_position)
	_step_to(second, portal.position)
	await wait_seconds(RULES.fill_seconds + 0.3)
	assert_true(main.current_screen is EndScreen, "the run ended for both")


func test_ac41_dev_menu_opens_the_portal() -> void:
	await _quiet_run()
	run.dev_menu.press("Open Way Home")
	await wait_physics_frames(1)
	assert_eq(_portals().size(), 1)
