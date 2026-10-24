class_name TapeStrip
extends Control
## A loose strip of see-through washi tape (spec 04 §2, look B) filling its own rect.
## Panels and photos draw theirs through StyleBoxFelt.add_tape instead.

var color: Color = UiColors.TAPE_GOLD


func _init(own: Color = UiColors.TAPE_GOLD, length: float = 90.0, width: float = 26.0) -> void:
	color = own
	custom_minimum_size = Vector2(length, width)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if size.x < 8.0 or size.y < 4.0:
		return
	FeltDraw.fill(self, FeltDraw.tape(size / 2.0, size.x, size.y, 0.0), color)
