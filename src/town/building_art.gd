class_name BuildingArt
extends RefCounted
## Felt drawings of the rebuilt town buildings (spec 03 §5, §6), one look per level: level 1 is a
## small cozy house with the building's sign picture, level 2 is bigger with a side room and
## windows, level 3 is full size with a flag and string lights. Calm colours only (no red/orange).

## Share of the spot a level fills (width, height); it grows towards the full spot.
const LEVEL_SIZES: Array[Vector2] = [Vector2(0.7, 0.72), Vector2(0.85, 0.86), Vector2(1.0, 1.0)]
const DOOR_COLOR: Color = Color("#2a2336")
const WINDOW_COLOR: Color = Color("#f6e7b0")
const FRAME_COLOR: Color = Color("#f4efe6")
const POLE_COLOR: Color = Color("#8a7660")
const LIGHT_COLORS: Array[Color] = [Color("#f6e7b0"), Color("#cdb8ec"), Color("#a9dccf")]
const GOLD_COLOR: Color = Color("#e3bd55")
const TEAL_COLOR: Color = Color("#5fb3a8")
const LAVENDER_COLOR: Color = Color("#b49ad8")
const PINK_COLOR: Color = Color("#e7b3cf")
const GLASS_COLOR: Color = Color(0.8, 0.92, 1.0, 0.75)


## The part of `rect` the building fills at `level` (standing on the spot's bottom edge).
static func footprint(rect: Rect2, level: int) -> Rect2:
	var share: Vector2 = LEVEL_SIZES[clampi(level, 1, LEVEL_SIZES.size()) - 1]
	var size: Vector2 = rect.size * share
	var bottom: Vector2 = Vector2(rect.get_center().x, rect.end.y)
	return Rect2(bottom - Vector2(size.x / 2.0, size.y), size)


## Draws `building` at `level` (1-3) in spot `rect`, scaled by `pop` around its bottom middle.
static func draw(
	canvas: CanvasItem, building: BuildingDef, rect: Rect2, level: int, pop: float = 1.0
) -> void:
	var bottom: Vector2 = Vector2(rect.get_center().x, rect.end.y)
	canvas.draw_set_transform(bottom, 0.0, Vector2.ONE * pop)
	var box: Rect2 = footprint(rect, level)
	box.position -= bottom
	if building.id == &"watchtower":
		box = box.grow_individual(-box.size.x * 0.18, 0.0, -box.size.x * 0.18, 0.0)
	var wall_top: float = box.position.y + box.size.y * 0.38
	var wall: Rect2 = Rect2(box.position.x, wall_top, box.size.x, box.end.y - wall_top)
	if level >= 2:
		_draw_annex(canvas, building, box)
	TownArt.pillow(canvas, wall, building.wall_color)
	_draw_roof(canvas, building, box, wall_top)
	_draw_door(canvas, wall)
	if level >= 2:
		_draw_windows(canvas, wall)
	var badge: Vector2 = Vector2(wall.get_center().x, wall.position.y + wall.size.y * 0.3)
	_draw_badge(canvas, building.id, badge, minf(box.size.x, box.size.y) * 0.13)
	if level >= 3:
		_draw_lights(canvas, box, wall_top)
		_draw_flag(canvas, building, Vector2(box.get_center().x, box.position.y))
	canvas.draw_set_transform(Vector2.ZERO)


static func _draw_roof(canvas: CanvasItem, building: BuildingDef, box: Rect2, eave: float) -> void:
	var roof: PackedVector2Array = [
		Vector2(box.position.x - 10.0, eave + 14.0),
		Vector2(box.get_center().x, box.position.y),
		Vector2(box.end.x + 10.0, eave + 14.0),
	]
	canvas.draw_colored_polygon(roof, building.roof_color)
	var fold: Color = building.roof_color.darkened(0.15)
	for i: int in range(1, 4):
		var x: float = box.position.x + box.size.x * i / 4.0
		var peak: Vector2 = Vector2(box.get_center().x, box.position.y + 14.0)
		canvas.draw_line(peak, Vector2(x, eave + 10.0), fold, 4.0)
	if building.id == &"snack_bar":
		_draw_awning(canvas, building, box, eave)


## A striped snack-bar awning under the roof.
static func _draw_awning(
	canvas: CanvasItem, building: BuildingDef, box: Rect2, eave: float
) -> void:
	var stripes: int = 6
	var width: float = box.size.x / stripes
	for i: int in stripes:
		var color: Color = FRAME_COLOR if i % 2 == 0 else building.roof_color.lightened(0.2)
		var stripe: Rect2 = Rect2(box.position.x + i * width, eave + 12.0, width, 22.0)
		canvas.draw_rect(stripe, color)


static func _draw_door(canvas: CanvasItem, wall: Rect2) -> void:
	var size: Vector2 = Vector2(wall.size.x * 0.18, wall.size.y * 0.45)
	var door: Rect2 = Rect2(Vector2(wall.get_center().x - size.x / 2.0, wall.end.y - size.y), size)
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = DOOR_COLOR
	box.corner_radius_top_left = roundi(size.x / 2.0)
	box.corner_radius_top_right = roundi(size.x / 2.0)
	canvas.draw_style_box(box, door)


