extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §5, AC-97): the Sewing Workshop is the 7th building. Until the town owns a
## gear pattern its spot is empty quilt (nothing drawn, nothing blocks); the first pattern brings
## its ruin with "New building!" (after a Lv 2 build and on arrival). It builds to Lv 3 like the
## other buildings and its levels open the Charm slot and stitch levels 2 and 3. In the night
## siege it is a normal target with health and no turret; damaged, it still lets you wear what
## you sewed but not sew or stitch until it's repaired.

const RICH: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 999}
const WORKSHOP: StringName = &"sewing_workshop"

var town: Town


func _rules() -> GearRules:
	return GearRules.current()


func _workshop() -> TownBuilding:
	return town.buildings[WORKSHOP]


func _wait_for_banner(title: String, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if town.is_banner_showing() and town.banner_title.text == title:
			return true
		await wait_physics_frames(1)
	return false


func _wait_until_calm(seconds: float) -> void:
	for i: int in roundi(seconds * FPS):
		if not town.is_settling():
			return
		await wait_physics_frames(1)


func test_ac97_without_a_pattern_the_spot_is_empty_quilt() -> void:
	main.town.building_levels["toy_box_armory"] = 1
	main.town.building_levels["lucky_jar"] = 1
	town = await go_to_town()
	await _wait_until_calm(4.0)
	var workshop: TownBuilding = _workshop()
	assert_true(workshop.waiting_for_reveal, "waits for a pattern")
	assert_false(workshop.is_visible_in_tree(), "nothing drawn")
	assert_false(main.town.revealed.has(String(WORKSHOP)))
	var spot: Rect2 = workshop.spot.rect
	assert_false(town.layout.blocking_rects(main.town).has(spot), "nothing blocks there")
	var hero: Player = first_player()
	hero.global_position = spot.get_center()
	await wait_physics_frames(3)
	assert_lt(hero.global_position.distance_to(spot.get_center()), 4.0, "the hero can stand there")
	assert_null(town.building_near(hero), "no card, no E")


func test_ac97_the_first_pattern_from_a_lv_2_build_brings_the_workshop() -> void:
	main.town.materials = RICH.duplicate()
	main.town.building_levels["toy_box_armory"] = 1
	town = await go_to_town()
	assert_true(town.try_build(town.buildings[&"toy_box_armory"]), "Armory to Lv 2")
	assert_true(await _wait_for_banner("New pattern: Pin Cushion Hat!", 6.0), "pattern first")
	assert_true(_workshop().waiting_for_reveal, "the Workshop waits for that banner")
	assert_true(await _wait_for_banner("New building!", 8.0), "then the new building")
	assert_string_contains(town.banner_subtitle.text, "Sewing Workshop")
	assert_false(_workshop().waiting_for_reveal)
	assert_true(_workshop().is_visible_in_tree(), "its ruin stands there now")
	assert_true(_workshop().unlocked, "and can be rebuilt")
	assert_eq(_workshop().shown_level, 0, "as a ruin")
	assert_true(SaveStore.read().revealed.has(String(WORKSHOP)), "saved")
	var spot: Rect2 = _workshop().spot.rect
	assert_true(town.layout.blocking_rects(main.town).has(spot), "it blocks like the others")


func test_ac97_it_builds_to_lv_3_and_opens_the_charm_slot_and_stitch_levels() -> void:
	main.town.materials = RICH.duplicate()
	main.town.gear.patterns.append("raincoat")
	town = await go_to_town()
	var shown: bool = await _wait_for_banner("New building!", 6.0)
	assert_true(shown, "a found pattern brings it on arrival")
	await _wait_until_calm(4.0)
	var workshop: TownBuilding = _workshop()
	assert_eq(GearBook.stitch_cap(main.town), 0, "nothing to sew at a ruin")
	var caps: Array[int] = []
	var charm: Array[bool] = []
	var body: Array[bool] = []
	for level: int in range(1, 4):
		var coins: int = main.town.material("coins")
		assert_true(town.try_build(workshop), "Workshop to Lv %d" % level)
		assert_lt(main.town.material("coins"), coins, "paid for Lv %d" % level)
		assert_eq(SaveStore.read().building_level(String(WORKSHOP)), level, "saved")
		caps.append(GearBook.stitch_cap(main.town))
		body.append(GearBook.slot_open(main.town, GearDef.Slot.BODY))
		charm.append(GearBook.slot_open(main.town, GearDef.Slot.CHARM))
		await _wait_until_calm(4.0)
		assert_eq(workshop.shown_level, level, "the look grows")
	assert_eq(caps, [1, 2, 3] as Array[int], "stitch levels open with the Workshop's levels")
	assert_eq(body, [true, true, true] as Array[bool], "Head and Body from Lv 1")
	assert_eq(charm, [false, true, true] as Array[bool], "Charm slot at Lv 2")
	assert_null(workshop.building.next(workshop.level), "Lv 3 is the top")
	assert_false(town.try_build(workshop), "nothing more to build")


func test_ac97_a_damaged_workshop_lets_you_wear_but_not_sew() -> void:
	main.town.materials = RICH.duplicate()
	main.town.gear.patterns.append_array(PackedStringArray(["raincoat", "lookout_cap"]))
	main.town.revealed.append(String(WORKSHOP))
	main.town.building_levels[String(WORKSHOP)] = 2
	assert_true(GearBook.sew(main.town, _rules().find("raincoat")), "sewn while it stands")
	main.town.damaged = PackedStringArray([String(WORKSHOP)])
	town = await go_to_town()
	assert_true(_workshop().damaged, "it shows the damage")
	assert_eq(GearBook.stitch_cap(main.town), 0, "no sewing or stitching")
	assert_false(GearBook.sew(main.town, _rules().find("lookout_cap")), "can't sew")
	assert_false(GearBook.sew(main.town, _rules().find("raincoat")), "can't stitch")
	assert_true(GearBook.take_off(main.town, 0, GearDef.Slot.BODY))
	assert_true(GearBook.wear(main.town, _rules().find("raincoat"), 0), "but can wear")
	town.interact(_workshop())
	assert_false(main.town.is_damaged(String(WORKSHOP)), "E repairs it")
	assert_eq(GearBook.stitch_cap(main.town), 2, "and sewing works again")


func test_ac97_in_the_siege_it_is_a_target_with_health_and_no_turret() -> void:
	main.town.gear.patterns.append("raincoat")
	main.town.revealed.append(String(WORKSHOP))
	main.town.building_levels = {"toy_box_armory": 1, "sewing_workshop": 2}
	main.town.siege_nights = 0
	town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	assert_not_null(siege, "the horde came")
	var target: SiegeBuilding = siege.targets.building(WORKSHOP)
	assert_not_null(target, "the Workshop fights along")
	var lv2: BuildingLevel = siege.layout.spot(WORKSHOP).building.reached(2)
	assert_eq(target.max_health, lv2.siege_health, "health from its level")
	assert_gt(target.max_health, 0.0)
	assert_false(siege.turrets.has(WORKSHOP), "no turret")
	assert_false(siege.rings.has(WORKSHOP), "no ring or trap")
	assert_true(siege.turrets.has(&"toy_box_armory"), "the Armory still shoots")


func test_ac97_before_a_pattern_the_siege_has_no_workshop() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	assert_false(siege.town_arena().buildings.has(WORKSHOP), "no ruin at dusk either")
	var spot: Rect2 = siege.layout.spot(WORKSHOP).rect
	assert_false(siege.enemies.obstacles.rects.has(spot), "zombies walk over the empty spot")
