class_name GiftBoxScreen
extends CanvasLayer
## The gift box moment (spec 02 §6): the game pauses, a big box wobbles, the lid pops off with
## confetti while Banane puts his sunglasses on, then what was inside is shown. It lasts about
## 2 seconds; any key or a click skips it. Keeps running while the run is frozen.

## The moment is over (played out or skipped).
signal finished

## When the lid pops, as a share of the moment.
const LID_POP_AT: float = 0.4
## How far right of the screen centre the big box stands.
const ART_OFFSET_X: float = 300.0
const TITLE: String = "Gift box!"
const HINT: String = "Any key: skip"
const HIGHLIGHT_COLOR: Color = Color("#f2b52e")
const TEXT_COLOR: Color = Color("#f7f3ea")
const OUTLINE_COLOR: Color = Color("#141218")
const CONFETTI_COLORS: PackedColorArray = [
	Color("#f2b52e"), Color("#4fc3f7"), Color("#f08a3c"), Color("#b388ff"), Color("#7bd88f")
]
## Movement keys don't skip: the player is usually still holding them.
const NOT_SKIPPING: Array[StringName] = [
	&"p1_move_left", &"p1_move_right", &"p1_move_up", &"p1_move_down"
]

## How long the moment lasts and when keys start to skip it (from the gift box rules).
var moment_seconds: float = 2.0
var skip_delay: float = 0.3
## Seconds since the moment started.
var time: float = 0.0
## True once the lid has popped (confetti, contents shown).
var lid_popped: bool = false
var art: GiftBoxArt
var title_label: Label
var contents_label: Label
var confetti: CPUParticles2D


func _init() -> void:
	layer = 21
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func is_open() -> bool:
	return visible


## Starts the moment for `gift` (its contents are shown once the lid pops).
func open(gift: GiftContents, rules: GiftBoxRules) -> void:
	moment_seconds = rules.moment_seconds
	skip_delay = rules.skip_delay
	time = 0.0
	lid_popped = false
	contents_label.text = "\n".join(gift.lines())
	contents_label.visible = false
	art.lid_open = 0.0
	art.wobble = 0.0
	visible = true


## Ends the moment now (also what a skip does).
func close() -> void:
	if not visible:
		return
	visible = false
	finished.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	time += delta
	var share: float = time / maxf(moment_seconds, 0.001)
	if share < LID_POP_AT:
		# The box shakes harder and harder before it opens.
		var build_up: float = share / LID_POP_AT
		art.wobble = build_up * sin(time * TAU * 7.0)
	else:
		art.wobble = 0.0
		art.lid_open = minf((share - LID_POP_AT) / 0.15, 1.0)
		if not lid_popped:
			_pop_lid()
	if time >= moment_seconds:
		close()


func _input(event: InputEvent) -> void:
	if not visible or time < skip_delay or not _is_skip(event):
		return
	get_viewport().set_input_as_handled()
	close()


func _is_skip(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.is_pressed()
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return false
	for action: StringName in NOT_SKIPPING:
		if event.is_action(action):
			return false
	return true


func _pop_lid() -> void:
	lid_popped = true
	contents_label.visible = true
	confetti.restart()
	Sfx.play(&"goal")


func _build() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.08, 0.07, 0.1, 0.45)
	add_child(dim)
	title_label = _label(TITLE, 72, HIGHLIGHT_COLOR, 150.0)
	art = GiftBoxArt.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Beside the middle of the screen, so Banane (in the middle) is seen putting his shades on.
	art.position.x += ART_OFFSET_X
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	contents_label = _label("", 40, TEXT_COLOR, 680.0)
	_label(HINT, 22, Color("#9a93a8"), 960.0)
	confetti = CPUParticles2D.new()
	confetti.position = Vector2(960.0 + ART_OFFSET_X, 470.0)
	confetti.emitting = false
	confetti.amount = 90
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


## A centred line of text whose top is `top` pixels from the top of the screen.
func _label(text: String, font_size: int, color: Color, top: float) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.offset_left = -600.0
	label.offset_right = 600.0
	label.offset_top = top
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 10)
	add_child(label)
	return label
