class_name FeltPiece
extends Node2D
## One cut-out felt piece of a plushie: a soft filled shape with a darker underside, a light
## top-left highlight and an optional dashed seam. A piece without a polygon is just a joint
## that groups other pieces.

## This piece's pivot in the art concept's coordinates; the node sits there.
var pivot: Vector2 = Vector2.ZERO
## Outline, relative to the pivot.
var polygon: PackedVector2Array = []
var color: Color = Color.WHITE
## Optional stitched seam (open line), relative to the pivot.
var seam: PackedVector2Array = []
var seam_color: Color = Color.BLACK
## Soft pieces get the volume shading; flat ones (eyes, shadows) don't.
var soft: bool = true


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


func _draw() -> void:
	if polygon.size() < 3:
		return
	if soft:
		draw_colored_polygon(FeltShapes.shifted(polygon, Vector2(1.5, 3.0)), color.darkened(0.4))
	draw_colored_polygon(polygon, color)
	if soft:
		var light: Color = color.lightened(0.3)
		light.a = 0.35
		var highlight: PackedVector2Array = FeltShapes.shrunk(polygon, 0.72)
		draw_colored_polygon(FeltShapes.shifted(highlight, Vector2(-3.0, -4.0)), light)
	_draw_seam()


func _draw_seam() -> void:
	if seam.size() < 2:
		return
	draw_polyline(FeltShapes.shifted(seam, Vector2(0.0, 1.5)), Color(0.0, 0.0, 0.0, 0.18), 5.0)
	for i: int in seam.size() - 1:
		draw_dashed_line(seam[i], seam[i + 1], seam_color, 2.0, 5.0)
