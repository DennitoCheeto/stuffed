class_name GoalScreen
extends CanvasLayer
## Shown when the run goal is reached (the boss is beaten): "You beat the Bedroom!" and the
## choice to end the run with a win or keep going endlessly. Keys 1 / 2, a click, or arrows +
## Enter. Keeps running while the run is frozen. In the Stitched Scrapbook look (spec 04 §6.4):
## a taped felt patch on the cloth, a hand-written title, a sticker, and sewn buttons (End run is
## the gold one). Built in code (goal_screen.tscn is only the root).

signal end_chosen
signal endless_chosen

## Picks are ignored this long after opening, so a key held from playing doesn't pick.
const INPUT_DELAY: float = 0.3
const TITLE: String = "You beat the Bedroom!"
const SUBTITLE: String = (
	"The Sock Puppet King is stuffed. Call it a win, or see how far your build carries you?"
)
const BUTTON_WIDTH: float = 520.0

var cloth: MenuCloth = MenuCloth.new(0.8, 0.3)
var panel: FeltPanel = FeltPanel.new(-1.5)
var heading: HandTitle = HandTitle.new(TITLE, 76, UiColors.PURPLE, -2.0)
var title_label: Label = heading.label
var subtitle_label: Label = UiFonts.label(SUBTITLE, 26, UiColors.INK_SOFT)
var sticker: Sticker = Sticker.new(
	"King stuffed!", UiColors.STICKER_TEAL, UiColors.STICKER_TEAL_INK, 6.0, 30
)
var end_button: SewnButton = SewnButton.new("[1]  End run", true, 32)
var endless_button: SewnButton = SewnButton.new("[2]  Keep going (endless)", false, 30)
var motion: ScreenMotion = ScreenMotion.new()

var _accepting: bool = false


func _ready() -> void:
	visible = false
	_build()
	end_button.pressed.connect(choose_end)
	endless_button.pressed.connect(choose_endless)


func is_open() -> bool:
	return visible


func open() -> void:
	visible = true
	_accepting = false
	motion.open([panel])
	sticker.slap()
	end_button.grab_focus()
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_accepting = true


func choose_end() -> void:
	if _accept():
		end_chosen.emit()


func choose_endless() -> void:
	if _accept():
		endless_chosen.emit()


func _accept() -> bool:
	if not visible or not _accepting:
		return false
	motion.finish()
	visible = false
	_accepting = false
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pick_card_1"):
		get_viewport().set_input_as_handled()
		choose_end()
	elif event.is_action_pressed(&"pick_card_2"):
		get_viewport().set_input_as_handled()
		choose_endless()


func _build() -> void:
	add_child(motion)
	add_child(cloth)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", -22)
	center.add_child(stack)
	sticker.size_flags_horizontal = Control.SIZE_SHRINK_END
	# The sticker overlaps the panel's top edge, drawn on top of it.
	sticker.z_index = 1
	stack.add_child(sticker)
	panel.add_tape(0.2, -5.0).add_tape(0.8, 4.0, UiColors.TAPE_TEAL)
	stack.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 18)
	column.custom_minimum_size.x = BUTTON_WIDTH + 120.0
	panel.content.add_child(column)
	column.add_child(heading)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(subtitle_label)
	var buttons: VBoxContainer = VBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 16)
	buttons.custom_minimum_size.x = BUTTON_WIDTH
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(buttons)
	buttons.add_child(end_button)
	buttons.add_child(endless_button)
