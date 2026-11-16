class_name MoonCalendarLook
extends RefCounted
## The moon calendar in the art kit's style (spec 07 §2): a night-sky felt board on a wooden
## post with a bright moon for every night until the horde and a pale one for every night that
## passed. When the horde is due, one big full moon fills the board. Built around the post's
## bottom middle.

const BOARD_HALF: float = 66.0
const BOARD_HEIGHT: float = 62.0
const POST_HEIGHT: float = 58.0
const MOON_RADIUS: float = 13.0
const DUE_MOON_RADIUS: float = 24.0
## Little stars on the board (relative to its top-left corner).
const STARS: PackedVector2Array = [Vector2(14, 12), Vector2(118, 14), Vector2(24, 50)]


## The look for `nights` to go out of `slots` moons on the board.
static func build(nights: int, slots: int) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new()
	var palette: WorldPalette = WorldPalette.current()
	LookParts.footprint_shadow(sketch, Rect2(-26.0, -6.0, 52.0, 6.0))
	sketch.rod(&"post", [Vector2(0.0, 0.0), Vector2(0.0, -POST_HEIGHT)], palette.wood, 9.0)
	var top: float = -POST_HEIGHT - BOARD_HEIGHT
	var board: Rect2 = Rect2(-BOARD_HALF, top, BOARD_HALF * 2.0, BOARD_HEIGHT)
	sketch.block(&"frame", board.grow(5.0), palette.calendar_sky_dark)
	sketch.block(&"board", board, palette.calendar_sky, true)
	for star: Vector2 in STARS:
		sketch.dot(board.position + star, 2.5, palette.moon)
	var middle_y: float = board.get_center().y
	if nights <= 0:
		sketch.disc(&"full_moon", Vector2(0.0, middle_y), DUE_MOON_RADIUS, palette.moon)
		return sketch
	var count: int = maxi(slots, nights)
	var gap: float = board.size.x / float(count + 1)
	for i: int in count:
		var at: Vector2 = Vector2(board.position.x + gap * (i + 1), middle_y)
		# Moons still to come sit on the right: the leftmost bright one is the next night.
		if i >= count - nights:
			sketch.disc(&"moon", at, MOON_RADIUS, palette.moon)
		else:
			sketch.dot(at, MOON_RADIUS * 0.8, palette.moon_spent)
	return sketch
