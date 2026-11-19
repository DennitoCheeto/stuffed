class_name GearEyeToggle
extends SewnButton
## A small sewn button with an eye (spec 09 §6, AC-100b): "Show on hero" (eye open) or "Hidden"
## (eye shut, crossed out) for one gear slot, or "Hide all" / "Show all" for every slot. On the
## sewing table and the Wardrobe's hero picker. A hidden piece still works, it just isn't drawn.

const EYE_SIZE: Vector2 = Vector2(30, 22)

## The gear slot it hides (a `GearDef.Slot`), or -1 for every slot ("Hide all").
var slot: int = -1
## True while it shows "hidden" (eye shut).
var hidden_now: bool = false
var eye: Control = Control.new()
var label: Label

var _says_state: bool = false


## `slot_index` = the slot (-1 = all). `words` = a fixed caption beside the eye ("Head"); with
## `says_state` the eye is followed by its state words instead ("Hide all" / "Show all").
func _init(slot_index: int, words: String = "", says_state: bool = false) -> void:
	super._init()
	slot = slot_index
	_says_state = says_state
	name = "Eye_%s" % ("all" if slot < 0 else GearDef.SLOT_NAMES[slot])
	caption.visible = false
	grows_on_hover = false
	box.radius = 16.0
	box.pad(10, 6)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(row)
	eye.custom_minimum_size = EYE_SIZE
	eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	eye.draw.connect(_draw_eye)
	row.add_child(eye)
	label = UiFonts.label(words, 18, UiColors.INK, UiFonts.heading())
	label.visible = not words.is_empty() or says_state
	row.add_child(label)


## Shows the state: `on` = hidden (eye shut). `words` is what it says (also its tooltip); a toggle
## made with a fixed caption keeps that caption.
func show_hidden(on: bool, words: String) -> void:
	hidden_now = on
	text = words
	tooltip_text = words
	if _says_state:
		label.text = words
	eye.queue_redraw()


func _draw_eye() -> void:
	var middle: Vector2 = eye.size / 2.0
	var half: Vector2 = EYE_SIZE / 2.0 - Vector2(2.0, 3.0)
	var upper: PackedVector2Array = []
	var lower: PackedVector2Array = []
	for i: int in 13:
		var x: float = lerpf(-half.x, half.x, i / 12.0)
		var bulge: float = half.y * (1.0 - pow(x / half.x, 2.0))
		upper.append(middle + Vector2(x, -bulge))
		lower.append(middle + Vector2(x, bulge))
	var ink: Color = UiColors.INK
	if hidden_now:
		# A shut eye: the lower lid line with lashes, crossed out.
		eye.draw_polyline(lower, ink, 2.0, true)
		for x: float in [-0.5, 0.0, 0.5]:
			var root: Vector2 = middle + Vector2(x * half.x, half.y * (1.0 - x * x))
			eye.draw_line(root, root + Vector2(x * 3.0, 4.0), ink, 1.5, true)
		eye.draw_line(middle + Vector2(-half.x, -half.y), middle + half, ink, 2.0, true)
		return
	var almond: PackedVector2Array = upper.duplicate()
	for i: int in range(lower.size() - 2, 0, -1):
		almond.append(lower[i])
	FeltDraw.fill(eye, almond, UiColors.PHOTO)
	eye.draw_circle(middle, half.y * 0.75, UiColors.TEAL)
	eye.draw_circle(middle, half.y * 0.35, ink)
	almond.append(almond[0])
	eye.draw_polyline(almond, ink, 2.0, true)
