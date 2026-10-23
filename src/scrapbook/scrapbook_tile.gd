class_name ScrapbookTile
extends Button
## One spot on a Scrapbook page: the felt picture and the name, or a silhouette and "?" while it
## hasn't been seen. Focusing or hovering it shows its details next to the grid.

## Focused or hovered: show my details.
signal looked_at(tile: ScrapbookTile)

const SIZE: Vector2 = Vector2(176, 176)
const PICTURE: float = 104.0
const UNSEEN_NAME: String = "?"
const TILE_COLOR: Color = Color("#f1eadb")
const UNSEEN_COLOR: Color = Color("#d9d0c0")
const EDGE_COLOR: Color = Color("#c9bba4")
const FOCUS_COLOR: Color = Color("#f2b52e")
const NAME_COLOR: Color = Color("#3b3346")

var entry: ScrapbookEntry
var seen: bool = false
var picture: ScrapbookPicture
var name_label: Label


func _init(what: ScrapbookEntry, is_seen: bool) -> void:
	entry = what
	seen = is_seen
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_ALL
	var paper: Color = TILE_COLOR if seen else UNSEEN_COLOR
	add_theme_stylebox_override(&"normal", _panel(paper, EDGE_COLOR))
	add_theme_stylebox_override(&"hover", _panel(paper, FOCUS_COLOR.darkened(0.2)))
	add_theme_stylebox_override(&"pressed", _panel(paper, FOCUS_COLOR))
	add_theme_stylebox_override(&"focus", _panel(Color(0, 0, 0, 0), FOCUS_COLOR, 5))
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	picture = ScrapbookPicture.new(PICTURE)
	picture.show_entry(entry, seen)
	column.add_child(picture)
	name_label = Label.new()
	name_label.text = entry.display_name if seen else UNSEEN_NAME
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override(&"font_size", 20)
	name_label.add_theme_color_override(&"font_color", NAME_COLOR)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_label)
	focus_entered.connect(func() -> void: looked_at.emit(self))
	mouse_entered.connect(func() -> void: looked_at.emit(self))


func _panel(fill: Color, edge: Color, width: int = 3) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(width)
	box.set_corner_radius_all(14)
	return box
