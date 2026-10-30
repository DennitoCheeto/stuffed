class_name LevelUpScreen
extends CanvasLayer
## The level-up moment and its 3 cards (4 with the Four of a Kind trick; spec 04 §6.3):
## "Level up!" hand-written on the felt cloth, the cards are felt patches that drop in straight
## (they never tilt while you choose). Pick with keys 1-4, a mouse click, or arrows + Enter. Right
## under the cards: Reroll (R), Skip (S) and Banish (B, then a card number) as sewn buttons with
## their uses left (spec 02 §20). They pulse on the first level-up of a run. While choosing a card
## to banish the cards wiggle with a scissors mark; B again or Esc cancels. Keeps running while the
## run is frozen. Built in code (the .tscn is only the root).

signal picked(offer: UpgradeOffer)
## The cards can be picked from now on.
signal cards_shown
## The player wants 3 new cards.
signal reroll_requested
## The player takes no card.
signal skip_requested
## The player banishes card `index` (0 = the first).
signal banish_requested(index: int)

## How long the big moment (quack, confetti) plays before the cards appear.
const MOMENT_TIME: float = 0.7
## Picks are ignored this long after the cards appear, so a key held from playing doesn't pick.
const INPUT_DELAY: float = 0.2
const PICK_ACTIONS: Array[StringName] = [
	&"pick_card_1", &"pick_card_2", &"pick_card_3", &"pick_card_4"
]
const TITLE: String = "Level up!"
## %s = the card numbers ("1, 2 or 3").
const BANISH_TITLE: String = "Banish which card? (%s)  Esc: cancel"
const TITLE_SIZE: int = 84
const BANISH_TITLE_SIZE: int = 56
## The long banish question tilts less, so it stays clear of the cards.
const TITLE_TILT: float = -3.0
const BANISH_TILT: float = -1.0
const HIGHLIGHT_COLOR: Color = UiColors.GOLD
const CARD_GAP: int = 30
## Own colours: soft blue, green and violet (never the red/orange of enemy danger).
const REROLL_COLOR: Color = Color("#5ab0e8")
const SKIP_COLOR: Color = Color("#7bd88f")
const BANISH_COLOR: Color = Color("#c38bf0")
## The first-level-up pulse: how long and how big.
const PULSE_TIME: float = 1.8
const PULSE_COUNT: int = 3
const PULSE_SCALE: float = 1.1
const CONFETTI_COLORS: PackedColorArray = [
	Color("#f2b52e"), Color("#4fc3f7"), Color("#f08a3c"), Color("#b388ff"), Color("#7bd88f")
]

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
var cloth: MenuCloth = MenuCloth.new(0.72, 0.3)
var title: HandTitle = HandTitle.new(TITLE, TITLE_SIZE, HIGHLIGHT_COLOR, TITLE_TILT)
var title_label: Label = title.label
## The cards and the buttons under them: they drop in together.
var cards_holder: Wobbly = Wobbly.new()
var card_row: HBoxContainer = HBoxContainer.new()
var confetti: CPUParticles2D = CPUParticles2D.new()
var motion: ScreenMotion = ScreenMotion.new()

var _accepting: bool = false
var _pulse: Tween


func _ready() -> void:
	visible = false
	_build()


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
	motion.finish()
	cards_holder.fade = 0.0
	if with_moment:
		confetti.restart()
		await get_tree().create_timer(MOMENT_TIME, true).timeout
	motion.open([cards_holder], false)
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
	motion.finish()
	visible = false
	_accepting = false
	_set_banishing(false)


## Picks card `index` (0 = the first) as if the player chose it; while banishing, banishes it.
func choose(index: int) -> void:
	if not _accepting or index < 0 or index >= offers.size():
		return
	if banishing:
		_set_banishing(false)
		banish_requested.emit(index)
		return
	_accepting = false
	picked.emit(offers[index])


## Asks for new cards (if a reroll is left).
func reroll() -> void:
	if not _accepting:
		return
	if reroll_button.disabled:
		reroll_button.nope()
		return
	_set_banishing(false)
	reroll_requested.emit()


