extends "res://tests/scenarios/run_scenario.gd"
## Spec 11 §10 (AC-129): every new visual of the six spec 11 evolutions (threads, tumbling
## zombies, fluff puffs, mend sparkle, hop rings, lasso rope, zipper halves) uses no danger colour
## and stays quieter than the zombies' ink on every floor (dusk too); a tumbling zombie keeps its
## normal zombie look. ProjectileLook's shot parts are swept in test_clarity_ladder.gd; the draw
## calls with a real GPU in `tools/benchmark.gd -- --new-evolutions` / `--new-bases`.

const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ColorSweep: GDScript = preload("res://tests/scenarios/color_sweep.gd")
const NEW_EVOLUTIONS: Array[StringName] = [
	&"cats_cradle",
	&"bowling_buttons",
	&"comfy_cloud",
	&"hopscotch_mortar",
	&"lasso_lash",
	&"unzipper",
]
## Shot tint colours that are 0-alpha "no tint" placeholders.
const SEE_THROUGH: float = 0.01
const TOUGH: float = 100000.0

var run: Run


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## Every colour in the data of `stats`' own sub-resources (look, behaviour rules).
func _data_colors(stats: WeaponStats) -> Dictionary[String, Color]:
	var found: Dictionary[String, Color] = {}
	for property: Dictionary in stats.get_property_list():
		var value: Variant = stats.get(String(property["name"]))
		if value is Resource and not value is Script and not value is Texture2D:
			var i: int = 0
			for color: Color in ColorSweep.colors_of(value as Resource):
				if color.a > SEE_THROUGH:
					found["%s.%s[%d]" % [stats.id, property["name"], i]] = color
				i += 1
	return found


func test_ac129_the_new_evolutions_data_colours_are_calm_and_quieter_than_zombies() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for evolved_id: StringName in NEW_EVOLUTIONS:
		var stats: WeaponStats = POOL.evolution_into(evolved_id).evolved
		var colors: Dictionary[String, Color] = _data_colors(stats)
		assert_gt(colors.size(), 1, "%s has its look swept" % evolved_id)
		for name: String in colors:
			assert_false(UiColors.is_danger(colors[name]), "%s %s" % [name, colors[name].to_html()])
			for floor_color: Color in _floors():
				var floor: float = WorldPalette.brightness(floor_color)
				var gap: float = absf(floor - WorldPalette.brightness(colors[name]))
				assert_lt(gap, absf(floor - ink), "%s on %s" % [name, floor_color.to_html()])


func _zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.max_health = TOUGH
	zombie.health = TOUGH
	zombie.move_speed = 0.0
	return zombie


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


func _helper(evolved_id: StringName, node_name: StringName) -> Node:
	return first_player().weapon(evolved_id).get_node_or_null(NodePath(node_name))


func _hopping() -> bool:
	for shot: Projectile in run.projectiles.fired_by(first_player().weapon(&"hopscotch_mortar")):
		if shot is HopscotchProjectile and (shot as HopscotchProjectile).hop > 0:
			return true
	return false


func _zipped() -> bool:
	return (_helper(&"unzipper", ZipperSeam.NAME) as ZipperSeam).shuts > 0


func test_ac129_live_new_evolution_visuals_use_no_danger_colour() -> void:
	run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	run.pickups.process_mode = Node.PROCESS_MODE_DISABLED
	var hero: Player = first_player()
	hero.invincible = true
	disarm(hero)
	var around: Vector2 = hero.global_position
	var crowd: Array[Zombie] = []
	for i: int in 24:
		crowd.append(_zombie(around + Vector2.from_angle(TAU * i / 24.0) * 150.0))
	for evolved_id: StringName in NEW_EVOLUTIONS:
		hero.add_weapon(POOL.evolution_into(evolved_id).evolved)
	await wait_physics_frames(2)
	# Every new effect on screen at once.
	(_helper(&"cats_cradle", CradleThreads.NAME) as CradleThreads).add(around, crowd[0].position)
	var lane: BowlingLane = _helper(&"bowling_buttons", BowlingLane.NAME) as BowlingLane
	lane.tumble(crowd[6], Vector2.DOWN)
	(_helper(&"comfy_cloud", FluffTrail.NAME) as FluffTrail).drop(around + Vector2(-60, 0))
	var rope: LassoRope = _helper(&"lasso_lash", LassoRope.NAME) as LassoRope
	assert_true(rope.rope_in(around.direction_to(crowd[0].global_position)), "a zombie roped")
	assert_true(lane.is_tumbling(crowd[6]), "a zombie tumbles")
	assert_eq(crowd[6].modulate, Color.WHITE, "a tumbling zombie keeps its zombie look")
	assert_true(await _wait_until(_hopping, 6.0), "a thimble hops")
	assert_true(await _wait_until(_zipped, 6.0), "the zipper snapped shut")
	var swept: Array[Node] = []
	for child: Node in hero.get_children():
		if child.name != "Puppet":
			swept.append(child)
	for shot: Node in run.projectiles.get_children():
		if not shot is EnemyBullet:
			swept.append(shot)
	var count: int = 0
	for node: Node in swept:
		for color: Color in ColorSweep.colors_of(node):
			count += 1
			assert_false(UiColors.is_danger(color), "%s %s" % [node.name, color.to_html()])
	assert_gt(count, 50, "the sweep found the effects")
