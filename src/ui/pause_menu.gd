class_name PauseMenu
extends CanvasLayer
## The Esc menu (spec 04 §6.2): a taped felt patch on the dimmed cloth with Resume (the gold
## button), Settings (the shared SettingsPanel), Recipes and Give up (back home with half the
## haul). Keeps running while the run is frozen. Built in code (pause_menu.tscn is only the root).

signal resumed
signal quit_requested

const BUTTON_WIDTH: float = 360.0

## The evolutions to list on the Recipes page (the run sets it).
var upgrade_pool: UpgradePool
## Damage numbers, reduced menu animations and volumes (spec 04 §6.2).
var settings: SettingsPanel = SettingsPanel.new()
var cloth: MenuCloth = MenuCloth.new(0.82, 0.35)
var panel: FeltPanel = FeltPanel.new(1.5)
var heading: HandTitle = HandTitle.new("Paused", 64, UiColors.PURPLE, -3.0)
var resume_button: SewnButton = SewnButton.new("Resume", true, 32)
var settings_button: SewnButton = SewnButton.new("Settings")
var recipes_button: SewnButton = SewnButton.new("Recipes")
var quit_button: SewnButton = SewnButton.new("Give up")
var recipes_page: RecipesPage = RecipesPage.new()
var motion: ScreenMotion = ScreenMotion.new()


func _ready() -> void:
	visible = false
	add_child(motion)
	add_child(cloth)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel.add_tape(0.5, 3.0)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 16)
	panel.content.add_child(column)
	column.add_child(heading)
	# Buttons fill the column: it sets their width.
	column.custom_minimum_size.x = BUTTON_WIDTH
	for button: SewnButton in [resume_button, settings_button, recipes_button, quit_button]:
		column.add_child(button)
	recipes_page.visible = false
	add_child(recipes_page)
	recipes_page.back_pressed.connect(_show_main)
	add_child(settings)
	settings.closed.connect(_on_settings_closed)
	resume_button.pressed.connect(close)
	settings_button.pressed.connect(show_settings)
	recipes_button.pressed.connect(show_recipes)
	quit_button.pressed.connect(quit_requested.emit)


func is_open() -> bool:
	return visible


func open() -> void:
	_show_main()
	visible = true
	motion.open([panel])
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	motion.finish()
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
	var from_recipes: bool = recipes_page.visible
	recipes_page.visible = false
	settings.visible = false
	panel.visible = true
	if from_recipes:
		recipes_button.grab_focus()
	else:
		resume_button.grab_focus()
