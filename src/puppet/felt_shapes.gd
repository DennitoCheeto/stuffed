class_name FeltShapes
extends RefCounted
## Builds the outlines of felt pieces (ellipses and curved paths) as polygons.


static func ellipse(center: Vector2, radii: Vector2, segments: int = 28) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in segments:
		var angle: float = TAU * i / segments
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points


static func circle(center: Vector2, radius: float, segments: int = 20) -> PackedVector2Array:
	return ellipse(center, Vector2(radius, radius), segments)


## A path like SVG "M start C c1 c2 end C ...": each curve is [control1, control2, end].
static func path(
	start: Vector2, curves: Array[PackedVector2Array], steps: int = 10
) -> PackedVector2Array:
	var points: PackedVector2Array = [start]
	var from: Vector2 = start
	for curve: PackedVector2Array in curves:
		for i: int in range(1, steps + 1):
			var t: float = float(i) / steps
			points.append(from.bezier_interpolate(curve[0], curve[1], curve[2], t))
		from = curve[2]
	return points


## Short form of `path` with plain numbers, copied from the SVG art concepts:
## [start_x, start_y, then 6 numbers (c1, c2, end) per curve].
static func svg_path(numbers: PackedFloat32Array, steps: int = 10) -> PackedVector2Array:
	var curves: Array[PackedVector2Array] = []
	for i: int in range(2, numbers.size() - 5, 6):
		var c1: Vector2 = Vector2(numbers[i], numbers[i + 1])
		var c2: Vector2 = Vector2(numbers[i + 2], numbers[i + 3])
		var end: Vector2 = Vector2(numbers[i + 4], numbers[i + 5])
		curves.append(PackedVector2Array([c1, c2, end]))
	return path(Vector2(numbers[0], numbers[1]), curves, steps)


## Straight-edged polygon from plain numbers: [x1, y1, x2, y2, ...].
static func points(numbers: PackedFloat32Array) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for i: int in range(0, numbers.size() - 1, 2):
		result.append(Vector2(numbers[i], numbers[i + 1]))
	return result


## Moves every point by `offset`.
static func shifted(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = []
	for point: Vector2 in points:
		result.append(point + offset)
	return result


## Scales the points towards their average (used for the soft highlight on top of a piece).
static func shrunk(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var middle: Vector2 = Vector2.ZERO
	for point: Vector2 in points:
		middle += point
	middle /= maxf(points.size(), 1)
	var result: PackedVector2Array = []
	for point: Vector2 in points:
		result.append(middle + (point - middle) * factor)
	return result
