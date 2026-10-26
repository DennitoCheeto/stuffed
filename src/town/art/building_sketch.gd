class_name BuildingSketch
extends RefCounted
## The building art kit (spec 05 §2.2, S3 "Stitched toy box" with clean borders). A look is a
## list of chunky felt pieces in 3/4 view, given in design units around the building's bottom
## middle (y up is negative). `draw` paints it in four passes: a contact shadow on the floor, one
## even ink outline around the whole silhouette (every piece's ink is drawn first, so the fills
## cover it everywhere except at the outer edge), the felt fills with their drawn-in materials
## (planks, nails, glass shine, ...), then light stitched seams a few px inside the pieces.
## A look is built once per building and level (`BuildingLooks` keeps it) and baked into one mesh,
## so a building is one draw call. A ruin's look is greyed a little (`greyed`).

## What the look shows, one name per visible piece (each level adds at least one, AC-60).
var parts: Array[StringName] = []
## True for a ruin: every colour is greyed and dimmed a little.
var greyed: bool = false

var _unit: float = 1.0
var _palette: WorldPalette = WorldPalette.current()
## Where the next pieces go (`turn`): ruins tip their pieces over.
var _turn: Transform2D = Transform2D.IDENTITY
var _shadows: Array[PackedVector2Array] = []
var _ink: Array[PackedVector2Array] = []
## Felt fills and detail strokes in drawing order; a width of 0 is a filled shape.
var _mark_points: Array[PackedVector2Array] = []
var _mark_colors: Array[Color] = []
var _mark_widths: PackedFloat32Array = []
## Stitch dashes: pairs of points (start, end).
var _seams: PackedVector2Array = []
## Shapes that could not be filled (crossing edges): tests keep this at zero.
var _broken: PackedStringArray = []
var _mesh: ArrayMesh
## The mesh being baked: triangle corners and their colours.
var _bake_points: PackedVector2Array = []
var _bake_colors: PackedColorArray = []


## `unit` = world pixels per design unit; `is_ruin` greys every colour a little.
func _init(unit: float = 1.0, is_ruin: bool = false) -> void:
	_unit = unit
	greyed = is_ruin


## Pieces added from now on are turned by `angle` around `pivot`, then moved by `shift`.
func turn(angle: float, pivot: Vector2 = Vector2.ZERO, shift: Vector2 = Vector2.ZERO) -> void:
	var to_pivot: Transform2D = Transform2D(0.0, -pivot * _unit)
	var back: Transform2D = Transform2D(angle, (pivot + shift) * _unit)
	_turn = back * to_pivot


func straighten() -> void:
	_turn = Transform2D.IDENTITY


## A felt piece with the ink outline; `sewn` adds a stitched line just inside its edge.
func piece(part: StringName, points: PackedVector2Array, color: Color, sewn: bool = false) -> void:
	var shape: PackedVector2Array = _place(points)
	_name(part)
	_add_ink(Geometry2D.offset_polygon(shape, _palette.building_outline))
	_add_fill(shape, color)
	if sewn:
		for inner: PackedVector2Array in Geometry2D.offset_polygon(shape, -_palette.seam_inset):
			_add_dashes(inner, true)


## A felt piece made from a rectangle.
func block(part: StringName, rect: Rect2, color: Color, sewn: bool = false) -> void:
	piece(part, corners(rect), color, sewn)


## A round felt piece (a ball, a button, a bulb).
func disc(part: StringName, center: Vector2, radius: float, color: Color) -> void:
	piece(part, FeltDraw.circle(center, radius, 20), color)


## A thick stroke with the ink outline (poles, pencils, ribbons, blades).
func rod(part: StringName, points: PackedVector2Array, color: Color, width: float) -> void:
	var path: PackedVector2Array = _place(points)
	var half: float = width * _unit / 2.0
	var outline: float = half + _palette.building_outline
	_name(part)
	var join: Geometry2D.PolyJoinType = Geometry2D.JOIN_ROUND
	var ends: Geometry2D.PolyEndType = Geometry2D.END_ROUND
	_add_ink(Geometry2D.offset_polyline(path, outline, join, ends))
	for shape: PackedVector2Array in Geometry2D.offset_polyline(path, half, join, ends):
		_add_fill(shape, color)


