class_name ProjectileLook
extends RefCounted
## The felt shots (banana peel, sewing pin, needle, button) and the zombies' stuffing ball,
## drawn once into the FeltAtlas. Shapes are in "atlas units": three times the on-screen size, for a sharp bake.
## Players' shots are soft and quiet; enemy bullets are bright with a dark outline (vision §6.1).

const DRAW_SCALE: float = 1.0 / 3.0
const UNITS: float = 3.0
const PEEL: StringName = &"shot/peel"
const PIN: StringName = &"shot/pin"
const NEEDLE: StringName = &"shot/needle"
const BUTTON: StringName = &"shot/button"
const BULLET: StringName = &"bullet/stuffing"
## On-screen radius of the stuffing ball part; bigger bullets scale it.
const BULLET_RADIUS: float = 8.0
## The peel is drawn a little bigger than its outline numbers.
const PEEL_SIZE: float = 1.3
const PEEL_COLOR: Color = Color("#efe3a0")
const PIN_LENGTH: float = 30.0
const PIN_SHAFT_COLOR: Color = Color("#d9d6e3")
const PIN_HEAD_COLOR: Color = Color("#e0475b")
const NEEDLE_LENGTH: float = 30.0
const NEEDLE_COLOR: Color = Color("#cfd3e0")
const BUTTON_RADIUS: float = 7.0
const BUTTON_COLOR: Color = Color("#8fc9b9")
const BUTTON_HOLE_COLOR: Color = Color("#4f7f73")
const BULLET_COLOR: Color = Color("#ff3d6e")
const BULLET_CORE_COLOR: Color = Color("#ffe1ea")
const BULLET_OUTLINE_COLOR: Color = Color("#14101a")


static func make_parts() -> Dictionary[StringName, FeltPiece]:
	return {
		PEEL: _peel(), PIN: _pin(), NEEDLE: _needle(), BUTTON: _button(), BULLET: _bullet()
	}


## Makes `sprite` show part `key` at its on-screen size (times `size_factor`).
static func apply(sprite: Sprite2D, key: StringName, size_factor: float = 1.0) -> void:
	FeltAtlas.show_part(sprite, key)
	sprite.scale *= DRAW_SCALE * size_factor


static func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for point: Vector2 in points:
		result.append(point * factor)
	return result


static func _peel() -> FeltPiece:
	var peel: FeltPiece = FeltPiece.new()
	var outline: PackedVector2Array = FeltShapes.svg_path(
		PackedFloat32Array([-14, 6, -8, -10, 8, -10, 14, 6, 6, -2, -6, -2, -14, 6])
	)
	peel.polygon = _scaled(outline, PEEL_SIZE * UNITS)
	peel.color = PEEL_COLOR
	return peel


## Points along +x: the tip at the pivot, the round head at the back.
static func _pin() -> FeltPiece:
	var pin: FeltPiece = FeltPiece.new()
	pin.soft = false
	var shaft: PackedVector2Array = FeltShapes.points(
		PackedFloat32Array([-PIN_LENGTH, -1.5, 0, -1.5, 7, 0, 0, 1.5, -PIN_LENGTH, 1.5])
	)
	pin.polygon = _scaled(shaft, UNITS)
	pin.color = PIN_SHAFT_COLOR
	var head: Vector2 = Vector2(-PIN_LENGTH, 0.0) * UNITS
	pin.add_layer(FeltShapes.circle(head, 4.0 * UNITS), PIN_HEAD_COLOR)
	return pin


## Points along +x like the pin: thin, with a little eye at the back.
static func _needle() -> FeltPiece:
	var needle: FeltPiece = FeltPiece.new()
	needle.soft = false
	var half: float = NEEDLE_LENGTH / 2.0
	var shaft: PackedVector2Array = FeltShapes.points(
		PackedFloat32Array([-half, -2.4, half - 6, -2, half, 0, half - 6, 2, -half, 2.4])
	)
	needle.polygon = _scaled(shaft, UNITS)
	needle.color = NEEDLE_COLOR
	var eye_center: Vector2 = Vector2(-half + 4.0, 0.0) * UNITS
	var eye: PackedVector2Array = FeltShapes.ellipse(eye_center, Vector2(2.6, 1.1) * UNITS)
	needle.add_layer(eye, BUTTON_HOLE_COLOR)
	return needle


static func _button() -> FeltPiece:
	var button: FeltPiece = FeltPiece.new()
	var radius: float = BUTTON_RADIUS * UNITS
	button.polygon = FeltShapes.circle(Vector2.ZERO, radius, 20)
	button.color = BUTTON_COLOR
	for hole: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		button.add_layer(FeltShapes.circle(hole * radius * 0.28, radius * 0.14), BUTTON_HOLE_COLOR)
	return button


static func _bullet() -> FeltPiece:
	var ball: FeltPiece = FeltPiece.new()
	ball.soft = false
	var radius: float = BULLET_RADIUS * UNITS
	ball.polygon = FeltShapes.circle(Vector2.ZERO, radius, 24)
	ball.color = BULLET_COLOR
	ball.outline_width = radius * 0.3
	ball.outline_color = BULLET_OUTLINE_COLOR
	var core: PackedVector2Array = FeltShapes.circle(Vector2(-0.2, -0.2) * radius, radius * 0.45)
	ball.add_layer(core, BULLET_CORE_COLOR)
	return ball
