extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §3, §11, AC-105): a zombie killed by a Pincushion Volley pin fires 2 new pins
## from where it fell (those never chain again); Yarn Bomb's sticky web yanks the zombies inside
## to its middle after 2 s and pops a second time. The new looks use no danger colour and stay
## quieter than the zombies.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const VOLLEY: WeaponStats = preload("res://data/weapons/pincushion_volley.tres")
const BOMB: WeaponStats = preload("res://data/weapons/yarn_bomb.tres")
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
	disarm(first_player())
	first_player().invincible = true


## Gives player 1 the recipe of `evolved_id` and evolves it with a gift box. Returns the weapon.
func _evolve(evolved_id: StringName) -> Weapon:
	var pool: UpgradePool = run.upgrade_pool
	var evolution: EvolutionDef = pool.evolution_into(evolved_id)
	var banane: Player = first_player()
	var base: UpgradeDef = pool.find(evolution.weapon)
	banane.add_weapon(base.weapon).level = base.top_level()
	banane.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	run.drop_gift_box(banane.global_position)
	await _wait_until(run.gift_screen.is_open, 1.0)
	run.gift_screen.close()
	await wait_physics_frames(1)
	return banane.weapon(evolved_id)


func _zombie(at: Vector2, health: float) -> Zombie:
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


func _shots(weapon: Weapon, kind: GDScript) -> Array[Projectile]:
	var result: Array[Projectile] = []
	for shot: Projectile in run.projectiles.fired_by(weapon):
		if shot.get_script() == kind:
			result.append(shot)
	return result


func _chained(volley: Weapon) -> Array[ChainPinProjectile]:
	var result: Array[ChainPinProjectile] = []
	for shot: Projectile in _shots(volley, ChainPinProjectile):
		if (shot as ChainPinProjectile).generation == 1:
			result.append(shot as ChainPinProjectile)
	return result


func _has_chained(volley: Weapon) -> bool:
	return not _chained(volley).is_empty()


func test_ac105_a_zombie_a_volley_pin_pops_fires_two_new_pins() -> void:
	await _quiet_run()
	var volley: Weapon = await _evolve(&"pincushion_volley")
	assert_true(volley is PincushionVolley)
	var spot: Vector2 = first_player().global_position + Vector2(150, 0)
	var kills: Array[int] = _count_kills()
	_zombie(spot, 1.0)
	assert_true(await _wait_until(_has_chained.bind(volley), 2.0), "new pins fly")
	assert_eq(kills.size(), 1, "the zombie popped")
	var chained: Array[ChainPinProjectile] = _chained(volley)
	assert_eq(chained.size(), VOLLEY.chain_pins.count, "two of them")
	var volley_pin: float = volley.current().damage
	for pin: ChainPinProjectile in chained:
		assert_lt(pin.global_position.distance_to(spot), 60.0, "from where it fell")
		assert_eq(pin.chains_left, 0, "they never chain again")
		assert_almost_eq(pin.damage, volley_pin * VOLLEY.chain_pins.damage_share, 0.01)
		assert_lt(pin.reach, volley.current().reach, "and fly shorter")
	assert_ne(chained[0].rotation, chained[1].rotation, "fanned out")


func test_ac105_chained_pins_hurt_zombies_but_start_no_new_chains() -> void:
	await _quiet_run()
	var volley: Weapon = await _evolve(&"pincushion_volley")
	volley.set_physics_process(false)
	var start: Vector2 = first_player().global_position + Vector2(0, 200)
	var kills: Array[int] = _count_kills()
	for i: int in 3:
		_zombie(start + Vector2(80 + i * 40, 0), 1.0)
	var pin: ChainPinProjectile = run.projectiles.spawn(ChainPinProjectile) as ChainPinProjectile
	pin.launch_chain(volley, start, Vector2.RIGHT)
	var most: int = 0
	for i: int in roundi(0.8 * FPS):
		most = maxi(most, _shots(volley, ChainPinProjectile).size())
		await wait_physics_frames(1)
	assert_eq(kills.size(), 3, "a chained pin still pierces and pops")
	assert_eq(most, 1, "no new pins: one generation only")


