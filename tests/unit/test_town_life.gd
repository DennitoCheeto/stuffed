extends GutTest
## Spec 05 §3.4: flags and bunting flutter (the building shader moves the corners a baked look
## marks as loose cloth), and the town life numbers make sense.

const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const LIFE_RULES: TownLifeRules = preload("res://data/town/town_life_rules.tres")


func _max(weights: PackedFloat32Array) -> float:
	var best: float = 0.0
	for weight: float in weights:
		best = maxf(best, weight)
	return best


func test_a_flag_flutters_but_its_pole_does_not() -> void:
	var sketch: BuildingSketch = BuildingSketch.new()
	LookParts.pin_flag(sketch, &"flag", Vector2.ZERO, 50.0, WorldPalette.current().clover)
	var weights: PackedFloat32Array = sketch.sway_weights()
	assert_almost_eq(_max(weights), 1.0, 0.05, "the cloth's loose end moves fully")
	assert_true(weights.has(0.0), "the pin stays put")


func test_bunting_flutters() -> void:
	var sketch: BuildingSketch = BuildingSketch.new()
	LookParts.bunting(sketch, &"bunting", Vector2(-50, 0), Vector2(50, 0), 10.0, 4)
	assert_gt(_max(sketch.sway_weights()), 0.9)


func test_plain_pieces_never_move() -> void:
	var sketch: BuildingSketch = BuildingSketch.new()
	sketch.block(&"wall", Rect2(-20, -40, 40, 40), WorldPalette.current().wood, true)
	assert_eq(_max(sketch.sway_weights()), 0.0)


func test_the_fort_flag_flutters_once_it_has_one() -> void:
	var fort: BuildingSketch = FortLook.build(LAYOUT, TownFort.PIECES)
	assert_gt(_max(fort.sway_weights()), 0.9, "flag and bunting")


func test_only_buildings_get_the_flutter_material() -> void:
	var palette: WorldPalette = WorldPalette.current()
	assert_gt(palette.flutter_pixels, 0.0)
	var building: ShaderMaterial = palette.building_material()
	assert_eq(building.get_shader_parameter(&"flutter_pixels"), palette.flutter_pixels)
	var floor_grain: ShaderMaterial = palette.grain_material()
	var off: Variant = floor_grain.get_shader_parameter(&"flutter_pixels")
	assert_true(off == null or float(off) == 0.0, "floors and puppets never move")


func test_life_numbers_make_sense() -> void:
	assert_gt(LIFE_RULES.sunbeam_starts.size(), 0)
	assert_gt(LIFE_RULES.sparkles_per_beam, 0)
	assert_lte(LIFE_RULES.plane_min_gap, LIFE_RULES.plane_max_gap)
	assert_gt(LIFE_RULES.plane_speed, 0.0)


func test_every_plushie_spot_can_be_reached() -> void:
	var rules: PlushieTownRules = load("res://data/town/plushie_town_rules.tres")
	assert_eq(LAYOUT.plushie_spots.size(), 4, "fort, table, nap, lookout")
	for spot: PlushieSpot in LAYOUT.plushie_spots:
		var target: Vector2 = spot.walk_target()
		assert_true(
			TownPlushie.is_walkable(LAYOUT, target, rules.keep_clear), "%s: free floor" % spot.id
		)
		if spot.building != &"":
			assert_not_null(LAYOUT.spot(spot.building), "%s: its building exists" % spot.id)
