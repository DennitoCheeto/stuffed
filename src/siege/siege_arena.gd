class_name SiegeArena
extends Arena
## The town room as the night siege's battlefield (spec 07 §2, §5): the same quilt, fort,
## Scrapbook stand and buildings (at their levels) as the Pillow Fort, at dusk. The pillow walls,
## the fort, the stand and the buildings block heroes; the zombies walk around the buildings and
## the fort and come in over the walls from just outside the room. Built in `setup` (it needs the
## town), which the siege calls before the run's own setup.

var layout: TownLayout
var fort: TownFort
## Building spot id -> its building (only looks: no tags, no cards).
var buildings: Dictionary[StringName, TownBuilding] = {}
var dusk: TownDusk

var _floor: TownFloor
var _save: TownSave


## Nothing to build before `setup`: the Bedroom's walls and looks are not wanted here.
func _ready() -> void:
	material = palette.grain_material()


## Builds the town room from `town_layout` with the buildings of `save`.
func setup(town_layout: TownLayout, save: TownSave) -> void:
	layout = town_layout
	_save = save
	size = layout.size
	wall_thickness = layout.wall_thickness
	furniture = null
	_floor = TownFloor.new(layout)
	add_child(_floor)
	_build_walls()
	for rect: Rect2 in _blocking_rects():
		_add_wall(rect)
	fort = TownFort.new(layout)
	fort.pieces = TownFort.pieces_for(save.total_levels(), layout.fort_piece_every)
	add_child(fort)
	add_child(ScrapbookStand.new(layout.scrapbook_rect))
	var standing: Array[TownBuilding] = []
	for spot: TownSpot in layout.spots:
		if spot.is_hidden_in(save):
			continue
		var level: int = save.building_level(String(spot.id))
		var building: TownBuilding = TownBuilding.new(spot, level, _is_open(spot, save))
		add_child(building)
		building.show_damaged(level > 0 and save.is_damaged(String(spot.id)))
		buildings[spot.id] = building
		standing.append(building)
	dusk = TownDusk.new(TownDusk.lit_rects(fort, standing))
	add_child(dusk)


## Adds `node` just above the town floor: under the fort, the buildings and the heroes.
func add_to_floor(node: Node2D) -> void:
	add_child(node)
	move_child(node, _floor.get_index() + 1)


## The room plus the pillow walls (the camera never shows anything outside).
func outer_rect() -> Rect2:
	return layout.outer_rect()


## Heroes start (and stand back up) right in front of the fort door.
func center() -> Vector2:
	return layout.spawn_position


## Where zombies may be: the room and a band `margin` wide all around it (they come in from
## there).
func spawn_area(margin: float) -> Rect2:
	return play_rect().grow(wall_thickness + margin)


## A point `margin` beyond the pillow walls on a random side (`radius` = the zombie's size).
func edge_point(margin: float, radius: float, rng: RandomNumberGenerator) -> Vector2:
	var out: float = wall_thickness + margin * 0.5 + radius
	var side: int = rng.randi_range(0, 3)
	match side:
		0:
			return Vector2(rng.randf_range(0.0, size.x), -out)
		1:
			return Vector2(size.x + out, rng.randf_range(0.0, size.y))
		2:
			return Vector2(rng.randf_range(0.0, size.x), size.y + out)
	return Vector2(-out, rng.randf_range(0.0, size.y))


func _blocking_rects() -> Array[Rect2]:
	if layout == null:
		return []
	return layout.blocking_rects(_save)


## True when `spot` stands open (rebuildable, its yarn gone) in `save`, like in the town.
static func _is_open(spot: TownSpot, save: TownSave) -> bool:
	if not spot.is_unlocked_in(save):
		return false
	return not spot.starts_locked() or save.revealed.has(String(spot.id))
