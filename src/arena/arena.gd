class_name Arena
extends Node2D
## The bedroom floor the run happens on: warm floorboards with a simple pattern (so movement is
## readable) bounded by toy-block walls, with hand-placed furniture (spec 02 §10). Walls and
## furniture bodies are built in code. Furniture blocks players (physics), zombies and enemy
## bullets (through `obstacles`); the players' shots fly over it. All colours come from the
## world palette (spec 05 §2.1); the whole room has the felt grain.

const WALL_LAYER: int = 1
const SHADOW_OFFSET: Vector2 = Vector2(10.0, 16.0)
## How see-through the light marks on toy blocks are.
const BLOCK_INNER_ALPHA: float = 0.35

## Size of the walkable floor in pixels (about 4 x 4 screens).
@export var size: Vector2 = Vector2(7680.0, 4320.0)
## Thickness of the toy-block walls around the floor.
@export var wall_thickness: float = 96.0
## Side length of one carpet pattern tile.
@export var tile_size: float = 192.0
## The furniture of this room (none = an open floor).
@export var furniture: FurnitureLayout

var palette: WorldPalette = WorldPalette.current()


func _ready() -> void:
	material = palette.grain_material()
	_build_walls()
	for rect: Rect2 in _blocking_rects():
		_add_wall(rect)


## The walkable floor, in arena coordinates.
func play_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## The floor plus the walls: the camera never shows anything outside this.
func outer_rect() -> Rect2:
	return play_rect().grow(wall_thickness)


func center() -> Vector2:
	return size / 2.0


## The furniture that blocks zombies and enemy bullets.
func obstacles() -> Obstacles:
	return Obstacles.new(_blocking_rects())


func _blocking_rects() -> Array[Rect2]:
	if furniture == null:
		return []
	return furniture.blocking_rects()


func _build_walls() -> void:
	var t: float = wall_thickness
	var outer: Rect2 = outer_rect()
	_add_wall(Rect2(outer.position, Vector2(outer.size.x, t)))
	_add_wall(Rect2(Vector2(outer.position.x, size.y), Vector2(outer.size.x, t)))
	_add_wall(Rect2(Vector2(-t, 0.0), Vector2(t, size.y)))
	_add_wall(Rect2(Vector2(size.x, 0.0), Vector2(t, size.y)))


