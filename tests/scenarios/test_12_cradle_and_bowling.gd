extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 11 §3, §4.1, §4.2, AC-120, AC-121, AC-122): a maxed Bouncy Yarn Ball + Magnet
## Pocket evolves into Cat's Cradle, whose bounces leave yarn threads that hurt the zombies touching
## them (at most 20) and whose balls send XP buttons to the hero. A maxed Button Shotgun + Quick
## Hands evolves into Bowling Buttons: hit zombies tumble and knock over the zombies they bump into,
## one step only; elites tumble half as long, bosses never. The new looks stay calm.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const ELITE: EliteRules = preload("res://data/elite_rules.tres")
const BIG_TED: BossDef = preload("res://data/bosses/big_ted.tres")
const CRADLE: WeaponStats = preload("res://data/weapons/cats_cradle.tres")
const BOWLING: WeaponStats = preload("res://data/weapons/bowling_buttons.tres")
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
	var hero: Player = first_player()
	var base: UpgradeDef = pool.find(evolution.weapon)
	hero.add_weapon(base.weapon).level = base.top_level()
	hero.apply_upgrade(UpgradeOffer.new(pool.find(evolution.partner), 1))
	run.drop_gift_box(hero.global_position)
	await _wait_until(run.gift_screen.is_open, 1.0)
	run.gift_screen.close()
	await wait_physics_frames(1)
	return hero.weapon(evolved_id)


func _zombie(at: Vector2, speed: float = 0.0) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.health = TOUGH
	zombie.move_speed = speed
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


func _has_threads(cradle: CatsCradle) -> bool:
	return cradle.threads.count() > 0


func test_ac120_yarn_ball_and_magnet_pocket_become_cats_cradle() -> void:
	await _quiet_run()
	var cradle: CatsCradle = await _evolve(&"cats_cradle") as CatsCradle
	assert_not_null(cradle, "Bouncy Yarn Ball + Magnet Pocket = Cat's Cradle")
	var hero: Player = first_player()
	assert_null(hero.weapon(&"bouncy_yarn_ball"), "the yarn ball is replaced")
	assert_true(hero.upgrade_levels().has(&"magnet_pocket"), "the item stays")


func test_ac121_bounces_leave_threads_between_the_bounce_points() -> void:
	await _quiet_run()
	var cradle: CatsCradle = await _evolve(&"cats_cradle") as CatsCradle
	var hero: Vector2 = first_player().global_position
	for offset: Vector2 in [Vector2(160, 0), Vector2(160, 140), Vector2(-60, 160)]:
		_zombie(hero + offset)
	assert_true(await _wait_until(_has_threads.bind(cradle), 4.0), "a bounce leaves a thread")
	var segments: PackedVector2Array = cradle.threads.segments()
	assert_gt(segments[0].distance_to(segments[1]), 40.0, "it stretches from point to point")


func test_ac121_a_thread_hurts_the_zombies_touching_it_for_its_lifetime() -> void:
	await _quiet_run()
	var cradle: CatsCradle = await _evolve(&"cats_cradle") as CatsCradle
	cradle.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var from: Vector2 = hero + Vector2(-150, 250)
	var to: Vector2 = hero + Vector2(150, 250)
	var touching: Zombie = _zombie(hero + Vector2(40, 255))
	var away: Zombie = _zombie(hero + Vector2(40, 380))
	cradle.threads.add(from, to)
	await _wait_seconds(1.1)
	var cut: float = TOUGH - touching.health
	var hit: float = CRADLE.yarn_cradle.thread_damage
	assert_almost_eq(cut, hit * 2.0, hit * 0.6, "4 damage every 0.5 s")
	assert_eq(away.health, TOUGH, "a zombie off the thread is safe")
	await _wait_seconds(CRADLE.yarn_cradle.thread_seconds)
	assert_eq(cradle.threads.count(), 0, "gone after 2.5 s")
	var after: float = touching.health
	await _wait_seconds(0.6)
	assert_eq(touching.health, after, "and hurts no more")


func test_ac121_at_most_twenty_threads_the_oldest_goes() -> void:
	await _quiet_run()
	var cradle: CatsCradle = await _evolve(&"cats_cradle") as CatsCradle
	cradle.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	for i: int in 25:
		cradle.threads.add(hero + Vector2(i * 10, 300), hero + Vector2(i * 10, 340))
	assert_eq(cradle.threads.count(), CRADLE.yarn_cradle.max_threads)
	assert_eq(cradle.threads.segments()[0], hero + Vector2(50, 300), "the first five went")


func test_ac121_the_ball_sends_xp_buttons_it_rolls_over_to_its_hero() -> void:
	await _quiet_run()
	var cradle: CatsCradle = await _evolve(&"cats_cradle") as CatsCradle
	cradle.set_physics_process(false)
	var hero: Player = first_player()
	var spot: Vector2 = hero.global_position + Vector2(GearEffects.pickup_reach(hero) + 200.0, 0)
	var button: XpButton = run.pickups.drop(EnemyStats.XpSize.SMALL, spot)
	await wait_physics_frames(2)
	assert_null(button.target, "out of the hero's reach")
	var ball: CradleProjectile = run.projectiles.spawn(CradleProjectile) as CradleProjectile
	ball.launch(cradle, Vector2.RIGHT)
	var snagged: bool = await _wait_until(func() -> bool: return button.target == hero, 2.0)
	assert_true(snagged, "the ball snags it and it flies to the hero")


