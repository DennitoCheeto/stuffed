extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §9, AC-17, AC-25): Big Ted, the mini-boss, arrives at 4:00 with a banner and
## a health bar at the top. His charge (a red lane on the floor) and his stomp (a red ring) are
## shown before they happen; he goes for the nearest player, spawning is lighter while he is
## alive, and he drops a gift box.

const BIG_TED: BigTedDef = preload("res://data/bosses/big_ted.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## Big Ted `offset` away from player 1, ready to start his next pattern at once.
func _big_ted(offset: Vector2) -> Zombie:
	var ted: Zombie = run.enemies.spawn_boss(BIG_TED, first_player().global_position + offset)
	ted.brain.pattern_cooldown = 0.0
	return ted


func _brain(ted: Zombie) -> BigTedBrain:
	return ted.brain as BigTedBrain


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


func test_ac17_big_ted_arrives_at_4_00_with_a_banner_and_a_health_bar() -> void:
	run = await start_run()
	disarm(first_player())
	first_player().invincible = true
	run.elapsed = BIG_TED.at_seconds - 1.0
	await wait_physics_frames(roundi(0.5 * FPS))
	assert_eq(run.enemies.bosses().size(), 0, "not before 4:00")
	assert_false(run.hud.boss_bar.visible)
	var arrived: bool = await _wait_until(
		func() -> bool: return not run.enemies.bosses().is_empty(), 1.0
	)
	assert_true(arrived, "he arrives at 4:00")
	assert_gte(run.elapsed, BIG_TED.at_seconds)
	var ted: Zombie = run.enemies.bosses()[0]
	assert_eq(ted.display_name, "Big Ted")
	assert_false(run.spawner.visible_rect().has_point(ted.position), "he walks in from off-screen")
	assert_true(run.hud.banner.visible, "a banner announces him")
	assert_eq(run.hud.banner_title.text, BIG_TED.banner)
	assert_true(run.hud.boss_bar.visible, "his health bar is at the top")
	assert_eq(run.hud.boss_label.text, "Big Ted")
	assert_eq(run.hud.boss_bar.value, ted.max_health)
	run.enemies.damage(ted, ted.max_health * 0.25)
	await wait_physics_frames(2)
	assert_almost_eq(run.hud.boss_bar.value, ted.max_health * 0.75, 1.0, "the bar goes down")
	await wait_physics_frames(roundi((BIG_TED.banner_seconds + 0.5) * FPS))
	assert_false(run.hud.banner.visible, "the banner goes away")
	assert_true(run.hud.boss_bar.visible, "the bar stays while he lives")


func test_ac17_charge_is_shown_as_a_red_lane_before_it_happens() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var ted: Zombie = _big_ted(Vector2(300, 0))
	var brain: BigTedBrain = _brain(ted)
	var aiming: bool = await _wait_until(
		func() -> bool: return brain.state == BigTedBrain.State.CHARGE_AIM, 0.5
	)
	assert_true(aiming, "he starts a charge")
	var telegraph: BossTelegraph = brain.telegraph
	assert_true(telegraph.is_visible_in_tree(), "a red lane shows his path")
	assert_eq(telegraph.kind, BossTelegraph.Kind.CHARGE)
	var toward_banane: Vector2 = ted.position.direction_to(banane.global_position)
	assert_gt(telegraph.path.normalized().dot(toward_banane), 0.99, "aimed at Banane")
	assert_gt(telegraph.path.length(), 300.0, "the lane goes past Banane")
	assert_almost_eq(telegraph.lane_width, ted.radius() * 2.0, 0.01, "as wide as his body")
	var start: Vector2 = ted.position
	var health: float = banane.health
	await wait_physics_frames(roundi(BIG_TED.charge_windup_seconds * 0.8 * FPS))
	assert_almost_eq(ted.position, start, Vector2.ONE, "he waits while the lane shows")
	assert_eq(banane.health, health, "nothing has hit Banane yet")
	assert_gt(telegraph.progress, 0.5, "the lane fills up")
	var charged: bool = await _wait_until(
		func() -> bool: return brain.state == BigTedBrain.State.DAZED, 2.0
	)
	assert_true(charged, "then he charges")
	assert_false(telegraph.is_showing(), "the lane is gone once he goes")
	assert_almost_eq(ted.position, start + telegraph.path, Vector2(2, 2), "along the lane")
	assert_lt(banane.health, health, "Banane stood in the lane and got run over")


func test_ac17_stomp_shows_a_ring_then_fires_a_ring_of_balls() -> void:
	await _quiet_run()
	first_player().invincible = true
	var ted: Zombie = _big_ted(Vector2(300, 0))
	var brain: BigTedBrain = _brain(ted)
	brain.next_pattern = BigTedBrain.Pattern.STOMP
	var winding: bool = await _wait_until(
		func() -> bool: return brain.state == BigTedBrain.State.STOMP_WINDUP, 0.5
	)
	assert_true(winding, "he starts a stomp")
	assert_eq(brain.telegraph.kind, BossTelegraph.Kind.STOMP, "a red ring shows on the floor")
	await wait_physics_frames(roundi(BIG_TED.stomp.windup_seconds * 0.7 * FPS))
	assert_eq(run.projectiles.hostile_count(), 0, "nothing while he swells up")
	assert_gt(ted.puppet.root.modulate.r, 1.1, "he glows: a stomp is coming")
	var fired: bool = await _wait_until(
		func() -> bool: return run.projectiles.hostile_count() > 0, 1.0
	)
	assert_true(fired, "then he stomps")
	assert_eq(run.projectiles.hostile_count(), BIG_TED.stomp.balls_in_volley(0), "a whole ring")
	assert_false(brain.telegraph.is_showing())


func test_ac17_patterns_take_turns() -> void:
	await _quiet_run()
	first_player().invincible = true
	var ted: Zombie = _big_ted(Vector2(300, 0))
	var patterns: Array[StringName] = []
	run.enemies.boss_telegraphed.connect(
		func(_boss: Zombie, pattern: StringName) -> void: patterns.append(pattern)
	)
	await _wait_until(func() -> bool: return patterns.size() >= 2, 10.0)
	assert_eq(patterns, [BigTedBrain.CHARGE, BigTedBrain.STOMP] as Array[StringName])
	assert_true(is_instance_valid(ted))


func test_ac17_spawning_is_lighter_while_he_is_alive() -> void:
	await _quiet_run()
	assert_eq(run.spawner.boss_rate_scale(), 1.0)
	var ted: Zombie = _big_ted(Vector2(400, 0))
	assert_eq(run.spawner.boss_rate_scale(), BIG_TED.spawn_rate_scale, "lighter with him")
	run.enemies.damage(ted, ted.max_health * 2.0)
	assert_eq(run.spawner.boss_rate_scale(), 1.0, "back to normal when he's beaten")


func test_ac17_beaten_big_ted_drops_a_gift_box() -> void:
	await _quiet_run()
	var ted: Zombie = run.spawner.spawn_boss(BIG_TED)
	assert_true(run.hud.boss_bar.visible)
	var died_at: Vector2 = ted.position
	run.enemies.damage(ted, ted.max_health * 2.0)
	await wait_physics_frames(2)
	var boxes: Array[GiftBox] = _boxes()
	assert_eq(boxes.size(), 1, "he drops a gift box")
	assert_almost_eq(boxes[0].position, died_at, Vector2.ONE, "where he fell")
	assert_false(run.hud.boss_bar.visible, "the health bar goes away")


func test_ac25_big_ted_goes_for_the_nearest_player() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(0, 500))
	second.invincible = true
	disarm(second)
	var ted: Zombie = _big_ted(Vector2(0, 320))
	var brain: BigTedBrain = _brain(ted)
	await _wait_until(func() -> bool: return brain.state == BigTedBrain.State.CHARGE_AIM, 0.5)
	assert_gt(brain.charge_direction.dot(Vector2.DOWN), 0.99, "charges at the nearer player 2")


func test_dev_menu_brings_big_ted() -> void:
	await _quiet_run()
	run.dev_menu.press("Spawn Big Ted")
	assert_eq(run.enemies.bosses().size(), 1)
	assert_true(run.hud.banner.visible)
