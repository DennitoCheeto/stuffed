extends GutTest

const AREA: Rect2 = Rect2(0, 0, 7680, 4320)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_points_are_outside_the_view_and_inside_the_arena() -> void:
	var view: Rect2 = Rect2(2880, 1620, 1920, 1080)
	var rng: RandomNumberGenerator = _rng(7)
	for i: int in 200:
		var point: Vector2 = SpawnPlacement.outside_view(view, AREA, 80.0, 16.0, rng)
		assert_false(view.has_point(point), "outside the view: %s" % point)
		assert_true(AREA.grow(-16.0).has_point(point), "inside the arena: %s" % point)


func test_view_in_a_corner_still_finds_room() -> void:
	var view: Rect2 = Rect2(-96, -96, 1920, 1080)
	var rng: RandomNumberGenerator = _rng(3)
	for i: int in 50:
		var point: Vector2 = SpawnPlacement.outside_view(view, AREA, 80.0, 16.0, rng)
		assert_true(point.is_finite())
		assert_false(view.has_point(point))


func test_no_room_returns_inf() -> void:
	var view: Rect2 = Rect2(-100, -100, 8000, 4600)
	var point: Vector2 = SpawnPlacement.outside_view(view, AREA, 80.0, 16.0, _rng(1))
	assert_false(point.is_finite())


func test_same_seed_same_points() -> void:
	var view: Rect2 = Rect2(2880, 1620, 1920, 1080)
	var a: RandomNumberGenerator = _rng(42)
	var b: RandomNumberGenerator = _rng(42)
	for i: int in 20:
		assert_eq(
			SpawnPlacement.outside_view(view, AREA, 80.0, 16.0, a),
			SpawnPlacement.outside_view(view, AREA, 80.0, 16.0, b)
		)
