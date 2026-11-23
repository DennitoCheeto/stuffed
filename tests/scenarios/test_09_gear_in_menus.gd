extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §6, §7, AC-100, AC-100b, AC-104; changed by #331): gear is not drawn on any
## hero (town, run) and costs the hero no draws; the sewing table shows the worn pieces as
## pictures beside the photo, the Wardrobe picker under each unlocked hero's photo, and they stay
## worn after a Wardrobe swap. The Patch Vest and Wind-up Key show their state as small icons
## under each hero's own bar. The hide toggles and the hide key are gone; an older save with
## hidden slots still loads and its gear still works.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const RICH: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 999}
const WORKSHOP: String = "sewing_workshop"
const HEAD: StringName = &"lookout_cap"
const BODY: StringName = &"patch_vest"
const CHARM: StringName = &"jingle_bell"


## Player 1 wears the cap, vest and bell (stitched to `level`) at a Workshop Lv 2; `hero` is
## played (unlocked).
func _dress_save(level: int = 1, hero: String = "banane") -> void:
	var save: TownSave = main.town
	save.building_levels[WORKSHOP] = 2
	save.revealed.append(WORKSHOP)
	save.materials = RICH.duplicate()
	for id: StringName in [HEAD, BODY, CHARM]:
		_put_on(0, id, level)
	if hero != "banane":
		save.plushies[hero] = "in_town"
		save.revealed.append(WardrobeRules.REVEALED_ID)
		save.revealed.append(WardrobeRules.HERO_PREFIX + hero)
		save.set_hero(0, hero)


func _put_on(player: int, id: StringName, level: int) -> void:
	var save: TownSave = main.town
	save.gear.add_pattern(String(id))
	save.gear.stitches[String(id)] = level
	save.gear.put_on(player, String(GearRules.current().find(String(id)).slot_name()), String(id))


func _arrive() -> Town:
	var town: Town = await go_to_town()
	await wait_physics_frames(3)
	while town.is_settling():
		await wait_physics_frames(1)
	return town


## Canvas items under `root` drawn in the world (baked pictures live in their own viewports).
func _drawn_pieces(root: Node) -> int:
	var count: int = 0
	for node: Node in root.find_children("*", "CanvasItem", true, false):
		if node.get_viewport() == root.get_viewport() and (node as CanvasItem).is_visible_in_tree():
			count += 1
	return count


## The ids of the pictures in `box` (GearPicture children), in order.
func _picture_ids(box: Node) -> Array[StringName]:
	var ids: Array[StringName] = []
	for child: Node in box.get_children():
		var picture: GearPicture = child as GearPicture
		if picture != null and not picture.is_queued_for_deletion():
			ids.append(picture.piece.id)
	return ids


func test_ac100_no_hero_draws_its_gear_and_a_wardrobe_swap_keeps_it() -> void:
	_dress_save()
	for hero: HeroStats in HEROES.heroes:
		if hero.plushie != null:
			main.town.plushies[String(hero.plushie.id)] = "in_town"
	var town: Town = await _arrive()
	for hero: HeroStats in HEROES.heroes:
		town.wardrobe.swap(0, hero)
		await wait_physics_frames(1)
		var player: Player = first_player()
		assert_eq(player.stats, hero)
		assert_eq(player.gear.pieces.size(), 3, "%s still wears all three" % hero.id)
		var puppet: Node = player.get_node("Puppet")
		assert_null(puppet.get_node_or_null(^"Gear"), "%s: no gear on the puppet" % hero.id)
		assert_false(&"gear_view" in puppet, "puppets have no gear view any more")


func test_ac104_full_gear_costs_the_hero_no_draws() -> void:
	_dress_save(3, "pip")
	var run: Run = await start_run()
	run.spawner.active = false
	var geared: Player = first_player()
	assert_eq(geared.gear.pieces.size(), 3)
	var plain: Player = PLAYER_SCENE.instantiate() as Player
	plain.stats = geared.stats
	plain.player_index = 1
	run.actors.add_child(plain)
	await wait_physics_frames(1)
	var with_gear: int = _drawn_pieces(geared.get_node("Puppet"))
	assert_eq(with_gear, _drawn_pieces(plain.get_node("Puppet")), "the same puppet with or without")
	plain.queue_free()


