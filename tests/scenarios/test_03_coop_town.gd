extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 03 §10, AC-48, hard rule 11): with two players both walk in town and both can
## rebuild; kills by either player go into the one shared haul; the Way Home portal takes both
## home, and both walk in town again.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const MATERIALS: MaterialRules = preload("res://data/town/material_rules.tres")
const WAY_HOME: WayHomeRules = preload("res://data/town/way_home_rules.tres")
const PLENTY: Dictionary[String, int] = {"coins": 9000, "stuffing": 300, "thread": 60}


func _player(index: int) -> Player:
	for player: Player in Players.all(get_tree()):
		if player.player_index == index:
			return player
	return null


## Puts `player` right below `id`'s spot (in reach) and returns its building.
func _stand_at(town: Town, player: Player, id: StringName) -> TownBuilding:
	var building: TownBuilding = town.buildings[id]
	var rect: Rect2 = building.spot.rect
	player.global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	return building


## A town with two players (as if both just came home together).
func _coop_town() -> Town:
	main.player_count = 2
	add_controls(1)
	return await go_to_town()


## Waits until the run's haul holds at least `coins` coins (kills happen through weapons). XP
## buttons are cleared on the way so no level-up freezes the run.
func _wait_for_coins(run: Run, coins: int) -> void:
	for i: int in roundi(10.0 * FPS):
		for button: XpButton in run.pickups.buttons:
			button.queue_free()
		run.pickups.buttons.clear()
		if run.haul.amount("coins") >= coins:
			return
		await wait_physics_frames(1)


func test_ac48_both_players_walk_in_town() -> void:
	var town: Town = await _coop_town()
	assert_eq(Players.all(get_tree()).size(), 2, "two players at home")
	var first: Player = _player(0)
	var second: Player = _player(1)
	assert_false(second.armed, "nobody carries weapons at home")
	var first_start: Vector2 = first.global_position
	var second_start: Vector2 = second.global_position
	await hold_action("p2_move_down", 30)
	assert_gt(second.global_position.y, second_start.y + 20.0, "player 2 walks")
	assert_almost_eq(first.global_position, first_start, Vector2.ONE, "player 1 stays")
	await hold_action("p1_move_down", 30)
	assert_gt(first.global_position.y, first_start.y + 20.0, "player 1 walks too")
	assert_not_null(town)


func test_ac48_both_players_can_rebuild_from_the_shared_jars() -> void:
	main.town.materials = PLENTY.duplicate()
	var town: Town = await _coop_town()
	var armory: TownBuilding = await _stand_at(town, _player(1), &"toy_box_armory")
	await tap_action("p2_interact")
	await wait_physics_frames(1)
	assert_eq(main.town.building_level("toy_box_armory"), 1, "player 2 rebuilt the Armory")
	var cost: int = armory.building.levels[0].coins
	assert_eq(main.town.material("coins"), PLENTY["coins"] - cost, "paid from the shared jars")
	_player(1).global_position = town.layout.spawn_position
	await _stand_at(town, _player(0), &"lucky_jar")
	await tap_action("p1_interact")
	await wait_physics_frames(1)
	assert_eq(main.town.building_level("lucky_jar"), 1, "player 1 rebuilt the Lucky Jar")


func test_ac48_kills_by_both_go_into_one_haul_and_the_portal_takes_both_home() -> void:
	main.player_count = 2
	var run: Run = await start_run()
	run.spawner.active = false
	run.floor_pickup_drops.next_drop_at = INF
	run.rescue_plan = null
	var first: Player = _player(0)
	var second: Player = _player(1)
	assert_not_null(second, "both players start the run")
	first.invincible = true
	second.invincible = true
	var coins: int = MATERIALS.kill_reward("Shambler").coins
	# Player 2 alone has weapons: the kill is theirs.
	disarm(first)
	run.enemies.spawn(SHAMBLER, second.global_position + Vector2(120, 0))
	await _wait_for_coins(run, coins)
	assert_eq(run.haul.amount("coins"), coins, "player 2's kill is in the haul")
	# Now only player 1 has weapons.
	first.add_weapon(first.starting_weapon)
	disarm(second)
	run.enemies.spawn(SHAMBLER, first.global_position + Vector2(-120, 0))
	await _wait_for_coins(run, 2 * coins)
	assert_eq(run.haul.amount("coins"), 2 * coins, "player 1's kill joins the same haul")
	disarm(first)
	var portal: WayHomePortal = run.open_way_home(first.global_position + Vector2(0, 300))
	second.global_position = portal.position
	second.velocity = Vector2.ZERO
	await wait_seconds(WAY_HOME.fill_seconds + 0.3)
	assert_true(main.current_screen is EndScreen, "one player in the portal ends the run")
	assert_eq(main.town.material("coins"), 2 * coins, "both kills are in the town's jars")
	var town: Town = await go_to_town()
	assert_not_null(town)
	assert_eq(Players.all(get_tree()).size(), 2, "both came home")
