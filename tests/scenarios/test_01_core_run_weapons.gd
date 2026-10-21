extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §5, AC-7): Banane's Peel Boomerang.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run


func _armed_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	return run


## A zombie that stands still and has a lot of health, so we can count the hits.
func _dummy(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.move_speed = 0.0
	zombie.max_health = 1000.0
	zombie.health = 1000.0
	return zombie


func _boomerang() -> PeelBoomerang:
	return first_player().weapon(&"peel_boomerang") as PeelBoomerang


func _projectiles() -> Array[BoomerangProjectile]:
	var result: Array[BoomerangProjectile] = []
	for shot: Projectile in run.projectiles.fired_by(_boomerang()):
		result.append(shot as BoomerangProjectile)
	return result


func test_banane_starts_with_the_peel_boomerang_only() -> void:
	await _armed_run()
	var weapons: Array[Weapon] = first_player().weapons()
	assert_eq(weapons.size(), 1)
	assert_not_null(_boomerang())
	assert_eq(_boomerang().level, 1)


func test_ac7_fires_automatically_at_the_nearest_zombie() -> void:
	await _armed_run()
	var banane: Player = first_player()
	_dummy(banane.global_position + Vector2(0, 160))
	_dummy(banane.global_position + Vector2(-320, 0))
	await wait_for_signal(_boomerang().fired, 2.0)
	await wait_physics_frames(3)
	var thrown: Array[BoomerangProjectile] = _projectiles()
	assert_eq(thrown.size(), 1, "one peel in flight")
	var offset: Vector2 = thrown[0].global_position - banane.global_position
	assert_gt(offset.y, 0.0, "flies down towards the nearer zombie")
	assert_almost_eq(offset.x, 0.0, 2.0)


func test_ac7_no_throw_without_zombies() -> void:
	await _armed_run()
	await wait_physics_frames(60)
	assert_eq(_projectiles().size(), 0)


func test_ac7_peel_returns_to_banane_and_follows_him() -> void:
	await _armed_run()
	var banane: Player = first_player()
	_dummy(banane.global_position + Vector2(400, 0))
	await wait_for_signal(_boomerang().fired, 2.0)
	var peel: BoomerangProjectile = _projectiles()[0]
	watch_signals(_boomerang())
	sender.action_down("p1_move_down")
	await wait_physics_frames(40)
	assert_true(peel.returning, "turned around at its reach")
	await wait_physics_frames(50)
	sender.action_up("p1_move_down")
	# The caught peel goes back to the pool (and may fly again), so we look at the weapon.
	assert_signal_emitted(_boomerang(), "peel_caught", "caught by Banane after he moved")


func test_ac7_hits_the_same_zombie_once_out_and_once_back() -> void:
	await _armed_run()
	var banane: Player = first_player()
	var zombie: Zombie = _dummy(banane.global_position + Vector2(150, 0))
	await wait_for_signal(_boomerang().fired, 2.0)
	var damage: float = _boomerang().current().damage
	await wait_physics_frames(30)
	assert_eq(zombie.health, 1000.0 - damage, "one hit on the way out")
	await wait_for_signal(_boomerang().peel_caught, 2.0)
	assert_eq(zombie.health, 1000.0 - 2.0 * damage, "one more on the way back, no more")


func test_ac7_kills_a_shambler() -> void:
	await _armed_run()
	var banane: Player = first_player()
	run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(150, 0))
	await wait_physics_frames(roundi(2.0 * FPS))
	assert_eq(run.enemies.kills, 1, "two peel hits kill a 10 HP shambler")


func test_ac9_level_two_throws_two_peels() -> void:
	await _armed_run()
	var banane: Player = first_player()
	_dummy(banane.global_position + Vector2(200, 0))
	_boomerang().level_up()
	await wait_for_signal(_boomerang().fired, 2.0)
	await wait_physics_frames(1)
	assert_eq(_projectiles().size(), 2)
