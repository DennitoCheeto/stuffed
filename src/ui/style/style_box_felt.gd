class_name StyleBoxFelt
extends StyleBox
## A felt patch (spec 04 §2): soft rounded felt with a dashed stitch line just inside the edge,
## an optional soft shadow, a thick bottom edge (buttons you press into) and tape strips on top.

const TAPE_SIZE: Vector2 = Vector2(90, 26)

@export var fill: Color = UiColors.FELT:
	set(value):
		fill = value
		emit_changed()
@export var stitch: Color = UiColors.STITCH:
	set(value):
		stitch = value
		emit_changed()
## Colour of the thick bottom edge (only drawn when `depth` > 0).
@export var edge: Color = UiColors.CREAM_EDGE:
	set(value):
		edge = value
		emit_changed()
@export var radius: float = 26.0:
	set(value):
		radius = value
		emit_changed()
## How far inside the edge the stitch line runs; 0 = no stitches.
@export var stitch_inset: float = 12.0:
	set(value):
		stitch_inset = value
		emit_changed()
@export var stitch_width: float = 3.0
@export var stitch_dash: float = 10.0
@export var stitch_gap: float = 7.0
## Thick bottom edge in px (a button's "body" you press into).
@export var depth: float = 0.0:
	set(value):
		depth = value
		emit_changed()
## Soft drop shadow below the patch (alpha 0 = none).
@export var shadow: Color = Color(0, 0, 0, 0)
@export var shadow_offset: float = 8.0

## 0 = resting on its edge, 1 = pressed all the way down into it.
var press: float = 0.0:
	set(value):
		press = clampf(value, 0.0, 1.0)
		emit_changed()
## Tape strips on the top edge: x = position as a share of the width, y = turn in degrees.
var tape_spots: Array[Vector2] = []
var tape_colors: Array[Color] = []


func _init(own_fill: Color = UiColors.FELT, own_stitch: Color = UiColors.STITCH) -> void:
	fill = own_fill
	stitch = own_stitch


## The HUD's quiet backing (spec 04 §2.3): dark felt, a thin soft stitch, no shadow or tape.
static func hud(corner: float = 12.0, inset: float = 4.0) -> StyleBoxFelt:
	var box: StyleBoxFelt = StyleBoxFelt.new(UiColors.HUD_FELT, UiColors.HUD_STITCH)
	box.radius = corner
	box.stitch_inset = inset
	box.stitch_width = 1.5
	box.stitch_dash = 6.0
	box.stitch_gap = 4.0
	return box


## Sets the space kept free for content inside the patch (the stitches and the edge included).
func pad(sides: float, top_bottom: float) -> StyleBoxFelt:
	content_margin_left = sides
	content_margin_right = sides
	content_margin_top = top_bottom
	content_margin_bottom = top_bottom + depth
	return self


## Adds a tape strip on the top edge at `at` (share of the width), turned by `degrees`.
func add_tape(at: float, degrees: float, color: Color) -> StyleBoxFelt:
	tape_spots.append(Vector2(at, degrees))
	tape_colors.append(color)
	emit_changed()
	return self


## The face of the patch inside `rect` (above the bottom edge, moved down when pressed).
func face_rect(rect: Rect2) -> Rect2:
	var sink: float = depth * press
	return Rect2(rect.position + Vector2(0, sink), rect.size - Vector2(0, depth))


## The dashed stitch line as multiline point pairs, for drawing and for tests.
func stitch_points(rect: Rect2) -> PackedVector2Array:
	if stitch_inset <= 0.0:
		return PackedVector2Array()
	var inner: Rect2 = face_rect(rect).grow(-stitch_inset)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return PackedVector2Array()
	var path: PackedVector2Array = FeltDraw.rounded(inner, maxf(radius - stitch_inset, 2.0))
	return FeltDraw.dashes(path, stitch_dash, stitch_gap)


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if shadow.a > 0.0:
		var low: Rect2 = Rect2(rect.position + Vector2(0, shadow_offset), rect.size)
		_polygon(to_canvas_item, FeltDraw.rounded(low, radius), shadow)
	if depth > 0.0:
		var bottom: Rect2 = Rect2(rect.position + Vector2(0, depth), rect.size - Vector2(0, depth))
		_polygon(to_canvas_item, FeltDraw.rounded(bottom, radius), edge)
	var face: Rect2 = face_rect(rect)
	_polygon(to_canvas_item, FeltDraw.rounded(face, radius), fill)
	var stitches: PackedVector2Array = stitch_points(rect)
	if not stitches.is_empty():
		var colors: PackedColorArray = [stitch]
		RenderingServer.canvas_item_add_multiline(
			to_canvas_item, stitches, colors, stitch_width, true
		)
	for index: int in tape_spots.size():
		var spot: Vector2 = tape_spots[index]
		var center: Vector2 = Vector2(face.position.x + face.size.x * spot.x, face.position.y)
		var shape: PackedVector2Array = FeltDraw.tape(
			center, TAPE_SIZE.x, TAPE_SIZE.y, deg_to_rad(spot.y)
		)
		_polygon(to_canvas_item, shape, tape_colors[index])


func _polygon(item: RID, points: PackedVector2Array, color: Color) -> void:
	FeltDraw.fill_smooth(item, points, color)
