class_name ScrapbookStand
extends Node2D
## A little stand with a big open book next to the fort: the Scrapbook (spec 03 §8). The book
## itself opens in M3-11; for now walking up shows "coming soon".

const STAND_COLOR: Color = Color("#8a7660")
const COVER_COLOR: Color = Color("#6f8fb8")
const PAGE_COLOR: Color = Color("#f1eadb")
const LINE_COLOR: Color = Color(0.3, 0.3, 0.4, 0.3)

var rect: Rect2


func _init(stand_rect: Rect2) -> void:
	rect = stand_rect
	name = "Scrapbook"


func _ready() -> void:
	var sign_label: Label = TownArt.label("Scrapbook", 22)
	add_child(sign_label)
	TownArt.center_label(sign_label, rect.get_center().x, rect.end.y + 10.0, 240.0)


func _draw() -> void:
	TownArt.pillow(self, rect, STAND_COLOR)
	var book: Rect2 = Rect2(rect.position + Vector2(8, -26), Vector2(rect.size.x - 16, 70))
	TownArt.pillow(self, book, COVER_COLOR, false)
	var page_size: Vector2 = Vector2(book.size.x / 2.0 - 10, book.size.y - 14)
	for side: int in 2:
		var page: Rect2 = Rect2(book.position + Vector2(6 + side * (page_size.x + 8), 7), page_size)
		draw_rect(page, PAGE_COLOR)
		for row: int in 4:
			var y: float = page.position.y + 12 + row * 11
			draw_line(Vector2(page.position.x + 6, y), Vector2(page.end.x - 6, y), LINE_COLOR, 2.0)
