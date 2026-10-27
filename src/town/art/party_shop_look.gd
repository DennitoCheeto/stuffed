class_name PartyShopLook
extends RefCounted
## The Party Shop in the art kit's style (spec 05 §3.2, PO pick P3 + P1): a stack of gift boxes
## whose big bottom box is a real shopfront. Ruin: the shop box squashed in, its ribbon loose on
## the floor and its lid fallen off. Lv 1: the shop box with a ribbon band, a shop window with
## empty shelves and a door. Lv 2: goods in the window (party popper, snow globe, magnet), a
## scalloped felt awning, a door bell and a second box on top with the "PARTY SHOP" sign.
## Lv 3: a third box with a bow, balloons and a little stand of presents outside.

## The shop box: front width and height, and how far its side and top go back (3/4 view).
const FRONT: Vector2 = Vector2(168.0, 112.0)
const DEPTH: Vector2 = Vector2(26.0, -13.0)
## Lv 3 moves the shop right to make room for the stand of presents.
const SHIFTS: Array[float] = [0.0, 0.0, 30.0]
## The boxes stacked on top (front size and depth).
const SECOND_BOX: Vector2 = Vector2(118.0, 64.0)
const SECOND_DEPTH: Vector2 = Vector2(20.0, -10.0)
const THIRD_BOX: Vector2 = Vector2(66.0, 46.0)
const THIRD_DEPTH: Vector2 = Vector2(14.0, -7.0)
## The sign on the second box, one line per entry, sewn in felt letters.
const SIGN_LINES: Array[String] = ["PARTY", "SHOP"]
const LETTER_SIZE: float = 2.0
## The shop window and the door, measured from the front's left edge and the floor.
const WINDOW: Rect2 = Rect2(12.0, -70.0, 78.0, 52.0)
const SHELF_YS: Array[float] = [-46.0, -24.0]
const DOOR: Rect2 = Rect2(110.0, -78.0, 36.0, 78.0)
## The awning's top edge (from the floor), its band and how far it reaches past the front.
const AWNING_TOP: float = -101.0
const AWNING_BAND: float = 14.0
const AWNING_OVERHANG: float = 6.0
## The stand of presents (Lv 3): its left edge and width.
const STAND_LEFT: float = -128.0
const STAND_WIDTH: float = 48.0
## Where each balloon floats (Lv 3).
const BALLOONS: Array[Vector2] = [
	Vector2(-118.0, -128.0), Vector2(-96.0, -152.0), Vector2(-74.0, -134.0)
]
const BALLOON_COLORS: Array[int] = [1, 0, 2]


static func build(level: int, unit: float) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new(unit, level <= 0)
	if level <= 0:
		_ruin(sketch)
	else:
		_standing(sketch, mini(level, 3))
	return sketch


static func _standing(sketch: BuildingSketch, level: int) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var shop: Rect2 = _shop_front(level)
	LookParts.box_shadow(sketch, shop.position.x, shop.size.x, DEPTH)
	if level >= 3:
		LookParts.footprint_shadow(sketch, Rect2(STAND_LEFT, -10.0, STAND_WIDTH, 10.0))
	_box(sketch, &"shop_box", shop, DEPTH, 0)
	_ribbon(sketch, shop, DEPTH, 0.58, 14.0, palette.paint_trim)
	_front_seams(sketch, shop)
	_window(sketch, palette, shop, level)
	_door(sketch, palette, shop)
	if level < 2:
		return
	_awning(sketch, palette, shop)
	_bell(sketch, palette, shop)
	var second: Rect2 = _on_top(shop, DEPTH, SECOND_BOX, SECOND_DEPTH)
	_box(sketch, &"second_box", second, SECOND_DEPTH, 1)
	_ribbon(sketch, second, SECOND_DEPTH, 0.5, 12.0, WorldPalette.pick(palette.toys, 0))
	_sign(sketch, palette, second)
	if level < 3:
		return
	var third: Rect2 = _on_top(second, SECOND_DEPTH, THIRD_BOX, THIRD_DEPTH)
	_box(sketch, &"third_box", third, THIRD_DEPTH, 2)
	_ribbon(sketch, third, THIRD_DEPTH, 0.5, 10.0, palette.ribbon)
	_bow(sketch, palette, Vector2(third.get_center().x, third.position.y) + THIRD_DEPTH / 2.0)
	_stand(sketch, palette)
	var tie: Vector2 = Vector2(STAND_LEFT + STAND_WIDTH * 0.5, -34.0)
	for i: int in BALLOONS.size():
		_balloon(sketch, palette, tie, BALLOONS[i], BALLOON_COLORS[i])


