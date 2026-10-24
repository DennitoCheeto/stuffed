class_name GiftBoxScreen
extends CanvasLayer
## The gift box moment (spec 02 §6, §20): the game pauses, a big box wobbles, the lid pops off
## with confetti while Banane puts his sunglasses on (about 1 second; a key or click skips to the
## contents). Then the contents stay on screen as big cards until the player confirms with
## Continue, Enter, Space or E. Keeps running while the run is frozen. In the Stitched Scrapbook
## look (spec 04 §6.4): the felt cloth over the dimmed run, a hand-written title, the contents as
## taped felt patches that drop in, and Continue as the gold sewn button.

## The moment is over (confirmed).
signal finished

## When the lid pops, as a share of the opening.
const LID_POP_AT: float = 0.4
## How far right of the screen centre the big box stands.
const ART_OFFSET_X: float = 300.0
const TITLE: String = "Gift box!"
const EVOLUTION_TITLE: String = "Evolution!"
## Evolutions get their own colour and more confetti: they should feel bigger.
const EVOLUTION_COLOR: Color = UiColors.STICKER_PINK
const CONFETTI: int = 90
const EVOLUTION_CONFETTI: int = 220
const OPENING_HINT: String = "Any key: skip"
const CONTINUE_TEXT: String = "Continue  [Enter / Space / E]"
const HIGHLIGHT_COLOR: Color = UiColors.GOLD
## The cards sit a little crooked, each its own way (degrees).
const CARD_TILTS: Array[float] = [-2.0, 1.5, -1.0, 2.0, -1.5]
const CONFETTI_COLORS: PackedColorArray = [
	Color("#f2b52e"), Color("#4fc3f7"), Color("#f08a3c"), Color("#b388ff"), Color("#7bd88f")
]
## Movement keys never skip or close: the player is usually still holding them.
const NOT_SKIPPING: Array[StringName] = [
	&"p1_move_left", &"p1_move_right", &"p1_move_up", &"p1_move_down"
]
## The keys that close the contents (a gamepad's A button too).
const CONFIRM_KEYS: Array[Key] = [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]

## How long the opening lasts, when keys start to skip it and when confirming starts to work
## (from the gift box rules).
var opening_seconds: float = 1.0
var skip_delay: float = 0.3
var confirm_delay: float = 0.5
## Seconds since the moment started.
var time: float = 0.0
## Seconds since the contents showed (0 while opening).
var contents_time: float = 0.0
## True once the lid has popped (confetti, sound).
var lid_popped: bool = false
## True once the opening is over and the contents are on screen.
var showing_contents: bool = false
## The box holds an evolution (bigger title, confetti and sound).
var evolution: bool = false
## The contents shown, one card each.
var cards: Array[GiftCardView] = []
var art: GiftBoxArt
var cloth: MenuCloth = MenuCloth.new(0.72, 0.3)
var title: HandTitle = HandTitle.new(TITLE, 84, HIGHLIGHT_COLOR, -3.0)
var title_label: Label = title.label
var hint_label: Label
var card_row: HBoxContainer
var continue_button: SewnButton = SewnButton.new(CONTINUE_TEXT, true, 28)
var motion: ScreenMotion = ScreenMotion.new()
var confetti: CPUParticles2D

var _gift: GiftContents


func _init() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func is_open() -> bool:
	return visible


## Starts the moment for `gift` (its cards show once the opening is over).
func open(gift: GiftContents, rules: GiftBoxRules) -> void:
	_gift = gift
	opening_seconds = rules.opening_seconds
	skip_delay = rules.skip_delay
	confirm_delay = rules.confirm_delay
	time = 0.0
	contents_time = 0.0
	lid_popped = false
	showing_contents = false
	evolution = gift.is_evolution()
	title_label.text = EVOLUTION_TITLE if evolution else TITLE
	var title_color: Color = EVOLUTION_COLOR if evolution else HIGHLIGHT_COLOR
	title_label.add_theme_color_override("font_color", title_color)
	confetti.amount = EVOLUTION_CONFETTI if evolution else CONFETTI
	for old: GiftCardView in cards:
		old.queue_free()
	cards.clear()
	card_row.visible = false
	continue_button.visible = false
	hint_label.visible = true
	art.visible = true
	art.lid_open = 0.0
	art.wobble = 0.0
	visible = true


## True once the contents are shown long enough that a confirm closes them.
func can_confirm() -> bool:
	return visible and showing_contents and contents_time >= confirm_delay


## The player confirms: closes the moment if the contents have been up long enough.
func confirm() -> void:
	if can_confirm():
		close()


