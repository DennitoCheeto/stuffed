extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §6, AC-43): the Party Shop reaches the next run with the numbers from data.
## Each level makes the wait between floor pickups shorter; at Lv 3 the first one is due after
## 15 s instead of 30 s or more.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const PARTY_SHOP: BuildingDef = preload("res://data/town/buildings/party_shop.tres")
const RULES: FloorPickupRules = preload("res://data/floor_pickup_rules.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


## Kills up to `count` zombies far from the players (stops early once `until_pickups` lie on the
## floor).
func _kill(count: int, until_pickups: int = -1) -> void:
	for i: int in count:
		var spot: Vector2 = first_player().global_position + Vector2(500.0, -200.0 + 20.0 * i)
		var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
		run.enemies.damage(zombie, 1000.0)
		if run.floor_pickups().size() == until_pickups:
			break
	await wait_physics_frames(1)


func test_ac43_without_a_party_shop_nothing_drops_at_15_seconds() -> void:
	await _quiet_run()
	assert_eq(run.floor_pickup_drops.gap_cut, 0.0)
	assert_gte(run.floor_pickup_drops.next_drop_at, RULES.first_drop_after)
	run.elapsed = 15.5
	await _kill(40)
	assert_eq(run.floor_pickups().size(), 0, "the first pickup waits for 30 s or more")


func test_ac43_party_shop_lv3_drops_the_first_pickup_after_15_seconds() -> void:
	main.town.building_levels["party_shop"] = 3
	await _quiet_run()
	var first_at: float = PARTY_SHOP.reached(3).first_pickup_at
	assert_eq(first_at, 15.0, "spec: the first after 15 s")
	run.elapsed = first_at - 0.5
	await _kill(40)
	assert_eq(run.floor_pickups().size(), 0, "not before 15 s")
	run.elapsed = first_at + 0.1
	await _kill(80, 1)
	assert_eq(run.floor_pickups().size(), 1, "a kill right after 15 s drops one")
	var keep: float = 1.0 - PARTY_SHOP.reached(3).pickup_gap_cut
	var gap: float = run.floor_pickup_drops.next_drop_at - run.elapsed
	assert_gte(gap, RULES.min_gap * keep - 0.01, "the shorter gap still holds")
	assert_lte(gap, (RULES.min_gap + RULES.gap_spread) * keep + 0.01, "45% shorter gap")


func test_ac43_party_shop_lv1_makes_the_gap_shorter() -> void:
	main.town.building_levels["party_shop"] = 1
	await _quiet_run()
	var cut: float = PARTY_SHOP.reached(1).pickup_gap_cut
	assert_almost_eq(run.floor_pickup_drops.gap_cut, 0.15, 0.001, "spec: -15% gap")
	assert_gte(run.floor_pickup_drops.next_drop_at, RULES.first_drop_after, "no early first")
	run.elapsed = run.floor_pickup_drops.next_drop_at + 0.1
	await _kill(80, 1)
	assert_eq(run.floor_pickups().size(), 1)
	var gap: float = run.floor_pickup_drops.next_drop_at - run.elapsed
	assert_gte(gap, RULES.min_gap * (1.0 - cut) - 0.01)
	assert_lte(gap, (RULES.min_gap + RULES.gap_spread) * (1.0 - cut) + 0.01)
