class_name Obstacles
extends RefCounted
## The furniture that blocks movement, as rectangles on the floor. Answers the questions zombies
## and enemy bullets ask: am I inside furniture, push me out of it, and which way do I walk to
## get around it (sliding along its side instead of getting stuck).

## A circle this close to furniture counts as touching it.
const TOUCH_MARGIN: float = 2.0
## A walker keeps its way round a piece until it is this far away from all furniture.
const RELEASE_MARGIN: float = 32.0
## A walk this much along the side (0..1) keeps its direction; less is "head-on".
const SLIDE_ALONG: float = 0.7

var rects: Array[Rect2] = []


func _init(blocking: Array[Rect2] = []) -> void:
	rects = blocking


func is_empty() -> bool:
	return rects.is_empty()


## True if a circle of `radius` at `point` overlaps any furniture.
func blocks(point: Vector2, radius: float = 0.0) -> bool:
	for rect: Rect2 in rects:
		if _overlaps(rect, point, radius):
			return true
	return false


## `point` moved the shortest way out of every piece of furniture a circle of `radius` overlaps.
func push_out(point: Vector2, radius: float) -> Vector2:
	var result: Vector2 = point
	for rect: Rect2 in rects:
		if _overlaps(rect, result, radius):
			result = _surface_point(rect, result) + _normal(rect, result) * radius
	return result


## Where a circle of `radius` at `point` should walk instead of `walk` (a velocity): unchanged
## when nothing is in the way, else along the side of the furniture it touches. `detour` is the
## way round it already chose (1 or -1, 0 = none yet). Returns [velocity, detour]: walking
## around a piece always goes the same way round, so it never turns back and gets stuck.
func steer(point: Vector2, radius: float, walk: Vector2, detour: int) -> Array:
	var near: bool = false
	for rect: Rect2 in rects:
		if not _overlaps(rect, point, radius + RELEASE_MARGIN):
			continue
		near = true
		if walk == Vector2.ZERO or not _overlaps(rect, point, radius + TOUCH_MARGIN):
			continue
		var normal: Vector2 = _normal(rect, point)
		if walk.dot(normal) >= 0.0:
			continue
		var side: Vector2 = normal.orthogonal()
		if detour == 0:
			detour = _pick_way_round(rect, point, walk, side)
		return [side * float(detour) * walk.length(), detour]
	return [walk, detour if near else 0]


## Walking mostly along the side: keep going that way. Walking into it head-on: go to the nearer
## end (a crowd splits up around the piece instead of jamming in the middle).
func _pick_way_round(rect: Rect2, point: Vector2, walk: Vector2, side: Vector2) -> int:
	var along: float = walk.normalized().dot(side)
	if absf(along) < SLIDE_ALONG:
		along = (point - rect.get_center()).dot(side)
	return -1 if along < 0.0 else 1


func _overlaps(rect: Rect2, point: Vector2, radius: float) -> bool:
	if radius <= 0.0:
		return rect.has_point(point)
	if not rect.grow(radius).has_point(point):
		return false
	if rect.has_point(point):
		return true
	return point.clamp(rect.position, rect.end).distance_squared_to(point) < radius * radius


## The point on the furniture's outline closest to `point` (inside or outside).
func _surface_point(rect: Rect2, point: Vector2) -> Vector2:
	var closest: Vector2 = point.clamp(rect.position, rect.end)
	if closest != point:
		return closest
	var normal: Vector2 = _normal(rect, point)
	if normal.x < 0.0:
		closest.x = rect.position.x
	elif normal.x > 0.0:
		closest.x = rect.end.x
	elif normal.y < 0.0:
		closest.y = rect.position.y
	else:
		closest.y = rect.end.y
	return closest


## The direction from the furniture towards `point` (out of its nearest side when inside).
func _normal(rect: Rect2, point: Vector2) -> Vector2:
	var offset: Vector2 = point - point.clamp(rect.position, rect.end)
	if offset.length_squared() > 0.0001:
		return offset.normalized()
	var to_left: float = point.x - rect.position.x
	var to_right: float = rect.end.x - point.x
	var to_top: float = point.y - rect.position.y
	var to_bottom: float = rect.end.y - point.y
	var nearest: float = minf(minf(to_left, to_right), minf(to_top, to_bottom))
	if nearest == to_left:
		return Vector2.LEFT
	if nearest == to_right:
		return Vector2.RIGHT
	if nearest == to_top:
		return Vector2.UP
	return Vector2.DOWN
