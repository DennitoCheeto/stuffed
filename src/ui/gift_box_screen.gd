class_name GiftBoxScreen
extends CanvasLayer
## The gift box moment (spec 02 §6, §20): the game pauses, a big box wobbles, the lid pops off
## with confetti while Banane puts his sunglasses on (about 1 second; a key or click skips to the
## contents). Then the contents stay on screen as big cards until the player confirms with
## Continue, Enter, Space or E. Keeps running while the run is frozen. In the Stitched Scrapbook
## look (spec 04 §6.4): the felt cloth over the dimmed run, a hand-written title, the contents as
## taped felt patches that drop in, and Continue as the gold sewn button.
## An evolution first plays the sewing reveal (spec 10 §3): weapon + item sewn into the evolved
## weapon with an "EVOLVED!" stamp; any key jumps to its end.

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
const CONTINUE_TEXT: String = "Continue  [Enter / Space / {interact}]"
const HIGHLIGHT_COLOR: Color = UiColors.GOLD
## The cards sit a little crooked, each its own way (degrees).
const CARD_TILTS: Array[float] = [-2.0, 1.5, -1.0, 2.0, -1.5]
## The card row: how wide it may get and the gap between cards. With more cards than fit (a big box
## with the Lucky Gift trick holds up to 6), the cards get narrower.
const ROW_WIDTH: float = 1800.0
const CARD_GAP: int = 24
## The card row's middle (from the screen middle) and half its height.
const ROW_MIDDLE_Y: float = -30.0
const ROW_HALF_HEIGHT: float = 200.0
## At the very end of the opening the box shrinks by this share as it fades (#342).
const BOX_OUT_SHRINK: float = 0.6
const CONFETTI_COLORS: PackedColorArray = [
	Color("#f2b52e"), Color("#4fc3f7"), Color("#f08a3c"), Color("#b388ff"), Color("#7bd88f")
]
## Movement keys never skip or close: the player is usually still holding them.
const NOT_SKIPPING: Array[StringName] = [
	&"p1_move_left", &"p1_move_right", &"p1_move_up", &"p1_move_down"
]
## The keys that close the contents, besides player 1's interact key (and a gamepad's A
## button).
const CONFIRM_KEYS: Array[Key] = [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
## The sewing reveal of an evolution (spec 10 §3) and how long its finished stamp stays before
## the cards come.
const MOMENT: EvolutionMomentRules = preload("res://data/ui/evolution_moment.tres")
const REVEAL_HOLD: float = 0.4

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
## True while the sewing reveal plays (after the lid popped, before the cards).
var revealing: bool = false
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
var reveal: EvolutionReveal = EvolutionReveal.new(MOMENT)

var _gift: GiftContents
var _rules: GiftBoxRules
var _hold_left: float = 0.0


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
	_rules = rules
	opening_seconds = rules.opening_seconds
	skip_delay = rules.skip_delay
	confirm_delay = rules.confirm_delay
	time = 0.0
	contents_time = 0.0
	lid_popped = false
	showing_contents = false
	evolution = gift.is_evolution()
	revealing = false
	reveal.visible = false
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
	art.squash = 0.0
	art.scale = Vector2.ONE
	art.modulate.a = 1.0
	visible = true


## How wide each of `count` plain cards is: the normal width, or narrower so they fit the row.
static func card_width(count: int) -> float:
	var room: float = (ROW_WIDTH - CARD_GAP * (count - 1)) / maxf(count, 1.0)
	return minf(GiftCardView.CARD_SIZE.x, floorf(room))


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
	if revealing:
		_play_reveal(delta)
		return
	var share: float = time / maxf(opening_seconds, 0.001)
	if share < LID_POP_AT:
		_wind_up(share / LID_POP_AT)
	else:
		if not lid_popped:
			_pop_lid()
		_after_pop(share)
	if time >= opening_seconds:
		if evolution:
			_start_reveal()
		else:
			_show_contents()


## Before the lid pops (`build_up` 0..1): the box rocks gently, then harder, and squashes down
## as it gathers itself (#342). Reduced motion keeps only the rocking.
func _wind_up(build_up: float) -> void:
	art.wobble = build_up * build_up * sin(time * TAU * _rules.shake_per_second)
	art.squash = 0.0 if UiFeel.reduced() else _rules.wind_up_squash * smoothstep(0.0, 1.0, build_up)


## After the lid popped (`share` of the opening): the lid eases off with a small overshoot, the
## box stretches up and springs back, and at the end it shrinks away so the cards can fly out.
func _after_pop(share: float) -> void:
	art.wobble = 0.0
	var lid: float = clampf((share - LID_POP_AT) / maxf(_rules.lid_share, 0.001), 0.0, 1.0)
	if UiFeel.reduced():
		art.lid_open = lid
		return
	art.lid_open = ease_out_back(lid)
	var since: float = time - LID_POP_AT * opening_seconds
	var spring: float = cos(TAU * _rules.pop_spring_per_second * since)
	art.squash = -_rules.pop_stretch * exp(-_rules.pop_damping * since) * spring
	var out_from: float = 1.0 - _rules.box_out_share
	var out: float = clampf((share - out_from) / maxf(_rules.box_out_share, 0.001), 0.0, 1.0)
	art.scale = Vector2.ONE * (1.0 - BOX_OUT_SHRINK * out * out)
	art.modulate.a = 1.0 - out


## 0..1 eased out with a small overshoot past 1 near the end (the lid flies a bit too far).
static func ease_out_back(t: float) -> float:
	var back: float = 1.70158
	var u: float = t - 1.0
	return 1.0 + (back + 1.0) * u * u * u + back * u * u


## Where each of `count` cards `width` wide starts, from its place in the row: at `from` (from
## the screen middle), so the cards fly out of the box (#342).
static func card_start_offsets(count: int, width: float, from: Vector2) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	var row: float = count * width + (count - 1) * CARD_GAP
	for index: int in count:
		var x: float = -row / 2.0 + width / 2.0 + index * (width + CARD_GAP)
		offsets.append(from - Vector2(x, ROW_MIDDLE_Y))
	return offsets


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
	if evolution and not (revealing and reveal.is_done()):
		_start_reveal()
		reveal.finish()
	else:
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
	var interact: Key = KeyBindings.key_of("interact")
	if key.physical_keycode == interact or key.keycode == interact:
		return true
	return CONFIRM_KEYS.has(key.keycode) or CONFIRM_KEYS.has(key.physical_keycode)


func _pop_lid() -> void:
	lid_popped = true
	confetti.restart()
	Sfx.play(&"evolution" if evolution else &"gift_open")


## The opening is over (played out or skipped): the box makes way for the cards.
func _show_contents() -> void:
	if not lid_popped:
		_pop_lid()
	revealing = false
	reveal.visible = false
	showing_contents = true
	contents_time = 0.0
	continue_button.text = KeyBindings.fill(CONTINUE_TEXT)
	art.visible = false
	hint_label.visible = false
	var parts: Array[Wobbly] = []
	var shown: Array[GiftCard] = _gift.cards()
	var width: float = card_width(shown.size())
	for card: GiftCard in shown:
		var tilt: float = CARD_TILTS[cards.size() % CARD_TILTS.size()]
		var view: GiftCardView = GiftCardView.new(card, tilt, width)
		card_row.add_child(view)
		cards.append(view)
		parts.append(view)
	card_row.visible = true
	continue_button.disabled = true
	continue_button.visible = true
	# Out of the box (an evolution's cards come out of the sewing reveal in the middle).
	var from: Vector2 = Vector2.ZERO if evolution else box_middle()
	var offsets: Array[Vector2] = card_start_offsets(shown.size(), width, from)
	var seconds: float = _rules.card_flow_seconds
	motion.flow_out(parts, offsets, seconds, _rules.card_flow_stagger, _rules.card_flow_grow)


## The middle of the big box, from the screen middle.
static func box_middle() -> Vector2:
	return Vector2(ART_OFFSET_X, 0.0) + GiftBoxArt.middle()


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
	card_row.offset_left = -ROW_WIDTH / 2.0
	card_row.offset_right = ROW_WIDTH / 2.0
	card_row.offset_top = ROW_MIDDLE_Y - ROW_HALF_HEIGHT
	card_row.offset_bottom = ROW_MIDDLE_Y + ROW_HALF_HEIGHT
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	card_row.add_theme_constant_override("separation", CARD_GAP)
	card_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_row)
	_build_continue()
	reveal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reveal.offset_left = -reveal.custom_minimum_size.x / 2.0
	reveal.offset_right = reveal.custom_minimum_size.x / 2.0
	reveal.offset_top = -reveal.custom_minimum_size.y / 2.0
	reveal.offset_bottom = reveal.custom_minimum_size.y / 2.0
	reveal.visible = false
	add_child(reveal)
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


## The lid popped on an evolution: the weapon and the item get sewn together (spec 10 §3).
func _start_reveal() -> void:
	if not lid_popped:
		_pop_lid()
	if revealing:
		return
	revealing = true
	_hold_left = REVEAL_HOLD
	art.visible = false
	hint_label.visible = true
	var into: StringName = _gift.evolution.icon
	reveal.start(_gift.evolution_from_icon, _gift.evolution_partner_icon, into)
	reveal.visible = true


func _play_reveal(delta: float) -> void:
	if not reveal.is_done():
		reveal.advance(delta)
		return
	_hold_left -= delta
	if _hold_left <= 0.0:
		_show_contents()
