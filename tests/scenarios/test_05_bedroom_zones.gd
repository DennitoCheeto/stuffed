extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 05 §4.2, AC-64): the new furniture of the Bedroom's places (crayons, the
## sharpener, the sewing box, the pincushion) blocks Banane, zombies and enemy bullets like the old
## pieces, Banane's shots fly over it, and zombies get around it.

const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const NEW_KINDS: Array[FurniturePiece.Kind] = [
	FurniturePiece.Kind.CRAYON,
	FurniturePiece.Kind.SHARPENER,
	FurniturePiece.Kind.SEWING_BOX,
	FurniturePiece.Kind.PINCUSHION,
]

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	first_player().invincible = true
	return run


## The first piece of `kind` in the room.
func _piece(kind: FurniturePiece.Kind) -> Rect2:
	for piece: FurniturePiece in run.arena.furniture.pieces:
		if piece.kind == kind:
			return piece.rect
	return Rect2()


func _place_banane(at: Vector2) -> Player:
	var banane: Player = first_player()
	banane.global_position = at
	banane.velocity = Vector2.ZERO
	await wait_physics_frames(2)
	return banane


func _clear_zombies() -> void:
	run.enemies.kill_all()
	run.pickups.buttons.clear()
	await wait_physics_frames(2)


## Waits up to `seconds` until `done` returns true; `every_frame` is called each frame.
func _wait_until(done: Callable, seconds: float, every_frame: Callable = Callable()) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		if every_frame.is_valid():
			every_frame.call()
		await wait_physics_frames(1)
	return done.call()


func test_ac64_banane_cannot_walk_into_the_new_pieces() -> void:
	await _quiet_run()
	for kind: FurniturePiece.Kind in NEW_KINDS:
		var rect: Rect2 = _piece(kind)
		assert_true(rect.has_area(), "the room has a %s" % kind)
		var banane: Player = await _place_banane(Vector2(rect.end.x + 80.0, rect.get_center().y))
		await hold_action("p1_move_left", 60)
		var limit: float = rect.end.x + banane.stats.hitbox_radius - 1.0
		assert_gte(banane.global_position.x, limit, "stopped at the side of the %s" % kind)
		assert_lt(banane.global_position.x, rect.end.x + 30.0, "walked right up to the %s" % kind)


func test_ac64_enemy_bullets_stop_at_the_new_pieces() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = false
	for kind: FurniturePiece.Kind in NEW_KINDS:
		var rect: Rect2 = _piece(kind)
		var middle: float = rect.get_center().y
		await _place_banane(Vector2(rect.position.x - 60.0, middle))
		var health: float = banane.health
		var ball: EnemyBullet = run.projectiles.spawn(EnemyBullet) as EnemyBullet
		var from: Vector2 = Vector2(rect.end.x + 150.0, middle)
		ball.launch(from, Vector2(-600.0, 0.0), 5.0, ProjectileLook.BULLET_RADIUS, 4.0, "Spitter")
		var no_balls: Callable = func() -> bool: return run.projectiles.hostile_count() == 0
		assert_true(await _wait_until(no_balls, 3.0), "the ball is gone")
		assert_gt(ball.position.x, rect.position.x, "it stopped at the %s" % kind)
		await wait_physics_frames(20)
		assert_eq(banane.health, health, "Banane behind the %s is safe" % kind)


## The boomerang (level 4: reach 330) hits a zombie on the far side of each piece small enough
## for it to reach over (the sewing box is wider than any reach; same rule, see AC-20).
func test_ac64_banane_shots_fly_over_the_new_pieces() -> void:
	await _quiet_run()
	assert_true(run.dev_menu.give(&"peel_boomerang", 4), "a long-reach boomerang")
	var kinds: Array[FurniturePiece.Kind] = [
		FurniturePiece.Kind.CRAYON, FurniturePiece.Kind.SHARPENER, FurniturePiece.Kind.PINCUSHION
	]
	for kind: FurniturePiece.Kind in kinds:
		await _clear_zombies()
		var rect: Rect2 = _piece(kind)
		var flat: bool = rect.size.x >= rect.size.y
		var mine: Vector2 = Vector2(rect.get_center().x, rect.position.y - 20.0)
		var behind: Vector2 = Vector2(rect.get_center().x, rect.end.y + 25.0)
		if not flat:
			mine = Vector2(rect.position.x - 20.0, rect.get_center().y)
			behind = Vector2(rect.end.x + 25.0, rect.get_center().y)
		await _place_banane(mine)
		var dummy: Zombie = run.enemies.spawn(SHAMBLER, behind)
		dummy.move_speed = 0.0
		dummy.max_health = 100000.0
		dummy.health = 100000.0
		var hurt: Callable = func() -> bool: return dummy.health < 100000.0
		assert_true(await _wait_until(hurt, 4.0), "a shot flew over the %s" % kind)


func test_ac64_zombies_walk_around_the_new_pieces() -> void:
	await _quiet_run()
	disarm(first_player())
	for kind: FurniturePiece.Kind in NEW_KINDS:
		await _clear_zombies()
		var rect: Rect2 = _piece(kind)
		var banane: Player = await _place_banane(Vector2(rect.get_center().x, rect.end.y + 80.0))
		# Right behind the middle of the piece: the worst spot to get stuck.
		var start: Vector2 = Vector2(rect.get_center().x, rect.position.y - 60.0)
		var zombie: Zombie = run.enemies.spawn(RUNNER, start)
		zombie.move_speed = 250.0
		var overlaps: Array[Vector2] = []
		var check: Callable = func() -> void:
			if run.enemies.obstacles.blocks(zombie.position, zombie.radius() - 1.0):
				overlaps.append(zombie.position)
		var reach: float = zombie.radius() + banane.stats.hitbox_radius + 4.0
		var at_banane: Callable = func() -> bool:
			return zombie.position.distance_to(banane.global_position) <= reach
		var arrived: bool = await _wait_until(at_banane, 10.0, check)
		assert_true(arrived, "it got around the %s (at %s)" % [kind, zombie.position])
		assert_eq(overlaps, [] as Array[Vector2], "it never walked into the %s" % kind)
