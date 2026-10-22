extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §6, §8, §20, AC-6, AC-8, AC-25, AC-26, AC-27): elites are big zombies with a
## gold patch that fire one telegraphed pattern and drop a gift box; touching the box opens it with
## the gift box moment for the player who touched it. Its contents stay as cards until confirmed.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


func _elite(at: Vector2) -> Zombie:
	return run.enemies.spawn(SHAMBLER, at, ELITE)


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


## Gives player 1 back the Peel Boomerang at `level` (scenarios disarm Banane).
func _boomerang(player: Player, level: int) -> Weapon:
	var weapon: Weapon = player.add_weapon(player.stats.starting_weapon)
	weapon.level = level
	return weapon


## A quiet run where Banane has a level 1 boomerang and a gift box opens for him.
func _open_box() -> void:
	await _quiet_run()
	_boomerang(first_player(), 1)
	await _drop_box()


## Drops a gift box on player 1 and waits until it opens.
func _drop_box() -> void:
	run.drop_gift_box(first_player().global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0), "the box opens")


func _showing_contents() -> bool:
	return run.gift_screen.showing_contents


## Presses and releases a key (two frames each).
func _press_key(key: Key) -> void:
	sender.key_down(key)
	await wait_physics_frames(2)
	sender.key_up(key)
	await wait_physics_frames(2)


func test_ac6_elite_is_big_with_a_gold_patch_and_lots_of_health() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var normal: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(-300, 0))
	var elite: Zombie = _elite(banane.global_position + Vector2(300, 0))
	await wait_physics_frames(2)
	assert_gt(elite.radius(), normal.radius() * 1.3, "bigger body")
	assert_gt(elite.puppet.origin.scale.y, normal.puppet.origin.scale.y * 1.3, "drawn bigger")
	assert_eq(elite.puppet.elite_marks.size(), 2, "gold patch and crown of stitches")
	for mark: Sprite2D in elite.puppet.elite_marks:
		assert_true(mark.is_visible_in_tree())
	assert_eq(normal.puppet.elite_marks.size(), 0)
	assert_gt(elite.health, normal.health * 5.0, "much more health")
	run.enemies.damage(elite, normal.max_health * 2.0)
	assert_false(elite.dead, "survives a hit that kills two shamblers")


func test_ac6_elite_winds_up_then_fires_a_ring() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	banane.invincible = true
	var elite: Zombie = _elite(banane.global_position + Vector2(220, 0))
	elite.attack_cooldown = 0.0
	assert_true(await _wait_until(elite.is_winding_up, 1.0), "it starts a wind-up")
	await _wait_until(func() -> bool: return elite.windup_progress() > 0.8, 2.0)
	assert_eq(run.projectiles.hostile_count(), 0, "nothing while it puffs up")
	assert_gt(elite.puppet.root.modulate.r, 1.1, "it glows: a shot is coming")
	var fired: bool = await _wait_until(
		func() -> bool: return run.projectiles.hostile_count() > 0, 1.0
	)
	assert_true(fired, "then it fires")
	assert_eq(run.projectiles.hostile_count(), ELITE.attack.balls_in_volley(0), "a whole ring")


func test_ac6_killed_elite_drops_a_gift_box() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var normal: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(-300, 0))
	run.enemies.damage(normal, 1000.0)
	await wait_physics_frames(1)
	assert_eq(_boxes().size(), 0, "a normal zombie drops no gift box")
	var spot: Vector2 = banane.global_position + Vector2(300, 0)
	var elite: Zombie = _elite(spot)
	var died_at: Vector2 = elite.position
	run.enemies.damage(elite, 100000.0)
	await wait_physics_frames(1)
	var boxes: Array[GiftBox] = _boxes()
	assert_eq(boxes.size(), 1, "the elite drops a gift box")
	assert_almost_eq(boxes[0].position, died_at, Vector2.ONE, "where it died")
	await wait_physics_frames(roundi(3.0 * FPS))
	assert_eq(_boxes().size(), 1, "it waits on the floor until touched")
	assert_false(boxes[0].opened)


