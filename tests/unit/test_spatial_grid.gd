extends GutTest


func test_finds_items_in_touched_cells_only() -> void:
	var grid: SpatialGrid = SpatialGrid.new(50.0)
	var near: RefCounted = RefCounted.new()
	var far: RefCounted = RefCounted.new()
	grid.insert(near, Vector2(10, 10))
	grid.insert(far, Vector2(500, 500))
	var found: Array = grid.candidates(Vector2(20, 20), 30.0)
	assert_has(found, near)
	assert_does_not_have(found, far)


func test_query_spans_neighbouring_cells() -> void:
	var grid: SpatialGrid = SpatialGrid.new(50.0)
	var left: RefCounted = RefCounted.new()
	var right: RefCounted = RefCounted.new()
	grid.insert(left, Vector2(45, 10))
	grid.insert(right, Vector2(55, 10))
	assert_eq(grid.candidates(Vector2(50, 10), 8.0).size(), 2)


func test_negative_positions_and_clear() -> void:
	var grid: SpatialGrid = SpatialGrid.new(50.0)
	var item: RefCounted = RefCounted.new()
	grid.insert(item, Vector2(-120, -5))
	assert_eq(grid.cell_of(Vector2(-120, -5)), Vector2i(-3, -1))
	assert_has(grid.candidates(Vector2(-110, -10), 20.0), item)
	grid.clear()
	assert_eq(grid.candidates(Vector2(-110, -10), 20.0).size(), 0)
