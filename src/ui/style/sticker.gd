class_name Sticker
extends Wobbly
## A sticker (spec 04 §2-3, look B): a stitched pill with hand-written words, tilted, that slaps
## on with a bounce and a "thwap". Run titles and "New!" markers are stickers.

var label: Label = Label.new()
var box: StyleBoxFelt = StyleBoxFelt.new()
var _tween: Tween


func _init(
	words: String,
	fill: Color = UiColors.STICKER_PINK,
	ink: Color = UiColors.STICKER_PINK_INK,
	degrees: float = 4.0,
	font_size: int = 26
) -> void:
	box.fill = fill
	box.stitch = fill.lightened(0.6)
	box.radius = 40.0
	box.stitch_inset = 6.0
	box.stitch_width = 2.0
	box.stitch_dash = 6.0
	box.stitch_gap = 4.0
	box.pad(20, 6)
	var pill: PanelContainer = PanelContainer.new()
	pill.add_theme_stylebox_override("panel", box)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = words
	label.add_theme_font_override("font", UiFonts.hand())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", ink)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(label)
	set_body(pill)
	tilt = degrees
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Slaps the sticker on: big and turned, then down to size with a bounce, and a "thwap".
func slap() -> void:
	Sfx.play(&"sticker")
	if _tween != null:
		_tween.kill()
	var style: UiStyle = UiFeel.STYLE
	if UiFeel.reduced():
		rest()
		return
	grow = style.slap_grow
	spin = -style.slap_spin
	fade = 0.0
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "grow", 1.0, style.slap_seconds)
	_tween.tween_property(self, "spin", 0.0, style.slap_seconds)
	_tween.tween_property(self, "fade", 1.0, style.slap_seconds * 0.4)


func is_slapping() -> bool:
	return _tween != null and _tween.is_running()
