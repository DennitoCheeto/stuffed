class_name StarBadge
extends Control
## A little felt star next to the "Star of the run" sticker (the fonts have no star sign).

const POINTS: int = 5
const INNER: float = 0.45


func _init(side: float = 40.0) -> void:
	custom_minimum_size = Vector2(side, side)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var radius: float = minf(size.x, size.y) / 2.0
	var center: Vector2 = size / 2.0
	FeltDraw.fill(self, star(center, radius), UiColors.GOLD_EDGE)
	FeltDraw.fill(self, star(center, radius - 3.0), UiColors.GOLD)


## The outline of a five-pointed star around `center`, point up.
static func star(center: Vector2, radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for index: int in POINTS * 2:
		var reach: float = radius if index % 2 == 0 else radius * INNER
		var angle: float = -PI / 2.0 + PI * index / POINTS
		points.append(center + Vector2(cos(angle), sin(angle)) * reach)
	return points
