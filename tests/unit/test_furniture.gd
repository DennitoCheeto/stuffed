extends GutTest
## Furniture (spec 02 §10, spec 05 §4.2): the obstacle geometry zombies and enemy bullets use, and
## the hand-placed bedroom layout with its six places (AC-63).

const LAYOUT: FurnitureLayout = preload("res://data/arena/bedroom_furniture.tres")
const ARENA_SIZE: Vector2 = Vector2(7680.0, 4320.0)
const BOX: Rect2 = Rect2(100, 100, 200, 100)
## The biggest body that walks the floor (the Sock Puppet King: radius 20 x size 3.2).
const BIGGEST_RADIUS: float = 64.0
## The kinds you walk over; everything else blocks.
const FLOOR_KINDS: Array[FurniturePiece.Kind] = [
	FurniturePiece.Kind.RUG,
	FurniturePiece.Kind.SCRIBBLES,
	FurniturePiece.Kind.SCISSORS,
	FurniturePiece.Kind.SPOOL,
	FurniturePiece.Kind.TRAIN_TRACK,
]
## What each place of the Bedroom must have (spec 05 §4.2): (zone, kind) pairs.
const ZONE_KINDS: Array[Vector2i] = [
	Vector2i(FurniturePiece.Zone.RUG, FurniturePiece.Kind.RUG),
	Vector2i(FurniturePiece.Zone.BED_SHADOW, FurniturePiece.Kind.BED),
	Vector2i(FurniturePiece.Zone.BLOCK_CITY, FurniturePiece.Kind.BLOCK_TOWER),
	Vector2i(FurniturePiece.Zone.CRAYON_CORNER, FurniturePiece.Kind.CRAYON),
	Vector2i(FurniturePiece.Zone.CRAYON_CORNER, FurniturePiece.Kind.SHARPENER),
	Vector2i(FurniturePiece.Zone.CRAYON_CORNER, FurniturePiece.Kind.SCRIBBLES),
	Vector2i(FurniturePiece.Zone.SEWING_CORNER, FurniturePiece.Kind.SEWING_BOX),
	Vector2i(FurniturePiece.Zone.SEWING_CORNER, FurniturePiece.Kind.PINCUSHION),
	Vector2i(FurniturePiece.Zone.SEWING_CORNER, FurniturePiece.Kind.SCISSORS),
	Vector2i(FurniturePiece.Zone.SEWING_CORNER, FurniturePiece.Kind.SPOOL),
	Vector2i(FurniturePiece.Zone.TRAIN_LOOP, FurniturePiece.Kind.TRAIN_TRACK),
]


func _box() -> Obstacles:
	return Obstacles.new([BOX] as Array[Rect2])


func test_blocks_points_and_circles() -> void:
	var box: Obstacles = _box()
	assert_true(box.blocks(Vector2(150, 150)), "inside")
	assert_false(box.blocks(Vector2(90, 150)), "outside")
	assert_true(box.blocks(Vector2(90, 150), 15.0), "a circle touching the side")
	assert_false(box.blocks(Vector2(90, 90), 12.0), "a circle near the corner but not on it")


func test_push_out_moves_a_circle_to_the_nearest_side() -> void:
	var box: Obstacles = _box()
	assert_eq(box.push_out(Vector2(95, 150), 10.0), Vector2(90, 150), "from just outside")
	assert_eq(box.push_out(Vector2(290, 150), 10.0), Vector2(310, 150), "from deep inside")
	assert_eq(box.push_out(Vector2(50, 50), 10.0), Vector2(50, 50), "free circles stay")


func test_steer_leaves_a_free_walk_alone() -> void:
	var result: Array = _box().steer(Vector2(50, 150), 10.0, Vector2(-100, 0), 0)
	assert_eq(result[0], Vector2(-100, 0))
	assert_eq(result[1], 0)


