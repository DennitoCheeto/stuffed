class_name TownFort
extends Node2D
## The fort in the middle of the Pillow Fort: a pillow wall, two cushion towers, a patchwork quilt
## roof and the Bedroom door (walk up and press E to start a run). Its body blocks walking. The
## fort grows with the town (spec 03 §5): a new piece after every few rebuilds/upgrades. Drawn
## with the building art kit (`FortLook`, spec 05 §3.2), one baked look per number of pieces.

## The pieces the fort gets as the town grows, in order.
const PIECES: PackedStringArray = [
	"flag", "string_lights", "second_tower", "bunting", "window_boxes", "big_banner"
]

var layout: TownLayout
## How many of PIECES the fort shows.
var pieces: int = 0:
	set(value):
		pieces = clampi(value, 0, PIECES.size())
		queue_redraw()

## Looks already built, by number of pieces.
var _looks: Dictionary[int, BuildingSketch] = {}


func _init(town_layout: TownLayout) -> void:
	layout = town_layout


func _ready() -> void:
	material = WorldPalette.current().building_material()


func _draw() -> void:
	var fort: Rect2 = layout.fort_rect
	draw_set_transform(Vector2(fort.get_center().x, fort.end.y))
	look().draw(self)
	draw_set_transform(Vector2.ZERO)


## The look the fort shows now (with its first `pieces` pieces).
func look() -> BuildingSketch:
	if not _looks.has(pieces):
		_looks[pieces] = FortLook.build(layout, PIECES.slice(0, pieces))
	return _looks[pieces]


## How many pieces the fort has after `total_levels` rebuilds/upgrades (one per `every`).
static func pieces_for(total_levels: int, every: int) -> int:
	return clampi(floori(float(total_levels) / maxi(every, 1)), 0, PIECES.size())


func has_piece(piece: String) -> bool:
	var index: int = PIECES.find(piece)
	return index >= 0 and index < pieces