func test_ac6_touching_the_box_opens_the_gift_box_moment() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var boomerang: Weapon = _boomerang(banane, 1)
	var elite: Zombie = _elite(banane.global_position + Vector2(120, 0))
	elite.attack_cooldown = 100.0
	run.enemies.damage(elite, 100000.0)
	await wait_physics_frames(1)
	_clear_xp()
	sender.action_down("p1_move_right")
	var opened: bool = await _wait_until(run.gift_screen.is_open, 2.0)
	sender.action_up("p1_move_right")
	assert_true(opened, "walking onto the box opens it")
	assert_true(run.is_frozen(), "the game pauses for the moment")
	assert_eq(_boxes().size(), 0, "the box is gone from the floor")
	var puppet: BananePuppet = banane.get_node("Puppet") as BananePuppet
	assert_eq(puppet.state, BananePuppet.State.QUACK, "Banane puts his sunglasses on")
	assert_between(boomerang.level, 2, 4, "1-3 level-ups of the only thing he has")
	var frozen_at: float = run.elapsed
	await wait_physics_frames(roundi(run.gift_box_rules.opening_seconds * 0.6 * FPS))
	assert_true(run.gift_screen.lid_popped, "the lid pops")
	assert_true(
		await _wait_until(_showing_contents, run.gift_box_rules.opening_seconds),
		"then what was inside is shown"
	)
	assert_eq(run.gift_screen.cards[0].title_label.text, "Peel Boomerang")
	await wait_seconds(2.0)
	assert_true(run.gift_screen.is_open(), "it waits for the player")
	assert_almost_eq(run.elapsed, frozen_at, 0.001, "the run timer waited")
	await _press_key(KEY_ENTER)
	assert_false(run.gift_screen.is_open(), "Enter closes it")
	assert_false(run.is_frozen(), "and the run goes on")


func test_ac26_a_key_during_the_opening_jumps_to_the_contents() -> void:
	await _open_box()
	await wait_physics_frames(roundi(run.gift_box_rules.skip_delay * FPS) + 2)
	assert_false(run.gift_screen.showing_contents, "still opening")
	await _press_key(KEY_ENTER)
	assert_true(run.gift_screen.is_open(), "a key never closes the box while it opens")
	assert_true(run.gift_screen.showing_contents, "it jumps straight to the contents")
	assert_true(run.gift_screen.lid_popped)
	await _press_key(KEY_ENTER)
	assert_true(run.gift_screen.is_open(), "the same key right after does not close it")


func test_ac26_contents_wait_for_confirmation_not_movement() -> void:
	await _open_box()
	assert_true(await _wait_until(_showing_contents, 2.0))
	await _press_key(KEY_SPACE)
	assert_true(run.gift_screen.is_open(), "nothing closes it in the first 0.5 s")
	assert_true(run.gift_screen.continue_button.disabled)
	await wait_seconds(run.gift_box_rules.confirm_delay + 0.1)
	for action: String in ["p1_move_up", "p1_move_down", "p1_move_left", "p1_move_right"]:
		await hold_action(action, 3)
	for key: Key in [KEY_W, KEY_A, KEY_S, KEY_D]:
		await _press_key(key)
	await wait_seconds(1.0)
	assert_true(run.gift_screen.is_open(), "moving never closes it")
	assert_true(run.is_frozen(), "the game stays paused")
	assert_false(run.gift_screen.continue_button.disabled, "Continue is ready")


func test_ac26_space_e_and_continue_click_close_it() -> void:
	await _quiet_run()
	_boomerang(first_player(), 1)
	for how: String in ["space", "e", "click"]:
		await _drop_box()
		assert_true(await _wait_until(_showing_contents, 2.0))
		await wait_seconds(run.gift_box_rules.confirm_delay + 0.1)
		match how:
			"space":
				await _press_key(KEY_SPACE)
			"e":
				await _press_key(KEY_E)
			"click":
				run.gift_screen.continue_button.pressed.emit()
				await wait_physics_frames(2)
		assert_false(run.gift_screen.is_open(), "%s closes it" % how)
		assert_false(run.is_frozen())


