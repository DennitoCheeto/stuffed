extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 11 §3, §4.5, §4.6, AC-120, AC-125, AC-126): a maxed Thread Whip + Sharp Scissors
## evolves into Lasso Lash, which every 3rd lash ropes the toughest zombie in the front arc (an
## elite first, never a boss), swings it once around the hero through the crowd and throws it
## towards the cursor, where the snip hurts it; a boss takes the lash twice instead. A maxed
## Zipper Ray + Long Thread evolves into Unzipper: the beam splits, sweeps open to both sides,
## snaps shut and hits every zombie it swept again.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const BIG_TED: BossDef = preload("res://data/bosses/big_ted.tres")
const LASSO: WeaponStats = preload("res://data/weapons/lasso_lash.tres")
const UNZIPPER: WeaponStats = preload("res://data/weapons/unzipper.tres")
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
	first_player().facing = Vector2.RIGHT


## Gives player 1 the recipe of `evolved_id` and evolves it with a gift box. Returns the weapon
## (its own attacks stopped: the tests call `attack` themselves).
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
	var evolved: Weapon = hero.weapon(evolved_id)
	if evolved != null:
		evolved.set_physics_process(false)
	return evolved


func _zombie(at: Vector2, health: float = TOUGH) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.health = health
	zombie.max_health = maxf(zombie.max_health, health)
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


func _is_idle(lasso: LassoLash) -> bool:
	return not lasso.rope.is_busy()


func _is_throwing(lasso: LassoLash) -> bool:
	return lasso.rope.phase == LassoRope.Phase.THROW


func test_ac120_thread_whip_and_sharp_scissors_become_lasso_lash() -> void:
	await _quiet_run()
	var lasso: LassoLash = await _evolve(&"lasso_lash") as LassoLash
	assert_not_null(lasso, "Thread Whip + Sharp Scissors = Lasso Lash")
	var hero: Player = first_player()
	assert_null(hero.weapon(&"thread_whip"), "the whip is replaced")
	assert_true(hero.upgrade_levels().has(&"sharp_scissors"), "the item stays")


func test_ac125_every_third_lash_ropes_the_toughest_an_elite_first() -> void:
	await _quiet_run()
	var lasso: LassoLash = await _evolve(&"lasso_lash") as LassoLash
	var hero: Vector2 = first_player().global_position
	var big: Zombie = _zombie(hero + Vector2(110, -30), TOUGH * 2.0)
	var elite: Zombie = run.enemies.spawn(SHAMBLER, hero + Vector2(110, 30), ELITE)
	elite.health = TOUGH
	elite.move_speed = 0.0
	assert_true(lasso.attack())
	assert_true(lasso.attack())
	assert_false(lasso.rope.is_busy(), "the first two lashes rope nothing")
	assert_true(lasso.attack())
	assert_eq(lasso.rope.roped, elite, "the third ropes the elite before a tougher zombie")
	assert_true(elite.held, "and holds it")
	assert_false(big.held)
	await _wait_until(_is_idle.bind(lasso), 3.0)
	assert_false(elite.held, "let go after the throw")
	assert_true(lasso.attack())
	assert_true(lasso.attack())
	assert_true(lasso.attack())
	var next: Zombie = lasso.rope.roped
	assert_true(next == elite or next == big, "every 3rd lash again")


func test_ac125_without_an_elite_the_toughest_zombie_is_roped() -> void:
	await _quiet_run()
	var lasso: LassoLash = await _evolve(&"lasso_lash") as LassoLash
	var hero: Vector2 = first_player().global_position
	_zombie(hero + Vector2(110, -30))
	var big: Zombie = _zombie(hero + Vector2(110, 30), TOUGH * 2.0)
	_zombie(hero + Vector2(-110, 0), TOUGH * 3.0)
	assert_true(lasso.rope.rope_in(Vector2.RIGHT))
	assert_eq(lasso.rope.roped, big, "the toughest in the front arc, not the one behind")


