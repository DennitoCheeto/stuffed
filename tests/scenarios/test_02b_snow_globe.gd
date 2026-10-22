extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02b §3, §5, AC-34): grabbing a Snow Globe freezes every zombie for 5 s: they
## can't move, attack or hurt by touch, but still take damage, and wear a pale icy tint. Enemy
## bullets in the air pop into fluff, no new zombies come, bosses only slow to half speed. In the
## last second the ice cracks and they shake; then everything goes on as normal.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")
const BIG_TED: BigTedDef = preload("res://data/bosses/big_ted.tres")

var run: Run
## How many volleys zombies spat (recorded by a lambda, never a held signal watcher).
var spat: Array[int] = []


func _quiet_run() -> Run:
	spat.clear()
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	run.enemies.zombie_spat.connect(func(_zombie: Zombie, balls: int) -> void: spat.append(balls))
	return run


func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _grabbed() -> bool:
	return not run.floor_pickup_log.is_empty()


## Drops a Snow Globe on player 1 and waits until it is grabbed (the freeze starts).
func _grab_globe() -> void:
	run.drop_floor_pickup(&"snow_globe", first_player().global_position)
	assert_true(await _wait_until(_grabbed, 0.2), "the globe is grabbed at once")


## Waits until the run clock reaches `freeze_started + seconds`.
func _wait_freeze_time(freeze_started: float, seconds: float) -> void:
	while run.elapsed < freeze_started + seconds:
		await wait_physics_frames(1)


func _enemy_bullets() -> int:
	var count: int = 0
	for shot: Projectile in run.projectiles.active:
		if shot is EnemyBullet:
			count += 1
	return count


func _poofs() -> int:
	var count: int = 0
	for child: Node in run.effects.get_children():
		if child is FluffPoofs:
			count += 1
	return count


func test_ac34_frozen_zombies_stand_still_and_cannot_hurt_but_take_damage() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	Sfx.history.clear()
	await _grab_globe()
	assert_eq(run.hud.banner_title.text, "SNOW GLOBE!", "its banner shows")
	assert_true(Sfx.history.has(&"snow_globe"), "with its own sound")
	assert_eq(run.floor_pickup_log[0]["name"], "Snow Globe", "it is logged")
	var started: float = run.elapsed
	var health_before: float = banane.health
	var toucher: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(10, 0))
	var walker: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(250, 0))
	var walker_at: Vector2 = walker.position
	var toucher_at: Vector2 = toucher.position
	await wait_seconds(2.0)
	assert_eq(banane.health, health_before, "touching a frozen zombie doesn't hurt")
	assert_eq(walker.position, walker_at, "a frozen zombie doesn't walk")
	assert_eq(toucher.position, toucher_at, "nor gets pushed")
	assert_true(walker.frozen)
	assert_eq(walker.puppet.modulate, ZombiePuppet.ICE_TINT, "it wears a pale icy tint")
	var full: float = walker.health
	run.enemies.damage(walker, 1.0, Vector2(500, 0))
	assert_lt(walker.health, full, "a frozen zombie still takes damage")
	await wait_physics_frames(3)
	assert_eq(walker.position, walker_at, "and isn't knocked back")
	assert_true(run.enemies.damage(toucher, 1000.0), "a frozen zombie can be killed")
	assert_lt(run.elapsed - started, run.floor_pickup_rules.freeze_seconds, "all while frozen")


func test_ac34_frozen_spitters_dont_spit_and_bullets_in_the_air_pop() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var spitter: Zombie = run.enemies.spawn(SPITTER, banane.global_position + Vector2(260, 0))
	var aim: Vector2 = Vector2.LEFT
	run.enemies.fire_volley(spitter, aim, spitter.attack, 3, spitter.spit_damage)
	assert_eq(_enemy_bullets(), 3, "stuffing balls are in the air")
	await _grab_globe()
	assert_eq(_enemy_bullets(), 0, "the balls in the air are gone")
	assert_eq(_poofs(), 1, "they pop into fluff")
	spitter.attack_cooldown = 0.0
	spat.clear()
	await wait_seconds(3.0)
	assert_eq(spat.size(), 0, "a frozen spitter doesn't spit")
	assert_false(spitter.is_winding_up(), "nor puff up")


func test_ac34_no_new_zombies_come_while_frozen() -> void:
	await _quiet_run()
	first_player().invincible = true
	run.elapsed = 150.0
	run.spawner.active = true
	await wait_seconds(1.0)
	assert_gt(run.enemies.alive_count(), 0, "zombies come before the globe")
	await _grab_globe()
	var started: float = run.elapsed
	var count: int = run.enemies.alive_count()
	await _wait_freeze_time(started, run.floor_pickup_rules.freeze_seconds - 0.2)
	assert_eq(run.enemies.alive_count(), count, "no new zombies while frozen")
	await _wait_freeze_time(started, run.floor_pickup_rules.freeze_seconds + 1.0)
	assert_gt(run.enemies.alive_count(), count, "they come again afterwards")


func test_ac34_bosses_are_not_frozen_only_slowed_to_half_speed() -> void:
	await _quiet_run()
	first_player().invincible = true
	var start: Vector2 = first_player().global_position + Vector2(900, 0)
	var ted: Zombie = run.enemies.spawn_boss(BIG_TED, start)
	await wait_seconds(1.0)
	var normal: float = ted.position.distance_to(start)
	assert_gt(normal, 20.0, "Big Ted walks towards Banane")
	await _grab_globe()
	var frozen_start: Vector2 = ted.position
	await wait_seconds(1.0)
	var slowed: float = ted.position.distance_to(frozen_start)
	assert_false(ted.frozen, "a boss isn't frozen")
	assert_almost_eq(slowed / normal, 0.5, 0.1, "he only moves at half speed")


func test_ac34_the_ice_cracks_in_the_last_second_then_everything_goes_on() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(250, 0))
	Sfx.history.clear()
	await _grab_globe()
	var started: float = run.elapsed
	var freeze: float = run.floor_pickup_rules.freeze_seconds
	var crack: float = run.floor_pickup_rules.freeze_crack_seconds
	await _wait_freeze_time(started, freeze - crack - 0.2)
	assert_eq(zombie.thaw_shake, 0.0, "the ice holds")
	assert_false(Sfx.history.has(&"ice_crack"))
	await _wait_freeze_time(started, freeze - crack * 0.5)
	assert_gt(zombie.thaw_shake, 0.0, "in the last second the zombies shake")
	assert_true(Sfx.history.has(&"ice_crack"), "and the ice cracks")
	assert_true(zombie.frozen, "but they are still frozen")
	var frozen_at: Vector2 = zombie.position
	await _wait_freeze_time(started, freeze + 1.0)
	assert_false(zombie.frozen, "the freeze is over")
	assert_eq(zombie.puppet.modulate, Color.WHITE, "the icy tint is gone")
	assert_eq(zombie.puppet.position, Vector2.ZERO, "no more shaking")
	assert_lt(
		zombie.position.distance_to(banane.global_position),
		frozen_at.distance_to(banane.global_position) - 10.0,
		"it walks again"
	)


func test_ac34_the_dev_menu_drops_a_snow_globe() -> void:
	await _quiet_run()
	run.dev_menu.press("Drop Snow Globe")
	assert_eq(run.floor_pickups().size(), 1)
	if run.floor_pickups().is_empty():
		return
	assert_eq(run.floor_pickups()[0].kind.id, &"snow_globe")
