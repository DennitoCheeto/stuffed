class_name FeltDraw
extends RefCounted
## Shape helpers for the felt UI pieces: rounded outlines, stitch dashes and tape strips.

const CORNER_STEPS: int = 6


## The outline of `rect` with round corners, clockwise from the top-left arc.
static func rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	if rect.size.x < 1.0 or rect.size.y < 1.0:
		return PackedVector2Array()
	var r: float = clampf(radius, 0.0, minf(rect.size.x, rect.size.y) / 2.0)
	var points: PackedVector2Array = []
	var corners: Array[Vector2] = [
		rect.position + Vector2(r, r),
		Vector2(rect.end.x - r, rect.position.y + r),
		rect.end - Vector2(r, r),
		Vector2(rect.position.x + r, rect.end.y - r),
	]
	for index: int in corners.size():
		var start: float = PI + index * PI / 2.0
		for step: int in CORNER_STEPS + 1:
			var angle: float = start + step * (PI / 2.0) / CORNER_STEPS
			var point: Vector2 = corners[index] + Vector2(cos(angle), sin(angle)) * r
			if points.is_empty() or not points[-1].is_equal_approx(point):
				points.append(point)
	if points.size() > 1 and points[0].is_equal_approx(points[-1]):
		points.remove_at(points.size() - 1)
	return points


## Stitch dashes along the closed outline `path`: pairs of points (start, end) for a multiline.
static func dashes(path: PackedVector2Array, dash: float, gap: float) -> PackedVector2Array:
	var result: PackedVector2Array = []
	if path.size() < 2 or dash <= 0.0:
		return result
	var closed: PackedVector2Array = path.duplicate()
	closed.append(path[0])
	var period: float = dash + gap
	var walked: float = 0.0
	var dash_start: Vector2 = closed[0]
	var drawing: bool = true
	for index: int in range(1, closed.size()):
		var from: Vector2 = closed[index - 1]
		var to: Vector2 = closed[index]
		var length: float = from.distance_to(to)
		var along: float = 0.0
		while along < length:
			var phase: float = fmod(walked, period)
			var left: float = (dash - phase) if drawing else (period - phase)
			var step: float = minf(left, length - along)
			along += step
			walked += step
			if step >= left - 0.0001:
				var point: Vector2 = from.lerp(to, along / length)
				if drawing:
					result.append(dash_start)
					result.append(point)
				else:
					dash_start = point
				drawing = not drawing
	return result


## A washi-tape strip centred on `center`: a slightly zig-zagged rectangle, turned by `angle`.
static func tape(center: Vector2, length: float, width: float, angle: float) -> PackedVector2Array:
	var half: Vector2 = Vector2(length, width) / 2.0
	var local: PackedVector2Array = [Vector2(-half.x, -half.y), Vector2(half.x, -half.y)]
	var teeth: int = 4
	for tooth: int in range(1, teeth):
		var y: float = -half.y + width * tooth / teeth
		var x: float = half.x - (3.0 if tooth % 2 == 1 else 0.0)
		local.append(Vector2(x, y))
	local.append(Vector2(half.x, half.y))
	local.append(Vector2(-half.x, half.y))
	for tooth: int in range(teeth - 1, 0, -1):
		var y: float = -half.y + width * tooth / teeth
		var x: float = -half.x + (3.0 if tooth % 2 == 1 else 0.0)
		local.append(Vector2(x, y))
	var turned: PackedVector2Array = []
	for point: Vector2 in local:
		turned.append(center + point.rotated(angle))
	return turned
