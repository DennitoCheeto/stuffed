extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 11 §3, §4.3, §4.4, AC-120, AC-123, AC-124): a maxed Stuffing Cloud + Extra
## Stuffing evolves into Comfy Cloud, which drops fluff puffs while its hero walks (at most 8) that
## hurt zombies on the cloud's beat, and every zombie it pops mends its hero (capped per second).
## A maxed Thimble Mortar + Big Spool evolves into Hopscotch Mortar: each thimble hops onward twice
## after landing, a blast at every landing, the last one bigger, the ring showing the next spot.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const COMFY: WeaponStats = preload("res://data/weapons/comfy_cloud.tres")
const HOPSCOTCH: WeaponStats = preload("res://data/weapons/hopscotch_mortar.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
## Health that no hit in these scenarios can take away.
const TOUGH: float = 100000.0

var run: Run


func before_each() -> void:
	RecipeBook.seen.clear()
	await super()


func after_each() -> void:
	RecipeBook.seen.clear()
	super()


func _quiet_run() -> void:
	run = await start_run()
	run.spawner.active = false
	run.pickups.process_mode = Node.PROCESS_MODE_DISABLED
	disarm(first_player())
	first_player().invincible = true


## Gives player 1 the recipe of `evolved_id` and evolves it with a gift box. Returns the weapon.
func _evolve(evolved_id: StringName) -> Weapon:
	var pool: UpgradePool = run.upgrade_pool
	var evolution: EvolutionDef = pool.evolution_into(evolved_id)
	var hero: Player = first_player()
	var base: UpgradeDef = pool.find(evolution.weapon)
	hero.add_weapon(base.weapon).level = base.top_level()
	hero.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	run.drop_gift_box(hero.global_position)
	await _wait_until(run.gift_screen.is_open, 1.0)
	run.gift_screen.close()
	await wait_physics_frames(1)
	return hero.weapon(evolved_id)


func _zombie(at: Vector2, health: float = TOUGH) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.health = health
	zombie.move_speed = 0.0
	return zombie


## Waits up to `seconds` until `done` returns true.
func _wait_until(done: Callable, seconds: float) -> bool:
	for i: int in roundi(seconds * FPS):
		if done.call():
			return true
		await wait_physics_frames(1)
	return done.call()


## Waits `seconds` of run time (slow motion right after an evolution stretches frames).
func _wait_seconds(seconds: float) -> void:
	var until: float = run.elapsed + seconds
	await _wait_until(func() -> bool: return run.elapsed >= until, seconds * 4.0)


func _hops(mortar: Weapon) -> Array[HopscotchProjectile]:
	var result: Array[HopscotchProjectile] = []
	for shot: Projectile in run.projectiles.fired_by(mortar):
		if shot is HopscotchProjectile:
			result.append(shot as HopscotchProjectile)
	return result


func test_ac120_stuffing_cloud_and_extra_stuffing_become_comfy_cloud() -> void:
	await _quiet_run()
	var comfy: ComfyCloud = await _evolve(&"comfy_cloud") as ComfyCloud
	assert_not_null(comfy, "Stuffing Cloud + Extra Stuffing = Comfy Cloud")
	var hero: Player = first_player()
	assert_null(hero.weapon(&"stuffing_cloud"), "the cloud is replaced")
	assert_true(hero.upgrade_levels().has(&"extra_stuffing"), "the item stays")


func test_ac123_walking_drops_puffs_standing_still_does_not() -> void:
	await _quiet_run()
	var comfy: ComfyCloud = await _evolve(&"comfy_cloud") as ComfyCloud
	await _wait_seconds(1.0)
	assert_eq(comfy.trail.count(), 0, "no puffs while standing still")
	var start: Vector2 = first_player().global_position
	var until: float = run.elapsed + 1.3
	await hold_action("p1_move_right", roundi(1.3 * FPS))
	while run.elapsed < until:
		await wait_physics_frames(1)
	var dropped: int = comfy.trail.count()
	assert_between(dropped, 2, 4, "a puff every 0.4 s of walking")
	var first: Vector2 = comfy.trail.spots()[0]
	assert_gt(first.x, start.x, "dropped along the way")
	assert_lt(first.x, first_player().global_position.x - 20.0, "behind the hero")


func test_ac123_at_most_eight_puffs_the_oldest_goes() -> void:
	await _quiet_run()
	var comfy: ComfyCloud = await _evolve(&"comfy_cloud") as ComfyCloud
	var hero: Vector2 = first_player().global_position
	for i: int in 11:
		comfy.trail.drop(hero + Vector2(400 + i * 10, 0))
	assert_eq(comfy.trail.count(), COMFY.comfy_fluff.max_puffs)
	assert_eq(comfy.trail.spots()[0], hero + Vector2(430, 0), "the first three went")


func test_ac123_puffs_hurt_zombies_inside_on_the_beat_then_go() -> void:
	await _quiet_run()
	var comfy: ComfyCloud = await _evolve(&"comfy_cloud") as ComfyCloud
	var hero: Vector2 = first_player().global_position
	var spot: Vector2 = hero + Vector2(0, 400)
	var inside: Zombie = _zombie(spot + Vector2(10, 0))
	var outside: Zombie = _zombie(spot + Vector2(120, 0))
	comfy.trail.drop(spot)
	await _wait_seconds(1.0)
	var beats: float = 1.0 / comfy.current().cooldown
	var hit: float = COMFY.comfy_fluff.puff_damage
	assert_almost_eq(TOUGH - inside.health, hit * beats, hit * 1.5, "5 damage on each beat")
	assert_eq(outside.health, TOUGH, "a zombie outside the puff is safe")
	await _wait_seconds(COMFY.comfy_fluff.puff_seconds)
	assert_eq(comfy.trail.count(), 0, "gone after 3 s")
	var after: float = inside.health
	await _wait_seconds(0.7)
	assert_eq(inside.health, after, "and hurts no more")


func test_ac123_pops_in_the_cloud_mend_the_hero_capped_per_second() -> void:
	await _quiet_run()
	var comfy: ComfyCloud = await _evolve(&"comfy_cloud") as ComfyCloud
	var hero: Player = first_player()
	hero.health = hero.max_health * 0.5
	var before: float = hero.health
	for i: int in 12:
		_zombie(hero.global_position + Vector2.from_angle(TAU * i / 12.0) * 80.0, 1.0)
	await _wait_seconds(0.5)
	var fluff: ComfyFluff = COMFY.comfy_fluff
	assert_gt(comfy.trail.mended, 0.0)
	var mended: float = hero.health - before
	assert_gt(mended, 0.0, "pops in the cloud mend the hero")
	assert_lte(mended, fluff.mend_per_second * 1.0 + 0.01, "at most 4 health per second")
	assert_eq(comfy.trail.mended, mended)


func test_ac123_only_the_cloud_s_own_kills_mend() -> void:
	await _quiet_run()
	var comfy: ComfyCloud = await _evolve(&"comfy_cloud") as ComfyCloud
	comfy.set_physics_process(false)
	var hero: Player = first_player()
	hero.health = hero.max_health * 0.5
	var whip: Weapon = hero.add_weapon(run.upgrade_pool.find(&"thread_whip").weapon)
	whip.set_physics_process(false)
	var before: float = hero.health
	var other: Zombie = _zombie(hero.global_position + Vector2(0, 400), 1.0)
	run.enemies.damage(other, 10.0, Vector2.ZERO, whip)
	await _wait_seconds(0.3)
	assert_eq(hero.health, before, "a pop by another weapon mends nothing")
	var own: Zombie = _zombie(hero.global_position + Vector2(0, 400), 1.0)
	run.enemies.damage(own, 10.0, Vector2.ZERO, comfy)
	assert_eq(hero.health, before + COMFY.comfy_fluff.mend_per_kill, "a pop by the cloud mends")


func test_ac120_thimble_mortar_and_big_spool_become_hopscotch_mortar() -> void:
	await _quiet_run()
	var mortar: HopscotchMortar = await _evolve(&"hopscotch_mortar") as HopscotchMortar
	assert_not_null(mortar, "Thimble Mortar + Big Spool = Hopscotch Mortar")
	var hero: Player = first_player()
	assert_null(hero.weapon(&"thimble_mortar"), "the mortar is replaced")
	assert_true(hero.upgrade_levels().has(&"big_spool"), "the item stays")


func test_ac124_a_thimble_hops_twice_onward_a_blast_at_every_landing() -> void:
	await _quiet_run()
	var mortar: HopscotchMortar = await _evolve(&"hopscotch_mortar") as HopscotchMortar
	mortar.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var hop: float = HOPSCOTCH.hopscotch.hop_distance
	var area: float = mortar.current().area
	var first: Vector2 = hero + Vector2(200, 0)
	var spots: Array[Zombie] = []
	for i: int in 3:
		spots.append(_zombie(first + Vector2(hop * i, 0)))
	# Just past a normal blast at the last landing, inside the bigger one.
	var edge: Zombie = _zombie(first + Vector2(hop * 2.0 + area * 1.15, 0))
	var beyond: Zombie = _zombie(first + Vector2(hop * 3.0 + area * 1.5, 0))
	var thimble: HopscotchProjectile = (
		run.projectiles.spawn(HopscotchProjectile) as HopscotchProjectile
	)
	thimble.launch(mortar, first)
	await _wait_until(func() -> bool: return _hops(mortar).size() > 1, 3.0)
	var next: HopscotchProjectile = _hops(mortar).filter(_is_hop.bind(1))[0]
	assert_almost_eq(next.global_position.x, first.x + hop, 0.5, "the ring sits on the next spot")
	assert_lt(next.fill_share(), 1.0, "and fills in while it hops")
	await _wait_until(func() -> bool: return _hops(mortar).is_empty(), 4.0)
	for i: int in 3:
		assert_lt(spots[i].health, TOUGH, "landing %d is a blast" % (i + 1))
	assert_lt(edge.health, TOUGH, "the last blast is bigger")
	assert_eq(beyond.health, TOUGH, "only two hops")


func _is_hop(shot: HopscotchProjectile, index: int) -> bool:
	return shot.hop == index


func test_ac124_the_last_blast_is_bigger_and_hops_go_away_from_the_hero() -> void:
	await _quiet_run()
	var mortar: HopscotchMortar = await _evolve(&"hopscotch_mortar") as HopscotchMortar
	mortar.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var thimble: HopscotchProjectile = (
		run.projectiles.spawn(HopscotchProjectile) as HopscotchProjectile
	)
	thimble.launch(mortar, hero + Vector2(-150, -150))
	var normal: float = thimble.blast_radius()
	assert_almost_eq(normal, mortar.current().area, 0.01)
	assert_eq(thimble.hops_left(), HOPSCOTCH.hopscotch.hops)
	assert_true(thimble.direction().is_equal_approx(Vector2(-1, -1).normalized()), "away")
	var last: HopscotchProjectile = (
		run.projectiles.spawn(HopscotchProjectile) as HopscotchProjectile
	)
	last.hop_from(mortar, hero, thimble.direction(), HOPSCOTCH.hopscotch.hops)
	assert_eq(last.hops_left(), 0)
	var bigger: float = normal * HOPSCOTCH.hopscotch.last_blast_scale
	assert_almost_eq(last.blast_radius(), bigger, 0.01, "1.3x")
	assert_almost_eq(last.ring_radius(), bigger, 0.5, "and its ring shows it")


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## The puff and thimble looks are ProjectileLook parts (swept by test_clarity_ladder); the mend
## sparkle is tinted in data.
func test_spec11_10_mend_sparkle_is_calm_and_quieter_than_the_zombies() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	var color: Color = COMFY.comfy_fluff.mend_color
	assert_false(UiColors.is_danger(color), "no danger colour")
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var gap: float = absf(floor - WorldPalette.brightness(color))
		assert_lt(gap, absf(floor - ink), floor_color.to_html())
