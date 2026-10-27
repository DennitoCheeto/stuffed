extends GutTest
## The Bedroom's furniture and its six places (spec 05 §4.2, §5, §6, M3.6-08): every piece
## has its look, each piece is baked once and drawn on its own node (off-screen pieces are skipped), no
## danger colour and no broken shape.

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
	for i: int in LAYER_PARTS.size():
		var shown: Array[StringName] = []
		for sketch: BuildingSketch in arena.furniture_sketches(i as FurnitureLook.Layer):
			shown.append_array(sketch.parts)
		for part: StringName in LAYER_PARTS[i]:
			assert_has(shown, part, "layer %d shows %s" % [i, part])


func test_each_piece_is_baked_once_and_drawn_on_its_own_node() -> void:
	var meshes: Array[ArrayMesh] = []
	for layer: FurnitureLook.Layer in FurnitureLook.Layer.values():
		var first: Array[BuildingSketch] = arena.furniture_sketches(layer)
		var again: Array[BuildingSketch] = arena.furniture_sketches(layer)
		assert_gt(first.size(), 1, "layer %d has a look per piece" % layer)
		for i: int in first.size():
			assert_same(first[i], again[i], "built once")
			assert_same(first[i].baked(), again[i].baked(), "and baked once")
			meshes.append(first[i].baked())
	var drawn: Array[ArrayMesh] = []
	for child: Node in arena.get_children():
		if child is BakedMeshNode:
			drawn.append((child as BakedMeshNode).mesh)
	for mesh: ArrayMesh in meshes:
		assert_has(drawn, mesh, "every piece is drawn on its own node")
	assert_has(drawn, BedroomLook.sunbeams(arena.size, arena.room), "the sunbeams too")


func test_no_danger_colours_and_no_broken_shapes() -> void:
	for layer: FurnitureLook.Layer in FurnitureLook.Layer.values():
		for sketch: BuildingSketch in arena.furniture_sketches(layer):
			assert_eq(sketch.broken_shapes(), PackedStringArray(), "every shape can be filled")
			for color: Color in sketch.colors():
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
