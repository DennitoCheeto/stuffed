class_name SewnButton
extends Button
## A chunky sewn-on fabric button (spec 04 §2-3, look A) that reacts to everything:
## hover / keyboard focus = lifts and grows with a spring + "felt pat"; press = squishes into its
## thick bottom edge + "boop"; disabled = flat and faded, a pressed one wiggles "nope".
## The Button itself stays still in the layout (and keeps `text`); its `face` does the moving.

const CLEAR: Color = Color(0, 0, 0, 0)
const STATES: Array[StringName] = [
	&"normal", &"hover", &"pressed", &"focus", &"disabled", &"hover_pressed"
]
const FONT_COLORS: Array[StringName] = [
	&"font_color",
	&"font_hover_color",
	&"font_pressed_color",
	&"font_focus_color",
	&"font_disabled_color",
	&"font_hover_pressed_color",
]
const NAVIGATION: Array[StringName] = [
	&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"
]
const DEPTH: float = 6.0

## The gold "go on" button (one per screen) or a cream one.
var main: bool = false
## False = hover / focus only lifts it, without growing (cards that must keep one size).
var grows_on_hover: bool = true
## True = a gold outline ring and gold stitches show while it is raised (hovered / focused).
var ring_on_raise: bool = false
## What shows and moves: the felt body with the caption.
var face: PanelContainer = PanelContainer.new()
var caption: Label = Label.new()
var box: StyleBoxFelt = StyleBoxFelt.new()
## The face's current pose: px lifted, size, extra turn in degrees.
var lifted: float = 0.0:
	set(value):
		lifted = value
		_place_face()
var grown: float = 1.0:
	set(value):
		grown = value
		_place_face()
var turned: float = 0.0:
	set(value):
		turned = value
		_place_face()

var _base_stitch: Color
var _hovered: bool = false
var _held: bool = false
var _shown_disabled: bool = false
var _tween: Tween
var _wiggle: Tween


func _init(words: String = "", is_main: bool = false, font_size: int = 26) -> void:
	main = is_main
	text = words
	focus_mode = Control.FOCUS_ALL
	for state: StringName in STATES:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	for color: StringName in FONT_COLORS:
		add_theme_color_override(color, CLEAR)
	box.fill = UiColors.GOLD if main else UiColors.FELT
	box.stitch = UiColors.GOLD_STITCH if main else UiColors.STITCH
	box.edge = UiColors.GOLD_EDGE if main else UiColors.CREAM_EDGE
	box.radius = 40.0
	box.stitch_inset = 8.0
	box.depth = DEPTH
	box.pad(40, 12)
	_base_stitch = box.stitch
	face.add_theme_stylebox_override("panel", box)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.text = words
	caption.add_theme_font_override("font", UiFonts.heading())
	caption.add_theme_font_size_override("font_size", font_size)
	caption.add_theme_color_override("font_color", UiColors.GOLD_INK if main else UiColors.INK)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(caption)
	add_child(face)
	face.minimum_size_changed.connect(_fit)
	_fit()
	resized.connect(_place_face)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_go_to_pose)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	gui_input.connect(_on_gui_input)


## Gives the button its own stitch colour (it still brightens when raised).
func set_stitch(color: Color) -> void:
	_base_stitch = color
	box.stitch = color.lightened(0.35) if is_raised() else color


## True while the gold outline ring shows (for tests).
func is_ringed() -> bool:
	return box.ring.a > 0.0


## How far the face is lifted right now (px) and its size (1 = normal), for tests.
func lift_amount() -> float:
	return lifted


func grow_amount() -> float:
	return grown


## True while the button looks "up" (hovered with the mouse or focused with the keyboard).
func is_raised() -> bool:
	return not disabled and (_hovered or has_focus()) and not _held


## A disabled button was pressed: a short "nope" wiggle.
func nope() -> void:
	Sfx.play(&"ui_nope")
	if _wiggle != null:
		_wiggle.kill()
	if not is_inside_tree() or UiFeel.reduced():
		return
	var style: UiStyle = UiFeel.STYLE
	var step: float = style.nope_seconds / 4.0
	_wiggle = create_tween().set_trans(Tween.TRANS_SINE)
	_wiggle.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for angle: float in [style.nope_spin, -style.nope_spin, style.nope_spin / 2.0, 0.0]:
		_wiggle.tween_property(self, "turned", angle, step)


func is_wiggling() -> bool:
	return _wiggle != null and _wiggle.is_running()


func _draw() -> void:
	# Button redraws when its text or disabled state changes: keep the face in step.
	if caption.text != text:
		caption.text = text
	if _shown_disabled != disabled:
		_shown_disabled = disabled
		_held = false
		_go_to_pose()


func _fit() -> void:
	custom_minimum_size = face.get_combined_minimum_size()


func _place_face() -> void:
	face.size = size
	face.pivot_offset = size / 2.0
	face.position = Vector2(0, -lifted)
	face.scale = Vector2.ONE * grown
	face.rotation = deg_to_rad(turned)


func _on_mouse_entered() -> void:
	_hovered = true
	if not disabled:
		Sfx.play(&"ui_hover")
	_go_to_pose()


func _on_mouse_exited() -> void:
	_hovered = false
	_held = false
	_go_to_pose()


func _on_focus_entered() -> void:
	if not disabled and moved_by_keyboard():
		Sfx.play(&"ui_hover")
	_go_to_pose()


func _on_down() -> void:
	_held = true
	Sfx.play(&"ui_press")
	_go_to_pose()


func _on_up() -> void:
	_held = false
	_go_to_pose()


func _on_gui_input(event: InputEvent) -> void:
	if not disabled:
		return
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	var clicked: bool = mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed(&"ui_accept"):
		nope()


## Springs the face to the pose of the current state.
func _go_to_pose() -> void:
	var style: UiStyle = UiFeel.STYLE
	var lift: float = 0.0
	var size_to: float = 1.0
	var press: float = 0.0
	if _held and not disabled:
		size_to = style.press_squish
		press = 1.0
	elif is_raised():
		lift = style.hover_lift
		size_to = style.hover_grow if grows_on_hover else 1.0
	box.stitch = _base_stitch.lightened(0.35) if is_raised() else _base_stitch
	var ringed: bool = ring_on_raise and is_raised()
	box.ring = UiColors.GOLD if ringed else Color(UiColors.GOLD, 0.0)
	if ringed:
		box.stitch = UiColors.GOLD_EDGE
	face.modulate.a = style.disabled_fade if disabled else 1.0
	if _tween != null:
		_tween.kill()
	if not is_inside_tree():
		lifted = lift
		grown = size_to
		box.press = press
		return
	var trans: Tween.TransitionType = Tween.TRANS_SINE if UiFeel.reduced() else Tween.TRANS_BACK
	_tween = create_tween().set_parallel().set_trans(trans).set_ease(Tween.EASE_OUT)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "lifted", lift, style.spring_seconds)
	_tween.tween_property(self, "grown", size_to, style.spring_seconds)
	_tween.tween_property(box, "press", press, style.spring_seconds * 0.5)


static func moved_by_keyboard() -> bool:
	for action: StringName in NAVIGATION:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			return true
	return false
