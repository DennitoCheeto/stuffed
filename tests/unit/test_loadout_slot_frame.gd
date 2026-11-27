extends GutTest
## Spec 11 §10 (AC-129): an evolved weapon's HUD slot draws its golden ring and star from one
## shared picture baked once (drawn shape by shape it cost ~8 draw calls per evolved slot).

const SIZE: Vector2 = LoadoutSlot.SLOT_SIZE
const CLOSE: float = 0.05


## The picture's pixel at `at` (slot units).
func _pixel(picture: Texture2D, at: Vector2) -> Color:
	var corner: Vector2 = Vector2.ONE * LoadoutSlot.PICTURE_MARGIN
	var spot: Vector2 = (at + corner) * LoadoutSlot.PICTURE_SCALE
	return picture.get_image().get_pixelv(Vector2i(spot))


func _is_gold(color: Color) -> bool:
	var gold: Color = LoadoutSlot.FRAME_COLOR
	var gap: float = maxf(absf(color.r - gold.r), absf(color.g - gold.g))
	gap = maxf(gap, absf(color.b - gold.b))
	return gap < CLOSE and color.a > 1.0 - CLOSE


func test_every_slot_shares_one_picture() -> void:
	var first: Texture2D = LoadoutSlot.frame_picture(SIZE)
	assert_same(LoadoutSlot.frame_picture(SIZE), first, "baked once, shared by all slots")
	var expected: Vector2 = SIZE + Vector2.ONE * LoadoutSlot.PICTURE_MARGIN * 2.0
	assert_eq(Vector2(first.get_size()), (expected * LoadoutSlot.PICTURE_SCALE).ceil())


func test_the_picture_shows_the_ring_and_the_star() -> void:
	var picture: Texture2D = LoadoutSlot.frame_picture(SIZE)
	var center: Vector2 = SIZE / 2.0
	var ring: Vector2 = center + Vector2.LEFT * (SIZE.x / 2.0 + 1.0)
	assert_true(_is_gold(_pixel(picture, ring)), "gold ring")
	var points: PackedVector2Array = LoadoutSlot.star_points(SIZE)
	var star: Vector2 = Vector2(SIZE.x - 3.0, 3.0)
	assert_true(_is_gold(_pixel(picture, star)), "gold star")
	var tip: Vector2 = points[0]
	var outline: Color = _pixel(picture, tip + Vector2(0.0, 0.5))
	assert_lt(outline.v, LoadoutSlot.FRAME_COLOR.v, "a dark outline at the star's edge")
	assert_lt(_pixel(picture, center).a, 0.01, "the icon shows through the middle")
