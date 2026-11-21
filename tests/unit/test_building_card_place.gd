extends GutTest
## #324: the town's info card keeps to the screen (BuildingCard.place).

const RECT: Rect2 = Rect2(770, 1150, 260, 180)
const CARD: Vector2 = Vector2(440, 300)


func test_no_view_keeps_the_old_spots() -> void:
	var over: Vector2 = BuildingCard.place(RECT, CARD, true, Rect2())
	var under: Vector2 = BuildingCard.place(RECT, CARD, false, Rect2())
	assert_eq(over.y, RECT.position.y - CARD.y - BuildingCard.GAP)
	assert_eq(under.y, RECT.end.y + BuildingCard.SIGN_HEIGHT)
	assert_eq(over.x, RECT.get_center().x - CARD.x / 2.0)


func test_it_stays_below_when_that_fits() -> void:
	var view: Rect2 = Rect2(0, 900, 1920, 1080)
	var spot: Vector2 = BuildingCard.place(RECT, CARD, false, view)
	assert_eq(spot.y, RECT.end.y + BuildingCard.SIGN_HEIGHT)


func test_it_flips_above_at_the_bottom_edge() -> void:
	var view: Rect2 = Rect2(0, 420, 1920, 1080)
	var spot: Vector2 = BuildingCard.place(RECT, CARD, false, view)
	assert_eq(spot.y, RECT.position.y - CARD.y - BuildingCard.GAP)
	assert_true(view.encloses(Rect2(spot, CARD)), "the card is on screen")


func test_it_flips_below_at_the_top_edge() -> void:
	var top: Rect2 = Rect2(770, 310, 260, 180)
	var view: Rect2 = Rect2(0, 0, 1920, 1080)
	var spot: Vector2 = BuildingCard.place(top, CARD, true, view)
	assert_eq(spot.y, top.end.y + BuildingCard.SIGN_HEIGHT)


func test_it_is_pushed_inside_when_neither_side_fits() -> void:
	var view: Rect2 = Rect2(600, 1000, 900, 500)
	var spot: Vector2 = BuildingCard.place(RECT, CARD, false, view)
	var room: Rect2 = view.grow(-BuildingCard.SCREEN_MARGIN)
	assert_true(room.encloses(Rect2(spot, CARD)), "pushed inside: %s" % spot)


func test_it_is_pushed_in_from_the_side() -> void:
	var view: Rect2 = Rect2(860, 420, 1920, 1080)
	var spot: Vector2 = BuildingCard.place(RECT, CARD, true, view)
	assert_eq(spot.x, view.position.x + BuildingCard.SCREEN_MARGIN)
