extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §8, AC-13): spitters keep their distance, puff up visibly before they spit,
## and their slow stuffing balls hurt any player (but Banane can outrun them).

const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")

var run: Run
## Every volley as [run time, balls].
var volleys: Array[Array] = []


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	volleys.clear()
	run.enemies.zombie_spat.connect(
		func(_zombie: Zombie, balls: int) -> void: volleys.append([run.elapsed, balls])
	)
	return run


func _spitter(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SPITTER, at)
	zombie.attack_cooldown = 0.0
	return zombie


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func test_ac13_spitter_puffs_up_before_it_spits() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var spitter: Zombie = _spitter(banane.global_position + Vector2(260, 0))
	var normal_size: float = spitter.puppet.root.scale.x
	assert_true(await _wait_until(spitter.is_winding_up, 1.0), "it starts a wind-up")
	var windup_started: float = run.elapsed
	assert_eq(run.projectiles.hostile_count(), 0, "nothing spat yet")
	await _wait_until(func() -> bool: return spitter.windup_progress() > 0.8, 1.0)
	assert_eq(run.projectiles.hostile_count(), 0, "still nothing while it puffs up")
	assert_gt(spitter.puppet.root.scale.x, normal_size * 1.2, "it visibly swells")
	assert_gt(spitter.puppet.root.modulate.r, 1.1, "and glows")
	var spat: bool = await _wait_until(func() -> bool: return not volleys.is_empty(), 1.0)
	assert_true(spat, "then it spits")
	var windup_time: float = volleys[0][0] - windup_started
	var expected: float = SPITTER.attack.windup_seconds - 2.0 / FPS
	assert_gte(windup_time, expected, "only after the wind-up")
	assert_eq(run.projectiles.hostile_count(), 1, "a single ball first")
	await wait_physics_frames(2)
	assert_almost_eq(spitter.puppet.root.scale.x, normal_size, 0.05, "back to normal size")


func test_ac13_spitter_ball_hurts_banane() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var health: float = banane.health
	_spitter(banane.global_position + Vector2(260, 0))
	var hit: bool = await _wait_until(func() -> bool: return banane.health < health, 5.0)
	assert_true(hit, "the stuffing ball reached Banane")
	assert_eq(banane.health, health - SPITTER.attack.bullet_damage)
	assert_eq(banane.last_hit_by, "Spitter", "you know what hit you")


func test_ac13_banane_can_outrun_the_balls() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var health: float = banane.health
	var spitter: Zombie = _spitter(banane.global_position + Vector2(-260, 0))
	await _wait_until(func() -> bool: return not volleys.is_empty(), 2.0)
	var ball: EnemyBullet = run.projectiles.active[0] as EnemyBullet
	assert_lt(ball.velocity.length(), banane.stats.move_speed, "slower than Banane")
	spitter.attack_cooldown = 100.0
	sender.action_down("p1_move_right")
	await wait_physics_frames(roundi(2.0 * FPS))
	sender.action_up("p1_move_right")
	assert_eq(banane.health, health, "running away, the ball never catches him")
	assert_gt(ball.position.distance_to(banane.global_position), 60.0, "it falls behind")


func test_spitter_keeps_its_distance() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var close: Zombie = _spitter(banane.global_position + Vector2(90, 0))
	var far: Zombie = _spitter(banane.global_position + Vector2(-520, 0))
	close.attack_cooldown = 100.0
	far.attack_cooldown = 100.0
	await wait_physics_frames(roundi(4.0 * FPS))
	var attack: SpitAttack = SPITTER.attack
	var low: float = attack.keep_distance - attack.distance_band - 5.0
	var high: float = attack.keep_distance + attack.distance_band + 5.0
	for zombie: Zombie in [close, far]:
		var distance: float = zombie.position.distance_to(banane.global_position)
		assert_between(distance, low, high, "%.0f px away" % distance)


func test_spitter_follows_a_single_ball_with_a_fan_of_three() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var spitter: Zombie = _spitter(banane.global_position + Vector2(260, 0))
	await _wait_until(func() -> bool: return not volleys.is_empty(), 2.0)
	spitter.attack_cooldown = 0.0
	await _wait_until(func() -> bool: return volleys.size() >= 2, 2.0)
	assert_eq(volleys[0][1], 1)
	assert_eq(volleys[1][1], 3, "a 3-ball fan")
	assert_eq(run.projectiles.hostile_count(), 4)


func test_spitter_does_not_shoot_from_far_away() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var away: Vector2 = Vector2(SPITTER.attack.fire_range + 300.0, 0)
	var spitter: Zombie = _spitter(banane.global_position + away)
	spitter.move_speed = 0.0
	await wait_physics_frames(roundi(2.0 * FPS))
	assert_false(spitter.is_winding_up())
	assert_eq(volleys.size(), 0)


func test_spitter_balls_hurt_any_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(0, 500))
	disarm(second)
	var health: float = second.health
	_spitter(second.global_position + Vector2(260, 0))
	var hit: bool = await _wait_until(func() -> bool: return second.health < health, 5.0)
	assert_true(hit, "player 2 was hit by the spitter nearest to them")