func test_ac105_a_volley_pin_starts_at_most_three_chains() -> void:
	await _quiet_run()
	var volley: Weapon = await _evolve(&"pincushion_volley")
	volley.set_physics_process(false)
	var start: Vector2 = first_player().global_position + Vector2(0, 200)
	for i: int in 6:
		_zombie(start + Vector2(80 + i * 30, 0), 1.0)
	var pin: ChainPinProjectile = run.projectiles.spawn(ChainPinProjectile) as ChainPinProjectile
	pin.launch(volley, Vector2.RIGHT)
	pin.global_position = start
	var most: int = 0
	for i: int in roundi(0.3 * FPS):
		most = maxi(most, _chained(volley).size())
		await wait_physics_frames(1)
	var cap: int = VOLLEY.chain_pins.chains_per_pin * VOLLEY.chain_pins.count
	assert_eq(most, cap, "6 kills, but only the first 3 chain")


func _yarns(bomb: Weapon) -> Array[Projectile]:
	return _shots(bomb, StickyYarnProjectile)


func test_ac105_yarn_bomb_yanks_its_zombies_together_and_pops() -> void:
	await _quiet_run()
	var bomb: Weapon = await _evolve(&"yarn_bomb")
	bomb.set_physics_process(false)
	var middle: Vector2 = first_player().global_position + Vector2(0, 250)
	var yarn: StickyYarnProjectile = (
		run.projectiles.spawn(StickyYarnProjectile) as StickyYarnProjectile
	)
	yarn.launch(bomb, middle)
	var caught: Array[Zombie] = []
	for angle: float in [0.5, 2.5, 4.5]:
		caught.append(_zombie(middle + Vector2.from_angle(angle) * yarn.radius() * 0.8, TOUGH))
	var before: Array[float] = []
	for zombie: Zombie in caught:
		before.append(zombie.position.distance_to(middle))
	assert_gt(yarn.tangle_in(), 0.0, "it waits first")
	var yanked: bool = await _wait_until(
		func() -> bool: return yarn.stage != StickyYarnProjectile.Stage.WEB, BOMB.yarn_tangle.delay
	)
	assert_true(yanked, "after 2 s the web yanks")
	var health: Array[float] = []
	for zombie: Zombie in caught:
		health.append(zombie.health)
	await wait_physics_frames(roundi((BOMB.yarn_tangle.knot_seconds + 0.05) * FPS))
	assert_eq(yarn.stage, StickyYarnProjectile.Stage.POP, "then it pops")
	assert_eq(yarn.popped, caught.size(), "hitting everyone it pulled in")
	for i: int in caught.size():
		var now: float = caught[i].position.distance_to(middle)
		assert_lt(now, before[i] * 0.6, "pulled to the middle")
		assert_lt(caught[i].health, health[i] - BOMB.yarn_tangle.pop_damage * 0.9, "second burst")
	await wait_physics_frames(roundi((BOMB.yarn_tangle.pop_seconds + 0.1) * FPS))
	assert_false(_yarns(bomb).has(yarn), "the web is gone")


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## Chained pins wear the volley's look (ProjectileLook.VOLLEY_*, swept by test_clarity_ladder);
## the knot and the pop are the sticky yarn's tint, a bit stronger.
func test_spec10_11_the_pop_is_calm_and_quieter_than_the_zombies() -> void:
	var pop: Color = StickyYarnProjectile.TINT
	pop.a = BOMB.yarn_tangle.pop_opacity
	assert_false(UiColors.is_danger(pop), "no danger colour")
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var gap: float = absf(floor - WorldPalette.brightness(floor_color.lerp(pop, pop.a)))
		assert_lt(gap, absf(floor - ink), floor_color.to_html())


## Records every kill from now on (killed zombies are freed a few frames later: no references).
func _count_kills() -> Array[int]:
	var kills: Array[int] = []
	run.enemies.zombie_killed.connect(func(_zombie: Zombie) -> void: kills.append(1))
	return kills
