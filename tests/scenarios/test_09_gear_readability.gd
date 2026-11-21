extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 09 §12, AC-104): no gear visual (the pieces at every stitch level, the Raincoat
## puddle, the Propeller Cap thump, the Jingle Bell shockwave, golden buttons, the apron snack,
## the Lookout ring, the spinning key) uses a danger colour, and on every floor (dusk too) the
## zombies' ink outline keeps the strongest contrast. The +3 draw call limit is checked in
## `test_09_gear_on_hero.gd`, the sewing table in the fit check, real-GPU fps with
## `tools/benchmark.gd -- --gear`.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const RULES: GearRules = preload("res://data/gear/gear_rules.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const ColorSweep: GDScript = preload("res://tests/scenarios/color_sweep.gd")
const TOP_LEVEL: int = 3


func _pieces_in(slot: GearDef.Slot) -> Array[GearDef]:
	var found: Array[GearDef] = []
	for piece: GearDef in RULES.pieces:
		if piece.slot == slot:
			found.append(piece)
	return found


## Every colour a gear effect is drawn with on the floor or around the hero.
func _effect_colors() -> Array[Color]:
	var colors: Array[Color] = [XpButtonLook.GOLDEN_COLOR, ApronSnack.COOKIE, ApronSnack.CRUMBS]
	for piece: GearDef in RULES.pieces:
		# Rings (Lookout, thump, shockwave) and the spinning key use the piece colour.
		colors.append(piece.color)
		if piece.effect_color.a > 0.0:
			colors.append(piece.effect_color)
		if piece.id == &"raincoat":
			# The puddle's rim, pool, ripples and glint (#328).
			colors.append_array(RaincoatPuddle.look_colors(piece.effect_color))
	return colors


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## A hero wearing `pieces` at stitch Lv 3, added to the run at `at`.
func _hero_wearing(run: Run, pieces: Array[GearDef], at: Vector2) -> Player:
	var hero: Player = PLAYER_SCENE.instantiate() as Player
	hero.stats = first_player().stats
	hero.player_index = 1
	var worn: WornGear = WornGear.new()
	for piece: GearDef in pieces:
		worn.pieces.append(piece)
		worn.levels[piece.id] = TOP_LEVEL
	hero.gear = worn
	hero.position = at
	run.actors.add_child(hero)
	return hero


## Makes every effect the hero's pieces have show up at once.
func _show_effects(hero: Player) -> void:
	hero.dashed.emit(hero.global_position, Vector2.RIGHT)
	hero.dash_landed.emit(hero.global_position + Vector2(60.0, 0.0))
	var apron: PicnicApron = hero.get_node_or_null("PicnicApron") as PicnicApron
	if apron != null:
		apron.drop()
	var bell: JingleBell = hero.get_node_or_null("JingleBell") as JingleBell
	if bell != null:
		bell.ring()
	var key: WindUpKey = hero.get_node_or_null("WindUpKey") as WindUpKey
	if key != null:
		key.wind_up()


## The colours of what the gear adds to `hero`: its effect nodes (with their puddles, snacks and
## rings) and the worn pieces' sprites. The hero's own puppet is swept in test_08.
func _gear_colors(hero: Player) -> Array[Color]:
	var colors: Array[Color] = []
	for child: Node in hero.get_children():
		var script: Script = child.get_script() as Script
		if script != null and script.resource_path.begins_with("res://src/gear/"):
			colors.append_array(ColorSweep.colors_of(child))
	var puppet: Node = hero.get_node("Puppet")
	colors.append_array(ColorSweep.colors_of(puppet.get("gear_view") as Node))
	return colors


func test_ac104_no_gear_piece_or_effect_uses_a_danger_colour() -> void:
	for color: Color in _effect_colors():
		assert_false(UiColors.is_danger(color), color.to_html())
	for piece: GearDef in RULES.pieces:
		for level: int in range(1, TOP_LEVEL + 1):
			for color: Color in GearLook.colors(piece, level):
				var text: String = "%s Lv %d %s" % [piece.id, level, color.to_html()]
				assert_false(UiColors.is_danger(color), text)


func test_ac104_live_gear_effects_use_no_danger_colour() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	var heads: Array[GearDef] = _pieces_in(GearDef.Slot.HEAD)
	var bodies: Array[GearDef] = _pieces_in(GearDef.Slot.BODY)
	var charms: Array[GearDef] = _pieces_in(GearDef.Slot.CHARM)
	var start: Vector2 = first_player().global_position
	for i: int in heads.size():
		var pieces: Array[GearDef] = [heads[i], bodies[i], charms[i]]
		var hero: Player = _hero_wearing(run, pieces, start + Vector2(0.0, 200.0 * (i + 1)))
		await wait_physics_frames(2)
		_show_effects(hero)
		await wait_physics_frames(2)
		var swept: Array[Color] = _gear_colors(hero)
		assert_true(swept.has(bodies[i].effect_color), "%s effect is in the sweep" % bodies[i].id)
		for color: Color in swept:
			assert_false(UiColors.is_danger(color), "%s: %s" % [heads[i].id, color.to_html()])
		hero.queue_free()
		await wait_physics_frames(1)


func test_ac104_golden_buttons_stay_below_the_danger_hue() -> void:
	var gold: Color = XpButtonLook.GOLDEN_COLOR
	assert_false(UiColors.is_danger(gold))
	assert_gt(gold.h, UiColors.DANGER_HUE_LOW, "yellow, not orange")


func test_ac104_zombies_keep_the_strongest_contrast_on_every_floor() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var danger_gap: float = absf(floor - ink)
		for color: Color in _effect_colors():
			var gap: float = absf(floor - WorldPalette.brightness(color))
			assert_lt(gap, danger_gap, "%s on %s" % [color.to_html(), floor_color.to_html()])
