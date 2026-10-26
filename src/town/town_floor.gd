class_name TownFloor
extends Node2D
## The Pillow Fort's ground (spec 05 §3.1): a sunny patchwork quilt, coloured thread paths to
## every building, the tape measure road from the fort door, props between the buildings and
## the pillow walls with a rick-rack trim. Baked once (`TownGroundLook`, a few meshes), so it
## costs a handful of draw calls. Nothing here blocks except the walls (their own bodies).
## All colours come from the world palette (spec 05 §2.1); the ground has the felt grain.

const NUMBER_SIZE: int = 15

var layout: TownLayout
var palette: WorldPalette = WorldPalette.current()


func _init(town_layout: TownLayout) -> void:
	layout = town_layout
	z_index = -10
	material = palette.grain_material()


func _draw() -> void:
	var layers: Array[BuildingSketch] = TownGroundLook.layers(layout)
	layers[0].draw(self)
	layers[1].draw(self)
	_draw_numbers()
	draw_set_transform(Vector2.ZERO)
	for i: int in range(2, layers.size()):
		layers[i].draw(self)


## Every fifth centimetre on the tape gets its number, turned along the tape.
func _draw_numbers() -> void:
	var font: Font = UiFonts.heading(700)
	var marks: Array[Transform2D] = TownGroundLook.road_numbers(layout)
	for i: int in marks.size():
		var at: Transform2D = marks[i]
		var text: String = str((i + 1) * TownGroundLook.LONG_TICK)
		var turn: float = at.get_rotation()
		draw_set_transform(at.origin, turn + PI / 2.0 if turn < 0.0 else turn - PI / 2.0)
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE).x
		var spot: Vector2 = Vector2(-width / 2.0, NUMBER_SIZE * 0.35)
		var ink: Color = palette.tape_ticks
		draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_SIZE, ink)
