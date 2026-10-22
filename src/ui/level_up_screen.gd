class_name LevelUpScreen
extends CanvasLayer
## The level-up moment and its 3 cards. Pick with keys 1/2/3, a mouse click, or arrows + Enter.
## Right under the cards: Reroll (R), Skip (S) and Banish (B, then 1/2/3) as big felt buttons with
## their uses left (spec 02 §20). They pulse on the first level-up of a run. While choosing a card to
## banish the cards wiggle with a scissors mark; B again or Esc cancels. Keeps running while the run
## is frozen.

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
const BANISH_TITLE: String = "Banish which card? (1, 2 or 3)  Esc: cancel"
const TITLE_SIZE: int = 72
const BANISH_TITLE_SIZE: int = 54
const HIGHLIGHT_COLOR: Color = Color("#f2b52e")
## Own colours: soft blue, green and violet (never the red/orange of enemy danger).
const REROLL_COLOR: Color = Color("#5ab0e8")
const SKIP_COLOR: Color = Color("#7bd88f")
const BANISH_COLOR: Color = Color("#c38bf0")
## The first-level-up pulse: how long and how big.
const PULSE_TIME: float = 1.8
const PULSE_COUNT: int = 3
const PULSE_SCALE: float = 1.1

var offers: Array[UpgradeOffer] = []
var cards: Array[UpgradeCard] = []
## The next card choice banishes that card instead of picking it.
var banishing: bool = false
var reroll_button: CardControlButton = CardControlButton.new(
	"Reroll", "R", "3 new cards", &"dice", REROLL_COLOR
)
var skip_button: CardControlButton = CardControlButton.new(
	"Skip", "S", "No card, heal a little", &"arrow", SKIP_COLOR
)
var banish_button: CardControlButton = CardControlButton.new(
	"Banish", "B", "Remove a card for this run", &"scissors", BANISH_COLOR
)
## The buttons pulse once per run, on the first level-up.
var pulsed: bool = false

var _accepting: bool = false
var _pulse: Tween

@onready var card_row: HBoxContainer = %CardRow
@onready var title_label: Label = %TitleLabel
@onready var confetti: CPUParticles2D = %Confetti


func _ready() -> void:
	visible = false
	_build_controls()


func is_open() -> bool:
	return visible


## True while the first-level-up pulse plays.
func is_pulsing() -> bool:
	return _pulse != null and _pulse.is_running()


## Reroll, Skip and Banish.
func controls() -> Array[CardControlButton]:
	return [reroll_button, skip_button, banish_button]


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
	if not pulsed:
		_pulse_controls()
	await get_tree().create_timer(INPUT_DELAY, true).timeout
	_accepting = true


## Swaps the cards on screen (after a reroll or a banish) without a new moment.
func show_offers(new_offers: Array[UpgradeOffer]) -> void:
	offers = new_offers
	_build_cards()
	cards[0].grab_focus()


## Shows how many rerolls, skips and banishes are left; a button with none left is disabled.
func show_controls(controls: CardControls) -> void:
	reroll_button.show_uses(controls.rerolls_left, controls.max_rerolls())
	skip_button.show_uses(controls.skips_left, controls.max_skips())
	banish_button.show_uses(controls.banishes_left, controls.max_banishes())
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
	elif event.is_action_pressed(&"pause") and banishing:
		get_viewport().set_input_as_handled()
		_set_banishing(false)


func _set_banishing(on: bool) -> void:
	banishing = on
	title_label.text = BANISH_TITLE if on else TITLE
	title_label.add_theme_font_size_override("font_size", BANISH_TITLE_SIZE if on else TITLE_SIZE)
	title_label.add_theme_color_override("font_color", BANISH_COLOR if on else HIGHLIGHT_COLOR)
	banish_button.set_active(on)
	for card: UpgradeCard in cards:
		card.set_marked(on)


func _build_cards() -> void:
	for old: UpgradeCard in cards:
		old.queue_free()
	cards.clear()
	for index: int in offers.size():
		var card: UpgradeCard = UpgradeCard.new()
		card.show_offer(offers[index], index + 1)
		card.pressed.connect(choose.bind(index))
		card_row.add_child(card)
		card.set_marked(banishing)
		cards.append(card)


## The row of Reroll / Skip / Banish buttons, right under the cards and as wide as them.
func _build_controls() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.offset_left = -560.0
	row.offset_right = 560.0
	row.offset_top = 268.0
	row.offset_bottom = 268.0 + CardControlButton.BUTTON_SIZE.y
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	add_child(row)
	for button: CardControlButton in controls():
		row.add_child(button)
	reroll_button.pressed.connect(reroll)
	skip_button.pressed.connect(skip)
	banish_button.pressed.connect(toggle_banish)


## The three buttons pulse a few times so a new player notices them.
func _pulse_controls() -> void:
	pulsed = true
	if _pulse != null:
		_pulse.kill()
	_pulse = create_tween()
	_pulse.tween_method(_pulse_step, 0.0, 1.0, PULSE_TIME)
	_pulse.tween_callback(_pulse_step.bind(1.0))


func _pulse_step(progress: float) -> void:
	var grow: float = absf(sin(progress * PI * PULSE_COUNT)) * (PULSE_SCALE - 1.0)
	for button: CardControlButton in controls():
		button.pivot_offset = button.size / 2.0
		button.scale = Vector2.ONE * (1.0 + grow)
