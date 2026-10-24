class_name PauseMenu
extends CanvasLayer
## The Esc menu: Resume, Settings (the shared SettingsPanel), Recipes, Give up (back home with
## half the haul). Keeps running while the run is frozen.

signal resumed
signal quit_requested

## The evolutions to list on the Recipes page (the run sets it).
var upgrade_pool: UpgradePool
var recipes_button: Button
var recipes_page: RecipesPage
## Damage numbers, reduced menu animations and volumes (spec 04 §6.2).
var settings: SettingsPanel = SettingsPanel.new()

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	_build_recipes()
	add_child(settings)
	settings.closed.connect(_on_settings_closed)
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(show_settings)
	quit_button.pressed.connect(quit_requested.emit)


func is_open() -> bool:
	return visible


func open() -> void:
	_show_main()
	visible = true
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	settings.visible = false
	visible = false
	GameSettings.save()
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or recipes_page.visible or settings.visible:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()


## Shows the Settings page instead of the menu.
func show_settings() -> void:
	panel.visible = false
	settings.open()


func _on_settings_closed() -> void:
	panel.visible = true
	settings_button.grab_focus()


## Shows the Recipes page instead of the menu.
func show_recipes() -> void:
	panel.visible = false
	recipes_page.visible = true
	recipes_page.show_recipes(upgrade_pool)


func _show_main() -> void:
	recipes_page.visible = false
	settings.visible = false
	panel.visible = true
	resume_button.grab_focus()


## A Recipes button above Quit, and the page it opens (both styled like the menu).
func _build_recipes() -> void:
	recipes_button = resume_button.duplicate() as Button
	recipes_button.text = "Recipes"
	quit_button.add_sibling(recipes_button)
	quit_button.get_parent().move_child(recipes_button, quit_button.get_index())
	recipes_button.pressed.connect(show_recipes)
	var back: Button = resume_button.duplicate() as Button
	recipes_page = RecipesPage.new(panel.get_theme_stylebox("panel"), back)
	recipes_page.visible = false
	add_child(recipes_page)
	recipes_page.back_pressed.connect(_show_main)
