class_name PlushiePhoto
extends Control
## A rescued plushie standing in a photo's picture area (Brought home, spec 04 §4.3).

## How much of the picture's height the plushie fills.
const FILL: float = 0.8

var plushie: PlushieDef


func _init(who: PlushieDef) -> void:
	plushie = who
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if plushie == null or size.y < 1.0:
		return
	var unit: float = size.y * FILL / PlushieLook.top(plushie, 1.0)
	PlushieLook.draw(self, plushie, Vector2(size.x / 2.0, size.y * 0.92), unit)
