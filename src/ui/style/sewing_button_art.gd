class_name SewingButtonArt
extends RefCounted
## Draws a little round sewing button (four holes, crossed thread): slider knobs, switch knobs
## and the decoration on the menu cloth.


## Draws the button on `item` at `center` with `radius` in `color` (`alpha` = see-through).
static func draw(
	item: CanvasItem, center: Vector2, radius: float, color: Color, alpha: float = 1.0
) -> void:
	var shadow: Color = Color(UiColors.SHADOW, UiColors.SHADOW.a * alpha)
	var low: Vector2 = center + Vector2(0, radius * 0.18)
	FeltDraw.fill(item, FeltDraw.circle(low, radius), shadow)
	var rim: Color = Color(color.darkened(0.3), alpha)
	FeltDraw.fill(item, FeltDraw.circle(center, radius), rim)
	FeltDraw.fill(item, FeltDraw.circle(center, radius * 0.82), Color(color, alpha))
	var ring: Color = Color(color.darkened(0.12), alpha)
	item.draw_arc(center, radius * 0.62, 0.0, TAU, 24, ring, 1.5, true)
	var hole: float = radius * 0.13
	var gap: float = radius * 0.24
	var holes: Array[Vector2] = [
		center + Vector2(-gap, -gap),
		center + Vector2(gap, -gap),
		center + Vector2(gap, gap),
		center + Vector2(-gap, gap),
	]
	var thread: Color = Color(UiColors.THREAD.darkened(0.2), alpha)
	item.draw_line(holes[0], holes[2], thread, maxf(radius * 0.09, 1.5), true)
	item.draw_line(holes[1], holes[3], thread, maxf(radius * 0.09, 1.5), true)
	for spot: Vector2 in holes:
		FeltDraw.fill(item, FeltDraw.circle(spot, hole), rim)
