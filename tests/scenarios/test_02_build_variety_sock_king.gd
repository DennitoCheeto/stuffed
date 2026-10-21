extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §9, §10, AC-18, AC-19, AC-25): the Sock Puppet King arrives at 8:00 and the
## run goes on until he is beaten. His sock spiral, summon and (angry, from half health) lunge are
## shown before they happen. Beating him pops all zombies, drops a big gift box and offers End run
## / Keep going. Boss music plays while he's on the field.

const KING: SockKingDef = preload("res://data/bosses/sock_puppet_king.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run
## Filled by the run's signal (no signal watchers: the run is freed when it ends).
var finished_results: Array[RunResult] = []


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## The King `offset` away from player 1, ready to start his next pattern at once.
func _king(offset: Vector2) -> Zombie:
	var king: Zombie = run.enemies.spawn_boss(KING, first_player().global_position + offset)
	king.brain.pattern_cooldown = 0.0
	return king


func _brain(king: Zombie) -> SockKingBrain:
	return king.brain as SockKingBrain


func _runners() -> int:
	var count: int = 0
	for zombie: Zombie in run.enemies.zombies:
		if zombie.stats == KING.summon_enemy:
			count += 1
	return count


func _boxes() -> Array[GiftBox]:
	var boxes: Array[GiftBox] = []
	for child: Node in run.floor_items.get_children():
		if child is GiftBox and not child.is_queued_for_deletion():
			boxes.append(child as GiftBox)
	return boxes


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func test_ac18_the_king_arrives_at_8_00_and_the_run_waits_for_him() -> void:
	run = await start_run()
	disarm(first_player())
	first_player().invincible = true
	run.elapsed = run.rules.goal_seconds - 0.5
	await wait_physics_frames(roundi(0.3 * FPS))
	assert_false(run.boss_fight, "not before 8:00")
	assert_eq(main.music.track, &"run")
	var arrived: bool = await _wait_until(func() -> bool: return run.boss_fight, 1.0)
	assert_true(arrived, "he arrives at 8:00")
	var king: Zombie = run.enemies.bosses()[0]
	assert_true(run.is_final_boss(king))
	assert_eq(run.hud.banner_title.text, KING.banner, "a banner announces him")
	assert_true(run.hud.boss_bar.visible, "his health bar is at the top")
	assert_eq(run.hud.boss_label.text, "Sock Puppet King")
	assert_eq(main.music.track, &"boss", "the boss track plays")
	await wait_physics_frames(roundi(2.0 * FPS))
	assert_false(run.goal_done, "8:00 alone is no longer the goal")
	assert_false(run.goal_screen.is_open())
	assert_gt(run.elapsed, run.rules.goal_seconds + 1.5, "the run goes on until he's beaten")
	assert_string_contains(run.hud.timer_label.text, "Boss fight")


func test_ac18_sock_spiral_comes_after_a_glow_and_turns() -> void:
	await _quiet_run()
	first_player().invincible = true
	var king: Zombie = _king(Vector2(300, 0))
	var brain: SockKingBrain = _brain(king)
	assert_eq(brain.next_pattern(), SockKingBrain.Pattern.SPIRAL)
	var winding: bool = await _wait_until(
		func() -> bool: return brain.state == SockKingBrain.State.SPIRAL_WINDUP, 0.5
	)
	assert_true(winding, "he starts a spiral")
	await wait_physics_frames(roundi(KING.spiral.windup_seconds * 0.7 * FPS))
	assert_eq(run.projectiles.hostile_count(), 0, "nothing while he glows")
	assert_gt(king.puppet.root.modulate.r, 1.1, "he glows: something is coming")
	await _wait_until(func() -> bool: return run.projectiles.hostile_count() > 0, 1.0)
	var first: Vector2 = _newest_ball_direction(king)
	await wait_physics_frames(roundi(0.8 * FPS))
	var arms: int = KING.spiral.balls_in_volley(0)
	assert_gt(run.projectiles.hostile_count(), arms * 3, "volley after volley")
	var later: Vector2 = _newest_ball_direction(king)
	var turned: float = rad_to_deg(absf(first.angle_to(later)))
	assert_between(fmod(turned, 360.0 / arms), 5.0, 360.0 / arms - 5.0, "the spiral turns")


## The direction (from the King) of the stuffing ball fired last, closest to his right.
func _newest_ball_direction(king: Zombie) -> Vector2:
	var best: Vector2 = Vector2.ZERO
	var best_distance: float = INF
	for shot: Projectile in run.projectiles.active:
		var ball: EnemyBullet = shot as EnemyBullet
		if ball == null:
			continue
		var distance: float = ball.position.distance_to(king.position)
		if distance < best_distance - 0.5:
			best_distance = distance
			best = king.position.direction_to(ball.position)
	return best


func test_ac18_summon_shows_marks_then_a_ring_of_runners_appears() -> void:
	await _quiet_run()
	first_player().invincible = true
	var king: Zombie = _king(Vector2(300, 0))
	var brain: SockKingBrain = _brain(king)
	brain.set_next_pattern(SockKingBrain.Pattern.SUMMON)
	var marking: bool = await _wait_until(
		func() -> bool: return brain.state == SockKingBrain.State.SUMMON_WINDUP, 0.5
	)
	assert_true(marking, "he starts a summon")
	assert_eq(brain.telegraph.kind, BossTelegraph.Kind.MARKS, "marks on the floor")
	assert_eq(brain.telegraph.marks.size(), KING.summon_count)
	await wait_physics_frames(roundi(KING.summon_windup_seconds * 0.7 * FPS))
	assert_eq(_runners(), 0, "nobody yet")
	await _wait_until(func() -> bool: return _runners() > 0, 1.0)
	assert_eq(_runners(), KING.summon_count, "a ring of runners")
	for point: Vector2 in brain.summon_points:
		assert_almost_eq(point.distance_to(king.position), KING.summon_radius, 2.0, "a ring")
	assert_false(brain.telegraph.is_showing())


func test_ac18_at_half_health_he_gets_angry_and_lunges_at_a_marked_spot() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var king: Zombie = _king(Vector2(320, 0))
	var brain: SockKingBrain = _brain(king)
	king.brain.pattern_cooldown = 100.0
	run.enemies.damage(king, king.max_health * 0.4)
	await wait_physics_frames(2)
	assert_false(brain.angry, "not angry above half health")
	run.enemies.damage(king, king.max_health * 0.2)
	await wait_physics_frames(2)
	assert_true(brain.angry, "angry below half health")
	assert_eq(run.hud.banner_title.text, KING.angry_banner)
	assert_eq(brain.next_pattern(), SockKingBrain.Pattern.LUNGE, "the lunge comes next")
	brain.pattern_cooldown = 0.0
	var aiming: bool = await _wait_until(
		func() -> bool: return brain.state == SockKingBrain.State.LUNGE_AIM, 0.5
	)
	assert_true(aiming, "he aims a lunge")
	assert_eq(brain.telegraph.kind, BossTelegraph.Kind.LANDING, "a red circle marks the spot")
	assert_almost_eq(brain.landing_spot, banane.global_position, Vector2(2, 2), "on Banane")
	var start: Vector2 = king.position
	var health: float = banane.health
	await wait_physics_frames(roundi(KING.lunge_windup_seconds * 0.8 * FPS))
	assert_almost_eq(king.position, start, Vector2.ONE, "he waits while the circle shows")
	assert_eq(banane.health, health, "nothing has hit Banane yet")
	var landed: bool = await _wait_until(
		func() -> bool: return brain.state == SockKingBrain.State.RECOVER, 2.0
	)
	assert_true(landed, "then he jumps and lands")
	assert_almost_eq(king.position, brain.landing_spot, Vector2(2, 2), "on the marked spot")
	assert_lt(banane.health, health, "Banane stood on the spot and got squashed")
	assert_eq(king.puppet.position, Vector2.ZERO, "back on the ground")


func test_ac18_beating_him_pops_all_drops_a_big_box_and_offers_the_choice() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var boomerang: Weapon = banane.add_weapon(banane.stats.starting_weapon)
	boomerang.level = 1
	run.elapsed = run.rules.goal_seconds + 30.0
	var king: Zombie = run.spawner.spawn_boss(KING)
	for i: int in 8:
		run.enemies.spawn(SHAMBLER, banane.global_position + Vector2.from_angle(i * 0.8) * 400.0)
	var died_at: Vector2 = king.position
	run.enemies.damage(king, king.max_health * 2.0)
	assert_true(run.goal_done, "beating him is the goal")
	var boxes: Array[GiftBox] = _boxes()
	assert_eq(boxes.size(), 1, "he drops a gift box")
	assert_true(boxes[0].big, "a big one")
	assert_almost_eq(boxes[0].position, died_at, Vector2.ONE)
	assert_eq(main.music.track, &"run", "the boss music stops")
	await wait_seconds(Run.POP_CHAIN_TIME + 0.2)
	assert_eq(run.enemies.alive_count(), 0, "all zombies pop")
	var opened: bool = await _wait_until(run.gift_screen.is_open, Run.CELEBRATION_TIME + 1.0)
	assert_true(opened, "the big box opens for Banane")
	assert_gte(boomerang.level, 4, "more inside: at least 3 level-ups")
	await wait_for_goal_screen(run)
	assert_true(run.goal_screen.is_open(), "then End run / Keep going")
	var title: Label = run.goal_screen.get_node("%TitleLabel") as Label
	assert_eq(title.text, "You beat the Bedroom!")


func test_ac19_dying_before_the_king_is_beaten_is_a_loss() -> void:
	await _quiet_run()
	run.finished.connect(func(result: RunResult) -> void: finished_results.append(result))
	run.elapsed = run.rules.goal_seconds + 10.0
	run.spawner.spawn_boss(KING)
	var banane: Player = first_player()
	banane.health = 1.0
	run.enemies.spawn(SHAMBLER, banane.global_position)
	await wait_seconds(Run.DEATH_PAUSE + 0.3)
	assert_eq(finished_results.size(), 1, "the run is over")
	if finished_results.is_empty():
		return
	assert_false(finished_results[0].won, "a loss")
	var end: EndScreen = main.current_screen as EndScreen
	assert_not_null(end)
	if end != null:
		assert_eq(end.title_label.text, "Banane got stuffed")


func test_ac25_the_king_lunges_at_the_nearest_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(0, 500))
	second.invincible = true
	disarm(second)
	var king: Zombie = _king(Vector2(0, 320))
	var brain: SockKingBrain = _brain(king)
	run.enemies.damage(king, king.max_health * 0.6)
	await _wait_until(func() -> bool: return brain.state == SockKingBrain.State.LUNGE_AIM, 0.5)
	assert_almost_eq(brain.landing_spot, second.global_position, Vector2(2, 2), "at player 2")


func test_dev_menu_jumps_to_the_king() -> void:
	run = await start_run()
	disarm(first_player())
	first_player().invincible = true
	run.dev_menu.press("Jump to the King")
	assert_true(await _wait_until(func() -> bool: return run.boss_fight, 2.0))
