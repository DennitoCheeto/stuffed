class_name HandTitle
extends Wobbly
## A hand-written heading (spec 04 §2, look B): Patrick Hand, slightly tilted.

var label: Label = Label.new()


func _init(
	words: String, font_size: int = 40, color: Color = UiColors.PURPLE, degrees: float = -2.0
) -> void:
	label.text = words
	label.add_theme_font_override("font", UiFonts.hand())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	set_body(label)
	tilt = degrees
