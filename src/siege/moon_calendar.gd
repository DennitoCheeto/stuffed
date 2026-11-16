class_name MoonCalendar
extends Node2D
## The felt moon calendar next to the fort door (spec 07 §2, AC-74): how many nights until the
## horde comes. Hidden until the first warning. Drawn with the building art kit
## (`MoonCalendarLook`); the sign text under it comes from `SiegeRules`.

## Nights to go (-1 = no warning yet, 0 = the siege is due).
var nights: int = -1
var sign_label: Label

var _look: BuildingSketch
var _text: String = ""


func _init(at: Vector2) -> void:
	name = "MoonCalendar"
	position = at
	visible = false


func _ready() -> void:
	material = WorldPalette.current().grain_material()
	sign_label = TownArt.label(_text, 22)
	add_child(sign_label)
	TownArt.center_label(sign_label, 0.0, 10.0, 300.0)


## Shows `nights_left` to go out of `slots` moons with the sign `text` (hidden before a warning).
func show_nights(nights_left: int, slots: int, text: String) -> void:
	nights = nights_left
	visible = nights_left >= 0
	_text = text
	if sign_label != null:
		sign_label.text = text
	_look = MoonCalendarLook.build(nights_left, slots) if visible else null
	queue_redraw()


func shown_text() -> String:
	return _text if visible else ""


func look() -> BuildingSketch:
	return _look


func _draw() -> void:
	if _look != null:
		_look.draw(self)
