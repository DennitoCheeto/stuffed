extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §4, §9, AC-78 Snack Bar + Party Shop, AC-82 healing): in the siege the built
## Snack Bar heals every hero standing in its ring (3 health per second at Lv 1, 8 at Lv 3; in
## co-op both heroes), and the built Party Shop pops confetti every few seconds that hurts the
## zombies in its ring (every 4 s at Lv 3), waiting loaded while nothing is in reach. Its damage
## counts under the Party Shop's own row. Knocked-down, damaged and unbuilt buildings do nothing.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const SNACK_BAR: StringName = &"snack_bar"
const PARTY_SHOP: StringName = &"party_shop"
## Health that no confetti pops in these tests.
const VERY_TOUGH: float = 100000.0
## How far below the building's middle a hero stands in the ring (the footprint is 180 high).
const IN_FRONT: float = 150.0
## A corner far from the snack bar, the party shop and the heroes.
const KEEPER_SPOT: Vector2 = Vector2(2350.0, 1400.0)

var siege: Siege


## Presses E at the door of a town with `levels` and the horde due; returns the siege with no
## waves coming and every hero unarmed (one still zombie keeps the night going).
func _start_siege(levels: Dictionary[String, int]) -> Siege:
	main.town.building_levels = levels
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var started: Siege = main.current_screen as Siege
	for hero: Player in Players.all(get_tree()):
		disarm(hero)
	started.waves.finished = true
	started.enemies.kill_all()
	# One still zombie far away, or the siege is won at once (no waves, nobody left).
	var keeper: Zombie = started.enemies.spawn(TANK, KEEPER_SPOT)
	keeper.max_health = VERY_TOUGH
	keeper.health = VERY_TOUGH
	keeper.move_speed = 0.0
	return started


## Puts `hero` at `at`, hurt by `missing` health and safe from zombies.
func _place_hurt(hero: Player, at: Vector2, missing: float) -> void:
	hero.global_position = at
	hero.velocity = Vector2.ZERO
	hero.health = hero.max_health - missing
	hero.invincible = true


func _ring_spot(id: StringName) -> Vector2:
	return siege.rings[id].position + Vector2(0.0, IN_FRONT)


func _tough(at: Vector2) -> Zombie:
	var zombie: Zombie = siege.enemies.spawn(TANK, at)
	zombie.max_health = VERY_TOUGH
	zombie.health = VERY_TOUGH
	zombie.move_speed = 0.0
	return zombie


func test_ac78_the_snack_bar_heals_a_hero_in_its_ring() -> void:
	siege = await _start_siege({"snack_bar": 1, "lucky_jar": 1})
	assert_true(siege.rings.has(SNACK_BAR), "the built snack bar has a healing ring")
	if not siege.rings.has(SNACK_BAR):
		return
	var ring: SiegeHealRing = siege.rings[SNACK_BAR] as SiegeHealRing
	assert_not_null(ring)
	var hero: Player = first_player()
	_place_hurt(hero, _ring_spot(SNACK_BAR), 50.0)
	var before: float = hero.health
	var start: float = siege.elapsed
	await wait_seconds(2.0)
	var per_second: float = (hero.health - before) / (siege.elapsed - start)
	assert_almost_eq(per_second, 3.0, 0.3, "Lv 1: 3 health per second")
	assert_true(ring.healing, "the ring glows while it heals")


func test_ac78_a_maxed_snack_bar_heals_8_per_second() -> void:
	siege = await _start_siege({"snack_bar": 3, "lucky_jar": 1})
	var hero: Player = first_player()
	_place_hurt(hero, _ring_spot(SNACK_BAR), 60.0)
	var before: float = hero.health
	var start: float = siege.elapsed
	await wait_seconds(2.0)
	var per_second: float = (hero.health - before) / (siege.elapsed - start)
	assert_almost_eq(per_second, 8.0, 0.5, "Lv 3: 8 health per second")


func test_ac78_no_healing_outside_the_ring() -> void:
	siege = await _start_siege({"snack_bar": 3, "lucky_jar": 1})
	var ring: SiegeRing = siege.rings[SNACK_BAR]
	var hero: Player = first_player()
	_place_hurt(hero, ring.position + Vector2(0.0, ring.radius + 80.0), 50.0)
	var before: float = hero.health
	await wait_seconds(1.0)
	assert_eq(hero.health, before, "too far away")
	assert_false(siege.rings[SNACK_BAR].healing)


