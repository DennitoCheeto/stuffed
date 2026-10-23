extends GutTest
## The Pillow Fort's layout and unlock rules (spec 03 §5, §6) and the Brought home texts.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SPEC_IDS: Array[StringName] = [
	&"toy_box_armory", &"lucky_jar", &"watchtower", &"snack_bar", &"party_shop", &"plush_hospital"
]
## Banane must fit through every gap between two things that block.
const MIN_GAP: float = 100.0


func _unlocked(town: TownSave) -> Array[StringName]:
	var ids: Array[StringName] = []
	for spot: TownSpot in LAYOUT.spots:
		if spot.is_unlocked_in(town):
			ids.append(spot.id)
	return ids


func test_the_town_has_the_6_buildings_of_the_spec() -> void:
	var ids: Array[StringName] = []
	for spot: TownSpot in LAYOUT.spots:
		ids.append(spot.id)
		assert_ne(spot.display_name(), "", "%s has a name" % spot.id)
	assert_eq(ids, SPEC_IDS)


func test_a_new_town_can_rebuild_exactly_the_armory_and_the_lucky_jar() -> void:
	assert_eq(_unlocked(TownSave.new()), [&"toy_box_armory", &"lucky_jar"] as Array[StringName])


func test_ruins_unlock_after_1_and_3_rebuilds_and_the_first_rescue() -> void:
	var town: TownSave = TownSave.new()
	town.building_levels["toy_box_armory"] = 1
	var after_one: Array[StringName] = _unlocked(town)
	assert_true(after_one.has(&"watchtower") and after_one.has(&"snack_bar"))
	assert_false(after_one.has(&"party_shop"))
	town.building_levels["lucky_jar"] = 2
	town.building_levels["watchtower"] = 1
	assert_true(_unlocked(town).has(&"party_shop"), "after 3 rebuilds")
	assert_false(_unlocked(town).has(&"plush_hospital"))
	town.plushies["bambam"] = "waiting"
	assert_true(_unlocked(town).has(&"plush_hospital"), "after the first rescue")


func test_locked_ruins_say_what_unlocks_them() -> void:
	assert_eq(LAYOUT.spot(&"watchtower").unlock_hint(), "Rebuild 1 building first")
	assert_eq(LAYOUT.spot(&"party_shop").unlock_hint(), "Rebuild 3 buildings first")
	assert_eq(LAYOUT.spot(&"plush_hospital").unlock_hint(), "Bring home a rescued plushie")


func test_everything_fits_on_the_blanket_with_room_to_walk_between() -> void:
	var rects: Array[Rect2] = LAYOUT.blocking_rects()
	var floor_rect: Rect2 = LAYOUT.play_rect().grow(-MIN_GAP)
	for i: int in rects.size():
		assert_true(floor_rect.encloses(rects[i]), "%s is inside with a gap" % rects[i])
		var padded: Rect2 = rects[i].grow(MIN_GAP / 2.0)
		for j: int in range(i + 1, rects.size()):
			var other: Rect2 = rects[j].grow(MIN_GAP / 2.0)
			assert_false(padded.intersects(other), "%s and %s leave a gap" % [rects[i], rects[j]])


func test_banane_appears_free_and_at_the_door() -> void:
	for rect: Rect2 in LAYOUT.blocking_rects():
		assert_false(rect.grow(20.0).has_point(LAYOUT.spawn_position), "not inside %s" % rect)
	var distance: float = TownLayout.distance_to(LAYOUT.door_rect, LAYOUT.spawn_position)
	assert_lte(distance, LAYOUT.reach, "E works right away")


func test_the_town_music_is_calmer_than_the_run() -> void:
	assert_true(MusicPlayer.TRACKS.has(&"town"))
	assert_lt(MusicPlayer.TRACKS[&"town"][0], MusicPlayer.TRACKS[&"run"][0])


func test_brought_home_says_what_share_was_kept() -> void:
	assert_eq(BroughtHomePanel.share_text(1.0), "You kept everything!")
	assert_string_contains(BroughtHomePanel.share_text(0.5), "half")


func test_a_given_up_run_says_so() -> void:
	var result: RunResult = RunResult.new()
	result.ending = "quit"
	assert_eq(result.title(), "You gave up")
	result.ending = "died"
	assert_eq(result.title(), "Banane got stuffed")
