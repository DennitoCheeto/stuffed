class_name TownLayout
extends Resource
## Where everything stands in the Pillow Fort (spec 03 §5, spec 05 §3.1). Tune it in
## data/town/pillow_fort.tres, not in code. All positions are in town pixels (0,0 = top left).

## Points per segment when a road or thread path is drawn smooth.
const SMOOTH_STEPS: int = 10

## The walkable quilt.
@export var size: Vector2 = Vector2(2500.0, 1500.0)
## Thickness of the pillow walls around the quilt.
@export var wall_thickness: float = 96.0
## The fort in the middle (blocks walking).
@export var fort_rect: Rect2 = Rect2(1050, 600, 400, 300)
## The Bedroom door in the fort's front wall.
@export var door_rect: Rect2 = Rect2(1205, 800, 90, 100)
## The Scrapbook stand (blocks walking).
@export var scrapbook_rect: Rect2 = Rect2(1560, 955, 140, 90)
## A player closer than this to the door or the stand can press E there.
@export var reach: float = 90.0
## Where Banane appears: right at the door, so E goes straight out again. Player 2+ stand
## next to him.
@export var spawn_position: Vector2 = Vector2(1250, 975)
## Space between co-op players when they appear.
@export var spawn_spacing: float = 90.0
## The fort gets a new piece (flag, lights, ...) after every this many rebuilds/upgrades.
@export var fort_piece_every: int = 3
## The 6 building spots around the fort.
@export var spots: Array[TownSpot] = []
## AC-62: every building's middle is at most this far from the door's middle (the town before
## spec 05 had its farthest building 732 px away; about 20% closer).
@export var max_building_distance: float = 585.0

@export_group("Ground")
## Side of one quilt patch.
@export var quilt_patch: float = 250.0
## The tape measure: the main road from the fort door (points along its middle, drawn smooth).
@export var road: PackedVector2Array = []
@export var road_width: float = 50.0
## Cozy props that don't block (drawn on the quilt). Plushies like to sit on the cushions.
@export var cushions: PackedVector2Array = []
@export var block_piles: PackedVector2Array = []
@export var flowers: PackedVector2Array = []
@export var loose_buttons: PackedVector2Array = []
@export var safety_pins: PackedVector2Array = []
@export var marbles: PackedVector2Array = []
## Cotton spools lying on their side, each with a thread trail.
@export var spools: PackedVector2Array = []
## Where the tent stands (its bottom middle) in which rescued plushies wait for a Hospital bed.
## It doesn't block walking.
@export var tent_position: Vector2 = Vector2(1910, 1320)


func play_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)


## The quilt plus the walls: the camera never shows anything outside this.
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


## How far a building stands from the Bedroom door (middle to middle).
func distance_from_door(each: TownSpot) -> float:
	return door_rect.get_center().distance_to(each.rect.get_center())


## The tape measure road as a smooth line.
func road_line() -> PackedVector2Array:
	return smooth(road)


## The coloured thread path from the road to `each` building, as a smooth line.
func thread_line(each: TownSpot) -> PackedVector2Array:
	return smooth(each.thread_path)


## Distance from `point` to the nearest edge of `rect` (0 inside it).
static func distance_to(rect: Rect2, point: Vector2) -> float:
	var nearest: Vector2 = point.clamp(rect.position, rect.end)
	return point.distance_to(nearest)


## A smooth line through `points` (Catmull-Rom), starting and ending at the first and last one.
static func smooth(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var result: PackedVector2Array = [points[0]]
	var last: int = points.size() - 1
	for i: int in last:
		var before: Vector2 = points[maxi(i - 1, 0)]
		var after: Vector2 = points[mini(i + 2, last)]
		for step: int in range(1, SMOOTH_STEPS + 1):
			var t: float = float(step) / SMOOTH_STEPS
			result.append(_catmull_rom(before, points[i], points[i + 1], after, t))
	return result


static func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2: float = t * t
	var t3: float = t2 * t
	var a: Vector2 = 2.0 * p1 + (p2 - p0) * t
	var b: Vector2 = (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
	var c: Vector2 = (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3
	return 0.5 * (a + b + c)