func _add_wall(rect: Rect2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = WALL_LAYER
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	draw_rect(play_rect(), palette.board_colors[0])
	_draw_carpet_pattern()
	_draw_blocks()
	if furniture != null:
		for piece: FurniturePiece in furniture.pieces:
			_draw_piece(piece)


func _draw_carpet_pattern() -> void:
	var columns: int = ceili(size.x / tile_size)
	var rows: int = ceili(size.y / tile_size)
	for row: int in rows:
		for column: int in columns:
			if (row + column) % 2 == 0:
				continue
			var tile: Rect2 = Rect2(Vector2(column, row) * tile_size, Vector2.ONE * tile_size)
			draw_rect(tile.intersection(play_rect()), WorldPalette.pick(palette.board_colors, 1))
	var seam: Color = palette.board_seam
	for column: int in range(1, columns):
		var x: float = column * tile_size
		draw_dashed_line(Vector2(x, 0.0), Vector2(x, size.y), seam, 2.0, 10.0)
	for row: int in range(1, rows):
		var y: float = row * tile_size
		draw_dashed_line(Vector2(0.0, y), Vector2(size.x, y), seam, 2.0, 10.0)


func _draw_blocks() -> void:
	var outer: Rect2 = outer_rect()
	var t: float = wall_thickness
	var count_x: int = ceili(outer.size.x / t)
	var count_y: int = ceili(size.y / t)
	for i: int in count_x:
		var x: float = outer.position.x + i * t
		_draw_block(Vector2(x, outer.position.y), i)
		_draw_block(Vector2(x, size.y), i + 1)
	for i: int in count_y:
		var y: float = i * t
		_draw_block(Vector2(-t, y), i + 2)
		_draw_block(Vector2(size.x, y), i + 3)


func _draw_block(top_left: Vector2, index: int) -> void:
	var t: float = wall_thickness
	var block: Rect2 = Rect2(top_left, Vector2(t, t))
	draw_rect(block.grow(-2.0), WorldPalette.pick(palette.wall_blocks, index))
	draw_rect(block.grow(-t * 0.25), Color(palette.seam_light, BLOCK_INNER_ALPHA), false, 3.0)


func _draw_piece(piece: FurniturePiece) -> void:
	match piece.kind:
		FurniturePiece.Kind.RUG:
			_draw_rug(piece.rect)
		FurniturePiece.Kind.BED:
			_draw_bed(piece.rect)
		FurniturePiece.Kind.TOY_BOX:
			_draw_toy_box(piece.rect)
		FurniturePiece.Kind.BLOCK_TOWER:
			_draw_tower(piece.rect)


## A soft felt panel with rounded corners and a stitched edge.
func _draw_felt(rect: Rect2, color: Color, corner: float, stitched: bool = true) -> void:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(int(corner))
	box.anti_aliasing = true
	box.draw(get_canvas_item(), rect)
	if stitched:
		_draw_stitches(rect.grow(-maxf(corner * 0.4, 8.0)))


func _draw_stitches(rect: Rect2) -> void:
	var corners: PackedVector2Array = [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]
	for i: int in corners.size():
		var next: Vector2 = corners[(i + 1) % corners.size()]
		draw_dashed_line(corners[i], next, palette.seam_light, 3.0, 12.0)


func _draw_shadow(rect: Rect2, corner: float) -> void:
	_draw_felt(Rect2(rect.position + SHADOW_OFFSET, rect.size), palette.shadow, corner, false)


func _draw_rug(rect: Rect2) -> void:
	var corner: float = minf(rect.size.x, rect.size.y) * 0.5
	_draw_felt(rect, palette.rug_border, corner, false)
	_draw_felt(rect.grow(-48.0), WorldPalette.pick(palette.rug_patches, 0), corner - 48.0, false)
	_draw_felt(rect.grow(-110.0), WorldPalette.pick(palette.rug_patches, 2), corner - 110.0, false)


func _draw_bed(rect: Rect2) -> void:
	_draw_shadow(rect, 36.0)
	_draw_felt(rect, palette.bed_frame, 36.0)
	var inner: Rect2 = rect.grow(-36.0)
	var pillow_height: float = inner.size.y * 0.2
	var pillow: Rect2 = Rect2(inner.position, Vector2(inner.size.x, pillow_height)).grow(-14.0)
	_draw_felt(pillow, palette.bed_pillow, 40.0)
	var blanket: Rect2 = Rect2(
		inner.position + Vector2(0.0, pillow_height), inner.size - Vector2(0.0, pillow_height)
	)
	_draw_felt(blanket, palette.bed_blanket, 28.0)
	var fold: Rect2 = Rect2(blanket.position, Vector2(blanket.size.x, 70.0))
	_draw_felt(fold, palette.bed_fold, 28.0, false)


func _draw_toy_box(rect: Rect2) -> void:
	_draw_shadow(rect, 24.0)
	_draw_felt(rect, palette.toy_box, 24.0)
	var lid: Rect2 = Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.35))
	_draw_felt(lid.grow(-10.0), palette.toy_box_lid, 18.0, false)
	var band_width: float = 44.0
	var band_left: float = rect.get_center().x - band_width / 2.0
	var band: Rect2 = Rect2(band_left, rect.position.y + 6.0, band_width, rect.size.y - 12.0)
	_draw_felt(band, palette.toy_box_band, 10.0, false)


## Toy blocks stacked in a 2 x 2 tower, seen from above.
func _draw_tower(rect: Rect2) -> void:
	_draw_shadow(rect, 12.0)
	var half: Vector2 = rect.size / 2.0
	for i: int in 4:
		var cell: Rect2 = Rect2(rect.position + Vector2(i % 2, floorf(i / 2.0)) * half, half)
		var color: Color = WorldPalette.pick(palette.tower_blocks, i + int(rect.position.x))
		_draw_felt(cell.grow(-3.0), color, 10.0, false)
		var inner: Color = Color(palette.seam_light, BLOCK_INNER_ALPHA)
		draw_rect(cell.grow(-half.x * 0.25), inner, false, 3.0)
