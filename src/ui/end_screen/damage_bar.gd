class_name DamageBar
extends Control
## A felt bar showing a weapon's share of the run's damage (end screen, spec 04 §4.1). It
## stretches when its row has room.

const BACK: Color = Color("#e4d6bb")
const FILL: Color = UiColors.TEAL

## 0..1 of the run's total damage.
var share: float = 0.0:
	set(value):
		share = clampf(value, 0.0, 1.0)
		queue_redraw()


func _init(own_share: float = 0.0, width: float = 84.0) -> void:
	share = own_share
	custom_minimum_size = Vector2(width, 14)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var back: Rect2 = Rect2(Vector2.ZERO, size)
	_round(back, BACK)
	if share > 0.0:
		var fill: Rect2 = Rect2(Vector2.ZERO, Vector2(maxf(size.x * share, size.y), size.y))
		_round(fill, FILL)


func _round(rect: Rect2, color: Color) -> void:
	var points: PackedVector2Array = FeltDraw.rounded(rect, rect.size.y / 2.0)
	if points.size() >= 3:
		FeltDraw.fill(self, points, color)
