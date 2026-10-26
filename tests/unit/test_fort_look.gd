extends GutTest
## The Pillow Fort and the Scrapbook stand in the building art kit (spec 05 §3.2, AC-60): the fort
## shows its cushion towers, quilt roof and door from the start, grows one visible piece per step
## (spec 03 §5), fits its spot and uses no danger colour; the stand is an open book on a stand.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const BASE_PARTS: Array[StringName] = [
	&"pillow_wall", &"towers", &"quilt_roof", &"door", &"windows"
]


func _fort(pieces: int) -> BuildingSketch:
	return FortLook.build(LAYOUT, TownFort.PIECES.slice(0, pieces))


func _check_clean(look: BuildingSketch, what: String) -> void:
	assert_eq(look.broken_shapes(), PackedStringArray(), what)
	for color: Color in look.colors():
		assert_false(UiColors.is_danger(color), "%s: %s" % [what, color.to_html()])


func test_the_fort_has_towers_a_quilt_roof_and_the_door() -> void:
	var look: BuildingSketch = _fort(0)
	for part: StringName in BASE_PARTS:
		assert_has(look.parts, part)
	assert_false(look.greyed, "the fort is never a ruin")
	assert_gt(look.seam_count(), 20, "sewn pillows and patches")


func test_the_fort_grows_one_visible_piece_at_a_time() -> void:
	for count: int in range(1, TownFort.PIECES.size() + 1):
		var before: BuildingSketch = _fort(count - 1)
		var after: BuildingSketch = _fort(count)
		var piece: StringName = StringName(TownFort.PIECES[count - 1])
		assert_false(before.parts.has(piece), "%s not there yet" % piece)
		assert_has(after.parts, piece, "%s shows" % piece)
		assert_gt(after.ink_count(), before.ink_count(), "%s adds outlined pieces" % piece)


func test_the_fort_fits_its_spot_and_keeps_the_door_in_place() -> void:
	var fort: Rect2 = LAYOUT.fort_rect
	for count: int in TownFort.PIECES.size() + 1:
		var look: BuildingSketch = _fort(count)
		_check_clean(look, "fort with %d pieces" % count)
		var area: Rect2 = look.bounds()
		assert_lt(area.size.x, fort.size.x * 1.05, "fits sideways")
		assert_between(area.end.y, 0.0, 10.0, "stands on the floor")
	var door_bottom: float = LAYOUT.door_rect.end.y - fort.end.y
	assert_almost_eq(door_bottom, 0.0, 0.5, "the door sits at the fort's bottom edge")


func test_the_town_fort_shows_the_look_for_its_pieces() -> void:
	var fort: TownFort = TownFort.new(LAYOUT)
	add_child_autofree(fort)
	assert_not_null(fort.material, "felt grain")
	fort.pieces = 2
	assert_has(fort.look().parts, &"string_lights")
	assert_same(fort.look(), fort.look(), "built once per number of pieces")
	fort.pieces = 0
	assert_false(fort.look().parts.has(&"flag"))


func test_the_scrapbook_stand_is_an_open_book_on_a_stand() -> void:
	var look: BuildingSketch = ScrapbookLook.build()
	for part: StringName in [&"stand", &"book", &"bookmark"]:
		assert_has(look.parts, part)
	_check_clean(look, "scrapbook stand")
	var rect: Rect2 = LAYOUT.scrapbook_rect
	assert_lt(look.bounds().size.x, rect.size.x + 10.0, "fits its spot")
	assert_same(ScrapbookStand.look(), ScrapbookStand.look(), "one look for the stand")
