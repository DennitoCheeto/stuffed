extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §3, §11, AC-105, AC-107): Snow Day (Pip's Snowball Toss + Thick Felt) builds a
## snowman on every landing that draws nearby zombies, then bursts and freezes them (at most 3
## stand); Bear Slam (Böbö's Paw Swat + Extra Stuffing) slams the ground every 4th swat, knocking
## the zombies in the ring down. Their recipes only show once the hero is unlocked; the Scrapbook
## lists them. The new looks use no danger colour and stay quieter than the zombies.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SNOW_DAY: WeaponStats = preload("res://data/weapons/snow_day.tres")
const BEAR_SLAM: WeaponStats = preload("res://data/weapons/bear_slam.tres")
const ROSTER: HeroRoster = preload("res://data/heroes/hero_roster.tres")
const PALETTE: WorldPalette = preload("res://data/art/world_palette.tres")
const SCRAPBOOK: ScrapbookRules = preload("res://data/scrapbook.tres")
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


func _has_snowman(snow: SnowDay) -> bool:
	return not snow.snowmen().is_empty()


func test_ac105_every_snow_day_landing_builds_a_snowman() -> void:
	await _quiet_run()
	var snow: SnowDay = await _evolve(&"snow_day") as SnowDay
	assert_not_null(snow, "Snowball Toss + Thick Felt = Snow Day")
	var target: Zombie = _zombie(first_player().global_position + Vector2(220, 0))
	assert_true(await _wait_until(_has_snowman.bind(snow), 4.0), "a snowman stands")
	var snowman: SnowmanProjectile = snow.snowmen()[0]
	var near: float = snow.current().area + 10.0
	assert_lt(snowman.global_position.distance_to(target.global_position), near, "where it landed")
	assert_true(run.enemies.lures.has(snowman.lure), "it draws zombies")


func test_ac105_zombies_nearby_walk_to_the_snowman_then_it_bursts_and_freezes_them() -> void:
	await _quiet_run()
	var snow: SnowDay = await _evolve(&"snow_day") as SnowDay
	snow.set_physics_process(false)
	var hero: Vector2 = first_player().global_position
	var spot: Vector2 = hero + Vector2(0, 320)
	snow.build_snowman(spot)
	var snowman: SnowmanProjectile = snow.snowmen()[0]
	var lured: Zombie = _zombie(spot + Vector2(160, 0), SHAMBLER.move_speed)
	var free: Zombie = _zombie(spot + Vector2(0, 360), SHAMBLER.move_speed)
	var start: float = lured.position.distance_to(spot)
	await wait_physics_frames(roundi(2.0 * FPS))
	assert_lt(lured.position.distance_to(spot), start - 50.0, "the zombie in reach walks to it")
	assert_lt(absf(lured.position.y - spot.y), 20.0, "straight to it, not to the hero")
	assert_gt(free.position.distance_to(spot), SNOW_DAY.snowmen.lure_reach, "the far one doesn't")
	var health: float = lured.health
	var burst: bool = await _wait_until(func() -> bool: return snowman.burst, 3.0)
	assert_true(burst, "after its lifetime it bursts")
	assert_gt(snowman.froze, 0)
	assert_gt(lured.ice_left, SNOW_DAY.snowmen.freeze_seconds - 0.2, "frozen for 1.5 s")
	assert_true(lured.is_stunned(), "can't move")
	assert_lt(lured.health, health, "and hurt")
	assert_false(run.enemies.lures.has(snowman.lure), "it draws no one any more")
	var at: Vector2 = lured.position
	await wait_physics_frames(roundi(0.5 * FPS))
	assert_lt(lured.position.distance_to(at), 2.0, "stays put while frozen")


func test_ac105_at_most_three_snowmen_stand() -> void:
	await _quiet_run()
	var snow: SnowDay = await _evolve(&"snow_day") as SnowDay
	snow.set_physics_process(false)
	for i: int in 5:
		snow.build_snowman(first_player().global_position + Vector2(-200 + i * 100, 300))
	assert_eq(snow.snowmen().size(), SNOW_DAY.snowmen.max_snowmen)


func test_ac105_every_fourth_bear_slam_swat_slams_the_ground() -> void:
	await _quiet_run()
	var slam: BearSlam = await _evolve(&"bear_slam") as BearSlam
	assert_not_null(slam, "Paw Swat + Extra Stuffing = Bear Slam")
	var ring: Array[Zombie] = []
	for i: int in 6:
		var angle: float = TAU * i / 6.0
		ring.append(_zombie(first_player().global_position + Vector2.from_angle(angle) * 120.0))
	var slammed: bool = await _wait_until(func() -> bool: return slam.slams > 0, 6.0)
	assert_true(slammed, "a slam")
	assert_eq(slam.swats, BEAR_SLAM.ground_slam.every, "on the 4th swat")
	var stunned: int = 0
	for zombie: Zombie in ring:
		if zombie.is_stunned():
			stunned += 1
		assert_lt(zombie.health, TOUGH - BEAR_SLAM.ground_slam.damage * 0.9, "hurt by the slam")
	assert_eq(stunned, ring.size(), "every zombie in the ring is knocked down")
	var rings: Array[Projectile] = []
	for shot: Projectile in run.projectiles.fired_by(slam):
		if shot is SlamRingProjectile:
			rings.append(shot)
	assert_eq(rings.size(), 1, "the ring spreads on the floor")


func _unlock_heroes() -> void:
	for hero: HeroStats in ROSTER.heroes:
		if hero.plushie != null:
			main.town.plushies[hero.plushie.id] = "in_town"


func test_ac107_the_heroes_recipes_wait_until_the_heroes_are_unlocked() -> void:
	run = await start_run()
	run.pause_menu.show_recipes()
	var all: int = run.upgrade_pool.evolutions.size()
	assert_eq(run.pause_menu.recipes_page.rows.size(), all - 2, "no Snow Day or Bear Slam yet")
	assert_true(run.perks.locked_hero_weapons.has(&"snowball_toss"), "Pip isn't home yet")
	assert_true(run.perks.locked_hero_weapons.has(&"paw_swat"), "nor Böbö")


func test_ac107_the_heroes_recipes_show_once_they_are_unlocked() -> void:
	_unlock_heroes()
	run = await start_run()
	run.pause_menu.show_recipes()
	var all: int = run.upgrade_pool.evolutions.size()
	assert_eq(run.pause_menu.recipes_page.rows.size(), all, "all six recipes")


func test_ac107_the_scrapbook_lists_the_new_evolutions() -> void:
	var weapons: ScrapbookPage = SCRAPBOOK.pages()[0]
	for id: String in ["snow_day", "bear_slam"]:
		var entry: ScrapbookEntry = weapons.find(id)
		assert_not_null(entry, id)
		if entry != null:
			assert_string_contains(entry.note, "Evolution:")


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## The snowman and the paw are ProjectileLook parts (swept by test_clarity_ladder); the slam ring is
## tinted in data, and a frozen zombie keeps the Snow Globe's ice tint.
func test_spec10_11_the_slam_ring_is_calm_and_quieter_than_the_zombies() -> void:
	var color: Color = BEAR_SLAM.ground_slam.ring_color
	assert_false(UiColors.is_danger(color), "no danger colour")
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var gap: float = absf(floor - WorldPalette.brightness(color))
		assert_lt(gap, absf(floor - ink), floor_color.to_html())
