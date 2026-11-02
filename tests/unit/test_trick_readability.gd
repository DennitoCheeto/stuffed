extends GutTest
## Trick readability (spec 06 §7, AC-73): friendly things that walk among the zombies with
## their own colours (the Plushie Buddy) get their danger colours calmed, so red/orange stays
## the enemies' (hard rule 9). The town keeps the plushies' real colours.

const PLUSHIES_DIR: String = "res://data/town/plushies/"
const BOBO: PlushieDef = preload("res://data/town/plushies/bobo.tres")


func _plushies() -> Array[PlushieDef]:
	var found: Array[PlushieDef] = []
	for file: String in DirAccess.get_files_at(PLUSHIES_DIR):
		if file.ends_with(".tres"):
			found.append(load(PLUSHIES_DIR + file) as PlushieDef)
	return found


func _colors(def: PlushieDef) -> Array[Color]:
	return [def.body_color, def.accent_color, def.detail_color, def.patch_color]


func test_calmed_leaves_calm_colours_alone() -> void:
	for color: Color in [UiColors.TEAL, UiColors.GOLD, UiColors.HEALTH, Color.WHITE]:
		assert_eq(UiColors.calmed(color), color)


func test_calmed_makes_danger_dustier_with_the_same_hue() -> void:
	for color: Color in [Hud.BOSS_COLOR, ProjectileLook.BULLET_COLOR, Color("#ff7a1a")]:
		assert_true(UiColors.is_danger(color), "the check sees %s" % color.to_html())
		var calm: Color = UiColors.calmed(color)
		assert_false(UiColors.is_danger(calm), color.to_html())
		assert_almost_eq(calm.h, color.h, 0.01, "same hue")
		assert_almost_eq(calm.v, color.v, 0.01, "same brightness")


func test_every_plushie_in_a_run_has_no_danger_colour() -> void:
	var plushies: Array[PlushieDef] = _plushies()
	assert_gt(plushies.size(), 3)
	for def: PlushieDef in plushies:
		var calm: PlushieDef = def.calmed()
		assert_eq(calm.id, def.id)
		assert_eq(calm.shape, def.shape)
		for color: Color in _colors(calm):
			assert_false(UiColors.is_danger(color), "%s: %s" % [def.id, color.to_html()])


func test_the_town_keeps_the_real_colours() -> void:
	assert_true(UiColors.is_danger(BOBO.body_color), "Böbö's brown alone would read as danger")
	var calm: PlushieDef = BOBO.calmed()
	assert_ne(calm.body_color, BOBO.body_color)
	assert_true(UiColors.is_danger(BOBO.body_color), "the data stays untouched")
