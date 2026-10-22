extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02b §2-§6, AC-31, AC-32, AC-33, AC-36): killed zombies drop floor pickups by
## the rules in data; touching one triggers it at once with a banner, a sound and a log line; the
## Big Magnet pulls every XP button in the arena to whoever grabbed it; pickups out of sight get
## an arrow at the screen edge.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run
## Every XP pickup as [player, value].
var collected: Array[Array] = []


func _quiet_run() -> Run:
	collected.clear()
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	run.pickups.collected.connect(
		func(player: Player, value: int, _chain: int) -> void: collected.append([player, value])
	)
	return run


func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


## Kills up to `count` zombies far from the players (stops early once `until_pickups` lie on the
## floor). Returns where the last one died.
func _kill(count: int, until_pickups: int = -1) -> Vector2:
	var died_at: Vector2 = Vector2.ZERO
	for i: int in count:
		var spot: Vector2 = first_player().global_position + Vector2(500.0, -200.0 + 20.0 * i)
		var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
		died_at = zombie.position
		run.enemies.damage(zombie, 1000.0)
		if run.floor_pickups().size() == until_pickups:
			break
	await wait_physics_frames(1)
	return died_at


func _grabbed() -> bool:
	return not run.floor_pickup_log.is_empty()


func _no_pickups_left() -> bool:
	return run.floor_pickups().is_empty() and run.pickups.buttons.is_empty()


func test_ac31_zombies_drop_floor_pickups_by_the_rules() -> void:
	await _quiet_run()
	var drops: FloorPickupDrops = run.floor_pickup_drops
	run.elapsed = 10.0
	await _kill(40)
	assert_eq(run.floor_pickups().size(), 0, "nothing in the first 30 s")
	run.elapsed = drops.next_drop_at + 0.1
	var died_at: Vector2 = await _kill(80, 1)
	assert_eq(run.floor_pickups().size(), 1, "a kill drops a pickup once one is due")
	if run.floor_pickups().is_empty():
		return
	assert_almost_eq(run.floor_pickups()[0].position, died_at, Vector2.ONE, "where it died")
	var first_at: float = run.elapsed
	await _kill(40)
	assert_eq(run.floor_pickups().size(), 1, "no second one right after")
	assert_gte(drops.next_drop_at - first_at, run.floor_pickup_rules.min_gap, "the gap holds")
	run.elapsed = drops.next_drop_at + 0.1
	await _kill(80, 2)
	assert_eq(run.floor_pickups().size(), 2, "the next one after the gap")
	run.elapsed = drops.next_drop_at + 0.1
	await _kill(80)
	assert_eq(run.floor_pickups().size(), 2, "never more than 2 on the floor")


func test_ac32_touching_a_pickup_triggers_it_at_once() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	Sfx.history.clear()
	run.elapsed = 75.0
	var magnet: FloorPickup = run.drop_floor_pickup(&"magnet", banane.global_position)
	assert_true(await _wait_until(_grabbed, 0.2), "grabbed at once")
	assert_true(run.hud.banner.visible, "a banner shows")
	assert_eq(run.hud.banner_title.text, "BIG MAGNET!")
	assert_true(Sfx.history.has(&"magnet"), "with its own sound")
	await wait_physics_frames(2)
	assert_false(is_instance_valid(magnet), "it is gone from the floor")
	assert_eq(run.floor_pickups().size(), 0)
	var entry: Dictionary = RunLog.to_entry(run.make_result("ended"))
	assert_eq(entry["floor_pickups"].size(), 1, "it is in the run log")
	if entry["floor_pickups"].is_empty():
		return
	assert_eq(entry["floor_pickups"][0]["name"], "Big Magnet")
	assert_eq(entry["floor_pickups"][0]["time"], 75.0)
	assert_eq(entry["floor_pickups"][0]["player"], 0)


func test_ac32_the_dev_menu_drops_a_magnet_next_to_banane() -> void:
	await _quiet_run()
	run.dev_menu.press("Drop Big Magnet")
	assert_eq(run.floor_pickups().size(), 1)
	if run.floor_pickups().is_empty():
		return
	var gap: float = run.floor_pickups()[0].position.distance_to(first_player().global_position)
	assert_between(gap, 40.0, 150.0, "a few steps away")


func test_ac33_big_magnet_pulls_every_xp_button_to_the_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var offsets: Array[Vector2] = [Vector2(1500, 0), Vector2(-1800, 900), Vector2(0, -1500)]
	for offset: Vector2 in offsets:
		run.pickups.drop(EnemyStats.XpSize.SMALL, banane.global_position + offset)
	await wait_seconds(0.5)
	assert_eq(run.pickups.buttons.size(), 3, "far buttons stay where they are on their own")
	var xp_before: int = banane.progress.xp
	run.drop_floor_pickup(&"magnet", banane.global_position)
	assert_true(await _wait_until(_no_pickups_left, 5.0), "every button flew in")
	assert_eq(collected.size(), 3)
	for pickup: Array in collected:
		assert_eq(pickup[0], banane, "to Banane")
	assert_eq(banane.progress.xp - xp_before, 3, "and their XP counts")


func test_ac33_the_magnet_pulls_to_whoever_grabbed_it() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(300, 0))
	await wait_physics_frames(1)
	run.pickups.drop(EnemyStats.XpSize.SMALL, banane.global_position + Vector2(-1500, 0))
	run.pickups.drop(EnemyStats.XpSize.SMALL, banane.global_position + Vector2(0, 1200))
	run.drop_floor_pickup(&"magnet", second.global_position)
	assert_true(await _wait_until(_no_pickups_left, 5.0), "every button flew in")
	assert_eq(collected.size(), 2)
	for pickup: Array in collected:
		assert_eq(pickup[0], second, "to player 2, who grabbed the magnet")
	assert_eq(run.floor_pickup_log[0]["player"], 1, "logged for player 2")


func test_ac36_a_pickup_out_of_sight_gets_an_edge_arrow() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	run.drop_floor_pickup(&"magnet", banane.global_position + Vector2(200, 0))
	await wait_physics_frames(2)
	assert_eq(run.pickup_arrows.points.size(), 0, "no arrow while it is on screen")
	run.drop_floor_pickup(&"magnet", banane.global_position + Vector2(1600, 0))
	await wait_physics_frames(2)
	var arrows: PickupArrows = run.pickup_arrows
	assert_eq(arrows.points.size(), 1, "one arrow for the pickup out of sight")
	if arrows.points.is_empty():
		return
	assert_true(arrows.is_visible_in_tree(), "the arrows are shown")
	assert_gt(arrows.directions[0].x, 0.95, "it points right, towards the pickup")
	var view: Rect2 = arrows.get_viewport_rect()
	assert_gt(arrows.points[0].x, view.end.x - 100.0, "at the right screen edge")
	assert_lt(arrows.points[0].x, view.end.x, "but inside the screen")
