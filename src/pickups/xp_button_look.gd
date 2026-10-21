class_name XpButtonLook
extends RefCounted
## The felt XP buttons (small, medium, big), drawn once into the FeltAtlas.
## Shapes are in "atlas units": three times the on-screen size, for a sharp bake.

const DRAW_SCALE: float = 1.0 / 3.0
const KEYS: Array[StringName] = [&"xp/small", &"xp/medium", &"xp/big"]
## On-screen radius per size, in pixels.
const RADII: PackedFloat32Array = [7.0, 9.0, 12.0]
const COLORS: PackedColorArray = [Color("#4fc3f7"), Color("#b388ff"), Color("#ffb74d")]
const HOLE_COLOR: Color = Color("#0b3b52")


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	var parts: Dictionary[StringName, FeltPiece] = {}
	for size: int in KEYS.size():
		parts[KEYS[size]] = _button(RADII[size] / DRAW_SCALE, COLORS[size])
	return parts


static func _button(radius: float, color: Color) -> FeltPiece:
	var button: FeltPiece = FeltPiece.new()
	button.polygon = FeltShapes.circle(Vector2.ZERO, radius, 24)
	button.color = color
	button.outline_width = radius * 0.12
	button.outline_color = color.darkened(0.6)
	var hole: float = radius * 0.2
	var spacing: float = radius * 0.33
	for offset: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		button.add_layer(FeltShapes.circle(offset * spacing, hole, 10), HOLE_COLOR)
	return button