## A fill inside a piece without its own outline (a side face, a shadow, a highlight).
func shade(points: PackedVector2Array, color: Color) -> void:
	_add_fill(_place(points), color)


## A small round fill without an outline (nail heads, button holes).
func dot(center: Vector2, radius: float, color: Color) -> void:
	shade(FeltDraw.circle(center, radius, 12), color)


## A drawn-in material line (plank gaps, wood grain, cracks), no outline. Keep it open: a closed
## line (last point = first) is baked as a filled shape.
func line(points: PackedVector2Array, color: Color, width: float = 2.0) -> void:
	_mark_points.append(_place(points))
	_mark_colors.append(_tint(color))
	_mark_widths.append(width * _unit)


## Stripes of `color` across `points` (gingham, painted bands): every `spacing` units, `width` wide.
func stripes(
	points: PackedVector2Array, color: Color, spacing: float, width: float, upright: bool
) -> void:
	var area: Rect2 = bounds_of(points)
	var at: float = area.position.x if upright else area.position.y
	var end: float = area.end.x if upright else area.end.y
	while at < end:
		var band: Rect2 = Rect2(at, area.position.y, width, area.size.y)
		if not upright:
			band = Rect2(area.position.x, at, area.size.x, width)
		for cut: PackedVector2Array in Geometry2D.intersect_polygons(corners(band), points):
			shade(cut, color)
		at += spacing


## A stitched seam along `points` (closed = all the way round).
func seam(points: PackedVector2Array, closed: bool = false) -> void:
	_add_dashes(_place(points), closed)


## The soft contact shadow on the floor (light from the top-left: it falls to the right).
func shadow(points: PackedVector2Array) -> void:
	_shadows.append(_place(points))


func draw(canvas: CanvasItem) -> void:
	canvas.draw_mesh(baked(), null)


## The finished look as one mesh of coloured triangles (built the first time it is needed), so a
## building costs one draw call however many pieces it has.
func baked() -> ArrayMesh:
	if _mesh == null:
		_mesh = _bake()
	return _mesh


## Every colour the look paints with (tests: none of them is a danger colour).
func colors() -> Array[Color]:
	var result: Array[Color] = [_palette.ink, _palette.shadow, _tint(_palette.seam_light)]
	result.append_array(_mark_colors)
	return result


## The area the outlined silhouette covers, in world pixels around the bottom middle.
func bounds() -> Rect2:
	var all: PackedVector2Array = []
	for shape: PackedVector2Array in _ink:
		all.append_array(shape)
	return bounds_of(all)


## Shapes that were left out because they could not be filled (should be none).
func broken_shapes() -> PackedStringArray:
	return _broken


func ink_count() -> int:
	return _ink.size()


func seam_count() -> int:
	return _seams.size() / 2


## The four corners of `rect`, clockwise from the top-left.
static func corners(rect: Rect2) -> PackedVector2Array:
	var top_right: Vector2 = Vector2(rect.end.x, rect.position.y)
	return [rect.position, top_right, rect.end, Vector2(rect.position.x, rect.end.y)]


## A five-pointed star around `center` (sparkles, painted stars).
static func star(center: Vector2, r: float) -> PackedVector2Array:
	var points: PackedVector2Array = []
	for i: int in 10:
		var radius: float = r if i % 2 == 0 else r * 0.45
		points.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * radius)
	return points