func test_ac100_the_sewing_table_shows_the_worn_pieces_beside_the_photo() -> void:
	_dress_save(2)
	var town: Town = await _arrive()
	town.sewing.open(town.buildings[StringName(WORKSHOP)], 0)
	await wait_physics_frames(1)
	var table: SewingTable = town.sewing.table
	var shown: Array[StringName] = []
	for slot: int in 3:
		shown.append_array(_picture_ids(table.slot_pictures[slot]))
	assert_eq(shown, [HEAD, BODY, CHARM] as Array[StringName], "one picture per slot")
	var cap: GearPicture = table.slot_pictures[GearDef.Slot.HEAD].get_child(0) as GearPicture
	assert_eq(cap.level, 2, "with its stitch level")
	assert_false(cap.locked)
	assert_null(table.get(&"eye_toggles"), "no hide toggles any more")
	assert_false(KeyBindings.ACTIONS.has("hide_gear"), "no hide key any more")
	table.close()


func test_ac100_the_wardrobe_picker_shows_them_under_each_unlocked_photo() -> void:
	_dress_save(1, "pip")
	var town: Town = await _arrive()
	town.wardrobe.open(0)
	await wait_physics_frames(1)
	var picker: HeroPicker = town.wardrobe.picker
	for hero: HeroStats in HEROES.heroes:
		var unlocked: bool = hero.plushie == null or hero.id == &"pip"
		assert_eq(picker.gear_rows.has(hero.id), unlocked, "a row under %s" % hero.id)
		if unlocked:
			var ids: Array[StringName] = _picture_ids(picker.gear_rows[hero.id])
			assert_eq(ids, [HEAD, BODY, CHARM] as Array[StringName], String(hero.id))
	picker.close()


func test_ac100_nothing_worn_no_pictures_on_the_picker() -> void:
	main.town.plushies["pip"] = "in_town"
	main.town.revealed.append(WardrobeRules.REVEALED_ID)
	main.town.revealed.append(WardrobeRules.HERO_PREFIX + "pip")
	var town: Town = await _arrive()
	town.wardrobe.open(0)
	await wait_physics_frames(1)
	for id: StringName in town.wardrobe.picker.gear_rows:
		assert_false(town.wardrobe.picker.gear_rows[id].visible, "no empty row under %s" % id)
	town.wardrobe.picker.close()


func test_ac100b_patch_and_key_icons_sit_under_each_heros_own_bar() -> void:
	main.town.building_levels[WORKSHOP] = 3
	_put_on(0, BODY, 1)
	_put_on(1, &"wind_up_key", 1)
	main.player_count = 2
	add_controls(1)
	var run: Run = await start_run()
	run.rescue_plan = null
	var heroes: Array[Player] = Players.all(get_tree())
	var one: Node = heroes[0].get_node("Overlay")
	var two: Node = heroes[1].get_node("Overlay")
	assert_not_null(one.call(&"patch_icon"), "player 1's patch icon")
	assert_null(one.call(&"key_icon"), "player 1 has no key")
	assert_null(two.call(&"patch_icon"))
	assert_not_null(two.call(&"key_icon"), "player 2's key icon")


func test_ac100b_an_older_save_with_hidden_slots_loads_and_its_gear_works() -> void:
	_dress_save()
	main.town.gear.hidden.append(PackedStringArray(["head", "body", "charm"]))
	main.save_now()
	main.load_town()
	assert_eq(main.town.gear.hidden[0].size(), 3, "kept in the save, nothing lost")
	await start_run()
	var player: Player = first_player()
	assert_eq(player.gear.pieces.size(), 3, "all three worn and working")
	assert_not_null(player.get_node_or_null(^"PatchVest"), "the vest's effect is on")
