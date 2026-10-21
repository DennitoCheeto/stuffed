class_name Arena
extends Node2D
## The bedroom floor the run happens on: a felt carpet with a simple pattern (so movement is
## readable) bounded by toy-block walls. Walls are built in code from `size`.

const WALL_LAYER: int = 1
const FLOOR_COLOR: Color = Color("#2b2733")
const FLOOR_TILE_COLOR: Color = Color("#302b39")
const FLOOR_STITCH_COLOR: Color = Color(1.0, 1.0, 1.0, 0.05)
const BLOCK_COLORS: Array[Color] = [
	Color("#8f4a46"), Color("#46648f"), Color("#a0843f"), Color("#4f7d55")
]
const BLOCK_INNER_COLOR: Color = Color(1.0, 1.0, 1.0, 0.1)

## Size of the walkable floor in pixels (about 4 x 4 screens).
@export var size: Vector2 = Vector2(7680.0, 4320.0)
## Thickness of the toy-block walls around the floor.
@export var wall_thickness: float = 96.0
## Side length of one carpet pattern tile.
@export var tile_size: float = 192.0


func _ready() -> void:
	_build_walls()


## The walkable floor, in arena coordinates.
func play_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## The floor plus the walls: the camera never shows anything outside this.
func outer_rect() -> Rect2:
	return play_rect().grow(wall_thickness)


func center() -> Vector2:
	return size / 2.0


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
	draw_rect(play_rect(), FLOOR_COLOR)
	_draw_carpet_pattern()
	_draw_blocks()


func _draw_carpet_pattern() -> void:
	var columns: int = ceili(size.x / tile_size)
	var rows: int = ceili(size.y / tile_size)
	for row: int in rows:
		for column: int in columns:
			if (row + column) % 2 == 0:
				continue
			var tile: Rect2 = Rect2(Vector2(column, row) * tile_size, Vector2.ONE * tile_size)
			draw_rect(tile.intersection(play_rect()), FLOOR_TILE_COLOR)
	for column: int in range(1, columns):
		var x: float = column * tile_size
		draw_dashed_line(Vector2(x, 0.0), Vector2(x, size.y), FLOOR_STITCH_COLOR, 2.0, 10.0)
	for row: int in range(1, rows):
		var y: float = row * tile_size
		draw_dashed_line(Vector2(0.0, y), Vector2(size.x, y), FLOOR_STITCH_COLOR, 2.0, 10.0)


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
	draw_rect(block.grow(-2.0), BLOCK_COLORS[index % BLOCK_COLORS.size()])
	draw_rect(block.grow(-t * 0.25), BLOCK_INNER_COLOR, false, 3.0)
