class_name TitleScreen
extends Control
## The first screen (spec 04 §6.1): the game name hand-written on the purple felt cloth, and the
## menu as sewn buttons on a taped felt patch: Continue (or New game the first time), Scrapbook,
## Settings, Quit and a small "Start over". Continue and New game open the town. Works with mouse
## and keyboard. Scrapbook and "Start over" only show with a saved town; "Start over" asks twice
## before the town is deleted. Settings opens the shared SettingsPanel. Built in code
## (title_screen.tscn is only the root).

signal start_requested
signal quit_requested
## The player confirmed "Start over" twice: the saved town should be deleted.
signal start_over_requested

const ASKS: PackedStringArray = [
	"Start over with a new town?",
	"Really? Your whole town will be gone.",
]
const GAME_NAME: String = "Stuffed"
const TAGLINE: String = "Stuffed animals vs. zombie plushies"
const NAME_SIZE: int = 170
const NAME_OUTLINE: int = 14
const MENU_WIDTH: float = 380.0

## Main sets this before the screen is shown: a saved town exists.
var has_save: bool = false
## Main sets this too: the saved town (what the Scrapbook shows).
var save: TownSave = TownSave.new()
var cloth: MenuCloth = MenuCloth.new()
## The hand-written game name and the line under it.
var logo: HandTitle = HandTitle.new(GAME_NAME, NAME_SIZE, UiColors.GOLD, -4.0)
var title_label: Label = logo.label
var tagline: HandTitle = HandTitle.new(TAGLINE, 34, UiColors.FELT, -1.5)
## The felt patch with the menu buttons.
var menu_panel: FeltPanel = FeltPanel.new(1.2)
var start_button: SewnButton = SewnButton.new("New game", true, 36)
## Opens the Scrapbook (only with a saved town).
var scrapbook_button: SewnButton = SewnButton.new("Scrapbook")
var settings_button: SewnButton = SewnButton.new("Settings")
var quit_button: SewnButton = SewnButton.new("Quit")
var start_over_button: SewnButton = SewnButton.new("Start over", false, 20)
var book: ScrapbookBook = ScrapbookBook.new()
var settings: SettingsPanel = SettingsPanel.new()
## The confirm patch (question + Yes / No), hidden until "Start over" is pressed.
var confirm_box: FeltPanel = FeltPanel.new(-1.5)
var confirm_label: Label = UiFonts.label("", 40, UiColors.INK, UiFonts.heading(600))
var yes_button: SewnButton = SewnButton.new("Yes")
var no_button: SewnButton = SewnButton.new("No, keep my town", true)
## 0 = not asking, 1 = first question shown, 2 = second question shown.
var confirm_step: int = 0
var version_label: Label = UiFonts.label("", 20, Color(UiColors.FELT, 0.7))
var motion: ScreenMotion = ScreenMotion.new()

## Everything of the main menu (hidden while the Scrapbook, Settings or the question is up).
var _front: VBoxContainer = VBoxContainer.new()


func _ready() -> void:
	_build()
	version_label.text = GameInfo.version_label()
	start_button.text = start_text()
	scrapbook_button.visible = has_save
	start_over_button.visible = has_save
	start_button.pressed.connect(start_requested.emit)
	scrapbook_button.pressed.connect(open_scrapbook)
	settings_button.pressed.connect(open_settings)
	quit_button.pressed.connect(quit_requested.emit)
	start_over_button.pressed.connect(press_start_over)
	yes_button.pressed.connect(_on_yes)
	no_button.pressed.connect(_close_confirm)
	book.closed.connect(_on_book_closed)
	settings.closed.connect(_on_settings_closed)
	start_button.grab_focus()
	motion.open([logo, tagline, menu_panel])


## "Continue" with a saved town, else "New game".
func start_text() -> String:
	return "Continue" if has_save else "New game"


## Pressing "Start over", then Yes twice, deletes the town. No (or Esc) backs out at any step.
func press_start_over() -> void:
	confirm_step = 1
	_show_confirm()


func _on_yes() -> void:
	if confirm_step < ASKS.size():
		confirm_step += 1
		_show_confirm()
		return
	_close_confirm()
	has_save = false
	start_over_button.visible = false
	scrapbook_button.visible = false
	start_button.text = start_text()
	start_over_requested.emit()


func _close_confirm() -> void:
	confirm_step = 0
	confirm_box.visible = false
	_front.visible = true
	start_button.grab_focus()


func _show_confirm() -> void:
	confirm_label.text = ASKS[confirm_step - 1]
	yes_button.text = "Yes, start over" if confirm_step == ASKS.size() else "Yes"
	_front.visible = false
	confirm_box.visible = true
	motion.open([confirm_box])
	no_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if settings.visible:
		return
	if confirm_step > 0 and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_close_confirm()


## Opens the Scrapbook over the title; the menu comes back when it closes.
func open_scrapbook() -> void:
	_front.visible = false
	book.open(save)


func _on_book_closed() -> void:
	_front.visible = true
	scrapbook_button.grab_focus()


func open_settings() -> void:
	_front.visible = false
	settings.open()


func _on_settings_closed() -> void:
	_front.visible = true
	settings_button.grab_focus()


func _build() -> void:
	add_child(motion)
	add_child(cloth)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_front.add_theme_constant_override(&"separation", 0)
	center.add_child(_front)
	title_label.add_theme_constant_override(&"outline_size", NAME_OUTLINE)
	title_label.add_theme_color_override(&"font_outline_color", UiColors.GOLD_EDGE.darkened(0.35))
	title_label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.3))
	title_label.add_theme_constant_override(&"shadow_offset_y", 8)
	_front.add_child(logo)
	_front.add_child(tagline)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = 28.0
	_front.add_child(gap)
	menu_panel.add_tape(0.5, -4.0).add_tape(0.06, 9.0, UiColors.TAPE_PINK)
	menu_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_front.add_child(menu_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 14)
	# Buttons fill the column: it sets their width.
	column.custom_minimum_size.x = MENU_WIDTH
	menu_panel.content.add_child(column)
	for button: SewnButton in [start_button, scrapbook_button, settings_button, quit_button]:
		column.add_child(button)
	start_over_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(start_over_button)
	_build_confirm()
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.offset_left = -440.0
	version_label.offset_top = -76.0
	version_label.offset_right = -40.0
	version_label.offset_bottom = -36.0
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(version_label)
	add_child(book)
	add_child(settings)


## The question patch in the middle of the screen: the question, Yes and "No, keep my town".
func _build_confirm() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	confirm_box.add_tape(0.5, 3.0, UiColors.TAPE_TEAL)
	confirm_box.visible = false
	center.add_child(confirm_box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 18)
	confirm_box.content.add_child(column)
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(confirm_label)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 28)
	buttons.add_child(no_button)
	buttons.add_child(yes_button)
	column.add_child(buttons)
