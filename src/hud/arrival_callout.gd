class_name ArrivalCallout
extends PanelContainer
## A small one-line HUD note when something turns up that the player only heard so far (#340):
## "A toy appeared!" when a floor toy drops, "A big one is here!" when an elite arrives. Much
## smaller than the big arrival banner, just under the boss bar's place, so both can show at
## once. The newest note replaces the old one. Stays still like the rest of the HUD.

## Distance from the top of the screen (under the boss bar, above the big banner).
const TOP: float = 122.0
const FONT_SIZE: int = 26
## The note fades out over its last this many seconds.
const FADE: float = 0.4
## Text colours: the toy's glow (warm cream) and the Spyglass arrow pink for elites. Neither is
## the enemies' danger red/orange (vision §6).
const TOY_COLOR: Color = FloorPickupLook.GLOW_COLOR
const ELITE_COLOR: Color = PickupArrows.THREAT_COLOR

var label: Label

var _left: float = 0.0


func _init() -> void:
	name = "ArrivalCallout"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = TOP
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var backing: StyleBoxFelt = StyleBoxFelt.hud(10.0)
	backing.pad(20, 2)
	add_theme_stylebox_override("panel", backing)
	label = Label.new()
	label.add_theme_font_override("font", UiFonts.body(800))
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_outline_color", UiColors.HUD_OUTLINE)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _process(delta: float) -> void:
	if not visible:
		return
	_left -= delta
	modulate.a = clampf(_left / FADE, 0.0, 1.0)
	visible = _left > 0.0


## Shows `text` in `color` for `seconds`.
func show_note(text: String, color: Color, seconds: float) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)
	_left = seconds
	modulate.a = 1.0
	visible = true
	reset_size()


## The text on show, or "" when hidden.
func shown_text() -> String:
	return label.text if visible else ""
