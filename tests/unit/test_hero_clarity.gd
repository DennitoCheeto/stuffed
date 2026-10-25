extends GutTest
## The hero stays easy to find on the light Sunny patchwork floors (#172, vision §6): Banane has
## the zombies' dark outline, and every player has a coloured ring under their feet that stands
## out from every floor colour and never looks like danger.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
## How much darker than every floor colour the hero's outline and ring must be.
const OUTLINE_CONTRAST: float = 0.5
const MARKER_CONTRAST: float = 0.2


func _floor_colors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
	return colors


func _spawn(index: int) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.player_index = index
	add_child_autofree(player)
	return player


func test_banane_has_the_zombies_dark_outline() -> void:
	var puppet: BananePuppet = _spawn(0).get_node("Puppet") as BananePuppet
	var pieces: Array[FeltPiece] = puppet.outlined_pieces()
	assert_gte(pieces.size(), 9, "feet, body, hood, beak and flaps")
	for piece: FeltPiece in pieces:
		assert_eq(piece.outline_width, ShamblerLook.OUTLINE)
		assert_eq(piece.outline_color, BananePuppet.OUTLINE_COLOR)


func test_the_outline_is_much_darker_than_every_floor() -> void:
	var ink: float = WorldPalette.brightness(BananePuppet.OUTLINE_COLOR)
	for color: Color in _floor_colors():
		var gap: float = WorldPalette.brightness(color) - ink
		assert_gt(gap, OUTLINE_CONTRAST, color.to_html())


func test_every_player_has_a_marker_in_their_own_colour() -> void:
	var first: HeroMarker = _spawn(0).get_node("Marker") as HeroMarker
	var second: HeroMarker = _spawn(1).get_node("Marker") as HeroMarker
	assert_eq(first.color, UiColors.PLAYER_MARKERS[0])
	assert_eq(second.color, UiColors.PLAYER_MARKERS[1])
	assert_ne(first.color, second.color)
	assert_lt(first.z_index, 0, "the ring lies on the floor, under zombies and shots")


func test_marker_colours_stand_out_from_every_floor_and_are_not_danger() -> void:
	for marker: Color in UiColors.PLAYER_MARKERS:
		assert_false(UiColors.is_danger(marker), marker.to_html())
		for color: Color in _floor_colors():
			var gap: float = WorldPalette.brightness(color) - WorldPalette.brightness(marker)
			assert_gt(gap, MARKER_CONTRAST, "%s on %s" % [marker.to_html(), color.to_html()])
