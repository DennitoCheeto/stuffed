extends GutTest
## What a player wears (spec 09 §7, §8, AC-100, AC-100b, AC-104): WornGear reads a player slot's
## pieces, stitch levels and hidden slots from the save; hidden pieces stay worn but aren't
## drawn; GearLook draws each piece without danger colours.

const RULES: GearRules = preload("res://data/gear/gear_rules.tres")
const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")


func _save_wearing(player: int, ids: Array[String], level: int) -> TownSave:
	var save: TownSave = TownSave.new()
	for id: String in ids:
		save.gear.add_pattern(id)
		save.gear.stitches[id] = level
		save.gear.put_on(player, RULES.find(id).slot_name(), id)
	return save


func test_reads_what_a_player_slot_wears() -> void:
	var save: TownSave = _save_wearing(1, ["lookout_cap", "jingle_bell"], 2)
	var worn: WornGear = WornGear.of(save, 1, RULES)
	assert_eq(worn.pieces.size(), 2)
	assert_eq(worn.in_slot(GearDef.Slot.HEAD).id, &"lookout_cap")
	assert_null(worn.in_slot(GearDef.Slot.BODY))
	assert_eq(worn.level_of(RULES.find("jingle_bell")), 2)
	assert_true(worn.has(&"jingle_bell"))
	assert_eq(WornGear.of(save, 0, RULES).pieces.size(), 0, "player 1 wears nothing")


func test_hidden_pieces_stay_worn_but_are_not_shown() -> void:
	var save: TownSave = _save_wearing(0, ["lookout_cap", "patch_vest", "jingle_bell"], 1)
	save.gear.set_hidden(0, "body", true)
	var worn: WornGear = WornGear.of(save, 0, RULES)
	assert_true(worn.has(&"patch_vest"), "still worn: its effect works")
	assert_true(worn.is_hidden(GearDef.Slot.BODY))
	assert_eq(worn.shown().size(), 2)
	assert_false(worn.shown().has(RULES.find("patch_vest")))
	assert_false(save.gear.slot_hidden(0, -1), "not every slot is hidden")
	save.gear.set_all_hidden(0, true)
	assert_true(save.gear.slot_hidden(0, -1))
	assert_eq(WornGear.of(save, 0, RULES).shown().size(), 0)


func test_the_look_key_changes_with_level_and_hiding() -> void:
	var save: TownSave = _save_wearing(0, ["lookout_cap"], 1)
	var first: String = WornGear.of(save, 0, RULES).look_key()
	save.gear.stitches["lookout_cap"] = 3
	var stitched: String = WornGear.of(save, 0, RULES).look_key()
	assert_ne(stitched, first, "a stitch level shows")
	save.gear.set_hidden(0, "head", true)
	assert_eq(WornGear.of(save, 0, RULES).look_key(), "", "hidden = nothing drawn")


func test_no_gear_colour_is_a_danger_colour() -> void:
	for piece: GearDef in RULES.pieces:
		for level: int in range(1, piece.max_level() + 1):
			for color: Color in GearLook.colors(piece, level):
				assert_false(UiColors.is_danger(color), "%s Lv %d %s" % [piece.id, level, color])


func test_every_hero_has_gear_anchors_inside_its_puppet() -> void:
	for hero: HeroStats in HEROES.heroes:
		var tall: float = 80.0 if hero.plushie == null else hero.puppet_height
		for slot: int in 3:
			var at: Vector2 = hero.gear_anchor(slot)
			assert_between(-at.y, 0.0, tall, "%s slot %d height" % [hero.id, slot])
			assert_lt(absf(at.x), tall * 0.5, "%s slot %d side" % [hero.id, slot])
		assert_gt(hero.gear_scale, 0.0)


func test_stitches_dash_an_open_line() -> void:
	var line: PackedVector2Array = [Vector2.ZERO, Vector2(10, 0)]
	var dashes: PackedVector2Array = GearLook.stitches(line, 2.0, 1.0)
	assert_eq(dashes.size() % 2, 0, "pairs for a multiline")
	assert_eq(dashes.size(), 8, "4 stitches along 10 px")
	assert_eq(dashes[0], Vector2.ZERO)
	assert_eq(dashes[1], Vector2(2, 0))
