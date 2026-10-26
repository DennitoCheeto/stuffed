class_name FeltDraw
extends RefCounted
## Shape helpers for the felt UI pieces: rounded outlines, stitch dashes and tape strips.

const CORNER_STEPS: int = 6
## Width of the soft fade around filled shapes (px).
const FEATHER: float = 1.2


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


## Fills `points` on the canvas item `item` with soft edges: the plain fill plus a thin ring that
## fades from `color` to see-through outside the edge (like Godot's anti-aliased style boxes), so
## felt shapes don't look jagged.
## `feather` is the ring width in the item's own units (wider when the item is drawn scaled down).
static func fill_smooth(
	item: RID, points: PackedVector2Array, color: Color, feather: float = FEATHER
) -> void:
	if points.size() < 3:
		return
	var colors: PackedColorArray = [color]
	RenderingServer.canvas_item_add_polygon(item, points, colors)
	var outer: PackedVector2Array = feathered(points, feather)
	var ring: PackedVector2Array = []
	var ring_colors: PackedColorArray = []
	var clear: Color = Color(color, 0.0)
	for index: int in points.size():
		ring.append(points[index])
		ring.append(outer[index])
		ring_colors.append(color)
		ring_colors.append(clear)
	var indices: PackedInt32Array = []
	var count: int = points.size()
	for index: int in count:
		var a: int = index * 2
		var b: int = ((index + 1) % count) * 2
		indices.append_array([a, a + 1, b, b, a + 1, b + 1])
	var no_uvs: PackedVector2Array = PackedVector2Array()
	RenderingServer.canvas_item_add_triangle_array(item, indices, ring, ring_colors, no_uvs)


## The same as `fill_smooth`, on a CanvasItem (for `_draw`).
static func fill(canvas: CanvasItem, points: PackedVector2Array, color: Color) -> void:
	fill_smooth(canvas.get_canvas_item(), points, color)


## Each point of the closed outline `points` moved `width` px outwards.
static func feathered(points: PackedVector2Array, width: float) -> PackedVector2Array:
	var count: int = points.size()
	var area: float = 0.0
	for index: int in count:
		area += points[index].cross(points[(index + 1) % count])
	var side: float = 1.0 if area > 0.0 else -1.0
	var result: PackedVector2Array = []
	for index: int in count:
		var before: Vector2 = points[(index - 1 + count) % count]
		var here: Vector2 = points[index]
		var after: Vector2 = points[(index + 1) % count]
		var normal_in: Vector2 = (here - before).normalized().orthogonal()
		var normal_out: Vector2 = (after - here).normalized().orthogonal()
		var normal: Vector2 = (normal_in + normal_out).normalized()
		if normal == Vector2.ZERO:
			normal = normal_out
		result.append(here + normal * width * side)
	return result


## A circle outline (for round felt shapes drawn with `fill`).
static func circle(center: Vector2, radius: float, steps: int = 32) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for step: int in steps:
		points.append(center + Vector2.from_angle(TAU * step / steps) * radius)
	return points
