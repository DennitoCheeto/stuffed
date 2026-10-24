extends RefCounted
## Fit check (spec 04 §5, AC-55): lists what doesn't fit on a screen: buttons, panels and sliders
## closer than 24 px to the window edge, labels and bars outside the window, anything sticking out
## of its felt box, and cut-off labels.
## Controls in the game world (under a Node2D, e.g. name tags over buildings) are skipped, and so
## are the children of a ScrollContainer (they may scroll out of view on purpose).

## The window sizes the game must fit (spec 04 §5).
const WINDOWS: Array[Vector2i] = [
	Vector2i(1920, 1080), Vector2i(1920, 1200), Vector2i(1280, 720), Vector2i(2560, 1440)
]
## The size the game lays out in (project.godot: viewport 1920 x 1080).
const BASE: Vector2 = Vector2(1920, 1080)
const MARGIN: float = 24.0
## Rounding slack in px.
const SLACK: float = 1.0


## The 2D size the game lays out in for `window` (stretch mode canvas_items, aspect expand).
static func layout_size(window: Vector2i) -> Vector2i:
	var scale: float = minf(window.x / BASE.x, window.y / BASE.y)
	return Vector2i(roundi(window.x / scale), roundi(window.y / scale))


## Every problem found under `root` (empty = it fits), each as a readable line.
static func problems(root: Node, screen: Rect2) -> PackedStringArray:
	var found: PackedStringArray = []
	_walk(root, screen, null, false, found)
	return found


static func _walk(
	node: Node, screen: Rect2, box: Control, in_world: bool, found: PackedStringArray
) -> void:
	var layer: CanvasLayer = node as CanvasLayer
	if layer != null:
		if not layer.visible:
			return
		in_world = false
	elif node is Node2D:
		in_world = true
	var control: Control = node as Control
	if control != null:
		if not control.is_visible_in_tree():
			return
		if not in_world:
			_check(control, screen, box, found)
			if control is ScrollContainer:
				return
			if control is PanelContainer:
				box = control
	for child: Node in node.get_children():
		_walk(child, screen, box, in_world, found)


static func _check(control: Control, screen: Rect2, box: Control, found: PackedStringArray) -> void:
	var checked: bool = (
		control is BaseButton
		or control is Label
		or control is PanelContainer
		or control is Range
		or control is ScrollContainer
	)
	if not checked or control.size.x < 1.0 or control.size.y < 1.0:
		return
	var rect: Rect2 = control.get_global_rect()
	var name: String = _name(control)
	# Buttons, panels and sliders keep the margin; labels and bars (the HUD sits at the edges on
	# purpose) only have to be inside the window.
	var keeps_margin: bool = not (control is Label or control is ProgressBar)
	var allowed: Rect2 = screen.grow(-MARGIN) if keeps_margin else screen
	if not allowed.grow(SLACK).encloses(rect):
		found.append("%s leaves the window: %s (allowed %s)" % [name, rect, allowed])
	if box != null and not box.get_global_rect().grow(SLACK).encloses(rect):
		found.append("%s sticks out of its box %s" % [name, _name(box)])
	var label: Label = control as Label
	if label != null and is_cut_off(label):
		found.append("%s is cut off" % name)


## True if some of the label's text can't be seen (trimmed, clipped or lines hidden).
static func is_cut_off(label: Label) -> bool:
	if label.text.strip_edges().is_empty():
		return false
	if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		if label.max_lines_visible >= 0 and label.get_line_count() > label.max_lines_visible:
			return true
		return label.get_visible_line_count() < label.get_line_count()
	var trims: bool = label.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
	if not label.clip_text and not trims:
		return false
	var font: Font = label.get_theme_font(&"font")
	var font_size: int = label.get_theme_font_size(&"font_size")
	var width: float = 0.0
	for line: String in label.text.split("\n"):
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	return width > label.size.x + SLACK


static func _name(control: Control) -> String:
	var words: String = ""
	var button: Button = control as Button
	var label: Label = control as Label
	if button != null:
		words = button.text
	elif label != null:
		words = label.text.left(30)
	return "%s '%s'" % [control.get_class(), words] if not words.is_empty() else str(control.name)
