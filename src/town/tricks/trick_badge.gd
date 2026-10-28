class_name TrickBadge
extends Control
## The round felt badge on a trick patch (spec 06 §2): the trick's step in its branch, "1" or
## "2" on teal felt, or a gold star for the star trick. Stitched around the edge.

const SIDE: float = 58.0
const STEP_COLOR: Color = UiColors.STICKER_TEAL
const STEP_INK: Color = UiColors.STICKER_TEAL_INK
const STAR_COLOR: Color = UiColors.GOLD
const STAR_INK: Color = UiColors.GOLD_INK
const STITCH_INSET: float = 5.0

## 1, 2 or 3 (3 = the star trick).
var step: int = 1
var number: Label


func _init(trick_step: int) -> void:
	step = trick_step
	custom_minimum_size = Vector2(SIDE, SIDE)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	number = UiFonts.label(str(step), 30, STEP_INK, UiFonts.heading())
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	number.visible = not is_star()
	add_child(number)


func is_star() -> bool:
	return step >= 3


func fill_color() -> Color:
	return STAR_COLOR if is_star() else STEP_COLOR


func _draw() -> void:
	var middle: Vector2 = size / 2.0
	var radius: float = minf(size.x, size.y) / 2.0
	FeltDraw.fill(self, FeltDraw.circle(middle, radius), fill_color())
	var seam: PackedVector2Array = FeltDraw.circle(middle, radius - STITCH_INSET, 28)
	var stitch: Color = fill_color().lightened(0.5)
	draw_multiline(FeltDraw.dashes(seam, 4.0, 3.0), stitch, 1.5, true)
	if is_star():
		FeltDraw.fill(self, star(middle, radius * 0.62, radius * 0.27), STAR_INK)


## A five-pointed star around `center`.
static func star(center: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for index: int in 10:
		var angle: float = -PI / 2.0 + index * PI / 5.0
		var reach: float = outer if index % 2 == 0 else inner
		points.append(center + Vector2(cos(angle), sin(angle)) * reach)
	return points
