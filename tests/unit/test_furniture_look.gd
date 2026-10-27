extends GutTest
## The Bedroom's furniture and its six places (spec 05 §4.2, §5, §6, M3.6-08): every piece has its
## look, all of it is baked once into two layers, no danger colour and no broken shape.

const ARENA_SCENE: PackedScene = preload("res://src/arena/arena.tscn")
## Pieces each layer must show, in `FurnitureLook.Layer` order.
const LAYER_PARTS: Array[Array] = [
	[
		&"bed_shadow",
		&"scribbles",
		&"shavings",
		&"thread_trail",
		&"needle",
		&"big_spool",
		&"scissor_blades",
		&"scissor_handles",
		&"train_track",
		&"track_grooves",
		&"toy_train",
	],
	[
		&"bed",
		&"pillow",
		&"blanket",
		&"toy_box",
		&"alphabet_blocks",
		&"block_letters",
		&"crayon",
		&"crayon_paper",
		&"sharpener",
		&"sewing_box",
		&"sewing_lid",
		&"pincushion",
		&"pins",
	],
]

var arena: Arena


func before_each() -> void:
	arena = ARENA_SCENE.instantiate() as Arena
	add_child_autofree(arena)


func test_every_layer_shows_its_pieces() -> void:
	var layers: Array[BuildingSketch] = arena.furniture_layers()
	assert_eq(layers.size(), FurnitureLook.Layer.size())
	for i: int in LAYER_PARTS.size():
		for part: StringName in LAYER_PARTS[i]:
			assert_has(layers[i].parts, part, "layer %d shows %s" % [i, part])


func test_the_furniture_is_baked_once() -> void:
	var first: Array[BuildingSketch] = arena.furniture_layers()
	var again: Array[BuildingSketch] = arena.furniture_layers()
	for i: int in first.size():
		assert_same(first[i], again[i], "layer %d is built once" % i)
		assert_same(first[i].baked(), again[i].baked(), "and baked once")
		assert_gt(first[i].baked().get_surface_count(), 0, "layer %d is drawn" % i)


func test_no_danger_colours_and_no_broken_shapes() -> void:
	for layer: BuildingSketch in arena.furniture_layers():
		assert_eq(layer.broken_shapes(), PackedStringArray(), "every shape can be filled")
		for color: Color in layer.colors():
			assert_false(UiColors.is_danger(color), "%s is enemy red/orange" % color.to_html())


func test_every_block_letter_has_a_glyph() -> void:
	for letter: String in FurnitureLook.BLOCK_LETTERS:
		assert_true(LookParts.GLYPHS.has(letter), "a stroke letter for %s" % letter)


## Decorations under the action are soft (spec 05 §5): scribbles and the bed's shadow see-through.
func test_floor_decorations_are_see_through() -> void:
	var room: BedroomRoom = arena.room
	assert_lt(room.scribble_alpha, 0.5, "scribbles are soft")
	var shade: float = WorldPalette.current().shadow.a * room.bed_shade_strength
	assert_lt(shade, 0.2, "the bed's shadow only dims the corner")
