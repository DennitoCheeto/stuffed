class_name FeltPiece
extends Node2D
## One cut-out felt piece of a plushie: soft filled shapes with a darker underside, a light
## top-left highlight, optional outline, stitched seams and drawn lines. A piece without shapes
## is just a joint that groups other pieces.

## This piece's pivot in the art concept's coordinates; the node sits there.
var pivot: Vector2 = Vector2.ZERO
## Main outline, relative to the pivot.
var polygon: PackedVector2Array = []
var color: Color = Color.WHITE
## Optional stitched seam (open line), relative to the pivot.
var seam: PackedVector2Array = []
var seam_color: Color = Color.BLACK
## Soft pieces get the volume shading; flat ones (eyes, shadows) don't.
var soft: bool = true
## Dark edge around every shape, in concept units (0 = none). Makes enemies stand out.
var outline_width: float = 0.0
var outline_color: Color = Color("#1d1a24")

var _layers: Array[PackedVector2Array] = []
var _layer_colors: PackedColorArray = []
var _lines: Array[PackedVector2Array] = []
var _line_colors: PackedColorArray = []
var _line_widths: PackedFloat32Array = []


## Adds a child piece at concept point `child_pivot`, with an outline in concept coordinates.
func add_piece(
	child_pivot: Vector2, outline: PackedVector2Array, fill: Color, is_soft: bool = true
) -> FeltPiece:
	var piece: FeltPiece = add_joint(child_pivot)
	piece.polygon = FeltShapes.shifted(outline, -child_pivot)
	piece.color = fill
	piece.soft = is_soft
	return piece


## Adds an empty child piece (a joint other pieces hang from) at concept point `child_pivot`.
func add_joint(child_pivot: Vector2) -> FeltPiece:
	var piece: FeltPiece = FeltPiece.new()
	piece.pivot = child_pivot
	piece.position = child_pivot - pivot
	piece.use_parent_material = true
	add_child(piece)
	return piece


## Sets the seam from a line in concept coordinates.
func set_seam(line: PackedVector2Array, stitch_color: Color) -> void:
	seam = FeltShapes.shifted(line, -pivot)
	seam_color = stitch_color
	queue_redraw()


## Another shape drawn on top of the main one (same shading), in concept coordinates.
func add_layer(outline: PackedVector2Array, fill: Color) -> void:
	_layers.append(FeltShapes.shifted(outline, -pivot))
	_layer_colors.append(fill)
	queue_redraw()


## A solid line drawn on top of all shapes (stitches, cracks, X eyes), in concept coordinates.
func add_line(points: PackedVector2Array, line_color: Color, width: float) -> void:
	_lines.append(FeltShapes.shifted(points, -pivot))
	_line_colors.append(line_color)
	_line_widths.append(width)
	queue_redraw()


## Everything this piece draws, relative to its pivot (with room for outline and shading).
func bounds() -> Rect2:
	var all_points: PackedVector2Array = polygon.duplicate()
	for layer: PackedVector2Array in _layers:
		all_points.append_array(layer)
	for line: PackedVector2Array in _lines:
		all_points.append_array(line)
	all_points.append_array(seam)
	if all_points.is_empty():
		return Rect2()
	var box: Rect2 = Rect2(all_points[0], Vector2.ZERO)
	for point: Vector2 in all_points:
		box = box.expand(point)
	return box.grow(outline_width + 6.0)


func _draw() -> void:
	if outline_width > 0.0:
		_draw_outline(polygon)
		for layer: PackedVector2Array in _layers:
			_draw_outline(layer)
	_draw_shape(polygon, color)
	for i: int in _layers.size():
		_draw_shape(_layers[i], _layer_colors[i])
	_draw_seam()
	for i: int in _lines.size():
		draw_polyline(_lines[i], _line_colors[i], _line_widths[i])


func _draw_outline(shape: PackedVector2Array) -> void:
	if shape.size() < 3:
		return
	for grown: PackedVector2Array in Geometry2D.offset_polygon(shape, outline_width):
		draw_colored_polygon(grown, outline_color)


func _draw_shape(shape: PackedVector2Array, fill: Color) -> void:
	if shape.size() < 3:
		return
	if soft:
		draw_colored_polygon(FeltShapes.shifted(shape, Vector2(1.5, 3.0)), fill.darkened(0.4))
	draw_colored_polygon(shape, fill)
	if soft:
		var light: Color = fill.lightened(0.3)
		light.a = 0.35
		var highlight: PackedVector2Array = FeltShapes.shrunk(shape, 0.72)
		draw_colored_polygon(FeltShapes.shifted(highlight, Vector2(-3.0, -4.0)), light)


func _draw_seam() -> void:
	if seam.size() < 2:
		return
	draw_polyline(FeltShapes.shifted(seam, Vector2(0.0, 1.5)), Color(0.0, 0.0, 0.0, 0.18), 5.0)
	for i: int in seam.size() - 1:
		draw_dashed_line(seam[i], seam[i + 1], seam_color, 2.0, 5.0)
