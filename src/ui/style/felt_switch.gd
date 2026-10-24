class_name FeltSwitch
extends Button
## An on/off switch in felt (spec 04 §6.2): the words on the left, a stitched felt track on the
## right with a sewing button that slides across (teal "ON" / cream "OFF"). Hover or keyboard
## focus rings the whole row with a stitch line, so the focused switch is always clear.
## A toggle Button underneath: `button_pressed`, `toggled` and `set_pressed_no_signal` work.

const TRACK: Vector2 = Vector2(96, 40)
const KNOB_RADIUS: float = 15.0
const TAG_SIZE: int = 15
const PADDING: Vector2 = Vector2(14, 8)
const FONT_COLORS: Array[StringName] = [
	&"font_color",
	&"font_hover_color",
	&"font_pressed_color",
	&"font_focus_color",
	&"font_hover_pressed_color",
]
const STATES: Array[StringName] = [
	&"normal", &"hover", &"pressed", &"focus", &"disabled", &"hover_pressed"
]

## Where the knob is: 0 = off (left), 1 = on (right). Slides when the switch flips.
var slide: float = 0.0:
	set(value):
		slide = value
		queue_redraw()

var _hovered: bool = false
var _tween: Tween


func _init(words: String = "", font_size: int = 26) -> void:
	text = words
	toggle_mode = true
	focus_mode = Control.FOCUS_ALL
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	var box: StyleBoxEmpty = StyleBoxEmpty.new()
	box.content_margin_left = PADDING.x
	box.content_margin_right = PADDING.x * 2.0 + TRACK.x
	box.content_margin_top = PADDING.y
	box.content_margin_bottom = PADDING.y
	for state: StringName in STATES:
		add_theme_stylebox_override(state, box)
	add_theme_font_override(&"font", UiFonts.body())
	add_theme_font_size_override(&"font_size", font_size)
	for color: StringName in FONT_COLORS:
		add_theme_color_override(color, UiColors.INK)
	custom_minimum_size = Vector2(0, TRACK.y + PADDING.y * 2.0)
	toggled.connect(_on_toggled)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)


## Like Button's, but the knob jumps to the new side too (no slide).
func show_pressed(on: bool) -> void:
	set_pressed_no_signal(on)
	_stop()
	slide = 1.0 if on else 0.0


## The track on the right (local px).
func track_rect() -> Rect2:
	var top: float = (size.y - TRACK.y) / 2.0
	return Rect2(Vector2(size.x - PADDING.x - TRACK.x, top), TRACK)


## The knob's centre (local px).
func knob_center() -> Vector2:
	var track: Rect2 = track_rect()
	var inset: float = track.size.y / 2.0
	var from: float = track.position.x + inset
	var to: float = track.end.x - inset
	return Vector2(lerpf(from, to, slide), track.get_center().y)


## True while the row looks "up" (hovered or focused).
func is_raised() -> bool:
	return not disabled and (_hovered or has_focus())


func _draw() -> void:
	if is_raised():
		var ring: PackedVector2Array = FeltDraw.dashes(
			FeltDraw.rounded(Rect2(Vector2.ZERO, size).grow(-2.0), 14.0), 8.0, 6.0
		)
		draw_multiline(ring, UiColors.PURPLE if has_focus() else UiColors.STITCH, 2.5, true)
	var track: Rect2 = track_rect()
	var on_color: Color = UiColors.THREAD.darkened(0.25)
	var fill: Color = UiColors.STITCH.lerp(on_color, slide)
	FeltDraw.fill(self, FeltDraw.rounded(track, track.size.y / 2.0), fill)
	var stitches: PackedVector2Array = FeltDraw.dashes(
		FeltDraw.rounded(track.grow(-5.0), track.size.y / 2.0 - 5.0), 5.0, 4.0
	)
	draw_multiline(stitches, fill.lightened(0.4), 1.5, true)
	var font: Font = UiFonts.body(800)
	var words: String = "ON" if button_pressed else "OFF"
	var width: float = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_SIZE).x
	var room: float = track.size.x - track.size.y
	# The word sits on the side the knob isn't on.
	var free_from: float = track.position.x + (4.0 if button_pressed else track.size.y - 4.0)
	var text_x: float = free_from + (room - width) / 2.0
	var baseline: float = track.get_center().y + font.get_ascent(TAG_SIZE) * 0.38
	var ink: Color = UiColors.FELT if button_pressed else UiColors.INK
	var spot: Vector2 = Vector2(text_x, baseline)
	draw_string(font, spot, words, HORIZONTAL_ALIGNMENT_LEFT, -1, TAG_SIZE, ink)
	var grow: float = UiFeel.STYLE.knob_grow if is_raised() else 1.0
	SewingButtonArt.draw(self, knob_center(), KNOB_RADIUS * grow, UiColors.GOLD)


func _on_toggled(on: bool) -> void:
	Sfx.play(&"ui_press")
	_stop()
	var target: float = 1.0 if on else 0.0
	if not is_inside_tree() or UiFeel.reduced():
		slide = target
		return
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "slide", target, UiFeel.STYLE.switch_seconds)


func _stop() -> void:
	if _tween != null:
		_tween.kill()
	_tween = null


func _on_hover(on: bool) -> void:
	_hovered = on
	if on and not disabled:
		Sfx.play(&"ui_hover")
	queue_redraw()


func _on_focus_entered() -> void:
	if SewnButton.moved_by_keyboard():
		Sfx.play(&"ui_hover")
	queue_redraw()
