extends "res://tests/scenarios/run_scenario.gd"
## M6-13 (spec 10 §11, AC-116): every new M6 visual (evolution behaviours, snowmen, slam ring,
## peels, stitch threads, chain pins, tangles, the evolution pulse, hint notes, the low-health
## heart) uses no danger colour, and the evolution effects drawn on the floor stay quieter than
## the zombies' ink on every floor (dusk too). ProjectileLook's shot colours are checked in
## test_clarity_ladder.gd; the draw-call limit with real GPU in `tools/benchmark.gd -- --evolutions`.

const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const MOMENT: EvolutionMomentRules = preload("res://data/ui/evolution_moment.tres")
const LOW_HEALTH: LowHealthRules = preload("res://data/ui/low_health.tres")
const ColorSweep: GDScript = preload("res://tests/scenarios/color_sweep.gd")
## Shot tint colours on WeaponStats that are 0-alpha "no tint" placeholders.
const SEE_THROUGH: float = 0.01


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## The colours in the data of every evolved weapon's own behaviour (peel trail, stitch-up,
## chain pins, tangle, snowmen, slam) and the evolution moment.
func _evolution_colors() -> Dictionary[String, Color]:
	var found: Dictionary[String, Color] = {}
	for evolution: EvolutionDef in POOL.evolutions:
		var stats: WeaponStats = evolution.evolved
		for property: Dictionary in stats.get_property_list():
			var value: Variant = stats.get(String(property["name"]))
			if value is Resource and not value is Script and not value is Texture2D:
				var i: int = 0
				for color: Color in ColorSweep.colors_of(value as Resource):
					if color.a > SEE_THROUGH:
						found["%s.%s[%d]" % [stats.id, property["name"], i]] = color
					i += 1
	var j: int = 0
	for color: Color in ColorSweep.colors_of(MOMENT):
		if color.a > SEE_THROUGH:
			found["evolution_moment[%d]" % j] = color
		j += 1
	return found


func test_ac116_evolution_behaviours_use_no_danger_colour() -> void:
	var colors: Dictionary[String, Color] = _evolution_colors()
	assert_gt(colors.size(), 6, "every evolution's look is swept")
	for name: String in colors:
		assert_false(UiColors.is_danger(colors[name]), "%s %s" % [name, colors[name].to_html()])


func test_ac116_evolution_effects_stay_quieter_than_the_zombies() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	var colors: Dictionary[String, Color] = _evolution_colors()
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var danger_gap: float = absf(floor - ink)
		for name: String in colors:
			var gap: float = absf(floor - WorldPalette.brightness(colors[name]))
			assert_lt(gap, danger_gap, "%s on %s" % [name, floor_color.to_html()])


func test_ac116_the_low_health_heart_is_never_red() -> void:
	# The heart patch's rose, from resting to the brightest point of a beat.
	for step: int in 11:
		var pulse: float = step / 10.0
		var color: Color = UiColors.HEALTH.lightened(LOW_HEALTH.pulse_lighten * pulse)
		assert_false(UiColors.is_danger(color), "pulse %.1f: %s" % [pulse, color.to_html()])


func test_ac116_live_m6_visuals_use_no_danger_colour() -> void:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	var hero: Player = first_player()
	for i: int in 24:
		var at: Vector2 = hero.global_position + Vector2.from_angle(TAU * i / 24.0) * 260.0
		run.enemies.spawn(run.spawner.schedule.entries[0].enemy, at)
	for evolution: EvolutionDef in POOL.evolutions:
		hero.add_weapon(evolution.evolved)
	run.evolution_moment.evolved(hero.weapons()[-1])
	hero.health = hero.max_health * LOW_HEALTH.threshold * 0.5
	RunHints.of(run).show_now("level_up")
	await wait_seconds(3.0)
	var swept: Array[Node] = [hero, RunHints.of(run), run.hud.spare_heart]
	for shot: Node in run.projectiles.get_children():
		if not shot is EnemyBullet:
			swept.append(shot)
	swept.append_array(run.find_children("*", "EvolutionPulse", true, false))
	var count: int = 0
	for node: Node in swept:
		for color: Color in _own_colors(node):
			count += 1
			assert_false(UiColors.is_danger(color), "%s %s" % [node.name, color.to_html()])
	assert_gt(count, 50, "the sweep found the effects")


## The colours `node` and its children carry, without the hero's own puppet (Banane's oranges
## are swept in test_08) and without zombies.
func _own_colors(node: Node) -> Array[Color]:
	if node is Player:
		var colors: Array[Color] = []
		for child: Node in node.get_children():
			if child.name != "Puppet":
				colors.append_array(ColorSweep.colors_of(child))
		return colors
	return ColorSweep.colors_of(node)
