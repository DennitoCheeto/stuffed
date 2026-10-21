class_name Crosshair
extends RefCounted
## The mouse cursor during a run: a small crosshair, drawn in code (spec 01 §3).

const SIZE: int = 32
const COLOR: Color = Color(0.97, 0.95, 0.9, 0.95)
const EDGE: Color = Color(0.11, 0.1, 0.14, 0.9)


## Shows the crosshair instead of the arrow.
static func use() -> void:
	var image: Image = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var middle: int = SIZE / 2
	for i: int in SIZE:
		var gap: bool = absi(i - middle) < 4
		if gap:
			continue
		for width: int in [-1, 0, 1]:
			var color: Color = COLOR if width == 0 else EDGE
			image.set_pixel(i, middle + width, color)
			image.set_pixel(middle + width, i, color)
	image.set_pixel(middle, middle, COLOR)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, Vector2(middle, middle))


## Back to the normal arrow (menus).
static func stop() -> void:
	Input.set_custom_mouse_cursor(null)