## The shop box's front at `level`, centred with its side.
static func _shop_front(level: int) -> Rect2:
	var left: float = -(FRONT.x + DEPTH.x) / 2.0 + SHIFTS[level - 1]
	return Rect2(left, -FRONT.y, FRONT.x, FRONT.y)


## The front of a box of `size` sitting in the middle of the top of the box `below`.
static func _on_top(below: Rect2, below_depth: Vector2, size: Vector2, depth: Vector2) -> Rect2:
	var middle: Vector2 = Vector2(below.get_center().x, below.position.y) + below_depth * 0.45
	var bottom_left: Vector2 = middle - Vector2((size.x + depth.x) / 2.0, 0.0)
	return Rect2(bottom_left - Vector2(0.0, size.y), size)


## A gift box in 3/4 view: front, shaded side and light top in the colours of box `index`.
static func _box(
	sketch: BuildingSketch, part: StringName, front: Rect2, depth: Vector2, index: int
) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var top_left: Vector2 = front.position
	var top_right: Vector2 = Vector2(front.end.x, front.position.y)
	sketch.block(part, front, WorldPalette.pick(palette.gift_boxes, index))
	var side: PackedVector2Array = [front.end, front.end + depth, top_right + depth, top_right]
	sketch.piece(part, side, WorldPalette.pick(palette.gift_box_sides, index))
	var top: PackedVector2Array = [top_left, top_right, top_right + depth, top_left + depth]
	sketch.piece(part, top, WorldPalette.pick(palette.gift_box_tops, index))


## A ribbon around a box: down the front at `share` of its width, back over the top and round
## the side at half height.
static func _ribbon(
	sketch: BuildingSketch, front: Rect2, depth: Vector2, share: float, width: float, color: Color
) -> void:
	sketch.mark(&"ribbon_band")
	var x: float = front.position.x + front.size.x * share - width / 2.0
	var band: Rect2 = Rect2(x, front.position.y, width, front.size.y)
	sketch.shade(BuildingSketch.corners(band), color)
	var top: Vector2 = band.position
	var over: PackedVector2Array = [
		top, top + Vector2(width, 0.0), top + Vector2(width, 0.0) + depth, top + depth
	]
	sketch.shade(over, color.lightened(0.15))
	var side: Vector2 = Vector2(front.end.x, front.get_center().y - width / 2.0)
	var down: Vector2 = Vector2(0.0, width)
	sketch.shade([side, side + depth, side + depth + down, side + down], color.darkened(0.18))


## Stitches along the shop front's sides and top (not across the bottom, where the door is).
static func _front_seams(sketch: BuildingSketch, front: Rect2) -> void:
	var inset: float = WorldPalette.current().seam_inset
	var inner: Rect2 = front.grow(-inset)
	var path: PackedVector2Array = [
		Vector2(inner.position.x, front.end.y - inset * 2.0),
		inner.position,
		Vector2(inner.end.x, inner.position.y),
		Vector2(inner.end.x, front.end.y - inset * 2.0),
	]
	sketch.seam(path)


## The shop window with two shelves: empty at Lv 1, goods from Lv 2.
static func _window(
	sketch: BuildingSketch, palette: WorldPalette, front: Rect2, level: int
) -> void:
	var pane: Rect2 = Rect2(WINDOW.position + Vector2(front.position.x, 0.0), WINDOW.size)
	sketch.block(&"shop_window", pane.grow(4.0), palette.tag)
	sketch.shade(BuildingSketch.corners(pane), palette.glass)
	sketch.mark(&"shelves")
	for y: float in SHELF_YS:
		var shelf: Rect2 = Rect2(pane.position.x, y, pane.size.x, 3.0)
		sketch.shade(BuildingSketch.corners(shelf), palette.wood)
	if level >= 2:
		_goods(sketch, palette, pane.position.x)
	var shine: Rect2 = Rect2(pane.position + Vector2(3.0, 3.0), Vector2(6.0, pane.size.y - 6.0))
	sketch.shade(BuildingSketch.corners(shine), Color(palette.glass_shine, 0.45))


