class_name FurnitureLayout
extends Resource
## The furniture of one area, placed by hand: the same each run (spec 02 §10).

@export var pieces: Array[FurniturePiece] = []


## The floor rectangles that block movement.
func blocking_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for piece: FurniturePiece in pieces:
		if piece.blocks:
			result.append(piece.rect)
	return result


func obstacles() -> Obstacles:
	return Obstacles.new(blocking_rects())
