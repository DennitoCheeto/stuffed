extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 02 §4, §11, AC-3, AC-5): items picked from cards work in a real run, and the
## HUD shows owned weapons and items with their levels.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	return run


## A pool with only these upgrades (plus the snack), so the scenario knows which cards appear.
func _only(ids: Array[StringName]) -> UpgradePool:
	var pool: UpgradePool = POOL.duplicate()
	pool.upgrades = []
	for upgrade: UpgradeDef in POOL.upgrades:
		if ids.has(upgrade.id):
			pool.upgrades.append(upgrade)
	return pool


## Levels Banane up and picks the first card with key 1.
func _level_up_and_pick_first() -> void:
	var banane: Player = first_player()
	banane.add_xp(banane.progress.xp_needed() - banane.progress.xp)
	await wait_for_signal(run.level_up_screen.cards_shown, 3.0)
	await wait_seconds(LevelUpScreen.INPUT_DELAY + 0.05)
	sender.action_down("pick_card_1")
	await wait_process_frames(2)
	sender.action_up("pick_card_1")
	await wait_process_frames(2)


func _slot_shows(slot: LoadoutSlot, icon: StringName, level: int) -> bool:
	return slot.icon_name == icon and slot.level == level and slot.is_visible_in_tree()


func test_ac3_thick_felt_card_makes_a_zombie_hit_hurt_less() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	disarm(banane)
	run.upgrade_pool = _only([&"thick_felt"])
	await _level_up_and_pick_first()
	assert_eq(banane.item_levels.get(&"thick_felt", 0), 1, "Thick Felt was picked")
	var hits: Array[float] = []
	banane.hurt.connect(func(amount: float) -> void: hits.append(amount))
	run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(10, 0))
	await wait_physics_frames(20)
	assert_gt(hits.size(), 0, "the zombie touched Banane")
	if not hits.is_empty():
		assert_almost_eq(hits[0], SHAMBLER.contact_damage * 0.92, 0.01, "8% less damage")


func test_ac3_big_spool_card_makes_the_peel_bigger() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var boomerang: Weapon = banane.weapon(&"peel_boomerang")
	var dummy: Zombie = run.enemies.spawn(SHAMBLER, banane.global_position + Vector2(200, 0))
	dummy.move_speed = 0.0
	dummy.max_health = 100000.0
	dummy.health = 100000.0
	await wait_until(func() -> bool: return not run.projectiles.fired_by(boomerang).is_empty(), 3.0)
	var normal: float = run.projectiles.fired_by(boomerang)[0].scale.x
	var normal_radius: float = boomerang.hit_radius()
	run.upgrade_pool = _only([&"big_spool"])
	await _level_up_and_pick_first()
	assert_almost_eq(boomerang.hit_radius(), normal_radius * 1.1, 0.01, "hits 10% wider")
	await wait_until(func() -> bool: return _peel_size(boomerang) > normal * 1.05, 4.0)
	assert_almost_eq(_peel_size(boomerang), normal * 1.1, 0.01, "the next peel is 10% bigger")


func _peel_size(boomerang: Weapon) -> float:
	var biggest: float = 0.0
	for shot: Projectile in run.projectiles.fired_by(boomerang):
		biggest = maxf(biggest, shot.scale.x)
	return biggest


func test_ac5_hud_shows_weapons_and_items_with_levels() -> void:
	await _quiet_run()
	disarm(first_player())
	var hud: Hud = run.hud
	assert_eq(hud.weapon_slots.size(), 6, "6 weapon slots")
	assert_eq(hud.item_slots.size(), 6, "6 item slots")
	first_player().add_weapon(POOL.find(&"peel_boomerang").weapon)
	assert_true(_slot_shows(hud.weapon_slots[0], &"boomerang", 1), "boomerang Lv 1")
	assert_true(_slot_shows(hud.item_slots[0], &"", 0), "no items yet")
	run.upgrade_pool = _only([&"big_spool"])
	await _level_up_and_pick_first()
	assert_true(_slot_shows(hud.item_slots[0], &"spool", 1), "Big Spool Lv 1")
	await _level_up_and_pick_first()
	assert_true(_slot_shows(hud.item_slots[0], &"spool", 2), "Big Spool Lv 2")
	run.upgrade_pool = _only([&"sewing_pin_sniper"])
	await _level_up_and_pick_first()
	run.upgrade_pool = _only([&"thick_felt"])
	await _level_up_and_pick_first()
	assert_true(_slot_shows(hud.weapon_slots[1], &"pin", 1), "sniper in the second weapon slot")
	assert_true(_slot_shows(hud.item_slots[1], &"felt", 1), "Thick Felt in the second item slot")
	assert_true(_slot_shows(hud.weapon_slots[2], &"", 0), "the other slots stay empty")
	assert_true(_slot_shows(hud.item_slots[5], &"", 0))
