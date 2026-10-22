extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §10, AC-20, AC-21): the bedroom furniture blocks Banane, zombies and enemy
## bullets, Banane's shots fly over it, and zombies walk around it instead of getting stuck.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const RUNNER: EnemyStats = preload("res://data/enemies/runner.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
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


## Waits up to `seconds` until `done` returns true; `every_frame` is called each frame.
func _wait_until(done: Callable, seconds: float, every_frame: Callable = Callable()) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		if every_frame.is_valid():
			every_frame.call()
		await wait_physics_frames(1)
	return done.call()


func test_ac20_banane_cannot_walk_into_the_bed() -> void:
	await _quiet_run()
	var bed: Rect2 = _piece(FurniturePiece.Kind.BED)
	var banane: Player = await _place_banane(Vector2(bed.end.x + 80.0, bed.get_center().y))
	await hold_action("p1_move_left", 90)
	var limit: float = bed.end.x + banane.stats.hitbox_radius - 1.0
	assert_gte(banane.global_position.x, limit, "stopped at the side of the bed")
	assert_lt(banane.global_position.x, bed.end.x + 30.0, "but walked right up to it")


func test_ac20_banane_cannot_dash_through_the_toy_box() -> void:
	await _quiet_run()
	var box: Rect2 = _piece(FurniturePiece.Kind.TOY_BOX)
	var banane: Player = await _place_banane(Vector2(box.get_center().x, box.end.y + 40.0))
	sender.action_down("p1_move_up")
	await wait_physics_frames(2)
	await tap_action("p1_dash")
	await wait_physics_frames(30)
	sender.action_up("p1_move_up")
	await wait_physics_frames(2)
	var limit: float = box.end.y + banane.stats.hitbox_radius - 1.0
	assert_gte(banane.global_position.y, limit, "the dash stops at the toy box")


func test_ac20_enemy_bullets_stop_at_furniture() -> void:
	await _quiet_run()
	var tower: Rect2 = _piece(FurniturePiece.Kind.BLOCK_TOWER)
	var middle: float = tower.get_center().y
	var banane: Player = await _place_banane(Vector2(tower.position.x - 60.0, middle))
	banane.invincible = false
	var health: float = banane.health
	var ball: EnemyBullet = run.projectiles.spawn(EnemyBullet) as EnemyBullet
	var from: Vector2 = Vector2(tower.end.x + 200.0, tower.get_center().y)
	ball.launch(from, Vector2(-300.0, 0.0), 5.0, ProjectileLook.BULLET_RADIUS, 4.0, "Spitter")
	var no_balls: Callable = func() -> bool: return run.projectiles.hostile_count() == 0
	var gone: bool = await _wait_until(no_balls, 3.0)
	assert_true(gone, "the ball is gone")
	assert_gt(ball.position.x, tower.position.x, "it stopped at the tower")
	await wait_physics_frames(30)
	assert_eq(banane.health, health, "Banane behind the tower is safe")


func test_ac20_banane_shots_fly_over_furniture() -> void:
	await _quiet_run()
	var tower: Rect2 = _piece(FurniturePiece.Kind.BLOCK_TOWER)
	await _place_banane(Vector2(tower.position.x - 20.0, tower.get_center().y))
	var behind: Vector2 = Vector2(tower.end.x + 25.0, tower.get_center().y)
	var dummy: Zombie = run.enemies.spawn(SHAMBLER, behind)
	dummy.move_speed = 0.0
	dummy.max_health = 1000.0
	dummy.health = 1000.0
	var hit: bool = await _wait_until(func() -> bool: return dummy.health < 1000.0, 4.0)
	assert_true(hit, "the boomerang hit the zombie behind the tower")


func test_ac20_ac21_a_zombie_walks_around_the_toy_box() -> void:
	await _quiet_run()
	disarm(first_player())
	var box: Rect2 = _piece(FurniturePiece.Kind.TOY_BOX)
	var banane: Player = await _place_banane(Vector2(box.get_center().x, box.end.y + 80.0))
	# Right behind the middle of the box: the worst spot to get stuck.
	var behind: Vector2 = Vector2(box.get_center().x, box.position.y - 60.0)
	var zombie: Zombie = run.enemies.spawn(RUNNER, behind)
	zombie.move_speed = 250.0
	var overlaps: Array[Vector2] = []
	var check: Callable = func() -> void:
		if run.enemies.obstacles.blocks(zombie.position, zombie.radius() - 1.0):
			overlaps.append(zombie.position)
	var reach: float = zombie.radius() + banane.stats.hitbox_radius + 4.0
	var at_banane: Callable = func() -> bool:
		return zombie.position.distance_to(banane.global_position) <= reach
	var arrived: bool = await _wait_until(at_banane, 10.0, check)
	assert_true(arrived, "it got around the toy box to Banane (at %s)" % zombie.position)
	assert_eq(overlaps, [] as Array[Vector2], "it never walked into the box")


func test_ac21_a_crowd_gets_around_the_bed() -> void:
	await _quiet_run()
	disarm(first_player())
	var bed: Rect2 = _piece(FurniturePiece.Kind.BED)
	var banane: Player = await _place_banane(Vector2(bed.end.x + 100.0, bed.get_center().y))
	var crowd: Array[Zombie] = []
	for i: int in 8:
		var y: float = bed.position.y + bed.size.y * (i + 0.5) / 8.0
		var zombie: Zombie = run.enemies.spawn(RUNNER, Vector2(bed.position.x - 80.0, y))
		zombie.move_speed = 300.0
		crowd.append(zombie)
	var all_there: Callable = func() -> bool:
		for zombie: Zombie in crowd:
			if zombie.position.distance_to(banane.global_position) > 120.0:
				return false
		return true
	var arrived: bool = await _wait_until(all_there, 15.0)
	var stuck: PackedStringArray = []
	for zombie: Zombie in crowd:
		if zombie.position.distance_to(banane.global_position) > 120.0:
			stuck.append(str(zombie.position))
	assert_true(arrived, "every zombie got around the bed (stuck: %s)" % ", ".join(stuck))
