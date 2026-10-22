class_name LoadoutSlot
extends Control
## One HUD slot: a small felt icon of an owned weapon or item with its level. Empty slots are a
## faint circle, so the player sees how much room is left. An evolved weapon's slot gets a golden
## frame and a small star (spec 02 §20).

const SLOT_SIZE: Vector2 = Vector2(44, 44)
const EMPTY_ALPHA: float = 0.35
const FRAME_COLOR: Color = Color("#f2c230")
const FRAME_WIDTH: float = 3.0
const STAR_RADIUS: float = 9.0

## The icon shown ("" = empty slot).
var icon_name: StringName = &""
## 0 = empty.
var level: int = 0
## True for an evolved weapon (golden frame + star).
var evolved: bool = false
## Draws the golden frame and star on top of the icon.
var frame: Control = Control.new()

var _icon: UpgradeIcon = UpgradeIcon.new()
var _level_label: Label = Label.new()


func _init() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.draw.connect(_draw_frame)
	add_child(frame)
	_level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_level_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_level_label.offset_right = 4.0
	_level_label.offset_bottom = 6.0
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", Color("#f2b52e"))
	_level_label.add_theme_color_override("font_outline_color", Color("#14101a"))
	_level_label.add_theme_constant_override("outline_size", 6)
	_level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_level_label)
	show_upgrade(&"", 0)


## Shows `icon` at `upgrade_level`; level 0 makes the slot empty. `is_evolved` adds the golden
## frame and star.
func show_upgrade(icon: StringName, upgrade_level: int, is_evolved: bool = false) -> void:
	icon_name = icon if upgrade_level > 0 else &""
	level = upgrade_level
	evolved = is_evolved and level > 0
	_icon.icon = icon_name
	_level_label.text = str(level) if level > 0 and not evolved else ""
	modulate.a = 1.0 if level > 0 else EMPTY_ALPHA
	frame.visible = evolved
	frame.queue_redraw()


func _draw_frame() -> void:
	var center: Vector2 = frame.size / 2.0
	var radius: float = minf(frame.size.x, frame.size.y) / 2.0
	frame.draw_arc(center, radius + 1.0, 0.0, TAU, 32, FRAME_COLOR, FRAME_WIDTH, true)
	var star_at: Vector2 = Vector2(frame.size.x - 3.0, 3.0)
	var points: PackedVector2Array = []
	for i: int in 10:
		var reach: float = STAR_RADIUS if i % 2 == 0 else STAR_RADIUS * 0.45
		points.append(star_at + Vector2.from_angle(TAU * i / 10.0 - PI / 2.0) * reach)
	frame.draw_colored_polygon(points, FRAME_COLOR)
	frame.draw_polyline(points + PackedVector2Array([points[0]]), Color("#14101a"), 1.5, true)
