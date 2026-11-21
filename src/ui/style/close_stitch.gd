class_name CloseStitch
extends SewnButton
## A small round sewn patch with a stitched X (#325): sits in the top right corner of a felt
## panel so the mouse can always close it (Esc still works). Made by `FeltPanel.add_close`.
## Mouse only: it takes no keyboard focus, so arrow keys keep moving between the panel's choices.

## The patch's size (it stays this size, the X is drawn inside).
const SIZE: Vector2 = Vector2(52, 52)
## How far the X's arms reach from the middle and how thick the thread is.
const ARM: float = 11.0
const THREAD: float = 5.0

var mark: Control = Control.new()


func _init() -> void:
	super._init("")
	name = "CloseStitch"
	caption.visible = false
	focus_mode = Control.FOCUS_NONE
	tooltip_text = "Close"
	box.radius = SIZE.x / 2.0
	box.stitch_inset = 5.0
	box.pad(0, 0)
	mark.custom_minimum_size = SIZE
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.draw.connect(_draw_mark)
	face.add_child(mark)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func _draw_mark() -> void:
	var middle: Vector2 = mark.size / 2.0
	for corner: Vector2 in [Vector2(1, 1), Vector2(1, -1)]:
		var from: Vector2 = middle - corner * ARM
		var to: Vector2 = middle + corner * ARM
		mark.draw_line(from, to, UiColors.PURPLE, THREAD, true)
