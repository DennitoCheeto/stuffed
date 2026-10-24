class_name FabricTag
extends PanelContainer
## A small fabric tag label (spec 04 §2, look A): levels, "EVO", key hints, item names.
## Tags don't tilt or move: they are read at a glance.

var label: Label = Label.new()
var box: StyleBoxFelt = StyleBoxFelt.new(UiColors.TAG, UiColors.TAG_STITCH)


func _init(
	words: String, fill: Color = UiColors.TAG, ink: Color = UiColors.INK, font_size: int = 15
) -> void:
	box.fill = fill
	box.stitch = fill.lightened(0.45) if fill.get_luminance() < 0.5 else fill.darkened(0.28)
	box.radius = 8.0
	box.stitch_inset = 3.0
	box.stitch_width = 1.5
	box.stitch_dash = 4.0
	box.stitch_gap = 3.0
	box.pad(10, 3)
	add_theme_stylebox_override("panel", box)
	label.text = words
	label.add_theme_font_override("font", UiFonts.body(800))
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ink)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