func test_ac82_in_co_op_both_heroes_heal_at_the_snack_bar() -> void:
	add_controls(1)
	main.player_count = 2
	siege = await _start_siege({"snack_bar": 2, "lucky_jar": 1})
	var heroes: Array[Player] = Players.all(get_tree())
	assert_eq(heroes.size(), 2, "two heroes in the siege")
	if heroes.size() < 2:
		return
	var spot: Vector2 = _ring_spot(SNACK_BAR)
	_place_hurt(heroes[0], spot + Vector2(-60.0, 0.0), 40.0)
	_place_hurt(heroes[1], spot + Vector2(60.0, 0.0), 40.0)
	var before: Array[float] = [heroes[0].health, heroes[1].health]
	await wait_seconds(1.5)
	assert_gt(heroes[0].health, before[0] + 5.0, "player 1 heals")
	assert_gt(heroes[1].health, before[1] + 5.0, "player 2 heals")


func test_ac78_a_knocked_down_snack_bar_stops_healing() -> void:
	siege = await _start_siege({"snack_bar": 3, "lucky_jar": 1})
	var bar: SiegeBuilding = siege.targets.building(SNACK_BAR)
	var hero: Player = first_player()
	_place_hurt(hero, _ring_spot(SNACK_BAR), 50.0)
	bar.hurt(bar.max_health)
	await wait_physics_frames(1)
	assert_false(siege.rings[SNACK_BAR].is_active(), "knocked down: the ring is gone")
	var before: float = hero.health
	await wait_seconds(1.0)
	assert_eq(hero.health, before, "no healing from a fallen snack bar")


func test_ac78_the_party_shop_pops_confetti_every_4_s_at_lv_3() -> void:
	siege = await _start_siege({"party_shop": 3, "lucky_jar": 1})
	assert_true(siege.rings.has(PARTY_SHOP), "the built party shop has a confetti trap")
	if not siege.rings.has(PARTY_SHOP):
		return
	var trap: SiegeConfettiTrap = siege.rings[PARTY_SHOP] as SiegeConfettiTrap
	var zombie: Zombie = _tough(trap.position + Vector2(0.0, -trap.radius + 40.0))
	var far: Zombie = _tough(trap.position + Vector2(trap.radius + 200.0, 0.0))
	var times: Array[float] = []
	trap.popped.connect(func(_hits: int) -> void: times.append(siege.elapsed))
	Sfx.history.clear()
	await wait_seconds(8.6)
	assert_eq(times.size(), 2, "two pops in 8.6 s")
	if times.size() == 2:
		assert_almost_eq(times[1] - times[0], 4.0, 0.1, "one pop every 4 s")
	assert_eq(zombie.health, VERY_TOUGH - 2.0 * trap.damage, "it hurts the zombie in reach")
	assert_eq(far.health, VERY_TOUGH, "not the one outside the ring")
	var row: WeaponTallyEntry = siege.enemies.tally.find(-1, WeaponTally.PARTY_SHOP)
	assert_not_null(row, "its own row in the weapon tally")
	if row != null:
		assert_eq(row.display_name, "Party Shop")
	assert_true(Sfx.history.has(siege.siege_rules.trap_sound), "a pop sound")


func test_ac78_the_trap_waits_loaded_until_a_zombie_comes() -> void:
	siege = await _start_siege({"party_shop": 3, "lucky_jar": 1})
	var trap: SiegeConfettiTrap = siege.rings[PARTY_SHOP] as SiegeConfettiTrap
	await wait_seconds(4.5)
	assert_eq(trap.pops, 0, "nothing in reach: no pop")
	assert_eq(trap.time_left(), 0.0, "loaded")
	var zombie: Zombie = siege.enemies.spawn(SHAMBLER, trap.position + Vector2(-120.0, -150.0))
	zombie.move_speed = 0.0
	await wait_physics_frames(3)
	assert_eq(trap.pops, 1, "pops as soon as a zombie steps in")
	assert_true(not is_instance_valid(zombie) or zombie.dead, "a shambler doesn't survive the confetti")


func test_ac78_damaged_and_unbuilt_buildings_have_no_ring() -> void:
	main.town.damaged = PackedStringArray(["snack_bar"])
	siege = await _start_siege({"snack_bar": 2, "lucky_jar": 1})
	assert_false(siege.rings.has(SNACK_BAR), "a damaged snack bar doesn't heal")
	assert_false(siege.rings.has(PARTY_SHOP), "a ruined party shop has no trap")
