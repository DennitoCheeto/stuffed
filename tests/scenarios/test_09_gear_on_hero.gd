extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §6, §7, AC-100, AC-100b): worn pieces show on the hero in the town, the
## Bedroom and on the photos, at that hero's anchors, moving with the puppet (squash, lean,
## flash), with one more detail per stitch level, and they stay on after a Wardrobe swap. Each
## slot (and "Hide all") can be hidden on the sewing table (eye toggles, the hide key) and the
## Wardrobe picker: a hidden piece isn't drawn but still worn, and the choice is saved per player.

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
		save.gear.add_pattern(String(id))
		save.gear.stitches[String(id)] = level
		save.gear.put_on(0, String(GearRules.current().find(String(id)).slot_name()), String(id))
	if hero != "banane":
		save.plushies[hero] = "in_town"
		save.revealed.append(WardrobeRules.REVEALED_ID)
		save.revealed.append(WardrobeRules.HERO_PREFIX + hero)
		save.set_hero(0, hero)


func _arrive() -> Town:
	var town: Town = await go_to_town()
	await wait_physics_frames(3)
	while town.is_settling():
		await wait_physics_frames(1)
	return town


func _gear_of(player: Player) -> HeroGear:
	var puppet: Node = player.get_node("Puppet")
	return puppet.get("gear_view") as HeroGear


func _shown_ids(player: Player) -> Array[StringName]:
	var ids: Array[StringName] = []
	for piece: GearDef in _gear_of(player).worn.shown():
		ids.append(piece.id)
	return ids


## Canvas items under `root` drawn in the world (baked pictures live in their own viewports).
func _drawn_pieces(root: Node) -> int:
	var count: int = 0
	for node: Node in root.find_children("*", "CanvasItem", true, false):
		if node.get_viewport() == root.get_viewport() and (node as CanvasItem).is_visible_in_tree():
			count += 1
	return count


func test_ac100_banane_wears_his_gear_in_town_at_his_anchors() -> void:
	_dress_save()
	await _arrive()
	var player: Player = first_player()
	var gear: HeroGear = _gear_of(player)
	assert_eq(gear.sprites.size(), 3, "cap, vest and bell are drawn")
	var puppet: BananePuppet = player.get_node("Puppet") as BananePuppet
	var feet: Vector2 = player.global_position + HeroMarker.FEET
	for slot: int in 3:
		var sprite: Sprite2D = gear.sprite(slot as GearDef.Slot)
		assert_not_null(sprite)
		var want: Vector2 = feet + player.stats.gear_anchor(slot)
		# Banane breathes and tilts his head a little: within a few pixels of the anchor.
		assert_almost_eq(sprite.global_position.distance_to(want), 0.0, 4.0, "slot %d" % slot)
	assert_true(gear.sprite(GearDef.Slot.HEAD).get_parent() is FeltPiece, "the cap rides the head")
	assert_ne(
		gear.sprite(GearDef.Slot.HEAD).get_parent(),
		gear.sprite(GearDef.Slot.BODY).get_parent(),
		"the head moves on its own"
	)
	assert_true(puppet.is_ancestor_of(gear.picture), "baked once into one picture")


func test_ac100_every_hero_wears_it_and_a_wardrobe_swap_keeps_it() -> void:
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
		assert_eq(_shown_ids(player), [HEAD, BODY, CHARM] as Array[StringName], String(hero.id))
		assert_eq(_gear_of(player).sprites.size(), 3, String(hero.id))
		if hero.plushie == null:
			continue
		var puppet: PlushiePuppet = player.get_node("Puppet") as PlushiePuppet
		for slot: int in 3:
			var sprite: Sprite2D = _gear_of(player).sprite(slot as GearDef.Slot)
			assert_eq(sprite.get_parent(), puppet.body, "moves with the whole body")
			assert_eq(sprite.position, hero.gear_anchor(slot), "%s slot %d" % [hero.id, slot])


