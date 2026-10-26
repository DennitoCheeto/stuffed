extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 05 §3.3, AC-61): less text, more town. A built building shows no text until a
## player walks up (the info card does that job); an open ruin keeps a small price tag; a golden
## "Can build!" tag floats over a building exactly while the jars can pay for its next level.


## Puts Banane at the fort door, away from every building.
func _stand_at_door(town: Town) -> void:
	first_player().global_position = town.layout.door_rect.get_center()
	await wait_physics_frames(2)


## Puts Banane right below `id`'s spot (in reach) and returns its building.
func _stand_at(town: Town, id: StringName) -> TownBuilding:
	var building: TownBuilding = town.buildings[id]
	var rect: Rect2 = building.spot.rect
	first_player().global_position = Vector2(rect.get_center().x, rect.end.y + 40.0)
	await wait_physics_frames(2)
	return building


func _settle(town: Town) -> void:
	for i: int in roundi(4.0 * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func test_ac61_a_built_building_shows_no_text_until_a_player_walks_up() -> void:
	main.town.building_levels["toy_box_armory"] = 1
	var town: Town = await go_to_town()
	await _stand_at_door(town)
	var armory: TownBuilding = town.buildings[&"toy_box_armory"]
	assert_eq(armory.shown_texts(), PackedStringArray(), "no name, level or effect text")
	assert_false(armory.price_tag.visible, "built: no price tag")
	assert_false(town.card.visible, "nobody next to it: no card")
	await _stand_at(town, &"toy_box_armory")
	assert_true(town.card.visible, "walking up shows the info card")
	assert_eq(town.card.building, armory)
	assert_string_contains(town.card.now_label.text, armory.building.effect_at(1))


func test_ac61_an_open_ruin_shows_its_price_tag_a_locked_one_only_its_yarn() -> void:
	var town: Town = await go_to_town()
	await _stand_at_door(town)
	var jar: TownBuilding = town.buildings[&"lucky_jar"]
	var cost: int = jar.building.levels[0].coins
	assert_true(jar.price_tag.visible, "the open ruin has a price tag")
	assert_eq(jar.cost_counters["coins"].shown, cost, "with the price of level 1")
	assert_true(jar.is_short_of("coins"), "grey: the jars are empty")
	assert_eq(jar.shown_texts(), PackedStringArray([str(cost)]), "only the price, no name")
	var tower: TownBuilding = town.buildings[&"watchtower"]
	assert_false(tower.unlocked, "the Watchtower starts locked")
	assert_false(tower.price_tag.visible, "a locked ruin has no price tag")
	assert_eq(tower.shown_texts(), PackedStringArray(), "and no text at all")


func test_ac61_can_build_shows_exactly_while_the_next_level_is_affordable() -> void:
	var jar_cost: int = 200
	main.town.materials["coins"] = jar_cost + 30
	var town: Town = await go_to_town()
	await _stand_at_door(town)
	var jar: TownBuilding = town.buildings[&"lucky_jar"]
	var armory: TownBuilding = town.buildings[&"toy_box_armory"]
	assert_eq(jar.building.levels[0].coins, jar_cost, "test set-up matches the data")
	assert_true(armory.building.levels[0].coins > jar_cost + 30, "the Armory costs more")
	assert_true(jar.shows_can_build(), "the jars can pay for the Lucky Jar")
	assert_true(jar.shown_texts().has(TownBuilding.CAN_BUILD_TEXT))
	assert_false(armory.shows_can_build(), "but not for the Armory")
	assert_false(town.buildings[&"watchtower"].shows_can_build(), "locked: never")
	var jar_top: float = jar.spot.rect.end.y + jar.shown_look().bounds().position.y
	assert_lt(jar.can_build_tag.position.y + jar.can_build_tag.size.y, jar_top, "over the drawing")
	await _stand_at(town, &"lucky_jar")
	assert_false(jar.shows_can_build(), "steps aside for the info card")
	await tap_action("p1_interact")
	await wait_physics_frames(1)
	assert_eq(main.town.building_level("lucky_jar"), 1, "built")
	await _stand_at_door(town)
	assert_false(jar.shows_can_build(), "gone during the build moment")
	await _settle(town)
	await wait_physics_frames(1)
	assert_false(jar.shows_can_build(), "gone after building (level 2 costs more)")
	assert_false(armory.shows_can_build(), "still too little for the Armory")
	main.town.materials["coins"] = 5000
	town.refresh()
	await wait_physics_frames(1)
	assert_true(armory.shows_can_build(), "shows as soon as the jars can pay")
	assert_false(armory.can_build_tag.position.y > armory.spot.rect.end.y, "above, not below")
	main.town.materials["coins"] = 0
	town.refresh()
	await wait_physics_frames(1)
	assert_false(armory.shows_can_build(), "gone when the jars can't pay any more")