## Lv 2: things the floor pickups come from, on the shelves: a party popper, a snow globe and a
## magnet on top, little presents and a ball below.
static func _goods(sketch: BuildingSketch, palette: WorldPalette, left: float) -> void:
	sketch.mark(&"goods")
	var shelf: float = SHELF_YS[0]
	var popper: Vector2 = Vector2(left + 14.0, shelf)
	for tip: Vector2 in [Vector2(-7.0, -24.0), Vector2(0.0, -26.0), Vector2(7.0, -23.0)]:
		var streamer: PackedVector2Array = [
			popper + Vector2(0.0, -15.0), popper + tip * 0.6 + Vector2(2.0, 0.0), popper + tip
		]
		sketch.line(streamer, WorldPalette.pick(palette.toys, 0), 2.0)
	var cone: PackedVector2Array = [
		popper + Vector2(-6.0, 0.0), popper + Vector2(6.0, 0.0), popper + Vector2(0.0, -16.0)
	]
	LookParts.outlined(sketch, cone, WorldPalette.pick(palette.toys, 3))
	var globe: Vector2 = Vector2(left + 39.0, shelf - 11.0)
	var base: Rect2 = Rect2(globe.x - 8.0, shelf - 4.0, 16.0, 4.0)
	LookParts.outlined(sketch, BuildingSketch.corners(base), palette.wood)
	LookParts.outlined(sketch, FeltDraw.circle(globe, 8.0, 16), palette.glass_side)
	sketch.dot(globe + Vector2(0.0, 3.0), 3.0, palette.clover)
	sketch.dot(globe + Vector2(-3.0, -3.0), 2.0, palette.glass_shine)
	var magnet: Vector2 = Vector2(left + 63.0, shelf)
	var horseshoe: PackedVector2Array = [
		magnet + Vector2(-6.0, -3.0),
		magnet + Vector2(-6.0, -12.0),
		magnet + Vector2(-4.0, -17.0),
		magnet + Vector2(0.0, -19.0),
		magnet + Vector2(4.0, -17.0),
		magnet + Vector2(6.0, -12.0),
		magnet + Vector2(6.0, -3.0),
	]
	sketch.line(horseshoe, palette.ink, 7.5)
	sketch.line(horseshoe, WorldPalette.pick(palette.toys, 2), 4.5)
	for side: float in [-6.0, 6.0]:
		sketch.dot(magnet + Vector2(side, -3.0), 2.4, palette.metal)
	var low: float = SHELF_YS[1]
	for i: int in 3:
		var box: Rect2 = Rect2(left + 6.0 + i * 15.0, low - 12.0 + (i % 2) * 2.0, 12.0, 12.0)
		box.size.y = low - box.position.y
		var wrap: Color = WorldPalette.pick(palette.toys, i + 1)
		LookParts.outlined(sketch, BuildingSketch.corners(box), wrap)
		var band: Rect2 = Rect2(box.get_center().x - 1.5, box.position.y, 3.0, box.size.y)
		sketch.shade(BuildingSketch.corners(band), palette.tag)
	var ball: PackedVector2Array = FeltDraw.circle(Vector2(left + 64.0, low - 7.0), 7.0, 16)
	LookParts.outlined(sketch, ball, palette.awning)
	sketch.dot(Vector2(left + 62.0, low - 9.0), 2.0, palette.glass_shine)


