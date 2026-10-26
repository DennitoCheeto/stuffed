extends GutTest
## The Pillow Fort's ground (spec 05 §3.1): quilt, thread paths, tape measure, props and pillow
## walls, built with the building art kit and baked once.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const PROP_PARTS: Array[StringName] = [
	&"cushion", &"toy_block", &"flower", &"button", &"safety_pin", &"marble", &"spool"
]


func test_the_ground_is_four_baked_layers_built_once() -> void:
	var layers: Array[BuildingSketch] = TownGroundLook.layers(LAYOUT)
	assert_eq(layers.size(), 4, "quilt, paths, props, walls")
	var again: Array[BuildingSketch] = TownGroundLook.layers(LAYOUT)
	for i: int in layers.size():
		assert_same(again[i], layers[i], "layer %d is built only once" % i)
		assert_gt(layers[i].baked().get_surface_count(), 0, "layer %d has a mesh" % i)


func test_every_ground_shape_can_be_filled() -> void:
	for layer: BuildingSketch in TownGroundLook.layers(LAYOUT):
		assert_eq(layer.broken_shapes().size(), 0)


func test_the_ground_has_no_danger_colour() -> void:
	for layer: BuildingSketch in TownGroundLook.layers(LAYOUT):
		for color: Color in layer.colors():
			assert_false(UiColors.is_danger(color), color.to_html())


func test_neighbouring_quilt_patches_are_different_kinds() -> void:
	for row: int in 6:
		for col: int in 10:
			var kind: TownGroundLook.Patch = TownGroundLook.patch_at(col, row)
			assert_ne(kind, TownGroundLook.patch_at(col + 1, row), "right of %d,%d" % [col, row])
			assert_ne(kind, TownGroundLook.patch_at(col, row + 1), "below %d,%d" % [col, row])


func test_the_paths_layer_has_the_tape_measure_with_numbers() -> void:
	var paths: BuildingSketch = TownGroundLook.layers(LAYOUT)[1]
	assert_has(paths.parts, &"tape_measure")
	assert_has(paths.parts, &"tape_tab")
	assert_gte(TownGroundLook.road_numbers(LAYOUT).size(), 4, "every 5 ticks a number")


func test_every_kind_of_prop_is_drawn() -> void:
	var props: BuildingSketch = TownGroundLook.layers(LAYOUT)[2]
	for part: StringName in PROP_PARTS:
		assert_has(props.parts, part)


func test_the_walls_have_pillows_and_a_rick_rack_trim() -> void:
	var walls: BuildingSketch = TownGroundLook.layers(LAYOUT)[3]
	assert_has(walls.parts, &"pillow_wall")
	assert_has(walls.parts, &"rick_rack")