func test_steer_turns_a_head_on_walk_along_the_side_at_full_speed() -> void:
	var result: Array = _box().steer(Vector2(90, 150), 10.0, Vector2(100, 0), 0)
	var walk: Vector2 = result[0]
	assert_almost_eq(walk.x, 0.0, 0.001, "no longer into the box")
	assert_almost_eq(walk.length(), 100.0, 0.001, "same speed")
	assert_ne(result[1], 0, "picked a way round")


func test_head_on_walkers_split_to_the_nearer_end() -> void:
	var box: Obstacles = _box()
	var target: Vector2 = Vector2(400, 150)
	var above: Vector2 = Vector2(90, 140)
	var below: Vector2 = Vector2(90, 160)
	var up: Array = box.steer(above, 10.0, above.direction_to(target) * 100.0, 0)
	var down: Array = box.steer(below, 10.0, below.direction_to(target) * 100.0, 0)
	assert_lt((up[0] as Vector2).y, 0.0, "above the middle: goes round the top")
	assert_gt((down[0] as Vector2).y, 0.0, "below the middle: goes round the bottom")


func test_steer_keeps_the_way_round_it_picked() -> void:
	var box: Obstacles = _box()
	var first: Array = box.steer(Vector2(90, 150), 10.0, Vector2(100, 5), 0)
	var detour: int = first[1]
	var again: Array = box.steer(Vector2(90, 150), 10.0, Vector2(100, -5), detour)
	assert_eq(again[1], detour, "doesn't turn back")
	assert_eq(signf((again[0] as Vector2).y), signf((first[0] as Vector2).y))


func test_steer_forgets_the_way_round_once_clear() -> void:
	var result: Array = _box().steer(Vector2(20, 150), 10.0, Vector2(100, 0), 1)
	assert_eq(result[1], 0)


## A walker right behind the middle of a box (the worst spot) reaches a target on the other side.
func test_a_walker_gets_around_a_box() -> void:
	var box: Obstacles = _box()
	var target: Vector2 = Vector2(200, 260)
	var radius: float = 12.0
	var walker: Vector2 = Vector2(200, 60)
	var detour: int = 0
	var delta: float = 1.0 / 60.0
	for i: int in 600:
		var walk: Vector2 = walker.direction_to(target) * 120.0
		var steered: Array = box.steer(walker, radius, walk, detour)
		detour = steered[1]
		walker = box.push_out(walker + (steered[0] as Vector2) * delta, radius)
		assert_false(box.blocks(walker, radius - 0.5), "never inside the box")
		if walker.distance_to(target) < 5.0:
			break
	assert_lt(walker.distance_to(target), 5.0, "reached the target (at %s)" % walker)


## The lookup grid only skips pieces that are far away: same answers as checking every piece.
func test_the_lookup_grid_gives_the_same_answers_as_checking_everything() -> void:
	var furniture: Obstacles = LAYOUT.obstacles()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	for i: int in 3000:
		# Right around a piece: the edges are where a cell could miss it.
		var near: Rect2 = furniture.rects[i % furniture.rects.size()].grow(BIGGEST_RADIUS)
		var point: Vector2 = near.position + near.size * Vector2(rng.randf(), rng.randf())
		var radius: float = rng.randf_range(1.0, BIGGEST_RADIUS)
		var any: bool = false
		for rect: Rect2 in furniture.rects:
			any = any or point.clamp(rect.position, rect.end).distance_to(point) < radius
		assert_eq(furniture.blocks(point, radius), any, "at %s, radius %.0f" % [point, radius])
		if any != furniture.blocks(point, radius):
			return


func test_floor_decorations_are_walked_over_and_the_rest_blocks() -> void:
	var kinds: Dictionary[FurniturePiece.Kind, bool] = {}
	for piece: FurniturePiece in LAYOUT.pieces:
		kinds[piece.kind] = true
		var should_block: bool = not FLOOR_KINDS.has(piece.kind)
		assert_eq(piece.blocks, should_block, "%s blocks" % piece.kind)
	for kind: FurniturePiece.Kind in FurniturePiece.Kind.values():
		assert_true(kinds.has(kind), "the bedroom has a %s" % kind)


