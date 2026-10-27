extends GutTest
## The building art kit (spec 05 §2.2, §3.2, AC-60): all six town buildings have their own look
## for ruin, Lv 1, Lv 2 and Lv 3, each level adds at least one visible piece, the ruin is the same
## object broken and greyed, every look fits its spot, uses no danger colour and is baked once
## into a mesh. The fort grows a piece at a time and the Scrapbook stand is drawn with the kit too.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
## Every building spot in the town.
const KIT_IDS: Array[StringName] = [
	&"toy_box_armory", &"lucky_jar", &"watchtower", &"snack_bar", &"party_shop", &"plush_hospital"
]
## What each ruin shows: the same object broken or tipped over.
const RUIN_PARTS: Dictionary[StringName, Array] = {
	&"toy_box_armory": [&"broken_box", &"fallen_lid"],
	&"lucky_jar": [&"tipped_jar", &"spilled_buttons"],
	&"watchtower": [&"fallen_reels", &"loose_thread"],
	&"snack_bar": [&"dented_tin", &"fallen_lid", &"crumbs"],
	&"party_shop": [&"squashed_box", &"loose_ribbon", &"fallen_lid"],
	&"plush_hospital": [&"collapsed_walls", &"fallen_roof", &"door_hole"],
}
## What Lv 3 of each building shows (spec 05 §3.2).
const TOP_PARTS: Dictionary[StringName, Array] = {
	&"toy_box_armory": [&"brass_corners", &"weapon_rack"],
	&"lucky_jar": [&"gold_lid", &"fairy_lights", &"clover_flag"],
	&"watchtower": [&"third_reel", &"thimble_lookout", &"telescope", &"plushie_on_watch"],
	&"snack_bar": [&"cupcake_tower", &"fairy_lights", &"second_table"],
	&"party_shop": [&"third_box", &"bow", &"balloons", &"present_stand"],
	&"plush_hospital": [&"downstairs_windows", &"roof_cross", &"flower_bushes"],
}
## What Lv 1 and Lv 2 of the redrawn Party Shop and Hospital show (spec 05 §3.2, #187).
const LEVEL_PARTS: Dictionary[String, Array] = {
	"party_shop 1": [&"shop_box", &"ribbon_band", &"shop_window", &"shelves", &"door"],
	"party_shop 2": [&"goods", &"awning", &"sign", &"door_bell", &"second_box"],
	"plush_hospital 1": [&"house", &"roof", &"door", &"front_step"],
	"plush_hospital 2": [&"upstairs", &"ward_windows", &"ward_beds", &"plushies_in_bed"],
}
## How far a look may stick out of its spot sideways (share of the spot's width).
const SIDE_ROOM: float = 0.05


func _spot(id: StringName) -> TownSpot:
	for spot: TownSpot in LAYOUT.spots:
		if spot.id == id:
			return spot
	return null


func _looks(id: StringName) -> Array[BuildingSketch]:
	var building: BuildingDef = _spot(id).building
	var looks: Array[BuildingSketch] = []
	for level: int in range(0, building.max_level() + 1):
		looks.append(BuildingLooks.sketch(building, level))
	return looks


func test_every_building_is_drawn_with_the_kit() -> void:
	assert_eq(KIT_IDS.size(), LAYOUT.spots.size(), "all six spots")
	for spot: TownSpot in LAYOUT.spots:
		assert_has(KIT_IDS, spot.id)
		assert_true(BuildingLooks.has_look(spot.building), String(spot.id))
	var unknown: BuildingDef = BuildingDef.new()
	unknown.id = &"not_a_building"
	assert_null(BuildingLooks.sketch(unknown, 1), "no look for an unknown building")


func test_every_level_has_its_own_look() -> void:
	for id: StringName in KIT_IDS:
		var looks: Array[BuildingSketch] = _looks(id)
		assert_eq(looks.size(), 4, "ruin + 3 levels")
		for level: int in looks.size():
			var look: BuildingSketch = looks[level]
			assert_not_null(look, "%s level %d" % [id, level])
			assert_gt(look.ink_count(), 3, "%s level %d has outlined pieces" % [id, level])
			assert_eq(look.broken_shapes(), PackedStringArray(), "%s level %d" % [id, level])
			for other: int in range(level + 1, looks.size()):
				assert_ne(look.parts, looks[other].parts, "%s %d vs %d" % [id, level, other])


func test_each_level_adds_at_least_one_visible_piece() -> void:
	for id: StringName in KIT_IDS:
		var looks: Array[BuildingSketch] = _looks(id)
		for level: int in range(2, looks.size()):
			var added: Array[StringName] = []
			for part: StringName in looks[level].parts:
				if not looks[level - 1].parts.has(part):
					added.append(part)
			assert_gt(added.size(), 0, "%s Lv %d adds a piece" % [id, level])
			assert_gt(looks[level].ink_count(), looks[level - 1].ink_count(), "and more pieces")


func test_the_ruin_is_the_same_object_broken_and_greyed() -> void:
	for id: StringName in KIT_IDS:
		var looks: Array[BuildingSketch] = _looks(id)
		assert_true(looks[0].greyed, "%s ruin is greyed" % id)
		for level: int in range(1, looks.size()):
			assert_false(looks[level].greyed, "%s Lv %d keeps its colours" % [id, level])
	for id: StringName in KIT_IDS:
		var ruin: Array[StringName] = _looks(id)[0].parts
		for part: StringName in RUIN_PARTS[id]:
			assert_has(ruin, part, "%s ruin shows %s" % [id, part])


