extends GutTest
## The clarity ladder (#172 part 2, vision §6, hard rule 9): danger reads first, the hero right
## after, own attacks are quieter and pickups never look like danger. The draw order lives in
## WorldLayers (checked against the real run in test_05_clarity_ladder.gd).

const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
## Enemy bullet colours in ProjectileLook (danger on purpose).
const ENEMY_PREFIXES: Array[String] = ["BULLET_", "HAZARD_"]
## The thimble's soft see-through drop shadow is not a shot colour.
const NOT_A_SHOT: Array[String] = ["SHADOW_COLOR"]


func _floor_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
	return colors


## Every colour constant ProjectileLook draws the players' shots with.
func _own_shot_colors() -> Dictionary[String, Color]:
	var found: Dictionary[String, Color] = {}
	var constants: Dictionary = (ProjectileLook as Script).get_script_constant_map()
	for name: String in constants:
		if not constants[name] is Color or NOT_A_SHOT.has(name):
			continue
		var enemy: bool = false
		for prefix: String in ENEMY_PREFIXES:
			enemy = enemy or name.begins_with(prefix)
		if not enemy:
			found[name] = constants[name]
	return found


func test_the_ladder_goes_floor_pickups_shots_enemies_heroes_bullets() -> void:
	var ladder: Array[int] = [
		WorldLayers.FLOOR_MARKS,
		WorldLayers.PICKUPS,
		WorldLayers.OWN_SHOTS,
		WorldLayers.ENEMIES,
		WorldLayers.HEROES,
		WorldLayers.ENEMY_BULLETS,
	]
	for i: int in ladder.size() - 1:
		assert_lt(ladder[i], ladder[i + 1], "step %d" % i)


func test_own_shots_never_use_a_danger_colour() -> void:
	var colors: Dictionary[String, Color] = _own_shot_colors()
	assert_gt(colors.size(), 20, "every shot colour is checked")
	for name: String in colors:
		assert_false(UiColors.is_danger(colors[name]), "%s %s" % [name, colors[name].to_html()])


func test_own_shots_are_quieter_than_the_zombies_on_every_floor() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	var colors: Dictionary[String, Color] = _own_shot_colors()
	for floor_color: Color in _floor_colors():
		var danger_gap: float = absf(WorldPalette.brightness(floor_color) - ink)
		for name: String in colors:
			var gap: float = absf(
				WorldPalette.brightness(floor_color) - WorldPalette.brightness(colors[name])
			)
			assert_lt(gap, danger_gap, "%s on %s" % [name, floor_color.to_html()])


func test_pickups_never_look_like_danger() -> void:
	var colors: Array[Color] = []
	for color: Color in XpButtonLook.COLORS:
		colors.append(color)
	colors.append(XpButtonLook.GOLDEN_COLOR)
	colors.append_array([GiftBoxLook.BOX_COLOR, GiftBoxLook.LID_COLOR, GiftBoxLook.RIBBON_COLOR])
	for color: Color in colors:
		assert_false(UiColors.is_danger(color), color.to_html())
