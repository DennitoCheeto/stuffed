extends GutTest
## The world palette (spec 05 §2.1, §5): town and Bedroom colours come from one data file, none
## of them is a danger colour (AC-58), and floor colours stay calm and bright (AC-59).

const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const ARENA_SCENE: PackedScene = preload("res://src/arena/arena.tscn")
const TOWN_LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
## World art that takes every colour from the palette. Spec 05 tickets add their scripts here
## as they redraw them (buildings: M3.6-02/03, town ground: M3.6-04, Bedroom: M3.6-07/08).
const WORLD_ART_SCRIPTS: Array[String] = [
	"res://src/arena/arena.gd",
	"res://src/arena/bedroom_look.gd",
	"res://src/arena/room_vignette.gd",
	"res://src/town/town_floor.gd",
	"res://src/town/town_art.gd",
	"res://src/town/art/building_sketch.gd",
	"res://src/town/art/building_looks.gd",
	"res://src/town/art/lucky_jar_look.gd",
	"res://src/town/art/armory_look.gd",
	"res://src/town/art/look_parts.gd",
	"res://src/town/art/watchtower_look.gd",
	"res://src/town/art/snack_bar_look.gd",
	"res://src/town/art/party_shop_look.gd",
	"res://src/town/art/hospital_look.gd",
	"res://src/town/art/fort_look.gd",
	"res://src/town/art/scrapbook_look.gd",
	"res://src/town/art/town_ground_look.gd",
	"res://src/town/town_fort.gd",
	"res://src/town/scrapbook_stand.gd",
	"res://src/town/town_life.gd",
]
## A colour written into the code: Color("#..."), Color(0.1, ...) or a named one like Color.RED.
## Color(some_colour, alpha) and Color.TRANSPARENT are fine.
const LITERAL_PATTERN: String = "Color\\(\\s*[\"'0-9.]|Color\\.(?!TRANSPARENT\\b)[A-Z]"


func test_the_palette_is_the_one_data_file() -> void:
	assert_eq(WorldPalette.current(), PALETTE)
	assert_eq(WorldPalette.PATH, PALETTE.resource_path)


func test_no_palette_colour_is_a_danger_colour() -> void:
	var colors: Array[Color] = PALETTE.all_colors()
	assert_gt(colors.size(), 40, "the palette lists all the world's colours")
	for color: Color in colors:
		assert_false(UiColors.is_danger(color), "%s is enemy red/orange" % color.to_html())


func test_world_art_takes_its_colours_from_the_palette() -> void:
	var literal: RegEx = RegEx.create_from_string(LITERAL_PATTERN)
	for path: String in WORLD_ART_SCRIPTS:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		assert_gt(lines.size(), 1, "%s exists" % path)
		for i: int in lines.size():
			var code: String = lines[i].strip_edges()
			if code.begins_with("#"):
				continue
			var found: RegExMatch = literal.search(code)
			assert_null(found, "%s:%d writes a colour itself: %s" % [path, i + 1, code])


func test_every_floor_colour_lies_in_the_brightness_band() -> void:
	var low: float = PALETTE.floor_brightness_min
	var high: float = PALETTE.floor_brightness_max
	assert_lt(low, high)
	for group: Array in PALETTE.floor_groups():
		assert_gt(group.size(), 1, "a floor group has at least two colours")
		for color: Color in group:
			var level: float = WorldPalette.brightness(color)
			assert_between(level, low, high, "%s brightness %.2f" % [color.to_html(), level])


func test_colours_of_one_floor_differ_only_a_little() -> void:
	var step: float = PALETTE.floor_max_step
	assert_gt(step, 0.0)
	for group: Array in PALETTE.floor_groups():
		for i: int in group.size():
			for j: int in range(i + 1, group.size()):
				var a: Color = group[i]
				var b: Color = group[j]
				var gap: float = absf(WorldPalette.brightness(a) - WorldPalette.brightness(b))
				assert_lt(gap, step, "%s vs %s: %.2f" % [a.to_html(), b.to_html(), gap])


func test_the_floors_are_no_longer_near_black() -> void:
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			assert_gt(WorldPalette.brightness(color), 0.5, color.to_html())


func test_the_bedroom_and_the_town_ground_have_felt_grain() -> void:
	var arena: Arena = ARENA_SCENE.instantiate() as Arena
	add_child_autofree(arena)
	_assert_felt(arena.material)
	var ground: TownFloor = TownFloor.new(TOWN_LAYOUT)
	add_child_autofree(ground)
	_assert_felt(ground.material)


func _assert_felt(material: Material) -> void:
	var felt: ShaderMaterial = material as ShaderMaterial
	assert_not_null(felt, "has a felt material")
	if felt == null:
		return
	assert_eq(felt.shader, WorldPalette.FELT_SHADER)
	assert_eq(felt.get_shader_parameter(&"grain_strength"), PALETTE.grain_strength)
	assert_gt(PALETTE.grain_strength, 0.0)
