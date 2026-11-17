extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §4, §5, AC-77, AC-78 Lucky Jar): in the siege, zombies on their way to the
## fort turn to a built building close by and knock at it; a hurt building shows a small health
## bar, and at 0 it is knocked down (tipped over) and the horde walks on to the fort. The Lucky
## Jar pulls zombies from further away. Ruins and damaged buildings stand still: the horde
## ignores them.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ARMORY: StringName = &"toy_box_armory"
const JAR: StringName = &"lucky_jar"
const TOWER: StringName = &"watchtower"
const PARTY_SHOP: StringName = &"party_shop"

var siege: Siege


## Presses E at the door of a town with `levels` and the horde due; returns the siege with no
## waves coming, the hero unhurt and unarmed (only test zombies).
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


func _look(id: StringName) -> TownBuilding:
	return siege.town_arena().buildings[id]


## Waits up to `seconds` until `target` took damage.
func _wait_until_hurt(target: SiegeTarget, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if target.health < target.max_health:
			return true
		await wait_physics_frames(1)
	return false


func test_ac77_a_building_on_the_way_is_attacked_and_knocked_down() -> void:
	siege = await _start_siege({"toy_box_armory": 1, "lucky_jar": 1})
	var armory: SiegeBuilding = siege.targets.building(ARMORY)
	assert_not_null(armory, "the built armory fights along")
	if armory == null:
		return
	var spot: Rect2 = armory.rect
	var zombie: Zombie = siege.enemies.spawn(SHAMBLER, Vector2(spot.position.x - 60.0, 760.0))
	assert_true(await _wait_until_hurt(armory, 4.0), "it turns to the armory and knocks at it")
	assert_eq(siege.fort.health, siege.fort.max_health, "the fort is left alone meanwhile")
	await wait_physics_frames(1)
	assert_true(siege.building_bars[ARMORY].visible, "a small health bar while hurt")
	armory.hurt(armory.max_health)
	await wait_physics_frames(1)
	assert_true(_look(ARMORY).knocked_down, "knocked down: it tips over")
	assert_false(siege.building_bars[ARMORY].visible, "no bar on a fallen building")
	assert_false(siege.over, "a building falling doesn't end the siege")
	var before: float = TownLayout.distance_to(siege.layout.fort_rect, zombie.position)
	await wait_seconds(4.0)
	var after: float = TownLayout.distance_to(siege.layout.fort_rect, zombie.position)
	assert_lt(after, before - 20.0, "the zombie walks on (around it) to the fort")


func test_ac77_the_lucky_jar_pulls_zombies_from_further_away() -> void:
	siege = await _start_siege({"toy_box_armory": 1, "lucky_jar": 1})
	var jar: SiegeBuilding = siege.targets.building(JAR)
	assert_not_null(jar)
	if jar == null:
		return
	# 180 px above the jar: a normal building would not draw it from here (110 px).
	var at: Vector2 = Vector2(jar.rect.get_center().x, jar.rect.position.y - 180.0)
	assert_gt(TownLayout.distance_to(jar.rect, at), siege.siege_rules.building_reach)
	siege.enemies.spawn(SHAMBLER, at)
	assert_true(await _wait_until_hurt(jar, 8.0), "it goes for the jar")
	assert_eq(siege.fort.health, siege.fort.max_health, "not for the fort")


func test_ac78_ruins_and_damaged_buildings_stand_still() -> void:
	main.town.damaged = PackedStringArray(["watchtower"])
	siege = await _start_siege({"toy_box_armory": 1, "lucky_jar": 1, "watchtower": 2})
	assert_not_null(siege.targets.building(ARMORY))
	assert_null(siege.targets.building(TOWER), "a damaged building doesn't fight")
	assert_null(siege.targets.building(PARTY_SHOP), "a ruin doesn't fight")
	assert_false(siege.building_bars.has(TOWER), "no health bar on it")
	assert_false(siege.building_bars.has(PARTY_SHOP))
	var tower: Rect2 = siege.layout.spots[2].rect
	var next_to_it: Zombie = siege.enemies.spawn(SHAMBLER, Vector2(tower.get_center().x, 270.0))
	await wait_physics_frames(2)
	assert_eq(siege.targets.goal_for(next_to_it, null), siege.fort, "it walks past to the fort")
	assert_false(_look(TOWER).knocked_down)
