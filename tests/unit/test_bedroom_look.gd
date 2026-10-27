extends GutTest
## The Bedroom's floor and room (spec 05 §4.1, §5, §6, M3.6-07): honey floorboards, the patchwork
## rug where every run starts, the top wall with two windows, sunbeams across the middle and the
## vignette. Everything is baked once, has no danger colour and no broken shape.

const ARENA_SCENE: PackedScene = preload("res://src/arena/arena.tscn")
const ROOM: BedroomRoom = preload("res://data/arena/bedroom_room.tres")
## Pieces each layer must show, in `BedroomLook.Layer` order.
const LAYER_PARTS: Array[Array] = [
	[&"floorboards", &"wood_grain", &"knots", &"nails"],
	[&"rug", &"rug_patches", &"rug_seams"],
	[&"toy_blocks", &"top_wall", &"baseboard"],
	[&"rug_buttons", &"window", &"window_glass", &"window_sill", &"curtains", &"curtain_rod"],
]

var arena: Arena


func before_each() -> void:
	arena = ARENA_SCENE.instantiate() as Arena
	add_child_autofree(arena)


func test_every_layer_shows_its_pieces() -> void:
	var layers: Array[BuildingSketch] = arena.look_layers()
	assert_eq(layers.size(), BedroomLook.Layer.size())
	for i: int in LAYER_PARTS.size():
		for part: StringName in LAYER_PARTS[i]:
			assert_has(layers[i].parts, part, "layer %d shows %s" % [i, part])


func test_the_room_is_baked_once() -> void:
	var first: Array[BuildingSketch] = arena.look_layers()
	var again: Array[BuildingSketch] = arena.look_layers()
	for i: int in first.size():
		assert_same(first[i], again[i], "layer %d is built once" % i)
		assert_same(first[i].baked(), again[i].baked(), "and baked once")
	var beams: ArrayMesh = BedroomLook.sunbeams(arena.size, arena.room)
	assert_same(beams, BedroomLook.sunbeams(arena.size, arena.room), "sunbeams are baked once")
	assert_gt(beams.get_surface_count(), 0, "the sunbeams are drawn")


func test_no_danger_colours_and_no_broken_shapes() -> void:
	for layer: BuildingSketch in arena.look_layers():
		assert_eq(layer.broken_shapes(), PackedStringArray(), "every shape can be filled")
		for color: Color in layer.colors():
			assert_false(UiColors.is_danger(color), "%s is enemy red/orange" % color.to_html())
	assert_false(UiColors.is_danger(WorldPalette.current().sunbeam), "sunbeam colour")


func test_the_room_keeps_its_size_and_the_top_wall_shows_above_the_floor() -> void:
	assert_eq(arena.play_rect(), Rect2(Vector2.ZERO, Vector2(7680.0, 4320.0)), "same room size")
	var outer: Rect2 = arena.outer_rect()
	assert_eq(outer.position.y, -ROOM.top_wall_height, "the camera may show the whole top wall")
	assert_eq(outer.position.x, -arena.wall_thickness, "side walls unchanged")
	assert_eq(outer.end, arena.size + Vector2.ONE * arena.wall_thickness, "bottom walls unchanged")


func test_two_windows_sit_on_the_top_wall() -> void:
	assert_eq(ROOM.window_centers.size(), 2, "two windows")
	var wall: Rect2 = Rect2(0.0, -ROOM.top_wall_height, arena.size.x, ROOM.top_wall_height)
	var first: Rect2 = BedroomLook.window_rect(ROOM, 0)
	var second: Rect2 = BedroomLook.window_rect(ROOM, 1)
	for glass: Rect2 in [first, second]:
		var frame: Rect2 = glass.grow(BedroomLook.FRAME)
		assert_true(wall.encloses(frame), "window %s is on the wall" % frame)
		assert_lt(frame.end.y, -ROOM.baseboard_height, "above the baseboard")
	var curtains: float = BedroomLook.CURTAIN_WIDTH * 2.0 + 40.0
	assert_false(first.grow(curtains).intersects(second), "windows and curtains don't overlap")


func test_the_rug_lies_where_every_run_starts() -> void:
	var rugs: Array[Rect2] = arena.rug_rects()
	assert_eq(rugs.size(), 1, "one patchwork rug")
	var start_screen: Rect2 = Rect2(arena.center() - Vector2(300, 200), Vector2(600, 400))
	assert_true(rugs[0].encloses(start_screen), "the start screen's middle is on the rug")


func test_sunbeams_fall_across_the_middle_of_the_room() -> void:
	var middle: float = arena.center().y
	var rug: Rect2 = arena.rug_rects()[0]
	for i: int in ROOM.window_centers.size():
		var corners: PackedVector2Array = BedroomLook.beam(ROOM, i)
		var glass: Rect2 = BedroomLook.window_rect(ROOM, i)
		assert_almost_eq(corners[0].x, glass.position.x, 0.1, "beam %d starts under its window" % i)
		assert_eq(corners[0].y, 0.0, "at the floor's top edge")
		assert_gt(corners[3].y, middle, "and reaches past the middle")
		var share: float = middle / corners[3].y
		var left: float = lerpf(corners[0].x, corners[3].x, share)
		var right: float = lerpf(corners[1].x, corners[2].x, share)
		assert_true(left < rug.end.x and right > rug.position.x, "beam %d crosses the rug" % i)


func test_the_beam_mesh_fades_out_softly() -> void:
	var mesh: ArrayMesh = BedroomLook.sunbeams(arena.size, ROOM)
	var colors: PackedColorArray = mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var strongest: float = 0.0
	var clear: int = 0
	for color: Color in colors:
		strongest = maxf(strongest, color.a)
		if is_zero_approx(color.a):
			clear += 1
	var light: Color = WorldPalette.current().sunbeam
	assert_almost_eq(strongest, light.a * ROOM.sunbeam_strength, 0.01, "see-through light")
	assert_lt(strongest, 0.5, "never covers what's under it")
	assert_gt(clear, colors.size() / 3, "soft sides and a soft end")


func test_the_vignette_is_clear_in_the_middle_and_soft_at_the_edges() -> void:
	var vignette: RoomVignette = RoomVignette.new(ROOM)
	add_child_autofree(vignette)
	assert_almost_eq(vignette.strength_at(Vector2(0.5, 0.5)), 0.0, 0.01, "clear middle")
	assert_almost_eq(vignette.strength_at(Vector2(0.0, 0.0)), 1.0, 0.01, "full in the corners")
	var edge: float = vignette.strength_at(Vector2(0.0, 0.5))
	assert_between(edge, 0.05, 0.6, "only a little at the edge middles")
	assert_eq(vignette.shade.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never catches clicks")
	assert_lt(WorldPalette.current().vignette.a, 0.4, "see-through")
