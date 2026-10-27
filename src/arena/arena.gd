class_name Arena
extends Node2D
## The Bedroom the run happens on (spec 05 §4.1): honey floorboards, the patchwork rug in the
## middle where every run starts, toy-block walls and the top wall with two windows, sunbeams
## falling across the middle, plus hand-placed furniture in six places (spec 02 §10, spec 05
## §4.2). Floor, rug, walls, sunbeams and furniture are baked once (`BedroomLook`,
## `FurnitureLook`, a few meshes). Walls and furniture bodies are built in code. Furniture
## blocks players (physics), zombies and enemy bullets (through `obstacles`); the players' shots
## fly over it. All colours come from the world palette (spec 05 §2.1); the whole room has the
## felt grain.

const WALL_LAYER: int = 1
const ROOM: BedroomRoom = preload("res://data/arena/bedroom_room.tres")

## Size of the walkable floor in pixels (about 4 x 4 screens).
@export var size: Vector2 = Vector2(7680.0, 4320.0)
## Thickness of the toy-block walls around the floor.
@export var wall_thickness: float = 96.0
## The furniture of this room (none = an open floor).
@export var furniture: FurnitureLayout
## How the floor and the room look (boards, rug, top wall, sunbeams, vignette).
@export var room: BedroomRoom = ROOM

var palette: WorldPalette = WorldPalette.current()


func _ready() -> void:
	material = palette.grain_material()
	_build_walls()
	for rect: Rect2 in _blocking_rects():
		_add_wall(rect)


## The walkable floor, in arena coordinates.
func play_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## The floor plus the walls (the top wall is taller): the camera never shows anything outside.
func outer_rect() -> Rect2:
	var outer: Rect2 = play_rect().grow(wall_thickness)
	return outer.grow_side(SIDE_TOP, room.top_wall_height - wall_thickness)


func center() -> Vector2:
	return size / 2.0


## The furniture that blocks zombies and enemy bullets.
func obstacles() -> Obstacles:
	return Obstacles.new(_blocking_rects())


## Where the patchwork rugs lie (the middle one is where every run starts).
func rug_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if furniture != null:
		for piece: FurniturePiece in furniture.pieces:
			if piece.kind == FurniturePiece.Kind.RUG:
				rects.append(piece.rect)
	return rects


## The baked furniture layers (floor decorations, then the pieces that block), back to front.
func furniture_layers() -> Array[BuildingSketch]:
	if furniture == null:
		return []
	return FurnitureLook.layers(furniture, room)


## The baked floor, rug, walls and window layers (back to front).
func look_layers() -> Array[BuildingSketch]:
	return BedroomLook.layers(size, wall_thickness, room, rug_rects())


func _blocking_rects() -> Array[Rect2]:
	if furniture == null:
		return []
	return furniture.blocking_rects()


func _build_walls() -> void:
	var t: float = wall_thickness
	var outer: Rect2 = outer_rect()
	_add_wall(Rect2(outer.position, Vector2(outer.size.x, -outer.position.y)))
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
	var layers: Array[BuildingSketch] = look_layers()
	layers[BedroomLook.Layer.BOARDS].draw(self)
	layers[BedroomLook.Layer.RUG].draw(self)
	for layer: BuildingSketch in furniture_layers():
		layer.draw(self)
	layers[BedroomLook.Layer.WALLS].draw(self)
	layers[BedroomLook.Layer.DETAILS].draw(self)
	draw_mesh(BedroomLook.sunbeams(size, room), null)
