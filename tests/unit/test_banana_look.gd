extends GutTest
## #341 (playtest 2026-11-21): the peel shots look like a real banana. Banana Split throws a ripe
## yellow banana and leaves a classic opened peel on the floor: its own part, never the danger
## colours (the clarity ladder test checks every colour against the floors).

const BANANA_PARTS: Array[StringName] = [ProjectileLook.PEEL, ProjectileLook.SPLIT_PEEL]


func _parts() -> Dictionary[StringName, FeltPiece]:
	var parts: Dictionary[StringName, FeltPiece] = ProjectileLook.make_parts()
	for piece: FeltPiece in parts.values():
		autofree(piece)
	return parts


## The y of the polygon's top edge at its middle and at its ends (screen y grows downwards).
func _top_at(polygon: PackedVector2Array, x: float) -> float:
	var best: float = INF
	var closest: float = INF
	for point: Vector2 in polygon:
		if absf(point.x - x) < closest - 0.01:
			closest = absf(point.x - x)
			best = point.y
		elif absf(absf(point.x - x) - closest) <= 0.01:
			best = minf(best, point.y)
	return best


func test_the_thrown_peels_are_long_curved_bananas_with_a_stem() -> void:
	var parts: Dictionary[StringName, FeltPiece] = _parts()
	for key: StringName in BANANA_PARTS:
		var banana: FeltPiece = parts[key]
		var box: Rect2 = Rect2(banana.polygon[0], Vector2.ZERO)
		for point: Vector2 in banana.polygon:
			box = box.expand(point)
		assert_gt(box.size.x, box.size.y * 2.0, "%s: long and thin like a banana" % key)
		var middle_top: float = _top_at(banana.polygon, 0.0)
		var end_top: float = _top_at(banana.polygon, box.position.x)
		assert_gt(middle_top, end_top, "%s: curved, its ends point up" % key)
		assert_gt(banana.bounds().end.x, box.end.x + 6.0, "%s: a stem sticks out" % key)


func test_floor_peels_have_their_own_opened_peel_look() -> void:
	var parts: Dictionary[StringName, FeltPiece] = _parts()
	assert_true(parts.has(ProjectileLook.FLOOR_PEEL), "a part of its own")
	var peel: FeltPiece = parts[ProjectileLook.FLOOR_PEEL]
	var stub: Rect2 = Rect2(peel.polygon[0], Vector2.ZERO)
	for point: Vector2 in peel.polygon:
		stub = stub.expand(point)
	var all: Rect2 = peel.bounds()
	assert_gt(all.size.x, stub.size.x * 2.5, "flaps spread out wide from the stub")
	assert_gt(all.end.y, stub.end.y + 20.0, "flaps flop down below the stub")
	var shot: FloorPeelProjectile = autofree(FloorPeelProjectile.new())
	var floor_sprite: Sprite2D = autofree(FeltAtlas.make_sprite(ProjectileLook.FLOOR_PEEL))
	var air_sprite: Sprite2D = autofree(FeltAtlas.make_sprite(ProjectileLook.SPLIT_PEEL))
	assert_eq(shot.region_rect, floor_sprite.region_rect, "a floor peel shows the opened peel")
	assert_ne(shot.region_rect, air_sprite.region_rect, "not the banana in the air")


func test_banana_colours_are_banana_yellow_and_never_danger() -> void:
	var colours: Array[Color] = [
		ProjectileLook.PEEL_COLOR,
		ProjectileLook.SPLIT_PEEL_COLOR,
		ProjectileLook.SPLIT_RIDGE_COLOR,
		ProjectileLook.PEEL_RIDGE_COLOR,
		ProjectileLook.PEEL_STEM_COLOR,
		ProjectileLook.PEEL_TIP_COLOR,
		ProjectileLook.FLOOR_PEEL_INSIDE_COLOR,
	]
	for colour: Color in colours:
		assert_false(UiColors.is_danger(colour), colour.to_html())
	var hue: float = ProjectileLook.SPLIT_PEEL_COLOR.h * 360.0
	assert_between(hue, 50.0, 65.0, "Banana Split's banana is yellow (was mint green)")
