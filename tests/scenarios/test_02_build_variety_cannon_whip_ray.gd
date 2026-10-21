extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §3, AC-1, AC-2): Yarn Cannon, Thread Whip and Zipper Ray, picked from a
## card, fire on their own towards the cursor as described, and one of their levels shows a
## visible change.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const CANNON: WeaponStats = preload("res://data/weapons/yarn_cannon.tres")
const WHIP: WeaponStats = preload("res://data/weapons/thread_whip.tres")
const RAY: WeaponStats = preload("res://data/weapons/zipper_ray.tres")

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


## Takes the weapon's cards until it reaches `to_level` (each card adds one level).
func _level_up(id: StringName, to_level: int) -> void:
	var banane: Player = first_player()
	while banane.weapon(id).level < to_level:
		var next: int = banane.weapon(id).level + 1
		banane.apply_upgrade(UpgradeOffer.new(POOL.find(id), next))


## Moves the mouse so the cursor is `offset` away from Banane. Mouse events arrive in window
## coordinates, so the point goes world → game canvas → window.
func _point_mouse(offset: Vector2) -> void:
	var viewport: Viewport = run.get_viewport()
	var target: Vector2 = first_player().global_position + offset
	var canvas: Vector2 = viewport.get_canvas_transform() * target
	sender.mouse_motion(viewport.get_screen_transform() * canvas)
	await wait_process_frames(2)


func test_ac1_cannon_fires_a_slow_ball_at_the_cursor_that_bursts() -> void:
	var cannon: Weapon = await _run_with_card(&"yarn_cannon")
	assert_not_null(cannon, "the card gave the cannon")
	await _point_mouse(Vector2(-300, 0))
	var first: Zombie = _dummy(Vector2(-200, 0))
	var next_to_it: Zombie = _dummy(Vector2(-200, CANNON.at_level(1).area * 0.6))
	var behind: Zombie = _dummy(Vector2(-200 - CANNON.at_level(1).area * 2.5, 0))
	var elsewhere: Zombie = _dummy(Vector2(200, 0))
	await wait_until(func() -> bool: return not _shots(cannon).is_empty(), 2.0)
	var ball: CannonProjectile = _shots(cannon)[0] as CannonProjectile
	var start: Vector2 = ball.global_position
	await wait_physics_frames(6)
	var moved: Vector2 = ball.global_position - start
	assert_lt(moved.x, 0.0, "towards the cursor, not the nearest zombie")
	assert_lt(moved.length() / 6.0 * FPS, 400.0, "slow")
	await wait_until(func() -> bool: return ball.burst, 2.0)
	await wait_physics_frames(1)
	assert_true(_hurt(first) and _hurt(next_to_it), "the burst hurt both zombies there")
	assert_false(_hurt(behind), "it burst on the first zombie instead of flying on")
	assert_false(_hurt(elsewhere))


func test_ac2_cannon_level_2_bursts_bigger() -> void:
	var cannon: Weapon = await _run_with_card(&"yarn_cannon")
	_level_up(&"yarn_cannon", 2)
	await _point_mouse(Vector2(-300, 0))
	_dummy(Vector2(-200, 0))
	# Outside a level-1 burst, inside a level-2 one.
	var edge: Zombie = _dummy(Vector2(-200, CANNON.at_level(1).area + SHAMBLER.radius + 6.0))
	await wait_until(func() -> bool: return not _shots(cannon).is_empty(), 2.0)
	var ball: CannonProjectile = _shots(cannon)[0] as CannonProjectile
	assert_eq(ball.burst_radius(), CANNON.at_level(2).area)
	await wait_until(func() -> bool: return ball.burst, 2.0)
	await wait_physics_frames(1)
	assert_true(_hurt(edge), "the bigger burst reached it")


func test_ac1_whip_lashes_an_arc_towards_the_cursor() -> void:
	var whip: Weapon = await _run_with_card(&"thread_whip")
	assert_not_null(whip, "the card gave the whip")
	await _point_mouse(Vector2(300, 0))
	var reach: float = WHIP.at_level(1).area
	var front: Zombie = _dummy(Vector2(reach * 0.6, 0))
	var front_side: Zombie = _dummy(Vector2(reach * 0.6, 0).rotated(deg_to_rad(40)))
	var behind: Zombie = _dummy(Vector2(-reach * 0.6, 0))
	var too_far: Zombie = _dummy(Vector2(reach * 2.0, 0))
	await wait_until(func() -> bool: return not _shots(whip).is_empty(), 2.0)
	assert_true(_hurt(front) and _hurt(front_side), "hit every zombie in the wide arc")
	assert_false(_hurt(behind), "nothing behind Banane")
	assert_false(_hurt(too_far), "nothing beyond the lash")
	await wait_seconds(WhipProjectile.SHOW_TIME + 0.05)
	assert_true(_shots(whip).is_empty(), "the lash is only a blink")


func test_ac2_whip_level_4_lashes_behind_too() -> void:
	var whip: Weapon = await _run_with_card(&"thread_whip")
	_level_up(&"thread_whip", 4)
	await _point_mouse(Vector2(300, 0))
	var behind: Zombie = _dummy(Vector2(-WHIP.at_level(4).area * 0.6, 0))
	await wait_until(func() -> bool: return not _shots(whip).is_empty(), 2.0)
	assert_eq(_shots(whip).size(), 2, "two lashes")
	assert_true(_hurt(behind), "the second one went behind")


func test_ac1_ray_beams_along_the_cursor_line_for_a_moment() -> void:
	var ray: Weapon = await _run_with_card(&"zipper_ray")
	assert_not_null(ray, "the card gave the ray")
	await _point_mouse(Vector2(0, -300))
	var near: Zombie = _dummy(Vector2(0, -100))
	var far: Zombie = _dummy(Vector2(0, -RAY.at_level(1).reach * 0.9))
	var off_line: Zombie = _dummy(Vector2(150, -200))
	await wait_until(func() -> bool: return not _shots(ray).is_empty(), 2.0)
	var beam: BeamProjectile = _shots(ray)[0] as BeamProjectile
	await wait_physics_frames(3)
	assert_true(_hurt(near) and _hurt(far), "hurt everything in the line")
	assert_false(_hurt(off_line), "not beside the line")
	await _point_mouse(Vector2(300, -400))
	await wait_physics_frames(2)
	await wait_seconds(RAY.hit_interval)
	assert_true(_hurt(off_line), "the beam follows the cursor while it lasts")
	await wait_seconds(RAY.at_level(1).duration)
	assert_true(_shots(ray).is_empty(), "and is gone after a moment")
	assert_eq(beam.visible, false)


func test_ac2_ray_level_4_reaches_further() -> void:
	var ray: Weapon = await _run_with_card(&"zipper_ray")
	_level_up(&"zipper_ray", 4)
	await _point_mouse(Vector2(0, -300))
	var far: Zombie = _dummy(Vector2(0, -(RAY.at_level(1).reach + 70)))
	await wait_until(func() -> bool: return not _shots(ray).is_empty(), 2.0)
	await wait_physics_frames(3)
	assert_true(_hurt(far), "the longer beam reached it")
