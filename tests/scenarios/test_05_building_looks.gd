extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 05 §2.2, §3.2, AC-60): in the real town, every building (the Toy Box Armory and
## the Lucky Jar by pressing E, the other four through the dev build) stands as its broken object
## while it is a ruin; building a level shows that level's own look with the build moment (a ruin
## shakes first, an upgrade pops up), up to level 3. The fort grows its pieces; all have felt grain.

const PLENTY: Dictionary[String, int] = {"coins": 9000, "stuffing": 300, "thread": 60}


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


func _look(building: TownBuilding, level: int) -> BuildingSketch:
	return BuildingLooks.sketch(building.building, level)


func test_ac60_a_ruin_shows_its_broken_object() -> void:
	var town: Town = await go_to_town()
	for id: StringName in [&"toy_box_armory", &"lucky_jar"]:
		var building: TownBuilding = town.buildings[id]
		assert_eq(building.level, 0)
		assert_same(building.shown_look(), _look(building, 0), "%s stands as a ruin" % id)
		assert_true(building.shown_look().greyed)
		var felt: ShaderMaterial = building.material as ShaderMaterial
		assert_not_null(felt, "%s has the felt grain" % id)
		if felt != null:
			assert_eq(felt.shader, WorldPalette.FELT_SHADER)


func test_ac60_each_build_shows_the_new_look_after_the_moment() -> void:
	main.town.materials = PLENTY.duplicate()
	var town: Town = await go_to_town()
	for id: StringName in [&"toy_box_armory", &"lucky_jar"]:
		var building: TownBuilding = await _stand_at(town, id)
		for level: int in range(1, 4):
			await tap_action("p1_interact")
			await wait_physics_frames(1)
			assert_eq(building.level, level, "%s paid for level %d" % [id, level])
			assert_true(building.is_busy(), "the build moment plays")
			if level == 1:
				assert_same(building.shown_look(), _look(building, 0), "the ruin shakes first")
			else:
				assert_lt(building.pop_scale(), 1.0, "the new look pops up from smaller")
			await _settle(town)
			assert_false(building.is_busy())
			var wanted: BuildingSketch = _look(building, level)
			assert_same(building.shown_look(), wanted, "%s Lv %d look" % [id, level])
		assert_eq(main.town.building_level(String(id)), 3)


func test_ac60_a_built_building_comes_back_with_its_look() -> void:
	main.town.building_levels["lucky_jar"] = 2
	main.town.building_levels["toy_box_armory"] = 3
	var town: Town = await go_to_town()
	var jar: TownBuilding = town.buildings[&"lucky_jar"]
	var armory: TownBuilding = town.buildings[&"toy_box_armory"]
	assert_same(jar.shown_look(), _look(jar, 2))
	assert_same(armory.shown_look(), _look(armory, 3))
	assert_false(jar.shown_look().greyed)


func test_ac60_the_other_four_grow_with_the_build_moment() -> void:
	var town: Town = await go_to_town()
	for id: StringName in [&"watchtower", &"snack_bar", &"party_shop", &"plush_hospital"]:
		var building: TownBuilding = town.buildings[id]
		assert_same(building.shown_look(), _look(building, 0), "%s stands as a ruin" % id)
		assert_true(building.shown_look().greyed, "%s ruin is greyed" % id)
		for level: int in range(1, 4):
			assert_true(town.dev_build(building), "%s builds level %d" % [id, level])
			assert_true(building.is_busy(), "the build moment plays")
			if level == 1:
				assert_same(building.shown_look(), _look(building, 0), "the ruin shakes first")
			else:
				assert_lt(building.pop_scale(), 1.0, "the new look pops up from smaller")
			await _settle(town)
			await _wait_still(building)
			var wanted: BuildingSketch = _look(building, level)
			assert_same(building.shown_look(), wanted, "%s Lv %d look" % [id, level])


func test_ac60_the_fort_and_the_scrapbook_stand_wear_the_kit() -> void:
	var town: Town = await go_to_town()
	assert_eq(town.fort.pieces, 0)
	assert_false(town.fort.look().parts.has(&"flag"))
	assert_not_null(town.fort.material, "the fort has the felt grain")
	assert_not_null(town.scrapbook.material, "the stand has the felt grain")
	assert_has(ScrapbookStand.look().parts, &"book")
	var jar: TownBuilding = town.buildings[&"lucky_jar"]
	for level: int in 3:
		town.dev_build(jar)
		await _settle(town)
		await _wait_still(jar)
	assert_eq(town.fort.pieces, 1, "a new piece after 3 builds")
	assert_has(town.fort.look().parts, &"flag", "the fort shows its flag")


func _wait_still(building: TownBuilding) -> void:
	for i: int in roundi(3.0 * FPS):
		if not building.is_busy():
			return
		await wait_physics_frames(1)
