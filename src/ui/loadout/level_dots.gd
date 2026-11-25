class_name LevelDots
extends Control
## A row of small felt dots: one per level, filled up to the current level (spec 04b §2).

const RADIUS: float = 5.0
const GAP: float = 4.0
const FILLED: Color = UiColors.GOLD
const EMPTY: Color = Color(UiColors.INK_SOFT, 0.3)
const EDGE: Color = UiColors.GOLD_EDGE

var level: int = 0
var top: int = 1


func _init(current: int, top_level: int) -> void:
	level = current
	top = maxi(top_level, 1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(top * (RADIUS * 2.0 + GAP) - GAP, RADIUS * 2.0 + 2.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


## How many dots are filled (for tests).
func filled() -> int:
	return mini(level, top)


func _draw() -> void:
	var y: float = size.y / 2.0
	for index: int in top:
		var center: Vector2 = Vector2(RADIUS + index * (RADIUS * 2.0 + GAP), y)
		if index < level:
			FeltDraw.fill(self, FeltDraw.circle(center, RADIUS + 1.0, 16), EDGE)
			FeltDraw.fill(self, FeltDraw.circle(center, RADIUS, 16), FILLED)
		else:
			FeltDraw.fill(self, FeltDraw.circle(center, RADIUS, 16), EMPTY)
