class_name LevelUpScreen
extends CanvasLayer
## The level-up moment and its 3 cards. Pick with keys 1/2/3, a mouse click, or arrows + Enter.
## Below the cards: Reroll (R), Skip (S) and Banish (B, then 1/2/3), each showing how many are
## left. Keeps running while the run is frozen.

signal picked(offer: UpgradeOffer)
## The cards can be picked from now on.
signal cards_shown
## The player wants 3 new cards.
signal reroll_requested
## The player takes no card.
signal skip_requested
## The player banishes card `index` (0-2).
signal banish_requested(index: int)

## How long the big moment (quack, confetti) plays before the cards appear.
const MOMENT_TIME: float = 0.7
## Picks are ignored this long after the cards appear, so a key held from playing doesn't pick.
const INPUT_DELAY: float = 0.2
const PICK_ACTIONS: Array[StringName] = [&"pick_card_1", &"pick_card_2", &"pick_card_3"]
const TITLE: String = "Level up!"
const BANISH_TITLE: String = "Banish which card? (1, 2 or 3)"
const BUTTON_COLOR: Color = Color("#2a2633")
const EDGE_COLOR: Color = Color("#4a4358")
const HIGHLIGHT_COLOR: Color = Color("#f2b52e")
const BANISH_COLOR: Color = Color("#e0603a")

var offers: Array[UpgradeOffer] = []
var cards: Array[UpgradeCard] = []
## The next card choice banishes that card instead of picking it.
var banishing: bool = false
var reroll_button: Button = Button.new()
var skip_button: Button = Button.new()
var banish_button: Button = Button.new()

var _accepting: bool = false

@onready var card_row: HBoxContainer = %CardRow
@onready var title_label: Label = %TitleLabel
@onready var confetti: CPUParticles2D = %Confetti


func _ready() -> void:
	visible = false
	_build_controls()


func is_open() -> bool:
	return visible


## Shows the cards for one level-up; `with_moment` plays the big moment first.
func open(new_offers: Array[UpgradeOffer], with_moment: bool) -> void:
	offers = new_offers
	visible = true
	_accepting = false
	_set_banishing(false)
	_build_cards()
	card_row.visible = false
	if with_moment:
		confetti.restart()
		await get_tree().create_timer(MOMENT_TIME, true).timeout
	card_row.visible = true
	cards[0].grab_focus()
	cards_shown.emit()
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_accepting = true


## Swaps the cards on screen (after a reroll or a banish) without a new moment.
func show_offers(new_offers: Array[UpgradeOffer]) -> void:
	offers = new_offers
	_build_cards()
	cards[0].grab_focus()


## Shows how many rerolls, skips and banishes are left; a button with none left is disabled.
func show_controls(controls: CardControls) -> void:
	_show_count(reroll_button, "Reroll", "R", controls.rerolls_left)
	_show_count(skip_button, "Skip", "S", controls.skips_left)
	_show_count(banish_button, "Banish", "B", controls.banishes_left)
	if banish_button.disabled:
		_set_banishing(false)


func close() -> void:
	visible = false
	_accepting = false
	_set_banishing(false)


## Picks card `index` (0-2), as if the player chose it; while banishing, banishes it instead.
func choose(index: int) -> void:
	if not _accepting or index < 0 or index >= offers.size():
		return
	if banishing:
		_set_banishing(false)
		banish_requested.emit(index)
		return
	_accepting = false
	picked.emit(offers[index])


## Asks for 3 new cards (if a reroll is left).
func reroll() -> void:
	if not _accepting or reroll_button.disabled:
		return
	_set_banishing(false)
	reroll_requested.emit()


## Takes no card (if a skip is left).
func skip() -> void:
	if not _accepting or skip_button.disabled:
		return
	_accepting = false
	_set_banishing(false)
	skip_requested.emit()


## Turns banish mode on or off: in banish mode the next card choice banishes that card.
func toggle_banish() -> void:
	if not _accepting or banish_button.disabled:
		return
	_set_banishing(not banishing)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	for index: int in PICK_ACTIONS.size():
		if event.is_action_pressed(PICK_ACTIONS[index]):
			get_viewport().set_input_as_handled()
			choose(index)
			return
	if event.is_action_pressed(&"reroll_cards"):
		get_viewport().set_input_as_handled()
		reroll()
	elif event.is_action_pressed(&"skip_cards"):
		get_viewport().set_input_as_handled()
		skip()
	elif event.is_action_pressed(&"banish_card"):
		get_viewport().set_input_as_handled()
		toggle_banish()


func _set_banishing(on: bool) -> void:
	banishing = on
	title_label.text = BANISH_TITLE if on else TITLE
	title_label.add_theme_color_override("font_color", BANISH_COLOR if on else HIGHLIGHT_COLOR)
	banish_button.add_theme_stylebox_override("normal", _panel(BANISH_COLOR if on else EDGE_COLOR))


func _build_cards() -> void:
	for old: UpgradeCard in cards:
		old.queue_free()
	cards.clear()
	for index: int in offers.size():
		var card: UpgradeCard = UpgradeCard.new()
		card.show_offer(offers[index], index + 1)
		card.pressed.connect(choose.bind(index))
		card_row.add_child(card)
		cards.append(card)


## The row of Reroll / Skip / Banish buttons under the cards.
func _build_controls() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.offset_left = -560.0
	row.offset_right = 560.0
	row.offset_top = 290.0
	row.offset_bottom = 360.0
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	add_child(row)
	for button: Button in [reroll_button, skip_button, banish_button]:
		button.custom_minimum_size = Vector2(260, 64)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 26)
		button.add_theme_color_override("font_color", Color("#f7f3ea"))
		button.add_theme_color_override("font_disabled_color", Color("#6f6a7a"))
		button.add_theme_stylebox_override("normal", _panel(EDGE_COLOR))
		button.add_theme_stylebox_override("hover", _panel(HIGHLIGHT_COLOR.darkened(0.3)))
		button.add_theme_stylebox_override("pressed", _panel(BANISH_COLOR))
		button.add_theme_stylebox_override("disabled", _panel(BUTTON_COLOR))
		button.add_theme_stylebox_override("focus", _panel(HIGHLIGHT_COLOR, false))
		row.add_child(button)
	reroll_button.pressed.connect(reroll)
	skip_button.pressed.connect(skip)
	banish_button.pressed.connect(toggle_banish)


func _show_count(button: Button, label: String, key: String, left: int) -> void:
	button.text = "%s [%s]  %d left" % [label, key, left]
	button.disabled = left <= 0


func _panel(edge: Color, filled: bool = true) -> StyleBoxFlat:
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = BUTTON_COLOR
	panel.draw_center = filled
	panel.border_color = edge
	panel.set_border_width_all(4)
	panel.set_corner_radius_all(14)
	return panel