func test_ac100_the_gear_moves_squashes_and_flashes_with_the_puppet() -> void:
	_dress_save(1, "pip")
	var run: Run = await start_run()
	run.spawner.active = false
	await wait_seconds(0.5)
	var player: Player = first_player()
	var puppet: PlushiePuppet = player.get_node("Puppet") as PlushiePuppet
	var cap: Sprite2D = _gear_of(player).sprite(GearDef.Slot.HEAD)
	player.hurt.emit(5.0)
	await wait_physics_frames(2)
	assert_gt(puppet.flash(), 0.0, "the hero flashes")
	assert_eq(_gear_of(player).flash(), puppet.flash(), "and its gear with it")
	assert_ne(puppet.body.scale, Vector2.ONE, "the hit squashes the body")
	var body: Transform2D = puppet.body.get_global_transform()
	var want: Vector2 = body * cap.position
	assert_almost_eq(cap.global_position.distance_to(want), 0.0, 0.01, "the cap is squashed along")
	await wait_seconds(1.0)
	await tap_action("p1_dash")
	await wait_physics_frames(3)
	assert_ne(puppet.body.rotation, 0.0, "the dash leans the body")
	assert_almost_eq(cap.global_rotation, puppet.body.global_rotation, 0.001, "the cap leans too")


func test_ac100_each_stitch_level_shows_one_more_detail() -> void:
	_dress_save(1)
	await _arrive()
	var gear: HeroGear = _gear_of(first_player())
	var before: SubViewport = gear.picture
	var cap: GearDef = GearRules.current().find(String(HEAD))
	assert_eq(gear.worn.level_of(cap), 1)
	main.town.gear.stitches[String(HEAD)] = 3
	main.current_screen.refresh()
	assert_eq(gear.worn.level_of(cap), 3, "the hero wears the stitched cap")
	assert_ne(gear.picture, before, "baked again with the new detail")
	for piece: GearDef in GearRules.current().pieces:
		var plain: int = GearLook.colors(piece, 1).size()
		assert_gt(GearLook.colors(piece, 3).size(), plain, "%s Lv 3 adds a detail" % piece.id)
		var lv2: Array[PackedVector2Array] = GearLook.seams(piece.slot, 2, Vector2.ZERO, 24.0)
		var lv1: Array[PackedVector2Array] = GearLook.seams(piece.slot, 1, Vector2.ZERO, 24.0)
		var more: bool = lv2.size() > lv1.size() or GearLook.colors(piece, 2).size() > plain
		assert_true(more, "%s Lv 2 adds a detail" % piece.id)


func test_ac100_the_hero_wears_it_in_the_bedroom_too() -> void:
	_dress_save(2, "bobo")
	await start_run()
	var player: Player = first_player()
	assert_true(player.gear.has(HEAD))
	assert_eq(_gear_of(player).sprites.size(), 3)


func test_ac104_full_gear_costs_at_most_three_more_draws() -> void:
	_dress_save(3, "pip")
	var run: Run = await start_run()
	run.spawner.active = false
	var geared: Player = first_player()
	var plain: Player = PLAYER_SCENE.instantiate() as Player
	plain.stats = geared.stats
	plain.player_index = 1
	run.actors.add_child(plain)
	await wait_physics_frames(1)
	var with_gear: int = _drawn_pieces(geared.get_node("Puppet"))
	var without: int = _drawn_pieces(plain.get_node("Puppet"))
	assert_gt(with_gear, without, "the gear is drawn")
	assert_lte(with_gear, without + 3, "%d vs %d" % [with_gear, without])
	plain.queue_free()


func test_ac100_the_sewing_table_photo_wears_it() -> void:
	_dress_save()
	var town: Town = await _arrive()
	town.sewing.open(town.buildings[StringName(WORKSHOP)], 0)
	await wait_physics_frames(1)
	var photo: HeroPhoto = town.sewing.table.photo
	assert_eq(photo.shown_gear().size(), 3, "cap, vest and bell on the photo")
	town.sewing.table.close()