func test_ac120_shotgun_and_quick_hands_become_bowling_buttons() -> void:
	await _quiet_run()
	var bowling: BowlingButtons = await _evolve(&"bowling_buttons") as BowlingButtons
	assert_not_null(bowling, "Button Shotgun + Quick Hands = Bowling Buttons")
	var hero: Player = first_player()
	assert_null(hero.weapon(&"button_shotgun"), "the shotgun is replaced")
	assert_true(hero.upgrade_levels().has(&"quick_hands"), "the item stays")


func test_ac122_a_zombie_the_buttons_hit_tumbles() -> void:
	await _quiet_run()
	var bowling: BowlingButtons = await _evolve(&"bowling_buttons") as BowlingButtons
	var front: Zombie = _zombie(first_player().global_position + Vector2(120, 0))
	var tumbled: bool = await _wait_until(bowling.lane.is_tumbling.bind(front), 3.0)
	assert_true(tumbled, "knocked back, it tumbles")
	assert_gt(front.tumble_left, 0.0)


func test_ac122_a_tumbling_zombie_knocks_over_the_ones_it_bumps_one_step_only() -> void:
	await _quiet_run()
	var bowling: BowlingButtons = await _evolve(&"bowling_buttons") as BowlingButtons
	bowling.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var front: Zombie = _zombie(hero + Vector2(300, 0))
	var gap: float = front.radius() * 2.0 + 2.0
	var behind: Zombie = _zombie(hero + Vector2(300 + gap, 0))
	var far: Zombie = _zombie(hero + Vector2(300 + gap * 2.0, 0))
	bowling.lane.tumble(front, Vector2.RIGHT)
	await _wait_until(func() -> bool: return behind.health < TOUGH, 1.0)
	var bump: float = BOWLING.zombie_bowling.bump_damage
	assert_almost_eq(TOUGH - behind.health, bump, 0.01, "bumped once, 10 damage")
	assert_gt(behind.knockback.x, 0.0, "and knocked onward")
	assert_false(bowling.lane.is_tumbling(behind), "a bumped zombie doesn't tumble itself")
	await _wait_seconds(BOWLING.zombie_bowling.tumble_seconds + 0.2)
	assert_eq(bowling.lane.tumbling().size(), 0, "the tumble ends after 0.4 s")
	assert_eq(far.health, TOUGH, "the chain stops after one step")


func test_ac122_knocking_over_three_plays_a_strike() -> void:
	await _quiet_run()
	var bowling: BowlingButtons = await _evolve(&"bowling_buttons") as BowlingButtons
	bowling.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var front: Zombie = _zombie(hero + Vector2(300, 0))
	var gap: float = front.radius() * 2.0 + 2.0
	for angle: float in [0.0, PI / 4.0, -PI / 4.0]:
		_zombie(front.position + Vector2.from_angle(angle) * gap)
	Sfx.history.clear()
	bowling.lane.tumble(front, Vector2.RIGHT)
	await _wait_until(func() -> bool: return bowling.lane.strikes > 0, 1.0)
	assert_eq(bowling.lane.strikes, 1, "a strike")
	assert_has(Sfx.history, BOWLING.zombie_bowling.strike_sound, "with its sound")


func test_ac122_elites_tumble_half_as_long_and_bosses_never() -> void:
	await _quiet_run()
	var bowling: BowlingButtons = await _evolve(&"bowling_buttons") as BowlingButtons
	bowling.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var elite: Zombie = run.enemies.spawn(SHAMBLER, hero + Vector2(-300, 0), ELITE)
	elite.health = TOUGH
	bowling.lane.tumble(elite, Vector2.LEFT)
	var half: float = BOWLING.zombie_bowling.tumble_seconds * BOWLING.zombie_bowling.elite_share
	assert_almost_eq(elite.tumble_left, half, 0.001, "an elite tumbles half as long")
	var ted: Zombie = run.enemies.spawn_boss(BIG_TED, hero + Vector2(0, 400))
	bowling.lane.tumble(ted, Vector2.DOWN)
	assert_false(bowling.lane.is_tumbling(ted), "a boss never tumbles")
	assert_eq(ted.tumble_left, 0.0)
	var next_to_ted: Zombie = _zombie(ted.position + Vector2(ted.radius() + 20.0, 0))
	var health: float = ted.health
	bowling.lane.tumble(next_to_ted, Vector2.LEFT)
	await _wait_seconds(0.3)
	assert_eq(ted.health, health, "and a tumbler doesn't bowl a boss over")


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## The ball and button looks are ProjectileLook parts (swept by test_clarity_ladder); the threads
## and the tumble streak are tinted in data.
func test_spec11_10_threads_and_streaks_are_calm_and_quieter_than_the_zombies() -> void:
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for color: Color in [CRADLE.yarn_cradle.thread_color, BOWLING.zombie_bowling.streak_color]:
		assert_false(UiColors.is_danger(color), "no danger colour")
		for floor_color: Color in _floors():
			var floor: float = WorldPalette.brightness(floor_color)
			var gap: float = absf(floor - WorldPalette.brightness(color))
			assert_lt(gap, absf(floor - ink), floor_color.to_html())