static func _door(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	var door: Rect2 = Rect2(DOOR.position + Vector2(front.position.x, 0.0), DOOR.size)
	sketch.block(&"door", door, palette.tag, true)
	var glass: Rect2 = Rect2(door.position + Vector2(8.0, 10.0), Vector2(door.size.x - 16.0, 22.0))
	sketch.shade(BuildingSketch.corners(glass), palette.glass_side)
	sketch.dot(Vector2(door.end.x - 8.0, door.get_center().y + 6.0), 3.0, palette.brass)


## Lv 2: the scalloped felt awning over the window and the door, with cream stripes.
static func _awning(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	var x0: float = front.position.x - AWNING_OVERHANG
	var x1: float = front.end.x + AWNING_OVERHANG
	var hem: float = AWNING_TOP + AWNING_BAND
	var count: int = roundi((x1 - x0) / 13.0)
	var r: float = (x1 - x0) / count / 2.0
	var shape: PackedVector2Array = [Vector2(x0, AWNING_TOP), Vector2(x1, AWNING_TOP)]
	for k: int in range(count - 1, -1, -1):
		var middle: float = x0 + (k + 0.5) * r * 2.0
		for step: int in 7:
			var angle: float = PI * step / 6.0
			shape.append(Vector2(middle + r * cos(angle), hem + r * sin(angle)))
	sketch.piece(&"awning", shape, palette.awning)
	sketch.stripes(shape, Color(palette.tag, 0.9), r * 4.0, r * 2.0, true)
	var band: Rect2 = Rect2(x0, AWNING_TOP, x1 - x0, 3.0)
	sketch.shade(BuildingSketch.corners(band), palette.awning_dark)


## Lv 2: a little brass bell on a bracket next to the door.
static func _bell(sketch: BuildingSketch, palette: WorldPalette, front: Rect2) -> void:
	var x: float = front.position.x + DOOR.end.x + 10.0
	var hang: float = AWNING_TOP + AWNING_BAND + 8.0
	sketch.line([Vector2(x, hang), Vector2(x, hang + 6.0)], palette.light_cord, 1.5)
	var bell: PackedVector2Array = [
		Vector2(x - 6.0, hang + 16.0),
		Vector2(x + 6.0, hang + 16.0),
		Vector2(x + 4.0, hang + 11.0),
		Vector2(x + 2.0, hang + 6.0),
		Vector2(x - 2.0, hang + 6.0),
		Vector2(x - 4.0, hang + 11.0),
	]
	sketch.piece(&"door_bell", bell, palette.brass)
	sketch.dot(Vector2(x, hang + 17.0), 1.8, palette.brass_dark)


## Lv 2: the "PARTY SHOP" sign board on the second box, a little tilted, in sewn felt letters.
static func _sign(sketch: BuildingSketch, palette: WorldPalette, box: Rect2) -> void:
	var size: Vector2 = Vector2(LookParts.letters_width(SIGN_LINES[0], LETTER_SIZE) + 16.0, 40.0)
	var middle: Vector2 = box.get_center() + Vector2(0.0, 2.0)
	var board: Rect2 = Rect2(middle - size / 2.0, size)
	sketch.turn(-0.05, middle)
	sketch.block(&"sign", board, palette.tag)
	var line_height: float = 6.0 * LETTER_SIZE
	var y: float = middle.y - line_height - 1.5
	for text: String in SIGN_LINES:
		var x: float = middle.x - LookParts.letters_width(text, LETTER_SIZE) / 2.0
		LookParts.letters(sketch, text, Vector2(x, y), LETTER_SIZE, palette.sign_text, 2.2)
		y += line_height + 3.0
	sketch.straighten()


## Lv 3: a big ribbon bow on top of the third box.
static func _bow(sketch: BuildingSketch, palette: WorldPalette, knot: Vector2) -> void:
	for side: float in [-1.0, 1.0]:
		var loop: PackedVector2Array = [
			knot,
			knot + Vector2(side * 10.0, -14.0),
			knot + Vector2(side * 20.0, -15.0),
			knot + Vector2(side * 23.0, -7.0),
			knot + Vector2(side * 16.0, -1.0),
		]
		sketch.piece(&"bow", loop, palette.ribbon)
		var tail: PackedVector2Array = [
			knot + Vector2(side * 2.0, 2.0),
			knot + Vector2(side * 12.0, 12.0),
			knot + Vector2(side * 7.0, 13.0),
		]
		sketch.piece(&"bow", tail, palette.ribbon_dark)
	sketch.disc(&"bow", knot + Vector2(0.0, -2.0), 5.0, palette.ribbon_dark)


## Lv 3: a little wooden stand outside with three presents on it.
static func _stand(sketch: BuildingSketch, palette: WorldPalette) -> void:
	var top: Rect2 = Rect2(STAND_LEFT, -30.0, STAND_WIDTH, 7.0)
	for x: float in [top.position.x + 6.0, top.end.x - 6.0]:
		sketch.rod(&"present_stand", [Vector2(x, -24.0), Vector2(x, 0.0)], palette.wood_side, 4.0)
	sketch.block(&"present_stand", top, palette.wood_top)
	var sizes: Array[Vector2] = [Vector2(15.0, 17.0), Vector2(13.0, 12.0), Vector2(12.0, 21.0)]
	var x: float = top.position.x + 3.0
	for i: int in sizes.size():
		var present: Rect2 = Rect2(Vector2(x, top.position.y - sizes[i].y), sizes[i])
		sketch.block(&"present_stand", present, WorldPalette.pick(palette.gift_boxes, i + 1))
		var band: Rect2 = Rect2(present.get_center().x - 2.0, present.position.y, 4.0, sizes[i].y)
		sketch.shade(BuildingSketch.corners(band), WorldPalette.pick(palette.toys, i))
		x += sizes[i].x + 2.0


## A felt balloon on a string tied to the stand.
static func _balloon(
	sketch: BuildingSketch, palette: WorldPalette, tie: Vector2, center: Vector2, index: int
) -> void:
	var bottom: Vector2 = center + Vector2(0.0, 17.0)
	var middle: Vector2 = tie.lerp(bottom, 0.5) + Vector2(5.0, 0.0)
	sketch.line([tie, middle, bottom], palette.light_cord, 1.4)
	var color: Color = WorldPalette.pick(palette.toys, index)
	sketch.piece(&"balloons", LookParts.oval(center, 13.0, 17.0), color)
	var knot: PackedVector2Array = [
		bottom + Vector2(-4.0, 4.0), bottom + Vector2(4.0, 4.0), bottom + Vector2(0.0, -1.0)
	]
	sketch.piece(&"balloons", knot, color)
	var shine: PackedVector2Array = LookParts.oval(center + Vector2(-5.0, -6.0), 3.0, 5.0, 10)
	sketch.shade(shine, palette.glass_shine)


## Ruin: the shop box squashed in at the top with a cracked window, its ribbon lying loose on the
## floor and its lid fallen off next to it.
static func _ruin(sketch: BuildingSketch) -> void:
	var palette: WorldPalette = WorldPalette.current()
	var left: float = -100.0
	var right: float = 60.0
	LookParts.box_shadow(sketch, left, right - left, DEPTH)
	var front: PackedVector2Array = [
		Vector2(left, 0.0),
		Vector2(right, 0.0),
		Vector2(right, -68.0),
		Vector2(30.0, -84.0),
		Vector2(-18.0, -58.0),
		Vector2(-62.0, -72.0),
		Vector2(left, -62.0),
	]
	var side: PackedVector2Array = [
		Vector2(right, 0.0),
		Vector2(right, 0.0) + DEPTH,
		Vector2(right, -68.0) + DEPTH,
		Vector2(right, -68.0),
	]
	sketch.piece(&"squashed_box", side, WorldPalette.pick(palette.gift_box_sides, 0))
	sketch.piece(&"squashed_box", front, WorldPalette.pick(palette.gift_boxes, 0))
	var band: Rect2 = Rect2(-4.0, -90.0, 14.0, 90.0)
	LookParts.clip_shade(sketch, front, band, palette.paint_trim)
	var pane: Rect2 = Rect2(left + 12.0, -46.0, 60.0, 30.0)
	sketch.block(&"cracked_window", pane.grow(4.0), palette.tag)
	sketch.shade(BuildingSketch.corners(pane), palette.glass)
	var crack: PackedVector2Array = [
		pane.position + Vector2(10.0, 0.0),
		pane.position + Vector2(24.0, 14.0),
		pane.position + Vector2(18.0, 20.0),
		pane.position + Vector2(34.0, 30.0),
	]
	sketch.line(crack, palette.ink, 1.4)
	var dent: PackedVector2Array = [Vector2(-56.0, -66.0), Vector2(-20.0, -52.0)]
	sketch.line(dent, Color(palette.ink, 0.5), 1.6)
	var ribbon: PackedVector2Array = [
		Vector2(-124.0, 2.0), Vector2(-114.0, -8.0), Vector2(-100.0, -4.0), Vector2(-86.0, 6.0)
	]
	sketch.rod(&"loose_ribbon", ribbon, palette.paint_trim, 7.0)
	var lid_top: PackedVector2Array = [
		Vector2(70.0, 4.0), Vector2(116.0, 4.0), Vector2(124.0, -8.0), Vector2(78.0, -8.0)
	]
	sketch.piece(&"fallen_lid", lid_top, WorldPalette.pick(palette.gift_box_tops, 0))
	var lip: Rect2 = Rect2(70.0, 4.0, 46.0, 7.0)
	sketch.block(&"fallen_lid", lip, WorldPalette.pick(palette.gift_boxes, 0))