func test_ac27_a_card_per_level_up_with_icon_name_and_level() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var boomerang: Weapon = _boomerang(banane, 1)
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(_showing_contents, 2.0))
	var cards: Array[GiftCardView] = run.gift_screen.cards
	assert_eq(cards.size(), boomerang.level - 1, "one card per level-up")
	for index: int in cards.size():
		assert_true(cards[index].visible)
		assert_eq(cards[index].icon.icon, &"boomerang", "its felt icon")
		assert_eq(cards[index].title_label.text, "Peel Boomerang")
		assert_eq(cards[index].level_label.text, "Lv %d → %d" % [index + 1, index + 2])
		assert_false(cards[index].from_icon.visible)


func test_ac8_with_everything_maxed_the_box_heals() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var boomerang: Weapon = _boomerang(banane, 5)
	banane.health = 20.0
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0))
	assert_eq(boomerang.level, 5)
	var heal: float = banane.max_health * run.gift_box_rules.heal_share
	assert_eq(banane.health, 20.0 + heal, "a big heal instead")
	assert_true(await _wait_until(_showing_contents, 2.0))
	assert_eq(run.gift_screen.cards.size(), 1, "one heal card")
	assert_eq(run.gift_screen.cards[0].title_label.text, "Big heal!")
	assert_eq(run.gift_screen.cards[0].level_label.text, "+%d health" % roundi(heal), "how much")


func test_ac25_the_box_opens_for_the_player_who_touched_it() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var first_boomerang: Weapon = _boomerang(banane, 1)
	var second: Player = run.spawn_player(1, banane.global_position + Vector2(0, 400))
	var second_boomerang: Weapon = second.weapon(second.stats.starting_weapon.id)
	run.drop_gift_box(second.global_position + Vector2(10, 0))
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0))
	assert_gt(second_boomerang.level, 1, "player 2 got the level-ups")
	assert_eq(first_boomerang.level, 1, "player 1 got nothing")


func test_a_level_up_during_the_moment_waits_for_it() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	_boomerang(banane, 1)
	run.drop_gift_box(banane.global_position)
	assert_true(await _wait_until(run.gift_screen.is_open, 1.0))
	banane.progress.level_up_now()
	await wait_physics_frames(2)
	assert_false(run.level_up_screen.is_open(), "the cards wait for the gift box")
	run.gift_screen.close()
	await wait_physics_frames(2)
	assert_true(run.level_up_screen.is_open(), "then the level-up comes")
	assert_true(run.is_frozen())


func test_ac6_elites_arrive_in_a_real_run() -> void:
	run = await start_run()
	disarm(first_player())
	first_player().invincible = true
	var arrived: Array[String] = []
	run.spawner.elite_spawned.connect(
		func(elite: Zombie) -> void: arrived.append(elite.display_name)
	)
	var first_time: float = run.spawner.schedule.elite_time(0)
	run.elapsed = first_time - 1.0
	await wait_physics_frames(roundi(0.5 * FPS))
	assert_eq(arrived.size(), 0, "not before its time")
	assert_true(await _wait_until(func() -> bool: return arrived.size() > 0, 1.5))
	assert_eq(arrived[0], "Elite " + run.spawner.schedule.elite_enemy(0).display_name)
	var elites: int = 0
	for zombie: Zombie in run.enemies.zombies:
		if zombie.is_elite():
			elites += 1
	assert_eq(elites, 1, "one elite in the horde")


func test_dev_menu_spawns_an_elite_and_drops_a_gift_box() -> void:
	await _quiet_run()
	run.dev_menu.press("Spawn elite")
	await wait_physics_frames(1)
	assert_true(run.enemies.zombies.any(func(zombie: Zombie) -> bool: return zombie.is_elite()))
	run.dev_menu.press("Drop gift box")
	assert_eq(_boxes().size(), 1)


## Removes the XP buttons on the floor (picking one up would open a level-up first).
func _clear_xp() -> void:
	for button: XpButton in run.pickups.buttons:
		button.queue_free()
	run.pickups.buttons.clear()
