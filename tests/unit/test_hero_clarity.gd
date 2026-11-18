extends GutTest
## The hero stays easy to find on the light Sunny patchwork floors (#172, vision §6): every hero
## (Banane and the plushie heroes, spec 08 §6, AC-90) has the zombies' dark outline, calm
## colours, and every player has a coloured ring under their feet that stands out from every
## Bedroom, town and dusk floor colour and never looks like danger.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const HEROES: HeroRoster = preload("res://data/heroes/hero_roster.tres")
## How much darker than every floor colour the hero's outline and ring must be.
const OUTLINE_CONTRAST: float = 0.5
const MARKER_CONTRAST: float = 0.2
## At dusk (the siege) the whole town is tinted darker, the outline and the ring too.
const DUSK_OUTLINE_CONTRAST: float = 0.4
const DUSK_MARKER_CONTRAST: float = 0.15


func _floor_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
	return colors


func _spawn(index: int, hero: HeroStats = null) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.player_index = index
	if hero != null:
		player.stats = hero
	add_child_autofree(player)
	return player


func _plushie_heroes() -> Array[HeroStats]:
	var found: Array[HeroStats] = []
	for hero: HeroStats in HEROES.heroes:
		if hero.plushie != null:
			found.append(hero)
	return found


func test_banane_has_the_zombies_dark_outline() -> void:
	var puppet: BananePuppet = _spawn(0).get_node("Puppet") as BananePuppet
	var pieces: Array[FeltPiece] = puppet.outlined_pieces()
	assert_gte(pieces.size(), 9, "feet, body, hood, beak and flaps")
	for piece: FeltPiece in pieces:
		assert_eq(piece.outline_width, ShamblerLook.OUTLINE)
		assert_eq(piece.outline_color, BananePuppet.OUTLINE_COLOR)


func test_ac90_every_plushie_hero_has_the_same_dark_outline() -> void:
	var heroes: Array[HeroStats] = _plushie_heroes()
	assert_eq(heroes.size(), 4, "Pip, Böbö, BamBam, Robbar")
	var banane: float = ShamblerLook.OUTLINE * BananePuppet.DRAW_SCALE
	for hero: HeroStats in heroes:
		var puppet: PlushiePuppet = _spawn(0, hero).get_node("Puppet") as PlushiePuppet
		assert_not_null(puppet, String(hero.id))
		if puppet == null:
			continue
		assert_almost_eq(puppet.outline_pixels(), banane, 0.01, String(hero.id))
		assert_eq(puppet.outline_color(), BananePuppet.OUTLINE_COLOR, String(hero.id))


func test_ac90_plushie_heroes_are_drawn_in_calm_colours() -> void:
	for hero: HeroStats in _plushie_heroes():
		var puppet: PlushiePuppet = _spawn(0, hero).get_node("Puppet") as PlushiePuppet
		var colors: Array[Color] = [
			puppet.look.body_color,
			puppet.look.accent_color,
			puppet.look.detail_color,
			puppet.look.patch_color,
		]
		for color: Color in colors:
			assert_false(UiColors.is_danger(color), "%s %s" % [hero.id, color.to_html()])
		assert_eq(puppet.look.shape, hero.plushie.shape, "the town plushie's own look")


func test_the_outline_is_much_darker_than_every_floor() -> void:
	var ink: float = WorldPalette.brightness(BananePuppet.OUTLINE_COLOR)
	for color: Color in _floor_colors():
		var gap: float = WorldPalette.brightness(color) - ink
		assert_gt(gap, OUTLINE_CONTRAST, color.to_html())


func test_ac90_the_outline_stands_out_on_every_dusk_floor_too() -> void:
	var ink: float = WorldPalette.brightness(BananePuppet.OUTLINE_COLOR * PALETTE.dusk_tint)
	for color: Color in _floor_colors():
		var gap: float = WorldPalette.brightness(color * PALETTE.dusk_tint) - ink
		assert_gt(gap, DUSK_OUTLINE_CONTRAST, color.to_html())


func test_every_player_has_a_marker_in_their_own_colour() -> void:
	var first: HeroMarker = _spawn(0).get_node("Marker") as HeroMarker
	var second: HeroMarker = _spawn(1).get_node("Marker") as HeroMarker
	assert_eq(first.color, UiColors.PLAYER_MARKERS[0])
	assert_eq(second.color, UiColors.PLAYER_MARKERS[1])
	assert_ne(first.color, second.color)
	assert_lt(first.z_index, 0, "the ring lies on the floor, under zombies and shots")


func test_ac90_every_hero_stands_on_their_ring() -> void:
	for hero: HeroStats in HEROES.heroes:
		var player: Player = _spawn(1, hero)
		var marker: HeroMarker = player.get_node("Marker") as HeroMarker
		assert_eq(marker.color, UiColors.PLAYER_MARKERS[1], String(hero.id))
		var puppet: Node2D = player.get_node("Puppet") as Node2D
		assert_gt(marker.get_index(), -1)
		assert_lt(marker.get_index(), puppet.get_index(), "the ring is under the hero")


func test_marker_colours_stand_out_from_every_floor_and_are_not_danger() -> void:
	for marker: Color in UiColors.PLAYER_MARKERS:
		assert_false(UiColors.is_danger(marker), marker.to_html())
		for color: Color in _floor_colors():
			var gap: float = WorldPalette.brightness(color) - WorldPalette.brightness(marker)
			assert_gt(gap, MARKER_CONTRAST, "%s on %s" % [marker.to_html(), color.to_html()])
			var dusk_floor: float = WorldPalette.brightness(color * PALETTE.dusk_tint)
			var dusk_ring: float = WorldPalette.brightness(marker * PALETTE.dusk_tint)
			assert_gt(dusk_floor - dusk_ring, DUSK_MARKER_CONTRAST, "%s at dusk" % marker.to_html())
