extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §14, late-game smoothness, PO feedback 2026-10-25): when a big crowd dies
## at once the run must not hitch. Only a few death bursts start per frame, killed zombies vanish
## at once but are freed a few per frame, the HUD jars update once per frame, heavy-hit freezes
## come at most once per cooldown, and nothing errors on a zombie freed between physics ticks
## or on an evolved weapon's sparkle shots.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const STORM: WeaponStats = preload("res://data/weapons/sewing_storm.tres")
const CROWD: int = 200


func _quiet_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	disarm(first_player())
	first_player().invincible = true
	return run


func _spawn_crowd(run: Run) -> void:
	var center: Vector2 = first_player().global_position
	for i: int in CROWD:
		var offset: Vector2 = Vector2.RIGHT.rotated(TAU * i / CROWD) * (200.0 + (i % 5) * 60.0)
		run.enemies.spawn(SHAMBLER, center + offset)
	await wait_physics_frames(2)


func _bursts(run: Run) -> int:
	var count: int = 0
	for child: Node in run.enemies.effects.get_children():
		if child is ZombieBurst:
			count += 1
	return count


func test_a_crowd_dying_at_once_starts_only_a_few_bursts_per_frame() -> void:
	var run: Run = await _quiet_run()
	await _spawn_crowd(run)
	assert_eq(run.enemies.alive_count(), CROWD)
	run.enemies.kill_all()
	assert_eq(run.enemies.alive_count(), 0, "all of them are dead at once")
	assert_eq(run.enemies.kills, CROWD)
	assert_lte(_bursts(run), EnemyManager.MAX_NEW_BURSTS_PER_FRAME, "only a few bursts per frame")
	assert_gt(_bursts(run), 0, "some still burst")
	assert_eq(run.enemies.dying_count(), CROWD, "hidden, waiting to be freed")
	for zombie: Node in run.enemies.actors.get_children():
		if zombie is Zombie:
			assert_false((zombie as Zombie).visible, "a killed zombie vanishes at once")
			break


func test_killed_zombies_are_freed_a_few_per_frame() -> void:
	var run: Run = await _quiet_run()
	await _spawn_crowd(run)
	run.enemies.kill_all()
	var before: int = run.enemies.dying_count()
	await wait_process_frames(1)
	var freed: int = before - run.enemies.dying_count()
	assert_gt(freed, 0, "freeing started")
	assert_lte(freed, EnemyManager.FREE_PER_FRAME, "but only a few per frame")
	var frames: int = ceili(float(CROWD) / EnemyManager.FREE_PER_FRAME) + 2
	await wait_process_frames(frames)
	assert_eq(run.enemies.dying_count(), 0, "all freed after a few frames")


func test_a_zombie_freed_since_the_last_physics_tick_is_skipped() -> void:
	var run: Run = await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(300, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	await wait_physics_frames(1)
	# Still in the lookup grid until the next physics tick.
	run.enemies.zombies.erase(zombie)
	zombie.free()
	var found: Array[Zombie] = run.enemies.query_circle(spot, 100.0)
	assert_eq(found.size(), 0, "the freed zombie is skipped without an error")


func test_the_jar_numbers_update_once_per_frame() -> void:
	var run: Run = await _quiet_run()
	var jars: RunJars = run.hud.jars
	await wait_process_frames(1)
	var start: int = jars.counters["coins"].shown
	for i: int in 50:
		run.collect({"coins": 2}, Vector2.ZERO)
	assert_eq(jars.shown("coins"), start + 100, "the haul is right at once")
	assert_eq(jars.counters["coins"].shown, start, "the label waits for the frame")
	await wait_process_frames(1)
	assert_eq(jars.counters["coins"].shown, start + 100, "and shows it once")


func test_heavy_hit_freezes_come_at_most_once_per_cooldown() -> void:
	var run: Run = await _quiet_run()
	var before: int = run.hit_stops
	run.hit_stop()
	run.hit_stop()
	run.hit_stop()
	assert_eq(run.hit_stops, before + 1, "one freeze, not three")
	await wait_seconds(run.rules.hit_stop_seconds + 0.1)
	assert_false(run.is_frozen(), "and it is over quickly")
	run.elapsed += run.rules.hit_stop_cooldown
	run.hit_stop()
	assert_eq(run.hit_stops, before + 2, "after the cooldown the next heavy hit freezes again")
	await wait_seconds(run.rules.hit_stop_seconds + 0.1)


func test_the_sewing_storm_ignores_its_sparkle_shots() -> void:
	var run: Run = await _quiet_run()
	var storm: Weapon = first_player().add_weapon(STORM)
	storm.attack()
	var needles: Array[Projectile] = run.projectiles.fired_by(storm)
	var count: int = needles.size()
	assert_gt(count, 0, "the storm is up")
	var pop: SparkleProjectile = run.projectiles.spawn(SparkleProjectile) as SparkleProjectile
	pop.launch(needles[0], first_player().global_position)
	storm.attack()
	var storm_needles: int = 0
	for shot: Projectile in run.projectiles.fired_by(storm):
		if shot is StormNeedleProjectile:
			storm_needles += 1
	assert_eq(storm_needles, count, "the sparkle neither breaks the fling nor counts as a needle")
