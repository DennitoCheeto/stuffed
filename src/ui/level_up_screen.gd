class_name LevelUpScreen
extends CanvasLayer
## The level-up moment and its 3 cards. Pick with keys 1/2/3, a mouse click, or arrows + Enter.
## Keeps running while the run is frozen.

signal picked(offer: UpgradeOffer)
## The cards can be picked from now on.
signal cards_shown

## How long the big moment (quack, confetti) plays before the cards appear.
const MOMENT_TIME: float = 0.7
## Picks are ignored this long after the cards appear, so a key held from playing doesn't pick.
const INPUT_DELAY: float = 0.2
const PICK_ACTIONS: Array[StringName] = [&"pick_card_1", &"pick_card_2", &"pick_card_3"]

var offers: Array[UpgradeOffer] = []
var cards: Array[UpgradeCard] = []

var _accepting: bool = false

@onready var card_row: HBoxContainer = %CardRow
@onready var title_label: Label = %TitleLabel
@onready var confetti: CPUParticles2D = %Confetti


func _ready() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Shows the cards for one level-up; `with_moment` plays the big moment first.
func open(new_offers: Array[UpgradeOffer], with_moment: bool) -> void:
	offers = new_offers
	visible = true
	_accepting = false
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


func close() -> void:
	visible = false
	_accepting = false


## Picks card `index` (0-2), as if the player chose it.
func choose(index: int) -> void:
	if not _accepting or index < 0 or index >= offers.size():
		return
	_accepting = false
	picked.emit(offers[index])


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	for index: int in PICK_ACTIONS.size():
		if event.is_action_pressed(PICK_ACTIONS[index]):
			get_viewport().set_input_as_handled()
			choose(index)
			return


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
