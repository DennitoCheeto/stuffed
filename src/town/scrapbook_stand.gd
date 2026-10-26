class_name ScrapbookStand
extends Node2D
## A little stand with a big open book next to the fort: the Scrapbook (spec 03 §8). E next to it
## opens the book (ScrapbookBook). Drawn with the building art kit (`ScrapbookLook`, spec 05 §3.2).

static var _look: BuildingSketch

var rect: Rect2


func _init(stand_rect: Rect2) -> void:
	rect = stand_rect
	name = "Scrapbook"


func _ready() -> void:
	material = WorldPalette.current().grain_material()
	var sign_label: Label = TownArt.label("Scrapbook", 22)
	add_child(sign_label)
	TownArt.center_label(sign_label, rect.get_center().x, rect.end.y + 10.0, 240.0)


## The stand's look (built once for every stand).
static func look() -> BuildingSketch:
	if _look == null:
		_look = ScrapbookLook.build()
	return _look


func _draw() -> void:
	draw_set_transform(Vector2(rect.get_center().x, rect.end.y))
	look().draw(self)
	draw_set_transform(Vector2.ZERO)
