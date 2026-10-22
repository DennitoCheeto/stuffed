extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §3, AC-39): kills add coins (and stuffing/thread from the bigger sources)
## straight to the run's haul, nothing new lands on the floor, XP buttons stay XP only, the HUD
## jars show the haul, and elites, bosses and gift boxes send a burst flying into the jars.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const RULES: MaterialRules = preload("res://data/town/material_rules.tres")

var run: Run


## A quiet run: no spawns, no weapons, no floor pickups, so the test decides what happens.
func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	run.floor_pickup_drops.next_drop_at = INF
	disarm(first_player())
	return run


func _kill(stats: EnemyStats, offset: Vector2, elite: EliteRules = null) -> void:
	var at: Vector2 = first_player().global_position + offset
	var zombie: Zombie = run.enemies.spawn(stats, at, elite)
	zombie.attack_cooldown = 100.0
	run.enemies.damage(zombie, 1_000_000.0)


func _floor_things() -> int:
	var count: int = 0
	for child: Node in run.floor_items.get_children():
		if not child.is_queued_for_deletion():
			count += 1
	return count


func test_ac39_a_kill_adds_coins_straight_to_the_haul() -> void:
	await _quiet_run()
	var floor_before: int = _floor_things()
	_kill(SHAMBLER, Vector2(300, 0))
	await wait_physics_frames(1)
	var coins: int = RULES.kill_reward("Shambler").coins
	assert_eq(run.haul.amount("coins"), coins, "coins from data")
	assert_eq(run.hud.jars.shown("coins"), coins, "the HUD jar ticks up")
	assert_eq(_floor_things(), floor_before, "no coin lies on the floor")
	assert_eq(run.pickups.buttons.size(), 1, "only the XP button drops")
	assert_true(run.hud.jars.bursts.is_empty(), "a normal kill sends no burst")


func test_ac39_xp_buttons_give_only_xp() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	run.pickups.drop(EnemyStats.XpSize.BIG, banane.global_position)
	await wait_physics_frames(roundi(0.5 * FPS))
	assert_true(run.pickups.buttons.is_empty(), "the button was picked up")
	assert_gt(banane.progress.xp + banane.progress.level - 1, 0, "it gave XP")
	assert_true(run.haul.materials.is_empty(), "and no materials")


func test_ac39_tanks_give_more_coins() -> void:
	await _quiet_run()
	_kill(TANK, Vector2(300, 0))
	await wait_physics_frames(1)
	assert_eq(run.haul.amount("coins"), RULES.kill_reward("Tank").coins)


func test_ac39_an_elite_gives_extra_and_a_burst_flies_to_the_jars() -> void:
	await _quiet_run()
	_kill(SHAMBLER, Vector2(300, 0), ELITE)
	await wait_physics_frames(1)
	var coins: int = RULES.kill_reward("Shambler").coins + RULES.elite_extra.coins
	assert_eq(run.haul.amount("coins"), coins)
	assert_eq(run.haul.amount("stuffing"), RULES.elite_extra.stuffing, "every elite: stuffing")
	assert_eq(run.hud.jars.bursts.size(), 1, "a burst flies")
	var burst: MaterialBurst = run.hud.jars.bursts[0]
	var to_jar: Vector2 = burst.pieces[0]["to"]
	assert_almost_eq(to_jar, run.hud.jars.jar_position("coins"), Vector2.ONE, "into the jar")
	var materials: Array[String] = []
	for piece: Dictionary in burst.pieces:
		if not materials.has(piece["material"]):
			materials.append(piece["material"])
	assert_eq(materials.size(), 2, "coins and tufts")
	await wait_seconds(burst.duration() + 0.2)
	assert_true(run.hud.jars.bursts.is_empty(), "all pieces landed and the burst is gone")


func test_ac39_opening_a_gift_box_adds_thread() -> void:
	await _quiet_run()
	run.drop_gift_box(first_player().global_position)
	await wait_physics_frames(3)
	assert_true(run.gift_screen.is_open(), "the box opened")
	assert_eq(run.haul.amount("thread"), RULES.gift_box.thread)
	assert_eq(run.hud.jars.shown("thread"), RULES.gift_box.thread)
	assert_eq(run.hud.jars.bursts.size(), 1, "a burst flies from the box")
	run.gift_screen.close()


func test_ac39_big_ted_gives_coins_stuffing_and_thread() -> void:
	await _quiet_run()
	var ted: Zombie = run.spawner.spawn_boss(run.spawner.schedule.mini_boss)
	run.enemies.damage(ted, ted.max_health * 10.0)
	await wait_physics_frames(1)
	var reward: MaterialReward = RULES.kill_reward("Big Ted")
	assert_eq(run.haul.amount("coins"), reward.coins)
	assert_eq(run.haul.amount("stuffing"), reward.stuffing)
	assert_eq(run.haul.amount("thread"), reward.thread)
	assert_false(run.hud.jars.bursts.is_empty(), "a burst flies")


func test_ac39_ac40_the_king_gives_his_reward_and_the_victory_bonus() -> void:
	await _quiet_run()
	beat_the_boss(run)
	await wait_physics_frames(1)
	var king: MaterialReward = RULES.kill_reward("Sock Puppet King")
	var bonus: MaterialReward = RULES.victory_bonus
	assert_eq(run.haul.amount("coins"), king.coins + bonus.coins)
	assert_eq(run.haul.amount("stuffing"), king.stuffing + bonus.stuffing)
	assert_eq(run.haul.amount("thread"), king.thread + bonus.thread)
	await wait_for_goal_screen(run)
	var thread: int = king.thread + bonus.thread + RULES.big_gift_box.thread
	assert_eq(run.haul.amount("thread"), thread, "plus the big gift box")


func test_ac39_popped_zombies_at_the_goal_give_nothing() -> void:
	await _quiet_run()
	for i: int in 5:
		run.enemies.spawn(SHAMBLER, first_player().global_position + Vector2(400, 60 * i))
	beat_the_boss(run)
	await wait_for_goal_screen(run)
	var king: MaterialReward = RULES.kill_reward("Sock Puppet King")
	assert_eq(run.haul.amount("coins"), king.coins + RULES.victory_bonus.coins)


func test_run_log_records_materials_and_how_the_run_ended() -> void:
	await _quiet_run()
	_kill(SHAMBLER, Vector2(300, 0))
	_kill(SHAMBLER, Vector2(-300, 0))
	_kill(SHAMBLER, Vector2(0, 300))
	await wait_physics_frames(1)
	run.pause()
	run.pause_menu.quit_button.pressed.emit()
	await wait_physics_frames(2)
	var entries: Array[Dictionary] = RunLog.read_all()
	assert_false(entries.is_empty())
	if entries.is_empty():
		return
	var entry: Dictionary = entries[-1]
	var coins: int = 3 * RULES.kill_reward("Shambler").coins
	assert_eq(int(entry["materials_collected"]["coins"]), coins)
	assert_eq(int(entry["materials_kept"]["coins"]), ceili(coins * RULES.keep_share_lost))
	assert_eq(entry["run_end"], "gave_up")
