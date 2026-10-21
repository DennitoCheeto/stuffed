class_name SpawnPlacement
extends RefCounted
## Picks where a new zombie appears: just outside the visible screen, but inside the arena.


## A random point on the ring `margin` pixels outside `view`, inside `area` (shrunk by `edge`).
## Returns Vector2.INF if there is no room (the caller skips this spawn).
static func outside_view(
	view: Rect2, area: Rect2, margin: float, edge: float, rng: RandomNumberGenerator
) -> Vector2:
	var ring: Rect2 = view.grow(margin)
	var inside: Rect2 = area.grow(-edge)
	for attempt: int in 12:
		var point: Vector2 = _point_on_border(ring, rng)
		if inside.has_point(point):
			return point
	return Vector2.INF


static func _point_on_border(rect: Rect2, rng: RandomNumberGenerator) -> Vector2:
	var perimeter: float = 2.0 * (rect.size.x + rect.size.y)
	var along: float = rng.randf() * perimeter
	if along < rect.size.x:
		return rect.position + Vector2(along, 0.0)
	along -= rect.size.x
	if along < rect.size.x:
		return Vector2(rect.position.x + along, rect.end.y)
	along -= rect.size.x
	if along < rect.size.y:
		return rect.position + Vector2(0.0, along)
	along -= rect.size.y
	return Vector2(rect.end.x, rect.position.y + along)
