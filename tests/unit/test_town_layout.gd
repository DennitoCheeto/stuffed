extends GutTest
## The Pillow Fort's layout and unlock rules (spec 03 §5, §6) and the Brought home texts.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const SPEC_IDS: Array[StringName] = [
	&"toy_box_armory", &"lucky_jar", &"watchtower", &"snack_bar", &"party_shop", &"plush_hospital"
]
## Banane must fit through every gap between two things that block.
const MIN_GAP: float = 100.0
## The farthest building from the door before spec 05 (middle to middle, px).
const OLD_FARTHEST: float = 732.5
## The views the town is seen in: 16:9 and 16:10 (wider windows show the same 1920 x 1080).
const VIEWS: Array[Vector2] = [Vector2(1920, 1080), Vector2(1920, 1200)]
## A thread path ends this close to its building.
const PATH_END_REACH: float = 40.0


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


func test_ac62_every_building_is_closer_to_the_door() -> void:
	var limit: float = OLD_FARTHEST * 0.8 + 1.0
	assert_lte(LAYOUT.max_building_distance, limit, "about 20% closer than before")
	for spot: TownSpot in LAYOUT.spots:
		var distance: float = LAYOUT.distance_from_door(spot)
		assert_lte(distance, LAYOUT.max_building_distance, "%s is %d px away" % [spot.id, distance])


func test_ac62_the_room_is_bigger_than_the_screen() -> void:
	for view: Vector2 in VIEWS:
		var room: Vector2 = LAYOUT.outer_rect().size
		assert_true(room.x >= view.x and room.y >= view.y, "%s fits in the room %s" % [view, room])


func test_the_tape_measure_starts_at_the_door_and_banane_stands_on_it() -> void:
	var road: PackedVector2Array = LAYOUT.road_line()
	assert_gt(road.size(), 2)
	assert_lte(TownLayout.distance_to(LAYOUT.door_rect, road[0]), 10.0, "it comes out of the door")
	assert_lte(_distance_to_line(road, LAYOUT.spawn_position), LAYOUT.road_width / 2.0)


func test_a_thread_path_runs_from_the_road_to_every_building() -> void:
	var road: PackedVector2Array = LAYOUT.road_line()
	for spot: TownSpot in LAYOUT.spots:
		var path: PackedVector2Array = LAYOUT.thread_line(spot)
		assert_gt(path.size(), 2, "%s has a path" % spot.id)
		if path.size() < 2:
			continue
		var start: float = _distance_to_line(road, path[0])
		assert_lte(start, LAYOUT.road_width / 2.0, "%s starts on the road" % spot.id)
		var end: float = TownLayout.distance_to(spot.rect, path[path.size() - 1])
		assert_lte(end, PATH_END_REACH, "%s ends at its building" % spot.id)
		for point: Vector2 in path:
			for rect: Rect2 in LAYOUT.blocking_rects():
				assert_false(rect.has_point(point), "%s path runs through %s" % [spot.id, rect])


func test_props_lie_on_the_quilt_and_not_under_a_building() -> void:
	var groups: Array[PackedVector2Array] = [
		LAYOUT.cushions,
		LAYOUT.block_piles,
		LAYOUT.flowers,
		LAYOUT.loose_buttons,
		LAYOUT.safety_pins,
		LAYOUT.marbles,
		LAYOUT.spools,
	]
	var count: int = 0
	for group: PackedVector2Array in groups:
		assert_gt(group.size(), 0, "every kind of prop is there")
		for point: Vector2 in group:
			count += 1
			var inside: bool = LAYOUT.play_rect().grow(-30.0).has_point(point)
			assert_true(inside, "%s is on the quilt" % point)
			for rect: Rect2 in LAYOUT.blocking_rects():
				assert_false(rect.grow(30.0).has_point(point), "%s is free of %s" % [point, rect])
	assert_gte(count, 20, "plenty of props between the buildings")


func _distance_to_line(line: PackedVector2Array, point: Vector2) -> float:
	var best: float = INF
	for i: int in range(1, line.size()):
		var nearest: Vector2 = Geometry2D.get_closest_point_to_segment(point, line[i - 1], line[i])
		best = minf(best, nearest.distance_to(point))
	return best

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
