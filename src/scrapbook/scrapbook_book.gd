class_name ScrapbookBook
extends CanvasLayer
## The Scrapbook, opened (spec 03 §8): a page each for Weapons (and evolutions), Items, Enemies,
## Floor pickups and Plushies, with a count per page ("Weapons 7 / 14"). Seen entries show their
## felt picture and name; unseen ones a silhouette and "?". The entry in focus shows its text
## (and a weapon's evolution partner) next to the grid. Arrow keys / mouse pick an entry, Q / E
## or the tabs turn the page, Esc closes. Keeps working while the town or title is paused.

## The book was closed.
signal closed

const RULES: ScrapbookRules = preload("res://data/scrapbook.tres")
const COLUMNS: int = 5
## Rows the grid always makes room for, so the book keeps its size on every page.
const ROWS: int = 3
const GAP: int = 14
const DETAIL_WIDTH: float = 500.0
const DETAIL_PICTURE: float = 200.0
const COVER_COLOR: Color = Color("#6f8fb8")
const PAPER_COLOR: Color = Color("#f6f0e3")
const INK_COLOR: Color = Color("#3b3346")
const NOTE_COLOR: Color = Color("#8a5a2b")
const TAB_COLOR: Color = Color("#dfe8f2")
const TAB_ON_COLOR: Color = Color("#f2b52e")
const UNSEEN_TEXT: String = "Not found yet."
## How to fill each page (shown for an unseen entry).
const HOW_TO_FIND: Dictionary[String, String] = {
	"weapons": "Take it on a level-up card, or evolve a weapon, to add it here.",
	"items": "Take it on a level-up card to add it here.",
	"enemies": "Meet it in a run to add it here.",
	"floor_pickups": "Grab it in a run to add it here.",
	"plushies": "Rescue them in a run to add them here.",
}

var save: TownSave = TownSave.new()
var pages: Array[ScrapbookPage] = []
var page_index: int = 0
## One tab per page ("Weapons 7 / 14").
var tabs: Array[Button] = []
## The current page's tiles, in book order.
var tiles: Array[ScrapbookTile] = []
## The entry shown in the details (null = none).
var shown: ScrapbookEntry
var detail_picture: ScrapbookPicture
var detail_name: Label
var detail_text: Label
var detail_note: Label

var _tab_row: HBoxContainer
var _grid: GridContainer


func _init() -> void:
	layer = 19
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.08, 0.85)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var cover: PanelContainer = PanelContainer.new()
	cover.add_theme_stylebox_override(&"panel", _box(PAPER_COLOR, COVER_COLOR, 14, 28))
	cover.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	cover.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cover.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(cover)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 18)
	cover.add_child(column)
	column.add_child(TownArt.label("Scrapbook", 56))
	_tab_row = HBoxContainer.new()
	_tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tab_row.add_theme_constant_override(&"separation", 10)
	column.add_child(_tab_row)
	var body: HBoxContainer = HBoxContainer.new()
	body.add_theme_constant_override(&"separation", 28)
	column.add_child(body)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override(&"h_separation", GAP)
	_grid.add_theme_constant_override(&"v_separation", GAP)
	var tile: Vector2 = ScrapbookTile.SIZE
	_grid.custom_minimum_size = Vector2(
		COLUMNS * tile.x + (COLUMNS - 1) * GAP, ROWS * tile.y + (ROWS - 1) * GAP
	)
	body.add_child(_grid)
	body.add_child(_build_details())
	var hint: Label = _ink("Arrows / mouse: look   Q / E: turn the page   Esc: close", 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)


func is_open() -> bool:
	return visible


## Opens the book on its first page with what `town_save` has seen.
func open(town_save: TownSave) -> void:
	save = town_save
	pages = RULES.pages()
	_build_tabs()
	visible = true
	show_page(0)


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Turns to page `index` (wraps around) and focuses its first entry.
func show_page(index: int) -> void:
	page_index = wrapi(index, 0, pages.size())
	for old: Node in _grid.get_children():
		_grid.remove_child(old)
		old.queue_free()
	tiles.clear()
	var page: ScrapbookPage = pages[page_index]
	for entry: ScrapbookEntry in page.entries:
		var tile: ScrapbookTile = ScrapbookTile.new(entry, page.is_seen(entry, save))
		tile.looked_at.connect(show_details)
		_grid.add_child(tile)
		tiles.append(tile)
	for i: int in tabs.size():
		tabs[i].button_pressed = i == page_index
	if tiles.is_empty():
		show_details(null)
	else:
		show_details(tiles[0])
		tiles[0].grab_focus()


