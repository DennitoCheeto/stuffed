class_name SpatialGrid
extends RefCounted
## Sorts objects into square cells by position, so "what is near this point?" only looks at a
## few cells instead of every object (needed for hundreds of zombies).

var cell_size: float = 64.0

var _cells: Dictionary[Vector2i, Array] = {}


func _init(size: float) -> void:
	cell_size = size


func clear() -> void:
	_cells.clear()


func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / cell_size), floori(point.y / cell_size))


func insert(item: Object, point: Vector2) -> void:
	var key: Vector2i = cell_of(point)
	if _cells.has(key):
		_cells[key].append(item)
	else:
		_cells[key] = [item]


## Everything in the cells the circle touches. Callers still check the exact distance.
func candidates(center: Vector2, radius: float) -> Array:
	var result: Array = []
	var reach: Vector2 = Vector2(radius, radius)
	var first: Vector2i = cell_of(center - reach)
	var last: Vector2i = cell_of(center + reach)
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			var key: Vector2i = Vector2i(x, y)
			if _cells.has(key):
				result.append_array(_cells[key])
	return result