## Ends the moment now, whatever it shows (tests and the run use it to clear the screen).
func close() -> void:
	if not visible:
		return
	motion.finish()
	visible = false
	finished.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	time += delta
	if showing_contents:
		contents_time += delta
		continue_button.disabled = not can_confirm()
		return
	var share: float = time / maxf(opening_seconds, 0.001)
	if share < LID_POP_AT:
		# The box shakes harder and harder before it opens.
		var build_up: float = share / LID_POP_AT
		art.wobble = build_up * sin(time * TAU * 7.0)
	else:
		art.wobble = 0.0
		art.lid_open = minf((share - LID_POP_AT) / 0.15, 1.0)
		if not lid_popped:
			_pop_lid()
	if time >= opening_seconds:
		_show_contents()


func _input(event: InputEvent) -> void:
	if not visible or not _is_press(event):
		return
	if showing_contents:
		# Clicks go to the Continue button.
		if _is_confirm(event):
			get_viewport().set_input_as_handled()
			confirm()
		return
	if time < skip_delay:
		return
	get_viewport().set_input_as_handled()
	_show_contents()


## A fresh key, click or gamepad button press that isn't movement.
func _is_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.is_pressed()
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return false
	for action: StringName in NOT_SKIPPING:
		if event.is_action(action):
			return false
	return true


func _is_confirm(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).button_index == JOY_BUTTON_A
	if not (event is InputEventKey):
		return false
	var key: InputEventKey = event as InputEventKey
	return CONFIRM_KEYS.has(key.keycode) or CONFIRM_KEYS.has(key.physical_keycode)


func _pop_lid() -> void:
	lid_popped = true
	confetti.restart()
	Sfx.play(&"evolution" if evolution else &"gift_open")


## The opening is over (played out or skipped): the box makes way for the cards.
func _show_contents() -> void:
	if not lid_popped:
		_pop_lid()
	showing_contents = true
	contents_time = 0.0
	art.visible = false
	hint_label.visible = false
	var parts: Array[Wobbly] = []
	for card: GiftCard in _gift.cards():
		var tilt: float = CARD_TILTS[cards.size() % CARD_TILTS.size()]
		var view: GiftCardView = GiftCardView.new(card, tilt)
		card_row.add_child(view)
		cards.append(view)
		parts.append(view)
	card_row.visible = true
	continue_button.disabled = true
	continue_button.visible = true
	motion.open(parts)


func _build() -> void:
	add_child(motion)
	add_child(cloth)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.offset_left = -600.0
	title.offset_right = 600.0
	title.offset_top = 110.0
	add_child(title)
	art = GiftBoxArt.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Beside the middle of the screen, so Banane (in the middle) is seen putting his shades on.
	art.position.x += ART_OFFSET_X
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	hint_label = UiFonts.label(OPENING_HINT, 26, UiColors.FELT, UiFonts.hand())
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint_label.offset_left = -600.0
	hint_label.offset_right = 600.0
	hint_label.offset_top = 960.0
	add_child(hint_label)
	card_row = HBoxContainer.new()
	card_row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card_row.offset_left = -900.0
	card_row.offset_right = 900.0
	card_row.offset_top = -230.0
	card_row.offset_bottom = 170.0
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", 24)
	card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_row)
	_build_continue()
	_build_confetti()


func _build_continue() -> void:
	continue_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	continue_button.offset_left = -260.0
	continue_button.offset_right = 260.0
	continue_button.offset_top = 230.0
	continue_button.offset_bottom = 310.0
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.pressed.connect(confirm)
	add_child(continue_button)


func _build_confetti() -> void:
	confetti = CPUParticles2D.new()
	confetti.position = Vector2(960.0 + ART_OFFSET_X, 470.0)
	confetti.emitting = false
	confetti.amount = CONFETTI
	confetti.lifetime = 1.6
	confetti.one_shot = true
	confetti.explosiveness = 1.0
	confetti.direction = Vector2(0, -1)
	confetti.spread = 70.0
	confetti.gravity = Vector2(0, 700)
	confetti.initial_velocity_min = 350.0
	confetti.initial_velocity_max = 700.0
	confetti.angular_velocity_min = -360.0
	confetti.angular_velocity_max = 360.0
	confetti.scale_amount_min = 6.0
	confetti.scale_amount_max = 11.0
	var colors: Gradient = Gradient.new()
	colors.colors = CONFETTI_COLORS
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	confetti.color_initial_ramp = colors
	add_child(confetti)
