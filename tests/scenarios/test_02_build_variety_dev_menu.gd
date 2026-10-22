extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §13, AC-22): the developer-menu actions added in M2 do what they say.

var run: Run


func _menu_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.dev_menu.toggle()
	await wait_physics_frames(1)
	return run


func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _count_of(type_name: String) -> int:
	var count: int = 0
	for zombie: Zombie in run.enemies.zombies:
		if zombie.stats.display_name == type_name:
			count += 1
	return count


func test_ac22_give_a_weapon_at_any_level() -> void:
	await _menu_run()
	run.dev_menu.choose_upgrade(&"thread_whip")
	run.dev_menu.press("Give Lv 3")
	var whip: Weapon = first_player().weapon(&"thread_whip")
	assert_not_null(whip, "Banane has the whip")
	if whip == null:
		return
	assert_eq(whip.level, 3)
	assert_eq(run.hud.weapon_slots[1].level, 3, "the HUD shows it")
	run.dev_menu.press("Give Lv 1")
	assert_eq(whip.level, 1, "weapons can go down too")


func test_ac22_give_an_item_at_any_level() -> void:
	await _menu_run()
	var spool: UpgradeDef = run.upgrade_pool.find(&"big_spool")
	run.dev_menu.choose_upgrade(&"big_spool")
	run.dev_menu.press("Give Lv 4")
	var banane: Player = first_player()
	assert_eq(banane.item_levels.get(&"big_spool", 0), 4)
	assert_almost_eq(banane.area_multiplier, 1.0 + 4.0 * spool.amount, 0.001, "4 levels apply")


func test_ac22_give_respects_full_slots() -> void:
	await _menu_run()
	run.dev_menu.press(DevMenu.MAX_EVERYTHING)
	var banane: Player = first_player()
	var missing: StringName = &""
	for upgrade: UpgradeDef in run.upgrade_pool.upgrades:
		var owned: int = banane.upgrade_levels().get(upgrade.id, 0)
		if upgrade.kind == UpgradeDef.Kind.WEAPON and owned == 0:
			missing = upgrade.id
	assert_ne(missing, &"", "some weapon is left out")
	assert_false(run.dev_menu.give(missing, 1), "no 7th weapon")
	assert_eq(banane.weapons().size(), run.upgrade_pool.max_weapons)


func test_ac22_max_everything() -> void:
	await _menu_run()
	run.dev_menu.press(DevMenu.MAX_EVERYTHING)
	var banane: Player = first_player()
	var pool: UpgradePool = run.upgrade_pool
	assert_eq(banane.weapons().size(), pool.max_weapons, "6 weapons")
	assert_eq(banane.items.size(), pool.max_items, "6 items")
	var evolved: int = 0
	for weapon: Weapon in banane.weapons():
		assert_true(weapon.is_maxed(), "%s maxed" % weapon.stats.display_name)
		if weapon.stats.evolved_from != &"":
			evolved += 1
	assert_eq(evolved, pool.evolutions.size(), "every evolution happened")
	for item: UpgradeDef in banane.items:
		assert_eq(banane.item_levels[item.id], item.top_level(), "%s maxed" % item.display_name)
	run.dev_menu.press("100 shamblers")
	banane.invincible = true
	var fought: bool = await _wait_until(func() -> bool: return run.enemies.kills > 0, 8.0)
	assert_true(fought, "all of it fights")


func test_ac22_spawn_one_and_ten_of_each_type() -> void:
	await _menu_run()
	run.dev_menu.press("1 tank")
	assert_eq(run.enemies.alive_count(), 1)
	assert_eq(_count_of("Tank"), 1)
	run.enemies.kill_all()
	run.dev_menu.press("1 of each")
	for stats: EnemyStats in DevMenu.ENEMY_TYPES:
		assert_eq(_count_of(stats.display_name), 1, "one %s" % stats.display_name)
	run.enemies.kill_all()
	run.dev_menu.press("10 of each")
	for stats: EnemyStats in DevMenu.ENEMY_TYPES:
		assert_eq(_count_of(stats.display_name), 10, "ten %ss" % stats.display_name)


func test_ac22_refill_rerolls_skips_and_banishes() -> void:
	await _menu_run()
	var controls: CardControls = first_player().card_controls
	controls.use_reroll()
	controls.use_skip()
	controls.banish(&"quick_feet")
	run.dev_menu.press(DevMenu.REFILL)
	var pool: UpgradePool = run.upgrade_pool
	assert_eq(controls.rerolls_left, pool.rerolls_per_run)
	assert_eq(controls.skips_left, pool.skips_per_run)
	assert_eq(controls.banishes_left, pool.banishes_per_run)
	assert_has(controls.banished, &"quick_feet", "banished stays banished")


func test_ac22_ready_to_evolve_then_walk_onto_the_box() -> void:
	await _menu_run()
	disarm(first_player())
	run.dev_menu.press("Ready: Banana Split")
	var banane: Player = first_player()
	assert_true(banane.weapon(&"peel_boomerang").is_maxed(), "top level")
	assert_true(banane.item_levels.has(&"quick_feet"), "partner owned")
	sender.action_down("p1_move_right")
	var opened: bool = await _wait_until(run.gift_screen.is_open, 2.0)
	sender.action_up("p1_move_right")
	assert_true(opened, "the gift box was next to Banane")
	assert_not_null(banane.weapon(&"banana_split"), "evolved")


func test_ac22_jump_to_big_ted() -> void:
	run = await start_run()
	disarm(first_player())
	first_player().invincible = true
	run.dev_menu.press("Jump to Big Ted")
	assert_true(await _wait_until(func() -> bool: return run.enemies.bosses().size() == 1, 3.0))
