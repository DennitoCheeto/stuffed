class_name TricksToast
extends PanelContainer
## "New: Snack Bar tricks!" near the bottom of the screen when a building reaches level 1
## (spec 06 §2): its trick branch opens. A taped felt patch, a little crooked; pops in, stays,
## fades. Waits for the "New weapons" toast if that one is still showing.

const SHOW_SECONDS: float = 3.2
const FADE_SECONDS: float = 0.5
const POP_SECONDS: float = 0.25
const TILT: float = -1.2
const BOTTOM_GAP: float = 140.0
const SUBTITLE: String = "Walk up to it and press T"

var title_label: Label
var subtitle_label: Label
var box: StyleBoxFelt = StyleBoxFelt.new()

## Seconds until it shows (waiting for another toast), then seconds left on screen.
var _wait: float = 0.0
var _left: float = 0.0


func _init() -> void:
	name = "TricksToast"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.shadow = UiColors.SHADOW
	box.pad(30, 18)
	box.add_tape(0.5, 3.0, UiColors.TAPE_GOLD)
	add_theme_stylebox_override(&"panel", box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	title_label = UiFonts.label("", 44, UiColors.PURPLE, UiFonts.hand())
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	subtitle_label = UiFonts.label(SUBTITLE, 24, UiColors.INK)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subtitle_label)


## "New: <building> tricks!", after `delay` seconds.
func show_for(building_name: String, delay: float = 0.0) -> void:
	title_label.text = "New: %s tricks!" % building_name
	_wait = maxf(delay, 0.0)
	_left = SHOW_SECONDS
	visible = false
	if _wait <= 0.0:
		_appear()


## True while it shows or waits to show.
func is_pending() -> bool:
	return _left > 0.0


func is_showing() -> bool:
	return visible


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_appear()
		return
	_left -= delta
	var shown: float = SHOW_SECONDS - _left
	var pop: float = 1.0 if UiFeel.reduced() else clampf(shown / POP_SECONDS, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.6, 1.0, ease(pop, -2.0))
	modulate.a = clampf(_left / FADE_SECONDS, 0.0, 1.0)
	if _left <= 0.0:
		visible = false


func _appear() -> void:
	_wait = 0.0
	modulate.a = 1.0
	visible = true
	reset_size()
	var screen: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2.ZERO
	position = Vector2((screen.x - size.x) / 2.0, screen.y - size.y - BOTTOM_GAP)
	pivot_offset = size / 2.0
	rotation = deg_to_rad(TILT)
	scale = Vector2.ONE * (1.0 if UiFeel.reduced() else 0.6)