static func bounds_of(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var area: Rect2 = Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		area = area.expand(point)
	return area


func _place(points: PackedVector2Array) -> PackedVector2Array:
	var placed: PackedVector2Array = []
	for point: Vector2 in points:
		placed.append(_turn * (point * _unit))
	return placed


func _name(part: StringName) -> void:
	if part != &"" and not parts.has(part):
		parts.append(part)


func _add_ink(shapes: Array[PackedVector2Array]) -> void:
	for shape: PackedVector2Array in shapes:
		if shape.size() >= 3 and not Geometry2D.triangulate_polygon(shape).is_empty():
			_ink.append(shape)


func _add_fill(shape: PackedVector2Array, color: Color) -> void:
	if shape.size() < 3 or Geometry2D.triangulate_polygon(shape).is_empty():
		_broken.append(str(shape))
		return
	_mark_points.append(shape)
	_mark_colors.append(_tint(color))
	_mark_widths.append(0.0)


func _add_dashes(path: PackedVector2Array, closed: bool) -> void:
	var points: PackedVector2Array = path.duplicate()
	if closed and points.size() > 2:
		points.append(points[0])
	var dash: float = _palette.seam_dash
	var period: float = dash + _palette.seam_gap
	var walked: float = 0.0
	for i: int in range(1, points.size()):
		var from: Vector2 = points[i - 1]
		var to: Vector2 = points[i]
		var length: float = from.distance_to(to)
		var along: float = 0.0
		while along < length:
			var phase: float = fmod(walked, period)
			var left: float = (dash - phase) if phase < dash else (period - phase)
			var step: float = minf(left, length - along)
			if phase < dash:
				_seams.append(from.lerp(to, along / length))
				_seams.append(from.lerp(to, (along + step) / length))
			along += step
			walked += step


## A ruin's colours: part of the way to grey, and a little darker.
func _tint(color: Color) -> Color:
	if not greyed:
		return color
	var grey: float = color.get_luminance()
	var faded: Color = color.lerp(Color(grey, grey, grey, color.a), _palette.ruin_grey)
	return faded.darkened(_palette.ruin_dim)


func _bake() -> ArrayMesh:
	_bake_points = PackedVector2Array()
	_bake_colors = PackedColorArray()
	for shape: PackedVector2Array in _shadows:
		_bake_fill(shape, _palette.shadow)
	for shape: PackedVector2Array in _ink:
		_bake_fill(shape, _palette.ink)
	for i: int in _mark_points.size():
		if _mark_widths[i] > 0.0:
			_bake_stroke(_mark_points[i], _mark_colors[i], _mark_widths[i])
		else:
			_bake_fill(_mark_points[i], _mark_colors[i])
	var thread: Color = _tint(_palette.seam_light)
	for i: int in range(0, _seams.size(), 2):
		var dash: PackedVector2Array = [_seams[i], _seams[i + 1]]
		_bake_stroke(dash, thread, _palette.seam_width)
	var mesh: ArrayMesh = ArrayMesh.new()
	if _bake_points.is_empty():
		return mesh
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _bake_points
	arrays[Mesh.ARRAY_COLOR] = _bake_colors
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## A line as filled shapes with round ends.
func _bake_stroke(path: PackedVector2Array, color: Color, width: float) -> void:
	var join: Geometry2D.PolyJoinType = Geometry2D.JOIN_ROUND
	var ends: Geometry2D.PolyEndType = Geometry2D.END_ROUND
	for shape: PackedVector2Array in Geometry2D.offset_polyline(path, width / 2.0, join, ends):
		_bake_fill(shape, color)


## A filled shape plus a thin ring fading out around it (soft felt edges, like `FeltDraw.fill`).
func _bake_fill(shape: PackedVector2Array, color: Color) -> void:
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(shape)
	for index: int in indices:
		_bake_points.append(shape[index])
		_bake_colors.append(color)
	if indices.is_empty():
		return
	var outer: PackedVector2Array = FeltDraw.feathered(shape, FeltDraw.FEATHER)
	var clear: Color = Color(color, 0.0)
	var count: int = shape.size()
	for i: int in count:
		var next: int = (i + 1) % count
		var ring: PackedVector2Array = [shape[i], outer[i], shape[next], shape[next], outer[i]]
		ring.append(outer[next])
		_bake_points.append_array(ring)
		_bake_colors.append_array([color, clear, color, color, clear, clear])