func test_ac63_each_place_has_its_pieces() -> void:
	for pair: Vector2i in ZONE_KINDS:
		var found: Array[int] = []
		for piece: FurniturePiece in LAYOUT.in_zone(pair.x as FurniturePiece.Zone):
			found.append(piece.kind)
		assert_has(found, pair.y, "zone %d has a kind %d" % [pair.x, pair.y])
	for zone: FurniturePiece.Zone in FurniturePiece.Zone.values():
		assert_false(LAYOUT.in_zone(zone).is_empty(), "zone %s is in the room" % zone)
	var towers: int = 0
	for piece: FurniturePiece in LAYOUT.in_zone(FurniturePiece.Zone.BLOCK_CITY):
		towers += 1 if piece.kind == FurniturePiece.Kind.BLOCK_TOWER else 0
	assert_gte(towers, 6, "block city is a city of towers with lanes between them")


## Every place lies in its own part of the room (spec 05 §4.2 "Where").
func test_ac63_each_place_lies_where_the_spec_says() -> void:
	var third: float = ARENA_SIZE.x / 3.0
	var middle: float = ARENA_SIZE.y / 2.0
	for piece: FurniturePiece in LAYOUT.pieces:
		var at: Vector2 = piece.rect.get_center()
		var where: String = "%s at %s" % [piece.kind, at]
		match piece.zone:
			FurniturePiece.Zone.RUG:
				assert_true(piece.rect.has_point(ARENA_SIZE / 2.0), "the rug: %s" % where)
			FurniturePiece.Zone.BED_SHADOW:
				assert_true(at.x < third and at.y < middle, "top-left: %s" % where)
			FurniturePiece.Zone.BLOCK_CITY:
				assert_true(at.x > third * 2.0 and at.y < middle, "top-right: %s" % where)
			FurniturePiece.Zone.CRAYON_CORNER:
				assert_true(at.x > third * 2.0 and at.y > middle, "bottom-right: %s" % where)
			FurniturePiece.Zone.SEWING_CORNER:
				assert_true(at.x < third and at.y > middle, "bottom-left: %s" % where)
			FurniturePiece.Zone.TRAIN_LOOP:
				var inside: bool = at.x > third and at.x < third * 2.0 and at.y > middle
				assert_true(inside, "bottom-middle: %s" % where)


func test_ac63_the_start_area_is_free() -> void:
	var start_view: Rect2 = Rect2(ARENA_SIZE / 2.0 - Vector2(960, 540), Vector2(1920, 1080))
	for rect: Rect2 in LAYOUT.blocking_rects():
		assert_false(rect.intersects(start_view), "nothing blocks the first screen: %s" % rect)


## Wide gaps everywhere, so even the boss fits between furniture and walls (no traps).
func test_ac63_furniture_leaves_room_to_walk_around() -> void:
	var gap: float = BIGGEST_RADIUS * 2.0 + 20.0
	var rects: Array[Rect2] = LAYOUT.blocking_rects()
	var floor_rect: Rect2 = Rect2(Vector2.ZERO, ARENA_SIZE)
	for i: int in rects.size():
		assert_true(floor_rect.grow(-gap).encloses(rects[i]), "away from the walls: %s" % rects[i])
		for j: int in range(i + 1, rects.size()):
			assert_false(rects[i].grow(gap / 2.0).intersects(rects[j].grow(gap / 2.0)))


func test_spawns_are_never_inside_furniture() -> void:
	var furniture: Obstacles = LAYOUT.obstacles()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var area: Rect2 = Rect2(Vector2.ZERO, ARENA_SIZE)
	# A view in the top-left corner: its spawn ring runs right through the bed.
	var view: Rect2 = Rect2(0, 0, 1920, 1080)
	for i: int in 300:
		var point: Vector2 = SpawnPlacement.outside_view(view, area, 80.0, 16.0, rng, furniture)
		if point.is_finite():
			assert_false(furniture.blocks(point, 16.0), "spawned inside furniture: %s" % point)
