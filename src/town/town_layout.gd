class_name TownLayout
extends Resource
## Where everything stands in the Pillow Fort (spec 03 §5). Tune it in
## data/town/pillow_fort.tres, not in code. All positions are in town pixels (0,0 = top left).

## The walkable blanket (a screen and a bit).
@export var size: Vector2 = Vector2(2880.0, 1800.0)
## Thickness of the pillow walls around the blanket.
@export var wall_thickness: float = 96.0
## The fort in the middle (blocks walking).
@export var fort_rect: Rect2 = Rect2(1240, 700, 400, 300)
## The Bedroom door in the fort's front wall.
@export var door_rect: Rect2 = Rect2(1395, 900, 90, 100)
## The Scrapbook stand (blocks walking).
@export var scrapbook_rect: Rect2 = Rect2(1760, 940, 140, 90)
## A player closer than this to the door or the stand can press E there.
@export var reach: float = 90.0
## Where Banane appears: right at the door, so E goes straight out again. Player 2+ stand
## next to him.
@export var spawn_position: Vector2 = Vector2(1440, 1075)
## Space between co-op players when they appear.
@export var spawn_spacing: float = 90.0
## The 6 building spots around the fort.
@export var spots: Array[TownSpot] = []
## Cozy props that don't block (drawn on the blanket).
@export var cushions: PackedVector2Array = []
@export var block_piles: PackedVector2Array = []
@export var lamps: PackedVector2Array = []


func play_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## The blanket plus the walls: the camera never shows anything outside this.
func outer_rect() -> Rect2:
	return play_rect().grow(wall_thickness)


## Everything that blocks walking: the fort, the stand and every building spot.
func blocking_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = [fort_rect, scrapbook_rect]
	for spot: TownSpot in spots:
		rects.append(spot.rect)
	return rects


func spot(id: StringName) -> TownSpot:
	for each: TownSpot in spots:
		if each.id == id:
			return each
	return null


## Distance from `point` to the nearest edge of `rect` (0 inside it).
static func distance_to(rect: Rect2, point: Vector2) -> float:
	var nearest: Vector2 = point.clamp(rect.position, rect.end)
	return point.distance_to(nearest)
