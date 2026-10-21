extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §3, AC-1, AC-2): Orbiting Needles and Button Shotgun, picked from a card,
## attack on their own as described, and their level 2 shows a visible change.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const NEEDLES: WeaponStats = preload("res://data/weapons/orbiting_needles.tres")
const SHOTGUN: WeaponStats = preload("res://data/weapons/button_shotgun.tres")

var run: Run


## A run without spawning or the boomerang, where only `id` is on the cards; picks it.
func _run_with_card(id: StringName) -> Weapon:
	run = await start_run()
	run.spawner.active = false
	var banane: Player = first_player()
	disarm(banane)
	var pool: UpgradePool = POOL.duplicate()
	pool.upgrades = [POOL.find(id)]
	run.upgrade_pool = pool
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)
	sender.action_down("pick_card_1")
	await wait_process_frames(2)
	sender.action_up("pick_card_1")
	await wait_process_frames(2)
	return banane.weapon(id)


func _dummy(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.move_speed = 0.0
	zombie.max_health = 100000.0
	zombie.health = 100000.0
	return zombie


func _shots(weapon: Weapon) -> Array[Projectile]:
	return run.projectiles.fired_by(weapon)


func test_ac1_needles_circle_banane_and_hurt_what_they_touch() -> void:
	var needles: Weapon = await _run_with_card(&"orbiting_needles")
	assert_not_null(needles, "the card gave the needles")
	var banane: Player = first_player()
	var reach: float = NEEDLES.at_level(1).reach
	var dummy: Zombie = _dummy(banane.global_position + Vector2(reach, 0))
	await wait_until(func() -> bool: return not _shots(needles).is_empty(), 2.0)
	var shots: Array[Projectile] = _shots(needles)
	assert_eq(shots.size(), 2, "level 1: two needles")
	for shot: Projectile in shots:
		assert_almost_eq(shot.global_position.distance_to(banane.global_position), reach, 1.0)
	var start: Vector2 = shots[0].global_position
	await wait_physics_frames(10)
	assert_gt(shots[0].global_position.distance_to(start), 20.0, "they move around the circle")
	await wait_seconds(1.5)
	assert_lt(dummy.health, dummy.max_health, "a needle hurt the zombie on the circle")
	var far: Zombie = _dummy(banane.global_position + Vector2(reach * 3.0, 0))
	await wait_seconds(0.5)
	assert_eq(far.health, far.max_health, "a zombie outside the circle is safe")


func test_ac1_needles_go_away_and_come_back() -> void:
	var needles: Weapon = await _run_with_card(&"orbiting_needles")
	var numbers: WeaponLevel = NEEDLES.at_level(1)
	await wait_until(func() -> bool: return not _shots(needles).is_empty(), 2.0)
	await wait_seconds(numbers.duration + 0.1)
	assert_true(_shots(needles).is_empty(), "gone after their duration")
	await wait_until(func() -> bool: return not _shots(needles).is_empty(), numbers.cooldown)
	assert_false(_shots(needles).is_empty(), "back after the cooldown")


func test_ac2_needles_level_2_has_three_needles() -> void:
	var needles: Weapon = await _run_with_card(&"orbiting_needles")
	first_player().apply_upgrade(UpgradeOffer.new(POOL.find(&"orbiting_needles"), 2))
	await wait_until(func() -> bool: return not _shots(needles).is_empty(), 2.0)
	await wait_until(func() -> bool: return _shots(needles).size() == 3, 8.0)
	assert_eq(_shots(needles).size(), 3)


func test_ac1_shotgun_fires_a_fan_of_buttons_that_push_back() -> void:
	var shotgun: Weapon = await _run_with_card(&"button_shotgun")
	assert_not_null(shotgun, "the card gave the shotgun")
	var banane: Player = first_player()
	var far: Zombie = _dummy(banane.global_position + Vector2(-SHOTGUN.at_level(1).reach * 2, 0))
	await wait_seconds(1.0)
	assert_true(_shots(shotgun).is_empty(), "no zombie close enough: it doesn't fire")
	far.dead = true
	var dummy: Zombie = _dummy(banane.global_position + Vector2(120, 0))
	await wait_until(func() -> bool: return not _shots(shotgun).is_empty(), 1.0)
	var shots: Array[Projectile] = _shots(shotgun)
	assert_eq(shots.size(), 3, "level 1: three buttons")
	var starts: Array[Vector2] = []
	for shot: Projectile in shots:
		starts.append(shot.global_position)
	await wait_physics_frames(3)
	var directions: Array[float] = []
	for i: int in shots.size():
		var moved: Vector2 = shots[i].global_position - starts[i]
		assert_gt(moved.x, 0.0, "towards the zombie")
		directions.append(snappedf(moved.angle(), 0.01))
	assert_ne(directions[0], directions[2], "spread out in a fan")
	var dummy_start: Vector2 = dummy.position
	await wait_physics_frames(15)
	assert_lt(dummy.health, dummy.max_health, "the buttons hurt")
	assert_gt(dummy.position.x, dummy_start.x + 5.0, "and pushed the zombie back")


func test_ac2_shotgun_level_2_fires_five_buttons() -> void:
	var shotgun: Weapon = await _run_with_card(&"button_shotgun")
	first_player().apply_upgrade(UpgradeOffer.new(POOL.find(&"button_shotgun"), 2))
	_dummy(first_player().global_position + Vector2(120, 0))
	await wait_until(func() -> bool: return not _shots(shotgun).is_empty(), 1.0)
	assert_eq(_shots(shotgun).size(), 5)
