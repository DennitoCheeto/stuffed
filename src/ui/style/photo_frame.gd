class_name PhotoFrame
extends Wobbly
## A taped-on photo (spec 04 §2, look B): a white frame with a shadow, a picture area and a
## hand-written caption, a bit crooked. Weapons on the end screen and rescued plushies use it.

## Put the picture (an icon, a plushie look...) into this.
var picture: PanelContainer = PanelContainer.new()
var caption: Label = Label.new()
var box: StyleBoxFelt = StyleBoxFelt.new(UiColors.PHOTO, UiColors.PHOTO)


func _init(
	words: String = "",
	picture_size: Vector2 = Vector2(170, 112),
	degrees: float = -3.0,
	tape: Color = UiColors.TAPE_TEAL
) -> void:
	box.radius = 4.0
	box.stitch_inset = 0.0
	box.shadow = UiColors.SHADOW
	box.shadow_offset = 5.0
	box.pad(10, 10)
	if tape.a > 0.0:
		box.add_tape(0.5, 5.0, tape)
	var frame: PanelContainer = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", box)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	frame.add_child(column)
	picture.custom_minimum_size = picture_size
	var backing: StyleBoxFlat = StyleBoxFlat.new()
	backing.bg_color = UiColors.FELT
	backing.set_corner_radius_all(4)
	picture.add_theme_stylebox_override("panel", backing)
	column.add_child(picture)
	caption.text = words
	caption.visible = words != ""
	caption.add_theme_font_override("font", UiFonts.hand())
	caption.add_theme_font_size_override("font_size", 24)
	caption.add_theme_color_override("font_color", UiColors.INK)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(caption)
	set_body(frame)
	tilt = degrees