## Takes no card (if a skip is left).
func skip() -> void:
	if not _accepting:
		return
	if skip_button.disabled:
		skip_button.nope()
		return
	_accepting = false
	_set_banishing(false)
	skip_requested.emit()


## Turns banish mode on or off: in banish mode the next card choice banishes that card.
func toggle_banish() -> void:
	if not _accepting:
		return
	if banish_button.disabled:
		banish_button.nope()
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
	title.tilt = BANISH_TILT if on else TITLE_TILT
	title_label.text = BANISH_TITLE % _card_numbers() if on else TITLE
	title_label.add_theme_font_size_override("font_size", BANISH_TITLE_SIZE if on else TITLE_SIZE)
	title_label.add_theme_color_override("font_color", BANISH_COLOR if on else HIGHLIGHT_COLOR)
	banish_button.set_active(on)
	for card: UpgradeCard in cards:
		card.set_marked(on)


## "1, 2 or 3" (or "1, 2, 3 or 4") for the cards on screen.
func _card_numbers() -> String:
	var count: int = maxi(offers.size(), 1)
	var numbers: PackedStringArray = []
	for number: int in range(1, count):
		numbers.append(str(number))
	if numbers.is_empty():
		return "1"
	return "%s or %d" % [", ".join(numbers), count]


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
	_link_focus()


## Arrow keys: left / right along the cards and along the buttons, down from a card to the button
## under it and up again (Godot's own guess jumps between the rows).
func _link_focus() -> void:
	if not is_inside_tree():
		return
	var buttons: Array[CardControlButton] = controls()
	for index: int in cards.size():
		var card: UpgradeCard = cards[index]
		var below: CardControlButton = buttons[mini(index, buttons.size() - 1)]
		var left: UpgradeCard = cards[maxi(index - 1, 0)]
		var right: UpgradeCard = cards[mini(index + 1, cards.size() - 1)]
		card.focus_neighbor_left = card.get_path_to(left)
		card.focus_neighbor_right = card.get_path_to(right)
		card.focus_neighbor_bottom = card.get_path_to(below)
		card.focus_neighbor_top = card.get_path_to(card)
	for index: int in buttons.size():
		var button: CardControlButton = buttons[index]
		var above: UpgradeCard = cards[mini(index, cards.size() - 1)]
		button.focus_neighbor_top = button.get_path_to(above)
		button.focus_neighbor_bottom = button.get_path_to(button)
		var left: CardControlButton = buttons[maxi(index - 1, 0)]
		var right: CardControlButton = buttons[mini(index + 1, buttons.size() - 1)]
		button.focus_neighbor_left = button.get_path_to(left)
		button.focus_neighbor_right = button.get_path_to(right)


## The cloth, the title, the cards and right under them the Reroll / Skip / Banish row.
func _build() -> void:
	add_child(motion)
	add_child(cloth)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 36)
	center.add_child(column)
	column.add_child(title)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 24)
	cards_holder.set_body(stack)
	column.add_child(cards_holder)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override(&"separation", CARD_GAP)
	stack.add_child(card_row)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", CARD_GAP)
	stack.add_child(row)
	for button: CardControlButton in controls():
		row.add_child(button)
	reroll_button.pressed.connect(reroll)
	skip_button.pressed.connect(skip)
	banish_button.pressed.connect(toggle_banish)
	_build_confetti()


func _build_confetti() -> void:
	confetti.position = Vector2(960, 220)
	confetti.emitting = false
	confetti.amount = 90
	confetti.lifetime = 1.6
	confetti.one_shot = true
	confetti.explosiveness = 1.0
	confetti.direction = Vector2(0, -1)
	confetti.spread = 80.0
	confetti.gravity = Vector2(0, 700)
	confetti.initial_velocity_min = 350.0
	confetti.initial_velocity_max = 650.0
	confetti.angular_velocity_min = -360.0
	confetti.angular_velocity_max = 360.0
	confetti.scale_amount_min = 6.0
	confetti.scale_amount_max = 11.0
	var colors: Gradient = Gradient.new()
	colors.colors = CONFETTI_COLORS
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	confetti.color_initial_ramp = colors
	add_child(confetti)


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
