extends GutTest
## The sewing table's rules (spec 09 §6, AC-98): each tile's main action for a player (Sew /
## Stitch / Wear / Take off / nothing), whether it works right now, doing it, the Workshop's
## "Can sew!" check, the Workshop level a piece still needs, and every gear colour stays calm.

const RULES: GearRules = preload("res://data/gear/gear_rules.tres")
const RICH: Dictionary[String, int] = {"coins": 99999, "stuffing": 999, "thread": 999}


func _piece(id: String) -> GearDef:
	return RULES.find(id)


## A town with the Workshop at `workshop_level`, jars holding `materials` and every pattern.
func _town(workshop_level: int, materials: Dictionary[String, int] = RICH) -> TownSave:
	var save: TownSave = TownSave.new()
	save.building_levels[String(RULES.workshop)] = workshop_level
	save.add_materials(materials)
	for piece: GearDef in RULES.pieces:
		save.gear.add_pattern(String(piece.id))
	return save


func test_a_found_pattern_offers_sew_and_sewing_puts_it_on() -> void:
	var save: TownSave = _town(1)
	var cap: GearDef = _piece("lookout_cap")
	assert_eq(GearBook.action_for(save, cap, 0), GearBook.Action.SEW)
	assert_true(GearBook.can_act(save, cap, 0))
	var coins: int = save.material("coins")
	assert_true(GearBook.act(save, cap, 0), "sewn")
	assert_eq(save.material("coins"), coins - cap.level(1).coins, "paid once")
	assert_eq(save.gear.worn_in(0, "head"), "lookout_cap", "on at once: the slot was empty")
	assert_eq(GearBook.action_for(save, cap, 0), GearBook.Action.TAKE_OFF, "Lv 1 is the cap")


func test_a_worn_piece_offers_stitch_when_the_workshop_allows_it() -> void:
	var save: TownSave = _town(2)
	var cap: GearDef = _piece("lookout_cap")
	GearBook.act(save, cap, 0)
	assert_eq(GearBook.action_for(save, cap, 0), GearBook.Action.STITCH)
	assert_true(GearBook.act(save, cap, 0))
	assert_eq(save.gear.stitch_level("lookout_cap"), 2, "stitched to Lv 2")
	assert_eq(GearBook.action_for(save, cap, 0), GearBook.Action.TAKE_OFF, "Workshop Lv 2 cap")
	assert_true(GearBook.act(save, cap, 0), "take off")
	assert_eq(save.gear.worn_in(0, "head"), "", "taken off")
	assert_eq(save.gear.stitch_level("lookout_cap"), 2, "still sewn")
	assert_eq(GearBook.action_for(save, cap, 0), GearBook.Action.WEAR)


func test_wearing_another_piece_of_the_slot_swaps_it_for_free() -> void:
	var save: TownSave = _town(1)
	GearBook.act(save, _piece("lookout_cap"), 0)
	GearBook.act(save, _piece("pin_cushion_hat"), 0)
	assert_eq(save.gear.worn_in(0, "head"), "lookout_cap", "sewing doesn't push a piece off")
	var coins: int = save.material("coins")
	assert_eq(GearBook.action_for(save, _piece("pin_cushion_hat"), 0), GearBook.Action.WEAR)
	assert_true(GearBook.act(save, _piece("pin_cushion_hat"), 0))
	assert_eq(save.gear.worn_in(0, "head"), "pin_cushion_hat", "swapped")
	assert_eq(save.material("coins"), coins, "free")


func test_short_of_materials_shows_the_action_but_it_does_nothing() -> void:
	var save: TownSave = _town(1, {"coins": 10, "stuffing": 0, "thread": 0})
	var cap: GearDef = _piece("lookout_cap")
	assert_eq(GearBook.action_for(save, cap, 0), GearBook.Action.SEW, "still says Sew")
	assert_false(GearBook.can_act(save, cap, 0))
	assert_false(GearBook.act(save, cap, 0))
	assert_eq(save.material("coins"), 10, "nothing taken")
	assert_eq(save.gear.stitch_level("lookout_cap"), 0)


func test_nothing_to_do_without_a_pattern_a_slot_or_while_another_player_wears_it() -> void:
	var save: TownSave = _town(1)
	save.gear.patterns.clear()
	assert_eq(GearBook.action_for(save, _piece("lookout_cap"), 0), GearBook.Action.NONE)
	save.gear.add_pattern("jingle_bell")
	assert_eq(GearBook.action_for(save, _piece("jingle_bell"), 0), GearBook.Action.NONE, "Lv 2")
	save.gear.add_pattern("lookout_cap")
	GearBook.act(save, _piece("lookout_cap"), 1)
	assert_eq(save.gear.worn_in(1, "head"), "lookout_cap", "player 2 sewed and wears it")
	assert_eq(GearBook.action_for(save, _piece("lookout_cap"), 0), GearBook.Action.NONE)
	assert_false(GearBook.act(save, _piece("lookout_cap"), 0))


func test_can_sew_any_follows_the_jars_and_the_workshop() -> void:
	assert_true(GearBook.can_sew_any(_town(1)))
	assert_false(GearBook.can_sew_any(_town(0)), "not built")
	assert_false(GearBook.can_sew_any(_town(1, {"coins": 10, "stuffing": 0, "thread": 0})))
	var damaged: TownSave = _town(1)
	damaged.damage(PackedStringArray([String(RULES.workshop)]))
	assert_false(GearBook.can_sew_any(damaged), "damaged: no sewing")
	var all_sewn: TownSave = _town(1)
	for piece: GearDef in RULES.pieces_in(GearDef.Slot.HEAD) + RULES.pieces_in(GearDef.Slot.BODY):
		all_sewn.gear.stitches[String(piece.id)] = 1
	assert_false(GearBook.can_sew_any(all_sewn), "everything a Lv 1 Workshop can sew is sewn")


func test_the_workshop_level_a_piece_needs() -> void:
	var save: TownSave = _town(1)
	assert_eq(GearBook.workshop_level_needed(save, _piece("lookout_cap")), 1)
	assert_eq(GearBook.workshop_level_needed(save, _piece("jingle_bell")), 2, "Charm slot")
	save.gear.stitches["lookout_cap"] = 1
	assert_eq(GearBook.workshop_level_needed(save, _piece("lookout_cap")), 2, "stitch Lv 2")
	save.gear.stitches["lookout_cap"] = 2
	assert_eq(GearBook.workshop_level_needed(save, _piece("lookout_cap")), 3, "stitch Lv 3")


func test_every_piece_has_a_calm_colour_and_says_where_its_pattern_comes_from() -> void:
	for piece: GearDef in RULES.pieces:
		assert_false(UiColors.is_danger(piece.color), "%s colour is calm" % piece.id)
		if piece.source_kind != GearDef.Source.BUILDING:
			assert_false(piece.found_text.is_empty(), "%s says who drops it" % piece.id)