static func _draw_windows(canvas: CanvasItem, wall: Rect2) -> void:
	var side: float = wall.size.y * 0.24
	for x: float in [wall.size.x * 0.2, wall.size.x * 0.8]:
		var middle: Vector2 = Vector2(wall.position.x + x, wall.position.y + wall.size.y * 0.55)
		var pane: Rect2 = Rect2(middle - Vector2.ONE * side / 2.0, Vector2.ONE * side)
		canvas.draw_rect(pane.grow(4.0), FRAME_COLOR)
		canvas.draw_rect(pane, WINDOW_COLOR)
		var bar_top: Vector2 = Vector2(middle.x, pane.position.y)
		canvas.draw_line(bar_top, Vector2(middle.x, pane.end.y), FRAME_COLOR, 2.0)


## Level 2+: a little side room on the right with its own pillow.
static func _draw_annex(canvas: CanvasItem, building: BuildingDef, box: Rect2) -> void:
	var size: Vector2 = Vector2(box.size.x * 0.3, box.size.y * 0.42)
	var annex: Rect2 = Rect2(Vector2(box.end.x - size.x * 0.55, box.end.y - size.y), size)
	TownArt.pillow(canvas, annex, building.wall_color.darkened(0.1))
	var cap: Rect2 = Rect2(annex.position - Vector2(6.0, 14.0), Vector2(annex.size.x + 12.0, 26.0))
	TownArt.pillow(canvas, cap, building.roof_color.lightened(0.1), false)


## Level 3: soft string lights along the roof edge.
static func _draw_lights(canvas: CanvasItem, box: Rect2, eave: float) -> void:
	var left: Vector2 = Vector2(box.position.x - 6.0, eave + 16.0)
	var right: Vector2 = Vector2(box.end.x + 6.0, eave + 16.0)
	var sag: Vector2 = Vector2(0.0, 14.0)
	var points: PackedVector2Array = []
	for i: int in 9:
		var t: float = i / 8.0
		points.append(left.lerp(right, t) + sag * sin(t * PI))
	canvas.draw_polyline(points, POLE_COLOR, 2.0, true)
	for i: int in points.size():
		canvas.draw_circle(points[i] + Vector2(0, 5), 5.0, LIGHT_COLORS[i % LIGHT_COLORS.size()])


## Level 3: a felt pennant on the roof's top.
static func _draw_flag(canvas: CanvasItem, building: BuildingDef, peak: Vector2) -> void:
	var top: Vector2 = peak - Vector2(0.0, 46.0)
	canvas.draw_line(peak, top, POLE_COLOR, 4.0)
	var flag: PackedVector2Array = [top, top + Vector2(38.0, 10.0), top + Vector2(0.0, 22.0)]
	canvas.draw_colored_polygon(flag, building.wall_color.lightened(0.25))
	canvas.draw_circle(top, 4.0, GOLD_COLOR)


## The building's picture on its front wall, so you can tell them apart at a glance.
static func _draw_badge(canvas: CanvasItem, id: StringName, at: Vector2, r: float) -> void:
	canvas.draw_circle(at, r * 1.35, FRAME_COLOR)
	match id:
		&"toy_box_armory":
			_part(canvas, at, r, Rect2(-1.0, -0.3, 2.0, 1.2), LAVENDER_COLOR)
			_part(canvas, at, r, Rect2(-1.1, -0.6, 2.2, 0.35), TEAL_COLOR)
			canvas.draw_circle(at + Vector2(r * 0.4, -r * 0.85), r * 0.35, GOLD_COLOR)
		&"lucky_jar":
			_part(canvas, at, r, Rect2(-0.7, -0.6, 1.4, 1.5), GLASS_COLOR)
			_part(canvas, at, r, Rect2(-0.8, -0.95, 1.6, 0.35), GOLD_COLOR)
			canvas.draw_circle(at + Vector2(0.0, r * 0.35), r * 0.35, GOLD_COLOR)
		&"watchtower":
			canvas.draw_circle(at, r * 0.9, DOOR_COLOR)
			canvas.draw_circle(at, r * 0.55, WINDOW_COLOR)
		&"snack_bar":
			canvas.draw_circle(at, r * 0.9, PINK_COLOR)
			canvas.draw_circle(at, r * 0.35, FRAME_COLOR)
		&"party_shop":
			for i: int in 3:
				var balloon: Vector2 = at + Vector2((i - 1) * r * 0.7, -r * 0.2 - (i % 2) * r * 0.3)
				canvas.draw_line(balloon, at + Vector2(0, r), POLE_COLOR, 1.5)
				var colors: Array[Color] = [LAVENDER_COLOR, TEAL_COLOR, GOLD_COLOR]
				canvas.draw_circle(balloon, r * 0.42, colors[i])
		_:
			_part(canvas, at, r, Rect2(-0.25, -0.8, 0.5, 1.6), TEAL_COLOR)
			_part(canvas, at, r, Rect2(-0.8, -0.25, 1.6, 0.5), TEAL_COLOR)


## A rectangle of the badge, given in units of its radius `r` around `at`.
static func _part(canvas: CanvasItem, at: Vector2, r: float, unit: Rect2, color: Color) -> void:
	canvas.draw_rect(Rect2(at + unit.position * r, unit.size * r), color)
