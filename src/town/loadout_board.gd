class_name LoadoutBoard
extends Node2D
## The "My loadout" corkboard by the Bedroom door (spec 04b §3, AC-118): walk up to it and press
## interact to see what you take into the next run. Not a building: no level, doesn't block
## walking. Drawn with the building art kit (`LoadoutBoardLook`).

static var _look: BuildingSketch

var rect: Rect2
var sign_label: Label


func _init(spot: Rect2) -> void:
	name = "LoadoutBoard"
	rect = spot
	position = Vector2(spot.get_center().x, spot.end.y)


func _ready() -> void:
	material = WorldPalette.current().grain_material()
	sign_label = TownArt.label(TownLoadoutPage.TEXTS.board_sign, 22)
	add_child(sign_label)
	TownArt.center_label(sign_label, 0.0, 10.0, 200.0)


## The board's look (built once).
static func look() -> BuildingSketch:
	if _look == null:
		_look = LoadoutBoardLook.build()
	return _look


func _draw() -> void:
	look().draw(self)


## True when a player at `point` is close enough to press interact here.
func is_near(point: Vector2, reach: float) -> bool:
	return TownLayout.distance_to(rect, point) <= reach
