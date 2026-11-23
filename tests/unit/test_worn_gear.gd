extends GutTest
## What a player wears (spec 09 §7, §8, AC-100, AC-104): WornGear reads a player slot's pieces and
## stitch levels from the save (old hidden slots don't matter any more, #331); GearLook draws each
## piece's own picture, without danger colours and with one more detail per stitch level.

const RULES: GearRules = preload("res://data/gear/gear_rules.tres")


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


func test_slots_hidden_in_an_old_save_are_still_worn() -> void:
	var save: TownSave = _save_wearing(0, ["lookout_cap", "patch_vest", "jingle_bell"], 1)
	save.gear.hidden.append(PackedStringArray(["body"]))
	var worn: WornGear = WornGear.of(save, 0, RULES)
	assert_eq(worn.pieces.size(), 3, "hiding is gone (#331): every worn piece counts")
	assert_true(worn.has(&"patch_vest"))


func test_no_gear_colour_is_a_danger_colour() -> void:
	for piece: GearDef in RULES.pieces:
		for level: int in range(1, piece.max_level() + 1):
			for color: Color in GearLook.colors(piece, level):
				assert_false(UiColors.is_danger(color), "%s Lv %d %s" % [piece.id, level, color])


func test_each_stitch_level_adds_a_detail() -> void:
	for piece: GearDef in RULES.pieces:
		var lv1: int = GearLook.colors(piece, 1).size()
		var lv2: int = GearLook.colors(piece, 2).size()
		assert_gt(lv2, lv1, "%s Lv 2 adds a darker detail" % piece.id)
		assert_gt(GearLook.colors(piece, 3).size(), lv2, "%s Lv 3 adds a lighter one" % piece.id)


func test_stitches_dash_an_open_line() -> void:
	var line: PackedVector2Array = [Vector2.ZERO, Vector2(10, 0)]
	var dashes: PackedVector2Array = GearLook.stitches(line, 2.0, 1.0)
	assert_eq(dashes.size() % 2, 0, "pairs for a multiline")
	assert_eq(dashes.size(), 8, "4 stitches along 10 px")
	assert_eq(dashes[0], Vector2.ZERO)
	assert_eq(dashes[1], Vector2(2, 0))
