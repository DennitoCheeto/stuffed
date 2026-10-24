class_name MenuCloth
extends Control
## The dark felt cloth behind menus (spec 04 §2): dusty purple felt with soft fibres, a dashed
## stitch line around the edge and a few sewing buttons sewn on as decoration. See-through
## (`opacity` < 1) over a run or the town, so the game shows dimmed behind it. Stops clicks from
## reaching the game underneath.

const FIBRES: int = 260
const FIBRE_LENGTH: float = 7.0
const FRAME_INSET: float = 22.0
const FRAME_RADIUS: float = 28.0
## Decoration buttons: x, y as shares of the screen and their radius (corners stay free of menus).
const BUTTONS: Array[Vector3] = [
	Vector3(0.06, 0.12, 22), Vector3(0.94, 0.86, 26), Vector3(0.9, 0.1, 16), Vector3(0.08, 0.9, 18)
]
const BUTTON_COLORS: Array[Color] = [
	UiColors.GOLD, UiColors.STICKER_TEAL, UiColors.STICKER_PINK, UiColors.FELT
]

var opacity: float = 1.0
## Darker cloth (e.g. a dimmed run behind it).
var shade: float = 0.0
## Only the colour: no fibres, frame or buttons (a dim layer over another cloth).
var plain: bool = false


func _init(own_opacity: float = 1.0, own_shade: float = 0.0, own_plain: bool = false) -> void:
	opacity = own_opacity
	shade = own_shade
	plain = own_plain
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


## The cloth colour (with its see-through amount).
func cloth_color() -> Color:
	return Color(UiColors.CLOTH.darkened(shade), opacity)


func _draw() -> void:
	var area: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(area, cloth_color())
	if plain:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var light: Color = Color(UiColors.CLOTH.lightened(0.25), 0.18 * opacity)
	var dark: Color = Color(UiColors.CLOTH.darkened(0.45), 0.2 * opacity)
	for index: int in FIBRES:
		var at: Vector2 = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var turn: Vector2 = Vector2.from_angle(rng.randf() * TAU) * FIBRE_LENGTH
		draw_line(at, at + turn, light if index % 2 == 0 else dark, 2.0, true)
	var frame: Rect2 = area.grow(-FRAME_INSET)
	if frame.size.x > 0.0 and frame.size.y > 0.0:
		var stitches: PackedVector2Array = FeltDraw.dashes(
			FeltDraw.rounded(frame, FRAME_RADIUS), 14.0, 10.0
		)
		draw_multiline(stitches, Color(UiColors.CLOTH.lightened(0.35), 0.55 * opacity), 3.0, true)
	for index: int in BUTTONS.size():
		var spot: Vector3 = BUTTONS[index]
		var color: Color = BUTTON_COLORS[index]
		var center: Vector2 = Vector2(spot.x * size.x, spot.y * size.y)
		SewingButtonArt.draw(self, center, spot.z, color, opacity)
