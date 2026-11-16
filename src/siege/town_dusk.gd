class_name TownDusk
extends Node2D
## Dusk in the Pillow Fort (spec 07 §2, §7) while the night siege is due and during it: a warm
## evening tint over the whole town (a `CanvasModulate`, never dark: the PO found the night look
## too dark) and a string of fairy lights over the fort and every built building. The lights are
## baked into one mesh with the building art kit. All colours come from the world palette.

## Bulbs on one string, how far down the drawing it hangs (share of its height) and its sag.
const BULBS: int = 7
const HANG: float = 0.3
const SAG: float = 16.0
## Glow around a bulb and the bulb itself (px).
const GLOW_RADIUS: float = 13.0
const BULB_RADIUS: float = 4.5
## The string starts this far inside the drawing's left and right edges.
const INSET: float = 14.0

var tint: CanvasModulate = CanvasModulate.new()
## Where the strings hang: the drawings (world rects) of the fort and the built buildings.
var lit: Array[Rect2] = []

var _look: BuildingSketch


func _init(lit_rects: Array[Rect2]) -> void:
	name = "Dusk"
	lit = lit_rects
	tint.color = WorldPalette.current().dusk_tint
	add_child(tint)
	_look = lights(lit_rects)


func _ready() -> void:
	material = WorldPalette.current().grain_material()


## The world rects of the drawings that get fairy lights: the fort and every built building.
static func lit_rects(fort: TownFort, buildings: Array[TownBuilding]) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var fort_rect: Rect2 = fort.layout.fort_rect
	rects.append(_placed(fort.look(), Vector2(fort_rect.get_center().x, fort_rect.end.y)))
	for building: TownBuilding in buildings:
		if building.level <= 0:
			continue
		var spot: Rect2 = building.spot.rect
		rects.append(_placed(building.shown_look(), Vector2(spot.get_center().x, spot.end.y)))
	return rects


## The baked fairy light strings over `rects`.
static func lights(rects: Array[Rect2]) -> BuildingSketch:
	var sketch: BuildingSketch = BuildingSketch.new()
	var palette: WorldPalette = WorldPalette.current()
	for rect: Rect2 in rects:
		var y: float = rect.position.y + rect.size.y * HANG
		var from: Vector2 = Vector2(rect.position.x + INSET, y)
		var to: Vector2 = Vector2(rect.end.x - INSET, y)
		var cord: PackedVector2Array = LookParts.sagging(from, to, SAG, BULBS)
		sketch.line(cord, palette.light_cord, 2.0)
		for i: int in BULBS:
			var bulb: Vector2 = cord[i] + Vector2(0.0, 5.0)
			sketch.dot(bulb, GLOW_RADIUS, palette.dusk_glow)
			sketch.dot(bulb, BULB_RADIUS, WorldPalette.pick(palette.fairy_lights, i))
	return sketch


func look() -> BuildingSketch:
	return _look


func _draw() -> void:
	_look.draw(self)


static func _placed(sketch: BuildingSketch, bottom: Vector2) -> Rect2:
	var bounds: Rect2 = sketch.bounds()
	return Rect2(bounds.position + bottom, bounds.size)
