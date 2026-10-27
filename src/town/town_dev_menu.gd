class_name TownDevMenu
extends CanvasLayer
## Developer menu in town (F1, spec 03 §10): give materials, rebuild or upgrade any building for
## free, add a plushie, fill or clear the Scrapbook, give or clear all tricks, reset the whole
## town. Everything it changes is saved right away (through the town's `changed`).

const PANEL_COLOR: Color = Color(0.1, 0.09, 0.13, 0.92)
## What "Give materials" puts in the jars (developer shortcut, not balance).
const GIFT: Dictionary[String, int] = {"coins": 1000, "stuffing": 50, "thread": 20}
const GIVE_MATERIALS: String = "Give materials"
const EMPTY_JARS: String = "Empty jars"
const BUILD_ALL: String = "Build everything"
const ADD_PLUSHIE: String = "Add plushie"
const FILL_BOOK: String = "Fill Scrapbook"
const CLEAR_BOOK: String = "Clear Scrapbook"
const GIVE_TRICKS: String = "Give all tricks"
const CLEAR_TRICKS: String = "Clear tricks"
const RESET: String = "Reset town"
const RESET_SURE: String = "Really reset?"
## The Scrapbook's pages and entries (to fill it).
const SCRAPBOOK: ScrapbookRules = preload("res://data/scrapbook.tres")

var town: Town
## Everything the menu can do, by button text (tests press them by name).
var buttons: Dictionary[String, Button] = {}


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40


func setup(owner_town: Town) -> void:
	town = owner_town
	_build()


func toggle() -> void:
	visible = not visible


## Presses the button with this text, as if clicked.
func press(text: String) -> void:
	buttons[text].pressed.emit()


## The button that builds the next level of `building` ("Build Toy Box Armory").
static func build_label(building: TownBuilding) -> String:
	return "Build %s" % building.building.display_name


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_menu"):
		get_viewport().set_input_as_handled()
		toggle()


func _build() -> void:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFelt = StyleBoxFelt.hud(12.0)
	style.fill = PANEL_COLOR
	style.pad(14, 14)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(16, 110)
	add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "Developer menu (F1)"
	title.add_theme_color_override("font_color", UiColors.GOLD)
	column.add_child(title)
	_row(column, [GIVE_MATERIALS, EMPTY_JARS], [give_materials, empty_jars])
	for spot: TownSpot in town.layout.spots:
		var building: TownBuilding = town.buildings[spot.id]
		_row(column, [build_label(building)], [_build_one.bind(building)])
	_row(column, [BUILD_ALL, ADD_PLUSHIE], [build_everything, add_plushie])
	_row(column, [FILL_BOOK, CLEAR_BOOK], [fill_scrapbook, clear_scrapbook])
	_row(column, [GIVE_TRICKS, CLEAR_TRICKS], [give_all_tricks, clear_tricks])
	_row(column, [RESET], [_ask_reset])


func _row(parent: Control, labels: Array[String], actions: Array[Callable]) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)
	for i: int in labels.size():
		var button: Button = Button.new()
		button.text = labels[i]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(actions[i])
		row.add_child(button)
		buttons[labels[i]] = button


func give_materials() -> void:
	for material: String in GIFT:
		town.save.materials[material] = town.save.material(material) + GIFT[material]
	_saved()


func empty_jars() -> void:
	town.save.materials.clear()
	_saved()


func _build_one(building: TownBuilding) -> void:
	town.dev_build(building)


## Every building at its top level at once (no moments, just the result).
func build_everything() -> void:
	for spot: TownSpot in town.layout.spots:
		var building: TownBuilding = town.buildings[spot.id]
		while building.building.next(building.level) != null:
			building.level += 1
		building.shown_level = building.level
		building.unlocked = true
		building.queue_redraw()
		town.save.building_levels[String(spot.id)] = building.level
	town.settle()
	_saved()


## The next plushie that hasn't been rescued yet comes home (it waits in the tent if no bed is
## free). Returns it, or null when all are home.
func add_plushie() -> PlushieDef:
	for who: PlushieDef in town.RESCUE_RULES.plushies:
		if town.save.plushies.has(who.id):
			continue
		town.save.plushies[who.id] = "waiting"
		town.save.mark_seen(ScrapbookRules.PLUSHIES, who.id)
		town.refresh_tent()
		town.move_in_waiting()
		_saved()
		return who
	return null


## Every entry of every Scrapbook page counts as seen (Recipes too).
func fill_scrapbook() -> void:
	for page: ScrapbookPage in SCRAPBOOK.pages():
		for entry: ScrapbookEntry in page.entries:
			town.save.mark_seen(page.id, entry.id)
	RecipeBook.load_from(town.save)
	_saved()


func clear_scrapbook() -> void:
	town.save.seen.clear()
	RecipeBook.load_from(town.save)
	_saved()


## Every trick of every building counts as bought (spec 06 §6), whatever the building levels.
func give_all_tricks() -> void:
	for trick: TrickDef in TrickBook.all_tricks(town.layout):
		if not town.save.has_trick(String(trick.id)):
			town.save.tricks.append(String(trick.id))
	_saved()


func clear_tricks() -> void:
	town.save.tricks.clear()
	_saved()


## The first press asks, the second one resets.
func _ask_reset() -> void:
	var button: Button = buttons[RESET]
	if button.text != RESET_SURE:
		button.text = RESET_SURE
		return
	button.text = RESET
	visible = false
	town.reset_requested.emit()


func _saved() -> void:
	town.refresh()
	town.changed.emit()
