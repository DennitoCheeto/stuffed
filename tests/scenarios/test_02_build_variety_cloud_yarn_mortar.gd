extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §3, AC-1, AC-2): Stuffing Cloud, Bouncy Yarn Ball and Thimble Mortar, picked
## from a card, attack on their own as described, and one of their levels shows a visible change.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const CLOUD: WeaponStats = preload("res://data/weapons/stuffing_cloud.tres")
const YARN: WeaponStats = preload("res://data/weapons/bouncy_yarn_ball.tres")
const MORTAR: WeaponStats = preload("res://data/weapons/thimble_mortar.tres")
## Far outside the 1920 × 1080 view around Banane, but still in the arena.
const OFF_SCREEN: Vector2 = Vector2(2600, 0)

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


## A zombie that stands still and can't die, `offset` away from Banane.
func _dummy(offset: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, first_player().global_position + offset)
	zombie.move_speed = 0.0
	zombie.max_health = 100000.0
	zombie.health = 100000.0
	return zombie


func _hurt(zombie: Zombie) -> bool:
	return zombie.health < zombie.max_health


func _shots(weapon: Weapon) -> Array[Projectile]:
	return run.projectiles.fired_by(weapon)


func _level_up(id: StringName, to_level: int) -> void:
	first_player().apply_upgrade(UpgradeOffer.new(POOL.find(id), to_level))


func test_ac1_cloud_stays_around_banane_and_hurts_zombies_inside_often() -> void:
	var cloud_weapon: Weapon = await _run_with_card(&"stuffing_cloud")
	assert_not_null(cloud_weapon, "the card gave the cloud")
	var numbers: WeaponLevel = CLOUD.at_level(1)
	var inside: Zombie = _dummy(Vector2(numbers.area * 0.5, 0))
	var outside: Zombie = _dummy(Vector2(-numbers.area * 2.5, 0))
	await wait_until(func() -> bool: return not _shots(cloud_weapon).is_empty(), 2.0)
	var cloud: CloudProjectile = _shots(cloud_weapon)[0] as CloudProjectile
	await wait_seconds(1.0)
	var hits: float = (inside.max_health - inside.health) / numbers.damage
	assert_gte(hits, 2.0, "hurt a few times within a second")
	assert_eq(outside.health, outside.max_health, "a zombie outside the cloud is safe")
	var banane: Player = first_player()
	await hold_action("p1_move_right", 20)
	await wait_physics_frames(1)
	assert_almost_eq(cloud.global_position, banane.global_position, Vector2.ONE, "it follows")
	assert_eq(_shots(cloud_weapon).size(), 1, "always one cloud")


func test_ac2_cloud_level_2_is_bigger() -> void:
	var cloud_weapon: Weapon = await _run_with_card(&"stuffing_cloud")
	await wait_until(func() -> bool: return not _shots(cloud_weapon).is_empty(), 2.0)
	var cloud: CloudProjectile = _shots(cloud_weapon)[0] as CloudProjectile
	var small: float = cloud.scale.x
	# Just outside the level-1 cloud, inside the level-2 one.
	var edge: Zombie = _dummy(Vector2(CLOUD.at_level(1).area + SHAMBLER.radius + 6.0, 0))
	await wait_seconds(0.6)
	assert_false(_hurt(edge), "level 1 doesn't reach it")
	_level_up(&"stuffing_cloud", 2)
	await wait_seconds(0.6)
	assert_true(_hurt(edge), "level 2 does")
	assert_gt(cloud.scale.x, small * 1.12, "and the cloud looks bigger")


