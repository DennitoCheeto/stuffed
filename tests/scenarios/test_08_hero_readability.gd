extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 08 §13, AC-93, AC-94): no hero effect (frost ring, snowballs, paw swipe, heart
## pulse, slide streak, the puppets themselves) uses a danger colour, and on every floor (dusk
## too) the zombies' ink outline keeps the strongest contrast. A plushie hero draws no more pieces
## than Banane (the real-GPU draw-call check is `tools/benchmark.gd -- --hero=<id>`).

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const ColorSweep: GDScript = preload("res://tests/scenarios/color_sweep.gd")
## The hero effects added in spec 08 (ProjectileLook constants are swept by test_clarity_ladder).
const EFFECT_SHOTS: Array[String] = [
	"SNOWBALL_COLOR", "SNOWBALL_SHADE_COLOR", "PAW_COLOR", "PAW_CLAW_COLOR"
]


func _plushie_heroes() -> Array[HeroStats]:
	var found: Array[HeroStats] = []
	for hero: HeroStats in HEROES.heroes:
		if hero.plushie != null:
			found.append(hero)
	return found


## Every colour a hero's effects are drawn with: the effect colours in its data and its shots.
func _effect_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for hero: HeroStats in HEROES.heroes:
		colors.append_array([hero.chilly_ring_color, hero.big_heart_color])
		colors.append(hero.belly_slide_trail_color)
	var constants: Dictionary = (ProjectileLook as Script).get_script_constant_map()
	for name: String in EFFECT_SHOTS:
		colors.append(constants[name])
	return colors


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


func test_ac93_no_hero_effect_or_puppet_uses_a_danger_colour() -> void:
	for color: Color in _effect_colors():
		assert_false(UiColors.is_danger(color), color.to_html())
	var run: Run = await start_run()
	run.spawner.active = false
	for hero: HeroStats in _plushie_heroes():
		var player: Player = PLAYER_SCENE.instantiate() as Player
		player.stats = hero
		player.player_index = 1
		run.actors.add_child(player)
		await wait_physics_frames(1)
		for color: Color in ColorSweep.colors_of(player.get_node("Puppet")):
			assert_false(UiColors.is_danger(color), "%s %s" % [hero.id, color.to_html()])
		player.queue_free()


func test_ac93_zombies_keep_the_strongest_contrast_on_every_floor() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var danger_gap: float = absf(floor - ink)
		for color: Color in _effect_colors():
			var gap: float = absf(floor - WorldPalette.brightness(color))
			assert_lt(gap, danger_gap, "%s on %s" % [color.to_html(), floor_color.to_html()])


func test_ac94_a_plushie_hero_draws_no_more_pieces_than_banane() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	var banane: int = _drawn_pieces(first_player().get_node("Puppet"))
	for hero: HeroStats in _plushie_heroes():
		var player: Player = PLAYER_SCENE.instantiate() as Player
		player.stats = hero
		player.player_index = 1
		run.actors.add_child(player)
		await wait_physics_frames(1)
		var pieces: int = _drawn_pieces(player.get_node("Puppet"))
		assert_lte(pieces, banane, "%s: %d pieces, Banane %d" % [hero.id, pieces, banane])
		player.queue_free()


## Canvas items under `root` that draw something in the world (the baked picture's own painter
## lives in a SubViewport and is drawn once).
func _drawn_pieces(root: Node) -> int:
	var count: int = 0
	for node: Node in root.find_children("*", "CanvasItem", true, false):
		if node.get_viewport() == root.get_viewport() and (node as CanvasItem).visible:
			count += 1
	return count