func test_ac125_the_swing_hurts_the_crowd_then_the_throw_lands_at_the_cursor_and_snips() -> void:
	await _quiet_run()
	var lasso: LassoLash = await _evolve(&"lasso_lash") as LassoLash
	var hero: Player = first_player()
	var at: Vector2 = hero.global_position
	var rules: LassoThrow = LASSO.lasso_throw
	var roped: Zombie = _zombie(at + Vector2(rules.swing_radius, 0))
	var crowd: Array[Zombie] = []
	for angle: float in [PI * 0.5, PI, PI * 1.5]:
		crowd.append(_zombie(at + Vector2.from_angle(angle) * rules.swing_radius))
	var far: Zombie = _zombie(at + Vector2(0, 450))
	assert_true(lasso.rope.rope_in(Vector2.RIGHT))
	await _wait_seconds(rules.swing_seconds * 0.5)
	assert_almost_eq(
		roped.position.distance_to(at), rules.swing_radius, 2.0, "it swings round the hero"
	)
	await _wait_until(_is_throwing.bind(lasso), 2.0)
	for zombie: Zombie in crowd:
		var swing: float = rules.swing_damage * lasso.damage_scale()
		assert_almost_eq(TOUGH - zombie.health, swing, 0.01, "20 (+ items) to each one passed")
		assert_gt(zombie.position.distance_to(at), rules.swing_radius, "and pushed away")
	assert_eq(lasso.rope.swing_hits, 3, "each one once")
	assert_eq(far.health, TOUGH, "a zombie far away is safe")
	assert_eq(roped.health, TOUGH, "the swung zombie isn't hurt yet")
	var aim: Vector2 = hero.aim_point()
	await _wait_until(_is_idle.bind(lasso), 2.0)
	assert_almost_eq(roped.position.distance_to(aim), 0.0, 2.0, "thrown to the cursor")
	var snip: float = lasso.current().damage * rules.snip_factor
	assert_almost_eq(TOUGH - roped.health, snip, 0.01, "the snip: 3x the lash")
	assert_has(Sfx.history, rules.snip_sound, "with its sound")
	assert_eq(lasso.rope.snips, 1)


func test_ac125_a_held_zombie_never_hurts_the_hero() -> void:
	await _quiet_run()
	await _evolve(&"lasso_lash")
	var hero: Player = first_player()
	hero.invincible = false
	# Held right on top of the hero (as it passes close during a swing): still no harm.
	var roped: Zombie = _zombie(hero.global_position)
	roped.held = true
	var health: float = hero.health
	await _wait_seconds(0.5)
	assert_eq(hero.health, health, "held = no touch damage")
	roped.held = false
	await _wait_seconds(0.5)
	assert_lt(hero.health, health, "the same zombie let go does hurt")


func test_ac125_a_boss_is_never_roped_it_takes_the_lash_twice() -> void:
	await _quiet_run()
	var lasso: LassoLash = await _evolve(&"lasso_lash") as LassoLash
	var hero: Vector2 = first_player().global_position
	var ted: Zombie = run.enemies.spawn_boss(BIG_TED, hero + Vector2(120, 0))
	ted.health = TOUGH
	_zombie(hero + Vector2(110, 40))
	var before: float = ted.health
	assert_true(lasso.rope.rope_in(Vector2.RIGHT))
	assert_false(lasso.rope.is_busy(), "nothing roped while a boss is the big one")
	assert_false(ted.held)
	assert_eq(lasso.rope.boss_doubles, 1)
	assert_almost_eq(before - ted.health, lasso.current().damage, 0.01, "an extra lash")
	var elite: Zombie = run.enemies.spawn(SHAMBLER, hero + Vector2(100, -40), ELITE)
	elite.health = TOUGH
	assert_true(lasso.rope.rope_in(Vector2.RIGHT))
	assert_eq(lasso.rope.roped, elite, "with an elite there, the elite is roped")
	assert_false(ted.held, "never the boss")


func _halves(unzipper: Weapon) -> Array[UnzipperProjectile]:
	var result: Array[UnzipperProjectile] = []
	for shot: Projectile in run.projectiles.fired_by(unzipper):
		if shot is UnzipperProjectile:
			result.append(shot as UnzipperProjectile)
	return result


