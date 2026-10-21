class_name LoadoutSlot
extends Control
## One HUD slot: a small felt icon of an owned weapon or item with its level. Empty slots are a
## faint circle, so the player sees how much room is left.

const SLOT_SIZE: Vector2 = Vector2(44, 44)
const EMPTY_ALPHA: float = 0.35

## The icon shown ("" = empty slot).
var icon_name: StringName = &""
## 0 = empty.
var level: int = 0

var _icon: UpgradeIcon = UpgradeIcon.new()
var _level_label: Label = Label.new()


func _init() -> void:
	custom_minimum_size = SLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)
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


## Shows `icon` at `upgrade_level`; level 0 makes the slot empty.
func show_upgrade(icon: StringName, upgrade_level: int) -> void:
	icon_name = icon if upgrade_level > 0 else &""
	level = upgrade_level
	_icon.icon = icon_name
	_level_label.text = str(level) if level > 0 else ""
	modulate.a = 1.0 if level > 0 else EMPTY_ALPHA
