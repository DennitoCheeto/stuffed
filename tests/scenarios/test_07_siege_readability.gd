extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 07 §7, AC-83): a siege with every building at its top level and plushies
## helping shows all siege visuals at once: turret shots, the Watchtower's pins, the healing
## ring, the confetti trap and its pop, the stuffing balls, a knocked-out plushie's dizzy stars,
## the fort bar (also nearly down), the wave counter, building bars, the fort arrow, dusk and its
## fairy lights, and the moon calendar in town. None of them uses a danger colour
## (UiColors.is_danger): red/orange belongs to the enemies (hard rule 9). On the dusk town the
## zombies' dark outline keeps the strongest contrast against the floor.

const ColorSweep: GDScript = preload("res://tests/scenarios/color_sweep.gd")
const TANK: EnemyStats = preload("res://data/enemies/tank.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const VERY_TOUGH: float = 1000000.0
## Where the test zombies stand, from a turret or ring (pixels).
const NEAR: Vector2 = Vector2(90.0, 110.0)

var siege: Siege


func _assert_calm(what: String, root: Object) -> void:
	var colors: Array[Color] = ColorSweep.colors_of(root)
	assert_gt(colors.size(), 0, "%s carries colours" % what)
	for color: Color in colors:
		assert_false(UiColors.is_danger(color), "%s uses danger %s" % [what, color.to_html()])


## Every building at Lv 3, Böbö (brown: danger if not calmed) and Pip in town, horde due.
func _start_full_siege() -> Siege:
	for spot: TownSpot in LAYOUT.spots:
		main.town.building_levels[String(spot.id)] = 3
		main.town.revealed.append(String(spot.id))
	main.town.plushies["bobo"] = "in_town"
	main.town.plushies["pip"] = "in_town"
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	return main.current_screen as Siege


func _tough(at: Vector2) -> Zombie:
	var zombie: Zombie = siege.enemies.spawn(TANK, at)
	zombie.max_health = VERY_TOUGH
	zombie.health = VERY_TOUGH
	zombie.move_speed = 0.0
	return zombie


func _our_shots() -> Array[Projectile]:
	var shots: Array[Projectile] = []
	for shot: Projectile in siege.projectiles.active:
		if not shot is EnemyBullet and shot.weapon != null and shot.weapon.is_turret():
			shots.append(shot)
	return shots


func _confetti() -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in siege.effects.get_children():
		if child is ConfettiBlast:
			found.append(child)
	return found


func test_ac83_no_siege_visual_uses_a_danger_colour() -> void:
	siege = await _start_full_siege()
	assert_not_null(siege)
	if siege == null:
		return
	siege.waves.finished = true
	siege.enemies.kill_all()
	var hero: Player = first_player()
	hero.invincible = true
	disarm(hero)
	for id: StringName in siege.turrets:
		_tough(siege.turrets[id].position + NEAR)
	var trap: SiegeConfettiTrap = siege.rings[&"party_shop"] as SiegeConfettiTrap
	_tough(trap.position + NEAR)
	hero.global_position = siege.rings[&"snack_bar"].position + Vector2(0.0, 150.0)
	hero.health = hero.max_health * 0.5
	siege.fort.hurt(siege.fort.max_health * 0.8)
	siege.targets.building(&"lucky_jar").hurt(10.0)
	var dizzy: SiegePlushie = siege.plushies["bobo"]
	dizzy.target.hurt(VERY_TOUGH)
	for i: int in roundi(6.0 * FPS):
		if trap.pops > 0 and _our_shots().size() > 0:
			break
		await wait_physics_frames(1)
	assert_gt(trap.pops, 0, "the confetti trap popped")
	assert_gt(_our_shots().size(), 0, "the turrets fire")
	assert_true(dizzy.is_out(), "a knocked-out plushie with dizzy stars")
	assert_eq(siege.fort_bar.fill_color(), FortHealthBar.LOW_COLOR, "the fort bar warns")
	for shot: Projectile in _our_shots():
		_assert_calm("turret shot %s" % shot.weapon.stats.id, shot)
	for id: StringName in siege.turrets:
		_assert_calm("turret %s" % id, siege.turrets[id])
	for id: StringName in siege.rings:
		_assert_calm("ring %s" % id, siege.rings[id])
	assert_gt(_confetti().size(), 0, "the trap's confetti")
	for confetti: Node in _confetti():
		_assert_calm("trap confetti", confetti)
	for id: String in siege.plushies:
		_assert_calm("plushie %s" % id, siege.plushies[id])
	_assert_calm("fort bar", siege.fort_bar)
	_assert_calm("wave counter", siege.wave_counter)
	for id: StringName in siege.building_bars:
		_assert_calm("building bar %s" % id, siege.building_bars[id])
	_assert_calm("edge arrows", siege.pickup_arrows)
	_assert_calm("dusk", siege.town_arena().dusk)
	assert_false(UiColors.is_danger(RULES.heal_ring_color))
	assert_false(UiColors.is_danger(RULES.trap_ring_color))
	assert_false(UiColors.is_danger(RULES.plushie_halo))
	assert_false(UiColors.is_danger(RULES.dizzy_color))


func test_ac83_the_calendar_and_the_dusk_town_have_no_danger_colour() -> void:
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	await wait_physics_frames(2)
	assert_not_null(town.dusk)
	_assert_calm("moon calendar", town.calendar)
	if town.dusk != null:
		_assert_calm("town dusk", town.dusk)


## On the dusk town the zombies' dark outline stands out from every floor colour more than any
## siege visual lying on the floor (rings, plushie halo, fairy lights): the danger reads first.
func test_ac83_zombies_keep_the_strongest_contrast_at_dusk() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	var ours: Array[Color] = [RULES.heal_ring_color, RULES.trap_ring_color, RULES.plushie_halo]
	ours.append(RULES.dizzy_color)
	ours.append(PALETTE.dusk_glow)
	ours.append_array(PALETTE.fairy_lights)
	for group: Array in PALETTE.floor_groups():
		for floor_color: Color in group:
			var dusk: float = WorldPalette.brightness(floor_color * PALETTE.dusk_tint)
			var zombie_gap: float = dusk - ink
			for color: Color in ours:
				var gap: float = absf(dusk - WorldPalette.brightness(color * PALETTE.dusk_tint))
				assert_gt(
					zombie_gap,
					gap,
					"%s on %s at dusk" % [color.to_html(), floor_color.to_html()],
				)