func _no_halves(unzipper: Weapon) -> bool:
	return _halves(unzipper).is_empty()


func test_ac120_zipper_ray_and_long_thread_become_unzipper() -> void:
	await _quiet_run()
	var unzipper: Unzipper = await _evolve(&"unzipper") as Unzipper
	assert_not_null(unzipper, "Zipper Ray + Long Thread = Unzipper")
	var hero: Player = first_player()
	assert_null(hero.weapon(&"zipper_ray"), "the ray is replaced")
	assert_true(hero.upgrade_levels().has(&"long_thread"), "the item stays")


func test_ac126_the_beam_splits_sweeps_open_to_both_sides_and_snaps_shut() -> void:
	await _quiet_run()
	var unzipper: Unzipper = await _evolve(&"unzipper") as Unzipper
	var sweep_rules: ZipperSweep = UNZIPPER.zipper_sweep
	var hero: Player = first_player()
	var aim: float = hero.global_position.direction_to(hero.aim_point()).angle()
	assert_true(unzipper.attack())
	var halves: Array[UnzipperProjectile] = _halves(unzipper)
	assert_eq(halves.size(), 2, "two halves")
	for half: UnzipperProjectile in halves:
		assert_almost_eq(half.rotation, aim, 0.01, "together at first, towards the cursor")
	assert_false(unzipper.attack(), "no new beam while one is out")
	var duration: float = unzipper.current().duration
	await _wait_seconds(duration * sweep_rules.open_share * 0.95)
	var open: float = deg_to_rad(sweep_rules.open_degrees)
	for half: UnzipperProjectile in halves:
		var off: float = angle_difference(aim, half.rotation)
		assert_almost_eq(off, half.side * open, 0.1, "each half swept ~50 deg to its side")
	await _wait_until(_no_halves.bind(unzipper), duration * 4.0)
	assert_eq(unzipper.seam.shuts, 1, "and zipped shut once")
	assert_has(Sfx.history, sweep_rules.shut_sound, "with its sound")


func test_ac126_every_swept_zombie_takes_the_zip_shut_hit() -> void:
	await _quiet_run()
	var unzipper: Unzipper = await _evolve(&"unzipper") as Unzipper
	var sweep_rules: ZipperSweep = UNZIPPER.zipper_sweep
	var hero: Player = first_player()
	var at: Vector2 = hero.global_position
	var aim: Vector2 = at.direction_to(hero.aim_point())
	var swept: Array[Zombie] = []
	for degrees: float in [40.0, -40.0]:
		swept.append(_zombie(at + aim.rotated(deg_to_rad(degrees)) * 300.0))
	var outside: Zombie = _zombie(at + aim.rotated(deg_to_rad(85.0)) * 300.0)
	assert_true(unzipper.attack())
	await _wait_until(_no_halves.bind(unzipper), unzipper.current().duration * 4.0)
	assert_eq(unzipper.seam.shut_hits, 2, "the two swept zombies")
	for zombie: Zombie in swept:
		assert_gte(TOUGH - zombie.health, sweep_rules.shut_damage, "the zip-shut hit lands")
	assert_eq(outside.health, TOUGH, "a zombie the halves never reached is safe")


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## The lash and zipper looks are ProjectileLook parts (swept by test_clarity_ladder); the rope,
## the throw streak and the seam flash are tinted in data.
func test_spec11_10_rope_streak_and_seam_are_calm_and_quieter_than_the_zombies() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	var colors: Array[Color] = [
		LASSO.lasso_throw.rope_color,
		LASSO.lasso_throw.streak_color,
		UNZIPPER.zipper_sweep.seam_color,
	]
	for color: Color in colors:
		assert_false(UiColors.is_danger(color), "no danger colour")
		for floor_color: Color in _floors():
			var floor: float = WorldPalette.brightness(floor_color)
			var gap: float = absf(floor - WorldPalette.brightness(color))
			assert_lt(gap, absf(floor - ink), floor_color.to_html())
