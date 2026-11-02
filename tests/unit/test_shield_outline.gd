extends GutTest
## Second Helping's outline (spec 06 §3.1): the part of the outline a shield covers.

const BOX: Rect2 = Rect2(0.0, 0.0, 30.0, 10.0)


func test_corners_go_clockwise_from_the_top_left() -> void:
	var corners: PackedVector2Array = ShieldOutline.corners_of(BOX)
	assert_eq(corners[0], Vector2(0.0, 0.0))
	assert_eq(corners[1], Vector2(30.0, 0.0))
	assert_eq(corners[2], Vector2(30.0, 10.0))
	assert_eq(corners[3], Vector2(0.0, 10.0))


func test_no_shield_is_no_line() -> void:
	assert_eq(ShieldOutline.outline_path(ShieldOutline.corners_of(BOX), 0.0).size(), 1)


func test_a_quarter_runs_along_the_top() -> void:
	# The outline is 80 long: a quarter (20) ends on the top edge.
	var path: PackedVector2Array = ShieldOutline.outline_path(ShieldOutline.corners_of(BOX), 0.25)
	assert_eq(path.size(), 2)
	assert_almost_eq(path[1].x, 20.0, 0.001)
	assert_almost_eq(path[1].y, 0.0, 0.001)


func test_half_turns_the_corner() -> void:
	var path: PackedVector2Array = ShieldOutline.outline_path(ShieldOutline.corners_of(BOX), 0.5)
	assert_eq(path[1], Vector2(30.0, 0.0))
	assert_eq(path[2], Vector2(30.0, 10.0))
	assert_almost_eq(path[path.size() - 1].x, 30.0, 0.001, "ends at the bottom right corner")


func test_full_closes_the_ring() -> void:
	var path: PackedVector2Array = ShieldOutline.outline_path(ShieldOutline.corners_of(BOX), 1.0)
	assert_eq(path[0], path[path.size() - 1])
	assert_eq(path.size(), 5)
