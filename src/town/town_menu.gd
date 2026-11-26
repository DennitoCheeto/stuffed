class_name TownMenu
extends CanvasLayer
## The Esc menu in town (look from spec 04): back to the fort, Settings (the shared
## SettingsPanel), the title screen, or quit the game. Keeps working while the town is paused.

signal resumed
signal title_requested
signal quit_requested
## "My loadout" was pressed: the town fills the page (`show_loadout`).
signal loadout_requested

const BUTTON_WIDTH: float = 380.0

var resume_button: SewnButton = SewnButton.new("Back to the fort", true, 32)
var loadout_button: SewnButton = SewnButton.new(TownLoadoutPage.TEXTS.town_button)
var settings_button: SewnButton = SewnButton.new("Settings")
## The "My loadout" page (spec 04b §3), shown instead of the menu.
var loadout_page: TownLoadoutPage = TownLoadoutPage.new()
var title_button: SewnButton = SewnButton.new("Title screen")
var quit_button: SewnButton = SewnButton.new("Quit game")
var settings: SettingsPanel = SettingsPanel.new()
## The felt patch with the buttons (hidden while Settings is open).
var panel: FeltPanel = FeltPanel.new(-1.5)
var motion: ScreenMotion = ScreenMotion.new()

## True while the page was opened at the corkboard: Back closes the whole menu.
var _board_only: bool = false
## True right after the corkboard page closed: the town ignores that key press once (it reads
## the keys before the hero's own after-a-screen guard, #336), or E would reopen the page.
var _swallow_press: bool = false


func _init() -> void:
	layer = 20
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(motion)
	add_child(MenuCloth.new(0.8, 0.3))
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel.add_tape(0.5, -3.0, UiColors.TAPE_TEAL)
	center.add_child(panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	panel.content.add_child(box)
	box.add_child(HandTitle.new("The Pillow Fort", 56, UiColors.PURPLE, -2.5))
	# Buttons fill the column: it sets their width.
	box.custom_minimum_size.x = BUTTON_WIDTH
	var buttons: Array[SewnButton] = [
		resume_button, loadout_button, settings_button, title_button, quit_button
	]
	for button: SewnButton in buttons:
		box.add_child(button)
	resume_button.pressed.connect(close)
	loadout_button.pressed.connect(loadout_requested.emit)
	loadout_page.visible = false
	add_child(loadout_page)
	loadout_page.back_pressed.connect(_on_loadout_back)
	settings_button.pressed.connect(show_settings)
	title_button.pressed.connect(title_requested.emit)
	quit_button.pressed.connect(quit_requested.emit)
	add_child(settings)
	settings.closed.connect(_on_settings_closed)


func is_open() -> bool:
	return visible


func open() -> void:
	_board_only = false
	settings.visible = false
	loadout_page.visible = false
	panel.visible = true
	visible = true
	motion.open([panel])
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if loadout_page.visible:
		return
	if visible and not settings.visible and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


## Shows the Settings page instead of the menu.
func show_settings() -> void:
	panel.visible = false
	settings.open()


## Shows the "My loadout" page for the town in `save` and every hero in `players`. With
## `board_only` (opened at the corkboard) the menu opens straight onto the page and Back closes
## it all; otherwise Back returns to the menu.
func show_loadout(
	save: TownSave, layout: TownLayout, players: Array[Player], board_only: bool = false
) -> void:
	if board_only:
		visible = true
		settings.visible = false
	_board_only = board_only
	panel.visible = false
	loadout_page.visible = true
	loadout_page.show_loadout(save, layout, players)


## True once, on the town's first frame after the corkboard page closed (see `_swallow_press`).
func swallows_press() -> bool:
	var swallow: bool = _swallow_press
	_swallow_press = false
	return swallow


func _on_loadout_back() -> void:
	loadout_page.visible = false
	if _board_only:
		_board_only = false
		_swallow_press = true
		close()
		return
	panel.visible = true
	loadout_button.grab_focus()


func _on_settings_closed() -> void:
	panel.visible = true
	settings_button.grab_focus()