func test_ac1_yarn_ball_bounces_between_zombies() -> void:
	var yarn: Weapon = await _run_with_card(&"bouncy_yarn_ball")
	assert_not_null(yarn, "the card gave the yarn ball")
	var far: Zombie = _dummy(Vector2(-YARN.at_level(1).reach * 3.0, 0))
	await wait_seconds(0.8)
	assert_true(_shots(yarn).is_empty(), "no zombie near: it doesn't throw")
	far.dead = true
	var first: Zombie = _dummy(Vector2(150, 0))
	var second: Zombie = _dummy(Vector2(150, 120))
	await wait_until(func() -> bool: return not _shots(yarn).is_empty(), 1.0)
	var ball: YarnProjectile = _shots(yarn)[0] as YarnProjectile
	await wait_until(func() -> bool: return _hurt(first) and _hurt(second), 2.0)
	assert_true(_hurt(first), "hit the zombie it was thrown at")
	assert_true(_hurt(second), "then bounced on to the next one")
	assert_gte(ball.hits, 2)


func test_ac1_yarn_ball_bounces_off_walls() -> void:
	var yarn: Weapon = await _run_with_card(&"bouncy_yarn_ball")
	var ball: YarnProjectile = run.projectiles.spawn(YarnProjectile) as YarnProjectile
	ball.launch(yarn, Vector2.LEFT)
	ball.global_position = Vector2(run.projectiles.play_rect.position.x + 10.0, 1000.0)
	await wait_physics_frames(3)
	assert_eq(ball.wall_bounces, 1, "bounced off the left wall")
	assert_gt(ball.direction().x, 0.0, "and flies back to the right")
	assert_true(run.projectiles.play_rect.has_point(ball.global_position), "stays inside")


func test_ac2_yarn_level_2_bounces_between_6_zombies() -> void:
	var yarn: Weapon = await _run_with_card(&"bouncy_yarn_ball")
	_level_up(&"bouncy_yarn_ball", 2)
	var row: Array[Zombie] = []
	for i: int in 8:
		row.append(_dummy(Vector2(120 + i * 70, 0)))
	await wait_until(func() -> bool: return not _shots(yarn).is_empty(), 1.0)
	await wait_until(func() -> bool: return _shots(yarn).is_empty(), 3.0)
	var hurt: int = row.filter(_hurt).size()
	assert_eq(hurt, 6, "one ball hit 6 different zombies")


func test_ac1_mortar_lobs_at_zombies_on_screen_with_a_shadow() -> void:
	var mortar: Weapon = await _run_with_card(&"thimble_mortar")
	assert_not_null(mortar, "the card gave the mortar")
	var off_screen: Zombie = _dummy(OFF_SCREEN)
	await wait_seconds(0.8)
	assert_true(_shots(mortar).is_empty(), "no zombie on screen: nothing to lob at")
	off_screen.dead = true
	# Two zombies close together: the thimble picks one at random, and the blast hits both.
	var pair: Array[Zombie] = [_dummy(Vector2(300, -100))]
	pair.append(_dummy(Vector2(300 + MORTAR.at_level(1).area * 0.6, -100)))
	await wait_until(func() -> bool: return not _shots(mortar).is_empty(), 1.0)
	var thimble: ThimbleProjectile = _shots(mortar)[0] as ThimbleProjectile
	var on_one: bool = pair.any(
		func(zombie: Zombie) -> bool:
			return thimble.global_position.distance_to(zombie.position) < 1.0
	)
	assert_true(on_one, "the shadow sits on one of the zombies")
	assert_true(thimble.visible, "the shadow shows where it lands")
	assert_gt(thimble.time_to_land(), 0.2, "in the air for a moment first")
	assert_false(_hurt(pair[0]) or _hurt(pair[1]), "nobody hurt before it lands")
	await wait_until(func() -> bool: return thimble.landed, 2.0)
	await wait_physics_frames(1)
	assert_true(_hurt(pair[0]) and _hurt(pair[1]), "the landing hurt both (area hit)")


func test_ac2_mortar_level_2_lobs_two_thimbles() -> void:
	var mortar: Weapon = await _run_with_card(&"thimble_mortar")
	_level_up(&"thimble_mortar", 2)
	_dummy(Vector2(300, 0))
	await wait_until(func() -> bool: return not _shots(mortar).is_empty(), 1.0)
	assert_eq(_shots(mortar).size(), 2)
