extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §14): the shared projectile system. Shots are reused instead of made new,
## enemy bullets hurt players and are drawn above everything, and a full screen stays one loop.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	return run


func _dummy(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.move_speed = 0.0
	zombie.max_health = 100000.0
	zombie.health = 100000.0
	return zombie


func _bullet(at: Vector2, velocity: Vector2, lifetime: float = 5.0) -> EnemyBullet:
	var bullet: EnemyBullet = run.projectiles.spawn(EnemyBullet) as EnemyBullet
	bullet.launch(at, velocity, 7.0, 8.0, lifetime, "Spitter")
	return bullet


func test_shots_are_reused_instead_of_made_new() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var boomerang: PeelBoomerang = banane.weapon(&"peel_boomerang") as PeelBoomerang
	_dummy(banane.global_position + Vector2(150, 0))
	var catches: Array[int] = []
	boomerang.peel_caught.connect(func() -> void: catches.append(1))
	await wait_physics_frames(roundi(6.0 * FPS))
	assert_gt(catches.size(), 3, "the peel was thrown and caught several times")
	assert_lte(run.projectiles.created, 2, "but only a peel or two were ever made")


func test_shots_are_moved_by_the_manager_not_by_themselves() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_dummy(banane.global_position + Vector2(150, 0))
	await wait_for_signal(banane.weapon(&"peel_boomerang").fired, 2.0)
	var peel: Projectile = run.projectiles.active[0]
	assert_false(peel.is_physics_processing(), "no physics callback per shot")
	assert_true(peel is Sprite2D, "drawn as a baked sprite, not shapes")


func test_shots_of_a_removed_weapon_vanish() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_dummy(banane.global_position + Vector2(300, 0))
	await wait_for_signal(banane.weapon(&"peel_boomerang").fired, 2.0)
	assert_eq(run.projectiles.active.size(), 1)
	disarm(banane)
	await wait_physics_frames(2)
	assert_eq(run.projectiles.active.size(), 0, "the peel is gone with its weapon")


func test_enemy_bullet_hurts_banane_once_and_is_gone() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	disarm(banane)
	var health: float = banane.health
	_bullet(banane.global_position + Vector2(100, 0), Vector2(-200, 0))
	await wait_physics_frames(roundi(0.8 * FPS))
	assert_eq(banane.health, health - 7.0, "one hit")
	assert_eq(banane.last_hit_by, "Spitter", "you know what hit you")
	assert_eq(run.projectiles.hostile_count(), 0, "the bullet is used up")


func test_dashing_banane_passes_through_an_enemy_bullet() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	disarm(banane)
	var health: float = banane.health
	_bullet(banane.global_position + Vector2(40, 0), Vector2(-150, 0), 2.0)
	await tap_action("p1_dash")
	await wait_physics_frames(roundi(0.3 * FPS))
	assert_eq(banane.health, health, "no damage while dashing")
	assert_eq(run.projectiles.hostile_count(), 1, "the bullet flies on behind him")


func test_enemy_bullet_expires_and_stops_at_the_arena_edge() -> void:
	await _quiet_run()
	disarm(first_player())
	var far: Vector2 = first_player().global_position + Vector2(0, 800)
	_bullet(far, Vector2.ZERO, 0.5)
	_bullet(Vector2(30, 30), Vector2(-300, 0))
	await wait_physics_frames(roundi(0.6 * FPS))
	assert_eq(run.projectiles.hostile_count(), 0)


func test_enemy_bullets_are_drawn_above_zombies_and_own_shots() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var zombie: Zombie = _dummy(banane.global_position + Vector2(150, 0))
	await wait_for_signal(banane.weapon(&"peel_boomerang").fired, 2.0)
	var peel: Projectile = run.projectiles.active[0]
	var bullet: EnemyBullet = _bullet(banane.global_position + Vector2(300, 300), Vector2.ZERO)
	var bullet_z: int = bullet.get_parent().z_index
	assert_gt(bullet_z, peel.get_parent().z_index, "above Banane's own shots")
	assert_gt(bullet_z, zombie.z_index, "above zombies")
	assert_gt(bullet_z, run.effects.z_index, "above death bursts")


func test_reaching_the_goal_clears_enemy_bullets() -> void:
	await _quiet_run()
	disarm(first_player())
	_bullet(first_player().global_position + Vector2(0, 600), Vector2.ZERO)
	beat_the_boss(run)
	await wait_physics_frames(10)
	assert_eq(run.projectiles.hostile_count(), 0)


## Many shots at once (a big build against a big horde) stay in one pool and all keep flying.
func test_a_full_screen_of_shots_and_bullets() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	for i: int in 200:
		_dummy(banane.global_position + Vector2.RIGHT.rotated(i * 0.31) * (200.0 + i))
	var sniper: SewingPinSniper = banane.add_weapon(SNIPER) as SewingPinSniper
	for i: int in 300:
		var pin: PinProjectile = run.projectiles.spawn(PinProjectile) as PinProjectile
		pin.launch(sniper, Vector2.RIGHT.rotated(i * 0.1))
	for i: int in 300:
		var spot: Vector2 = banane.global_position + Vector2.RIGHT.rotated(i * 0.2) * 600.0
		_bullet(spot, Vector2.LEFT.rotated(i * 0.2) * 60.0)
	assert_eq(run.projectiles.active.size(), 600)
	await wait_physics_frames(30)
	assert_gt(run.projectiles.hostile_count(), 250, "slow bullets are still flying")
	await wait_physics_frames(roundi(1.5 * FPS))
	# Only the sniper's own newest attack may still be flying.
	assert_lt(run.projectiles.fired_by(sniper).size(), 5, "the 300 pins finished")
	var made: int = run.projectiles.created
	for i: int in 100:
		var pin: PinProjectile = run.projectiles.spawn(PinProjectile) as PinProjectile
		pin.launch(sniper, Vector2.UP)
	assert_eq(run.projectiles.created, made, "new pins came from the pool")
