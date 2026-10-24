class_name ThreadSlider
extends HSlider
## A slider that looks like a thread with a sewing button as the knob (spec 04 §6.2): the part
## up to the knob is a sewn-in teal thread, the rest a loose dashed one. Hover or keyboard focus
## grows the knob with a spring and rings it, so the focused slider is always clear.

const KNOB_RADIUS: float = 17.0
const HEIGHT: float = 48.0
const WAVE: float = 3.0
const WAVE_LENGTH: float = 26.0
const STEPS_PER_WAVE: int = 8
const FOCUS_RING: float = 6.0
const DASH: float = 9.0
const DASH_GAP: float = 6.0

## The knob's size right now (1 = resting), animated by hover / focus.
var knob_grow: float = 1.0:
	set(value):
		knob_grow = value
		queue_redraw()

var _hovered: bool = false
var _tween: Tween


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(0, HEIGHT)
	var blank: ImageTexture = _blank_knob()
	for icon: StringName in [&"grabber", &"grabber_highlight", &"grabber_disabled", &"tick"]:
		add_theme_icon_override(icon, blank)
	for box: StringName in [&"slider", &"grabber_area", &"grabber_area_highlight"]:
		add_theme_stylebox_override(box, StyleBoxEmpty.new())
	value_changed.connect(_on_value_changed)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_go_to_pose)
	resized.connect(queue_redraw)


## Where the knob sits (local px): follows the value like Godot's own grabber.
func knob_center() -> Vector2:
	var span: float = maxf(size.x - KNOB_RADIUS * 2.0, 0.0)
	return Vector2(KNOB_RADIUS + span * ratio, size.y / 2.0)


## True while the knob looks "up" (hovered or focused).
func is_raised() -> bool:
	return editable and (_hovered or has_focus())


func _draw() -> void:
	var knob: Vector2 = knob_center()
	var left: float = KNOB_RADIUS * 0.5
	var right: float = size.x - KNOB_RADIUS * 0.5
	# The loose thread: short dashes from the knob to the end.
	var x: float = knob.x
	while x < right:
		var dash: PackedVector2Array = _wave(x, minf(x + DASH, right))
		if dash.size() > 1:
			draw_polyline(dash, UiColors.STITCH.darkened(0.1), 3.0, true)
		x += DASH + DASH_GAP
	var sewn: PackedVector2Array = _wave(left, knob.x)
	if sewn.size() > 1:
		draw_polyline(sewn, UiColors.THREAD.darkened(0.15), 5.0, true)
	var radius: float = KNOB_RADIUS * knob_grow
	if has_focus():
		draw_arc(knob, radius + FOCUS_RING, 0.0, TAU, 32, UiColors.PURPLE, 3.0, true)
	SewingButtonArt.draw(self, knob, radius, UiColors.GOLD)


func _wave(from: float, to: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	if to - from < 1.0:
		return points
	var middle: float = size.y / 2.0
	var step: float = WAVE_LENGTH / STEPS_PER_WAVE
	var x: float = from
	while x < to:
		points.append(Vector2(x, middle + sin(x / WAVE_LENGTH * TAU) * WAVE))
		x += step
	points.append(Vector2(to, middle + sin(to / WAVE_LENGTH * TAU) * WAVE))
	return points


func _on_value_changed(_value: float) -> void:
	queue_redraw()


func _on_hover(on: bool) -> void:
	_hovered = on
	if on and editable:
		Sfx.play(&"ui_hover")
	_go_to_pose()


func _on_focus_entered() -> void:
	if SewnButton.moved_by_keyboard():
		Sfx.play(&"ui_hover")
	_go_to_pose()


func _go_to_pose() -> void:
	var style: UiStyle = UiFeel.STYLE
	var size_to: float = style.knob_grow if is_raised() else 1.0
	queue_redraw()
	if _tween != null:
		_tween.kill()
	if not is_inside_tree():
		knob_grow = size_to
		return
	var trans: Tween.TransitionType = Tween.TRANS_SINE if UiFeel.reduced() else Tween.TRANS_BACK
	_tween = create_tween().set_trans(trans).set_ease(Tween.EASE_OUT)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "knob_grow", size_to, style.spring_seconds)


## An empty picture the size of the knob, so Godot lays out the grabber where we draw ours.
static func _blank_knob() -> ImageTexture:
	var side: int = int(KNOB_RADIUS * 2.0)
	var image: Image = Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(image)
