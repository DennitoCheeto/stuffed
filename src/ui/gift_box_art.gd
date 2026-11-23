class_name GiftBoxArt
extends Control
## The big gift box of the opening moment, drawn around this control's position: it wobbles,
## squashes and stretches, then its lid flies up and tips over.

const BOX_COLOR: Color = GiftBoxLook.BOX_COLOR
const LID_COLOR: Color = GiftBoxLook.LID_COLOR
const RIBBON_COLOR: Color = GiftBoxLook.RIBBON_COLOR
const OUTLINE_COLOR: Color = GiftBoxLook.OUTLINE_COLOR
const HALF_WIDTH: float = 90.0
const BOX_HEIGHT: float = 140.0
const LID_HEIGHT: float = 44.0
const OUTLINE: float = 6.0
## The box stands on this line, below this control's position.
const BOTTOM_Y: float = BOX_HEIGHT / 2.0 + 20.0

## -1..1: how far the box leans while it shakes.
var wobble: float = 0.0:
	set(value):
		wobble = value
		queue_redraw()
## 0 = closed, 1 = the lid has flown off (a little past 1 while it overshoots).
var lid_open: float = 0.0:
	set(value):
		lid_open = value
		queue_redraw()
## Squash and stretch around the box's bottom: 0.1 = 10% flatter and wider, negative = taller.
var squash: float = 0.0:
	set(value):
		squash = value
		queue_redraw()


## Where the middle of the box is drawn, from this control's position.
static func middle() -> Vector2:
	return Vector2(0.0, BOTTOM_Y - BOX_HEIGHT / 2.0)


func _draw() -> void:
	var bottom: Vector2 = Vector2(0.0, BOTTOM_Y)
	var stretch: Vector2 = Vector2(1.0 + squash, 1.0 - squash)
	draw_set_transform(bottom, deg_to_rad(10.0 * wobble), stretch)
	var box: Rect2 = Rect2(-HALF_WIDTH, -BOX_HEIGHT, HALF_WIDTH * 2.0, BOX_HEIGHT)
	_felt_rect(box, BOX_COLOR)
	draw_rect(Rect2(-14.0, -BOX_HEIGHT, 28.0, BOX_HEIGHT), RIBBON_COLOR)
	if lid_open > 0.0:
		# Light spilling out of the open box.
		var light: Color = Color(1.0, 0.9, 0.5, 0.5 * minf(lid_open, 1.0))
		var w: float = HALF_WIDTH
		var top: float = -BOX_HEIGHT
		var far: float = top - 260.0
		var beam: PackedVector2Array = [Vector2(-w, top), Vector2(w, top)]
		beam.append_array([Vector2(w * 1.8, far), Vector2(-w * 1.8, far)])
		draw_colored_polygon(beam, light)
	var box_top: float = -BOX_HEIGHT * (1.0 - squash)
	var lift: Vector2 = Vector2(110.0 * lid_open, box_top - 170.0 * sin(lid_open * PI * 0.6))
	var lean: float = deg_to_rad(10.0 * wobble)
	draw_set_transform(bottom + lift.rotated(lean), deg_to_rad(35.0 * lid_open), Vector2.ONE)
	var lid_width: float = HALF_WIDTH + 12.0
	_felt_rect(Rect2(-lid_width, -LID_HEIGHT, lid_width * 2.0, LID_HEIGHT), LID_COLOR)
	draw_rect(Rect2(-14.0, -LID_HEIGHT, 28.0, LID_HEIGHT), RIBBON_COLOR)
	for side: float in [-1.0, 1.0]:
		_ellipse(Vector2(side * 30.0, -LID_HEIGHT - 16.0), Vector2(30.0, 18.0), RIBBON_COLOR)


func _felt_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(OUTLINE), OUTLINE_COLOR)
	draw_rect(rect, color)
	var shade: Rect2 = Rect2(rect.position.x, rect.end.y - 14.0, rect.size.x, 14.0)
	draw_rect(shade, color.darkened(0.25))


func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var outline: PackedVector2Array = FeltShapes.ellipse(center, radii + Vector2.ONE * OUTLINE)
	draw_colored_polygon(outline, OUTLINE_COLOR)
	draw_colored_polygon(FeltShapes.ellipse(center, radii), color)
