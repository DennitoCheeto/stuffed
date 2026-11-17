extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §4, AC-78 Toy Box Armory + Watchtower): in the siege the built Armory fires
## the hero's starting weapon at nearby zombies (weapon Lv 1 / 3 / 5 by building level) and the
## Watchtower fires slow, strong pins at the toughest zombie in range (every 2 s at Lv 1, every
## second at Lv 3). Their damage counts in the weapon tally under the building's own row. A
## knocked-down, damaged or unbuilt building doesn't fire.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const ARMORY: StringName = &"toy_box_armory"
const TOWER: StringName = &"watchtower"
## Health that no pin pops in these tests.
const VERY_TOUGH: float = 100000.0

var siege: Siege


## Presses E at the door of a town with `levels` and the horde due; returns the siege with no
## waves coming and the hero unhurt and unarmed (only the buildings fight).
func _start_siege(levels: Dictionary[String, int]) -> Siege:
	main.town.building_levels = levels
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var started: Siege = main.current_screen as Siege
	var hero: Player = first_player()
	hero.invincible = true
	disarm(hero)
	started.waves.finished = true
	started.enemies.kill_all()
	return started


func _tally(source: StringName) -> WeaponTallyEntry:
	return siege.enemies.tally.find(-1, source)


## Waits up to `seconds` until the tally row `source` has dealt damage.
func _wait_for_damage(source: StringName, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		var row: WeaponTallyEntry = _tally(source)
		if row != null and row.damage > 0.0:
			return true
		await wait_physics_frames(1)
	return false


func _tough(stats: EnemyStats, at: Vector2) -> Zombie:
	var zombie: Zombie = siege.enemies.spawn(stats, at)
	zombie.max_health = VERY_TOUGH
	zombie.health = VERY_TOUGH
	return zombie


## Seconds between the turret's shots over `seconds` of siege (0 = fewer than 2 shots).
func _shot_gap(turret: SiegeTurret, seconds: float) -> float:
	var times: Array[float] = []
	turret.weapon.fired.connect(func() -> void: times.append(siege.elapsed))
	await wait_seconds(seconds)
	if times.size() < 2:
		return 0.0
	return (times[-1] - times[0]) / (times.size() - 1)


func test_ac78_the_armory_fires_the_heros_starting_weapon() -> void:
	siege = await _start_siege({"toy_box_armory": 1, "lucky_jar": 1})
	var start_weapon: WeaponStats = first_player().starting_weapon
	assert_true(siege.turrets.has(ARMORY), "the built armory is a turret")
	if not siege.turrets.has(ARMORY):
		return
	var turret: SiegeTurret = siege.turrets[ARMORY]
	assert_eq(turret.weapon.stats, start_weapon, "the hero's starting weapon")
	assert_eq(turret.weapon.level, 1, "at weapon Lv 1")
	assert_true(turret.weapon.is_turret())
	var near: Vector2 = Vector2(turret.position.x - 380.0, 760.0)
	siege.enemies.spawn(SHAMBLER, near)
	assert_true(await _wait_for_damage(ARMORY, 4.0), "it hits a zombie close by")
	var row: WeaponTallyEntry = _tally(ARMORY)
	assert_eq(row.display_name, "Toy Box Armory", "its own row in the weapon tally")
	assert_almost_eq(siege.enemies.tally.total_damage, row.damage, 0.01, "all from the armory")


func test_ac78_the_armorys_weapon_grows_with_its_level() -> void:
	siege = await _start_siege({"toy_box_armory": 3, "lucky_jar": 1})
	assert_eq(siege.turrets[ARMORY].weapon.level, 5, "Lv 3 armory fires a Lv 5 weapon")


func test_ac78_the_armory_ignores_zombies_out_of_range() -> void:
	siege = await _start_siege({"toy_box_armory": 1, "lucky_jar": 1})
	var turret: SiegeTurret = siege.turrets[ARMORY]
	var far: Vector2 = turret.position + Vector2(0.0, turret.weapon.mount_range + 150.0)
	var zombie: Zombie = siege.enemies.spawn(SHAMBLER, far)
	zombie.move_speed = 0.0
	var shots: Array[int] = []
	turret.weapon.fired.connect(func() -> void: shots.append(1))
	await wait_seconds(1.5)
	assert_eq(shots.size(), 0, "nothing to fire at in range")


func test_ac78_the_watchtower_pins_the_toughest_zombie() -> void:
	siege = await _start_siege({"watchtower": 1, "lucky_jar": 1})
	assert_true(siege.turrets.has(TOWER), "the built watchtower is a turret")
	if not siege.turrets.has(TOWER):
		return
	var turret: SiegeTurret = siege.turrets[TOWER]
	assert_true(turret.weapon is TowerPin)
	var small: Zombie = siege.enemies.spawn(SHAMBLER, turret.position + Vector2(-350.0, 0.0))
	var tank: Zombie = _tough(TANK, turret.position + Vector2(420.0, -120.0))
	small.move_speed = 0.0
	tank.move_speed = 0.0
	assert_true(await _wait_for_damage(TOWER, 4.0), "it fires")
	assert_lt(tank.health, VERY_TOUGH, "at the toughest zombie")
	assert_eq(small.health, small.max_health, "not at the weaker one")
	assert_eq(_tally(TOWER).display_name, "Watchtower")


func test_ac78_a_new_watchtower_fires_every_two_seconds() -> void:
	siege = await _start_siege({"watchtower": 1, "lucky_jar": 1})
	var slow: SiegeTurret = siege.turrets[TOWER]
	var tank: Zombie = _tough(TANK, slow.position + Vector2(400.0, 0.0))
	tank.move_speed = 0.0
	assert_almost_eq(await _shot_gap(slow, 5.0), 2.0, 0.1, "Lv 1: one pin every 2 s")


func test_ac78_a_maxed_watchtower_fires_every_second() -> void:
	siege = await _start_siege({"watchtower": 3, "lucky_jar": 1})
	var fast: SiegeTurret = siege.turrets[TOWER]
	var tank: Zombie = _tough(TANK, fast.position + Vector2(400.0, 0.0))
	tank.move_speed = 0.0
	assert_almost_eq(await _shot_gap(fast, 4.0), 1.0, 0.1, "Lv 3: one pin every second")


func test_ac78_a_knocked_down_building_stops_firing() -> void:
	siege = await _start_siege({"toy_box_armory": 1, "lucky_jar": 1})
	var armory: SiegeBuilding = siege.targets.building(ARMORY)
	var turret: SiegeTurret = siege.turrets[ARMORY]
	armory.hurt(armory.max_health)
	await wait_physics_frames(1)
	assert_false(turret.is_firing(), "knocked down: it stops")
	var zombie: Zombie = siege.enemies.spawn(SHAMBLER, turret.position + Vector2(-300.0, 0.0))
	zombie.move_speed = 0.0
	await wait_seconds(1.5)
	assert_null(_tally(ARMORY), "no damage from a fallen armory")


func test_ac78_damaged_and_unbuilt_buildings_dont_fire() -> void:
	main.town.damaged = PackedStringArray(["toy_box_armory"])
	siege = await _start_siege({"toy_box_armory": 2, "lucky_jar": 1})
	assert_false(siege.turrets.has(ARMORY), "a damaged armory doesn't fire")
	assert_false(siege.turrets.has(TOWER), "a ruined watchtower doesn't fire")
	assert_true(siege.turrets.is_empty(), "the Lucky Jar is no turret")