func test_ac100b_the_table_hides_a_slot_and_hide_all() -> void:
	_dress_save()
	var town: Town = await _arrive()
	town.sewing.open(town.buildings[StringName(WORKSHOP)], 0)
	await wait_physics_frames(1)
	var table: SewingTable = town.sewing.table
	assert_eq(table.eye_toggles[0].text, GearRules.current().shown_text)
	# The hide key on the cap's tile hides the head slot.
	table.tiles[HEAD].grab_focus()
	await tap_action("p1_hide_gear")
	await wait_physics_frames(1)
	assert_true(main.town.gear.is_hidden(0, "head"), "saved for player 1")
	assert_eq(table.eye_toggles[0].text, GearRules.current().hidden_text)
	assert_true(table.eye_toggles[0].hidden_now)
	var player: Player = first_player()
	assert_null(_gear_of(player).sprite(GearDef.Slot.HEAD), "the cap isn't drawn")
	assert_true(player.gear.has(HEAD), "but still worn (its effect works)")
	assert_eq(table.photo.shown_gear().size(), 2, "the photo hides it too")
	# Clicking the eye shows it again.
	table.eye_toggles[0].pressed.emit()
	await wait_physics_frames(1)
	assert_false(main.town.gear.is_hidden(0, "head"))
	assert_not_null(_gear_of(player).sprite(GearDef.Slot.HEAD))
	# Hide all.
	table.hide_all_toggle.pressed.emit()
	await wait_physics_frames(1)
	assert_true(main.town.gear.slot_hidden(0, -1), "every slot hidden")
	assert_eq(_gear_of(player).sprites.size(), 0, "nothing drawn")
	assert_eq(player.gear.pieces.size(), 3, "all three still worn")
	assert_eq(table.hide_all_toggle.text, GearRules.current().show_all_text)
	table.close()
	# Saved: it survives closing and reopening the game.
	main.save_now()
	var loaded: TownSave = SaveStore.read()
	assert_true(loaded.gear.slot_hidden(0, -1), "hidden after a reload")


func test_ac100b_hidden_gear_stays_hidden_in_the_run() -> void:
	_dress_save()
	main.town.gear.set_hidden(0, "body", true)
	await start_run()
	var player: Player = first_player()
	assert_true(player.gear.has(BODY), "worn: the vest still works")
	assert_null(_gear_of(player).sprite(GearDef.Slot.BODY), "not drawn")
	assert_eq(_gear_of(player).sprites.size(), 2)


func test_ac100b_the_wardrobe_picker_hides_gear_too() -> void:
	_dress_save(1, "pip")
	var town: Town = await _arrive()
	town.wardrobe.open(0)
	await wait_physics_frames(1)
	var picker: HeroPicker = town.wardrobe.picker
	assert_true(picker.gear_row.visible, "toggles show while something is worn")
	var pip: HeroStats = HEROES.find(&"pip")
	assert_eq(picker.photos[pip.id].shown_gear().size(), 3, "Pip's photo wears the gear")
	picker.eye_toggles[GearDef.Slot.CHARM].pressed.emit()
	await wait_physics_frames(1)
	assert_true(main.town.gear.is_hidden(0, "charm"), "saved")
	assert_eq(picker.photos[pip.id].shown_gear().size(), 2)
	assert_null(_gear_of(first_player()).sprite(GearDef.Slot.CHARM), "the hero in town follows")
	await tap_action("p1_hide_gear")
	await wait_physics_frames(1)
	assert_true(main.town.gear.slot_hidden(0, -1), "the hide key = Hide all on the picker")
	picker.close()


func test_ac100b_nothing_worn_no_toggles_on_the_picker() -> void:
	main.town.plushies["pip"] = "in_town"
	main.town.revealed.append(WardrobeRules.REVEALED_ID)
	main.town.revealed.append(WardrobeRules.HERO_PREFIX + "pip")
	var town: Town = await _arrive()
	town.wardrobe.open(0)
	await wait_physics_frames(1)
	assert_false(town.wardrobe.picker.gear_row.visible)
	town.wardrobe.picker.close()
