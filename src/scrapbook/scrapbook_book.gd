class_name ScrapbookBook
extends CanvasLayer
## The Scrapbook, opened (spec 03 §8): a page each for Weapons (and evolutions), Items, Enemies,
## Floor pickups and Plushies, with a count per page ("Weapons 7 / 14"). Seen entries show their
## felt picture and name; unseen ones a silhouette and "?". The entry in focus shows its text
## (and a weapon's evolution partner) next to the grid. Arrow keys / mouse pick an entry, Q / E
## or the tabs turn the page, Esc closes. Keeps working while the town or title is paused.
## Stitched Scrapbook look (spec 04 §6.7): the felt cloth, the book is a taped felt patch with a
## hand-written title, the tabs are fabric tags and the entries are photos (ScrapbookTile).

## The book was closed.
signal closed

const RULES: ScrapbookRules = preload("res://data/scrapbook.tres")
const COLUMNS: int = 5
## Rows the grid always makes room for, so the book keeps its size on every page.
const ROWS: int = 3
const GAP: int = 14
const DETAIL_WIDTH: float = 500.0
const DETAIL_PICTURE: float = 200.0
const INK_COLOR: Color = UiColors.INK
const NOTE_COLOR: Color = UiColors.TEAL
## Fabric-tag tabs: plain, and the open page's.
const TAB_COLOR: Color = UiColors.TAG
const TAB_ON_COLOR: Color = UiColors.STICKER_TEAL
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
## The taped photo around the detail picture.
var detail_photo: PhotoFrame
var detail_name: Label
var detail_text: Label
var detail_note: Label

var cloth: MenuCloth = MenuCloth.new(0.94)
var cover: FeltPanel = FeltPanel.new(-0.8)
var motion: ScreenMotion = ScreenMotion.new()

var _tab_row: HBoxContainer
var _grid: GridContainer


func _init() -> void:
	layer = 19
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(cloth)
	add_child(motion)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	cover.add_tape(0.12, -6.0).add_tape(0.88, 5.0, UiColors.TAPE_PINK)
	center.add_child(cover)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	cover.content.add_child(column)
	column.add_child(HandTitle.new("Scrapbook", 60))
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
	var hint: Label = _ink("Arrows / mouse: look   Q / E: turn the page   Esc: close", 20)
	hint.add_theme_color_override(&"font_color", UiColors.INK_SOFT)
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
	motion.open([cover])


func close() -> void:
	if not visible:
		return
	motion.finish()
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
	for spot: int in page.entries.size():
		var entry: ScrapbookEntry = page.entries[spot]
		var tile: ScrapbookTile = ScrapbookTile.new(entry, page.is_seen(entry, save), spot)
		tile.looked_at.connect(show_details)
		_grid.add_child(tile)
		tiles.append(tile)
	for i: int in tabs.size():
		tabs[i].button_pressed = i == page_index
		(tabs[i] as SewnButton).box.fill = TAB_ON_COLOR if i == page_index else TAB_COLOR
	if tiles.is_empty():
		show_details(null)
	else:
		show_details(tiles[0])
		tiles[0].grab_focus()


## Turns `step` pages forward (negative = back).
func turn(step: int) -> void:
	show_page(page_index + step)
	Sfx.play(&"page")


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
		var tab: SewnButton = _tab(pages[i].count_text(save))
		tab.pressed.connect(show_page.bind(i))
		_tab_row.add_child(tab)
		tabs.append(tab)


func _build_details() -> Control:
	var details: VBoxContainer = VBoxContainer.new()
	details.custom_minimum_size = Vector2(DETAIL_WIDTH, 0.0)
	details.add_theme_constant_override(&"separation", 12)
	var photo_size: Vector2 = Vector2(DETAIL_PICTURE, DETAIL_PICTURE)
	detail_photo = PhotoFrame.new("", photo_size, 2.5, UiColors.TAPE_GOLD)
	detail_photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	details.add_child(detail_photo)
	detail_picture = ScrapbookPicture.new(DETAIL_PICTURE)
	detail_photo.picture.add_child(detail_picture)
	detail_name = _ink("", 42)
	detail_name.add_theme_font_override(&"font", UiFonts.hand())
	detail_name.add_theme_color_override(&"font_color", UiColors.PURPLE)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_child(detail_name)
	detail_text = _ink("", 24)
	details.add_child(detail_text)
	detail_note = _ink("", 22)
	detail_note.add_theme_color_override(&"font_color", NOTE_COLOR)
	details.add_child(detail_note)
	return details


## Dark ink on the paper, wrapping.
func _ink(text: String, font_size: int) -> Label:
	var label: Label = UiFonts.label(text, font_size, INK_COLOR)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(DETAIL_WIDTH, 0.0)
	return label


## A tab is a small fabric tag you can press (it lifts like every sewn button).
func _tab(words: String) -> SewnButton:
	var tab: SewnButton = SewnButton.new(words, false, 22)
	tab.toggle_mode = true
	tab.focus_mode = Control.FOCUS_NONE
	tab.box.fill = TAB_COLOR
	tab.box.radius = 10.0
	tab.box.stitch_inset = 4.0
	tab.box.stitch_width = 2.0
	tab.box.stitch_dash = 6.0
	tab.box.stitch_gap = 4.0
	tab.box.depth = 4.0
	tab.box.pad(18, 6)
	tab.set_stitch(UiColors.TAG_STITCH)
	return tab