## Turns `step` pages forward (negative = back).
func turn(step: int) -> void:
	show_page(page_index + step)
	Sfx.play(&"pop", 1.2)


func current_page() -> ScrapbookPage:
	return pages[page_index]


## The tile of entry `id` on the current page, or null.
func tile_for(id: String) -> ScrapbookTile:
	for tile: ScrapbookTile in tiles:
		if tile.entry.id == id:
			return tile
	return null


## Shows `tile`'s entry next to the grid: picture, name, text and note, or "?" while unseen.
func show_details(tile: ScrapbookTile) -> void:
	shown = tile.entry if tile != null else null
	var seen: bool = tile != null and tile.seen
	detail_picture.show_entry(shown, seen)
	if shown == null:
		detail_name.text = ""
		detail_text.text = ""
		detail_note.text = ""
	elif seen:
		detail_name.text = shown.display_name
		detail_text.text = shown.text
		detail_note.text = shown.note
	else:
		detail_name.text = ScrapbookTile.UNSEEN_NAME
		detail_text.text = UNSEEN_TEXT
		detail_note.text = HOW_TO_FIND.get(current_page().id, "")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_Q or key.keycode == KEY_PAGEUP:
		get_viewport().set_input_as_handled()
		turn(-1)
	elif key.keycode == KEY_E or key.keycode == KEY_PAGEDOWN:
		get_viewport().set_input_as_handled()
		turn(1)


func _build_tabs() -> void:
	for old: Button in tabs:
		_tab_row.remove_child(old)
		old.queue_free()
	tabs.clear()
	for i: int in pages.size():
		var tab: Button = Button.new()
		tab.text = pages[i].count_text(save)
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_size_override(&"font_size", 24)
		tab.add_theme_color_override(&"font_color", INK_COLOR)
		tab.add_theme_color_override(&"font_pressed_color", INK_COLOR)
		tab.add_theme_color_override(&"font_hover_color", INK_COLOR)
		tab.add_theme_color_override(&"font_hover_pressed_color", INK_COLOR)
		tab.add_theme_stylebox_override(&"normal", _tab_box(TAB_COLOR))
		tab.add_theme_stylebox_override(&"hover", _tab_box(TAB_COLOR.lightened(0.4)))
		tab.add_theme_stylebox_override(&"pressed", _tab_box(TAB_ON_COLOR))
		tab.add_theme_stylebox_override(&"hover_pressed", _tab_box(TAB_ON_COLOR))
		tab.pressed.connect(show_page.bind(i))
		_tab_row.add_child(tab)
		tabs.append(tab)


func _build_details() -> Control:
	var details: VBoxContainer = VBoxContainer.new()
	details.custom_minimum_size = Vector2(DETAIL_WIDTH, 0.0)
	details.add_theme_constant_override(&"separation", 12)
	detail_picture = ScrapbookPicture.new(DETAIL_PICTURE)
	details.add_child(detail_picture)
	detail_name = _ink("", 38)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_child(detail_name)
	detail_text = _ink("", 26)
	details.add_child(detail_text)
	detail_note = _ink("", 24)
	detail_note.add_theme_color_override(&"font_color", NOTE_COLOR)
	details.add_child(detail_note)
	return details


## Dark ink on the paper, wrapping.
func _ink(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(DETAIL_WIDTH, 0.0)
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", INK_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _tab_box(fill: Color) -> StyleBoxFlat:
	return _box(fill, COVER_COLOR, 3, 10)


func _box(fill: Color, edge: Color, width: int, margin: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(width)
	box.set_corner_radius_all(16)
	box.set_content_margin_all(margin)
	return box