func test_level_3_shows_the_full_object() -> void:
	for id: StringName in KIT_IDS:
		var top: Array[StringName] = _looks(id)[3].parts
		for part: StringName in TOP_PARTS[id]:
			assert_has(top, part, "%s Lv 3 shows %s" % [id, part])


func test_party_shop_and_hospital_grow_like_the_picked_mockup() -> void:
	for key: String in LEVEL_PARTS:
		var id: StringName = StringName(key.get_slice(" ", 0))
		var level: int = key.get_slice(" ", 1).to_int()
		var looks: Array[BuildingSketch] = _looks(id)
		for part: StringName in LEVEL_PARTS[key]:
			assert_has(looks[level].parts, part, "%s shows %s" % [key, part])
			if level == 2:
				assert_does_not_have(looks[1].parts, part, "%s: %s is new" % [key, part])
	var hospital: Array[BuildingSketch] = _looks(&"plush_hospital")
	var one_storey: float = hospital[1].bounds().size.y
	assert_gt(hospital[2].bounds().size.y, one_storey * 1.3, "Lv 2 grows an upstairs")


func test_the_shop_sign_is_sewn_in_felt_letters() -> void:
	for text: String in PartyShopLook.SIGN_LINES:
		for letter: String in text:
			assert_true(LookParts.GLYPHS.has(letter), "a stroke letter for %s" % letter)
	assert_eq(LookParts.letters_width("AB", 2.0), 20.0, "4 + 2 + 4 grid steps")
	var sketch: BuildingSketch = BuildingSketch.new()
	var before: int = sketch.colors().size()
	LookParts.letters(sketch, "PARTY", Vector2.ZERO, 2.0, PALETTE.sign_text, 2.0)
	assert_eq(sketch.colors().size() - before, 9, "P 1 + A 2 + R 2 + T 2 + Y 2 strokes")
	assert_true(_looks(&"party_shop")[2].parts.has(&"sign"), "the sign hangs at Lv 2")


func test_a_greyed_colour_is_greyer_and_darker() -> void:
	var fresh: BuildingSketch = BuildingSketch.new()
	var ruin: BuildingSketch = BuildingSketch.new(1.0, true)
	var square: Rect2 = Rect2(0, 0, 20, 20)
	fresh.block(&"x", square, PALETTE.paint)
	ruin.block(&"x", square, PALETTE.paint)
	var before: Color = fresh.colors()[-1]
	var after: Color = ruin.colors()[-1]
	assert_lt(after.s, before.s, "less colourful")
	assert_lt(after.v, before.v, "a little darker")
	assert_gt(PALETTE.ruin_grey, 0.0)


func test_the_looks_fit_their_spot_and_grow() -> void:
	for id: StringName in KIT_IDS:
		var spot: TownSpot = _spot(id)
		var looks: Array[BuildingSketch] = _looks(id)
		var room: float = spot.rect.size.x * (1.0 + SIDE_ROOM)
		for level: int in looks.size():
			var area: Rect2 = looks[level].bounds()
			assert_lt(area.size.x, room, "%s level %d fits sideways" % [id, level])
			assert_between(area.end.y, 0.0, 20.0, "%s level %d stands on the floor" % [id, level])
		var small: Rect2 = looks[1].bounds()
		var big: Rect2 = looks[3].bounds()
		assert_gt(big.get_area(), small.get_area() * 1.3, "%s Lv 3 is clearly bigger" % id)


func test_the_looks_use_no_danger_colour() -> void:
	for id: StringName in KIT_IDS:
		for look: BuildingSketch in _looks(id):
			for color: Color in look.colors():
				assert_false(UiColors.is_danger(color), "%s: %s" % [id, color.to_html()])


func test_sewn_pieces_get_stitched_seams_inside_the_edge() -> void:
	var sketch: BuildingSketch = BuildingSketch.new()
	sketch.block(&"plain", Rect2(0, 0, 100, 60), PALETTE.wood)
	assert_eq(sketch.seam_count(), 0)
	sketch.block(&"sewn", Rect2(0, 100, 100, 60), PALETTE.wood, true)
	assert_gt(sketch.seam_count(), 10, "a dashed seam all the way round")
	var inner: Rect2 = Rect2(0, 100, 100, 60).grow(-PALETTE.seam_inset + 0.01)
	var outline: Rect2 = sketch.bounds()
	assert_almost_eq(outline.position.x, -PALETTE.building_outline, 0.5, "even ink outline")
	assert_true(inner.has_point(Vector2(50, 100 + PALETTE.seam_inset)), "seam sits inside")
	assert_gt(_looks(&"toy_box_armory")[1].seam_count(), 0, "the armory box is sewn")


func test_a_look_is_built_once_and_baked_into_one_mesh() -> void:
	var building: BuildingDef = _spot(&"lucky_jar").building
	var look: BuildingSketch = BuildingLooks.sketch(building, 2)
	assert_same(BuildingLooks.sketch(building, 2), look, "kept, not built again")
	var mesh: ArrayMesh = look.baked()
	assert_same(look.baked(), mesh, "baked once")
	assert_eq(mesh.get_surface_count(), 1, "one draw call for the whole building")
	var corners: int = mesh.surface_get_array_len(0)
	assert_gt(corners, 300, "every piece is in it")
