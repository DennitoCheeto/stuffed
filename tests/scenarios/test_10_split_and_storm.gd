extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §3, §11, AC-105): Banana Split's peels leave slippery peels on the zombies
## they hit on the way back (stun on step, at most 6 on the floor); Sewing Storm's flung needles
## trail thread that pulls tight, yanking the zombies they passed towards the hero and hitting
## them again. The new looks use no danger colour and stay quieter than the zombies.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SPLIT: WeaponStats = preload("res://data/weapons/banana_split.tres")
const STORM: WeaponStats = preload("res://data/weapons/sewing_storm.tres")
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


func _tough_zombie(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
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


func _has_floor_peels(split: BananaSplit) -> bool:
	return not split.floor_peels().is_empty()


func test_ac105_banana_split_peels_drop_a_slippery_peel_where_they_hit() -> void:
	await _quiet_run()
	var split: BananaSplit = await _evolve(&"banana_split") as BananaSplit
	assert_not_null(split)
	var zombie: Zombie = _tough_zombie(first_player().global_position + Vector2(150, 0))
	assert_true(await _wait_until(_has_floor_peels.bind(split), 4.0), "a peel lands")
	var peel: FloorPeelProjectile = split.floor_peels()[0]
	assert_lt(peel.global_position.distance_to(zombie.global_position), 60.0, "where it hit")
	assert_false(zombie.is_stunned(), "not slippery the moment it lands")
	var tripped: bool = await _wait_until(zombie.is_stunned, SPLIT.peel_trail.arm_seconds + 0.5)
	assert_true(tripped, "the zombie standing on it slips")


func test_ac105_a_slippery_peel_stuns_whoever_steps_on_it_once() -> void:
	await _quiet_run()
	var split: BananaSplit = await _evolve(&"banana_split") as BananaSplit
	var spot: Vector2 = first_player().global_position + Vector2(0, 260)
	split.drop_peel(spot)
	await _wait_until(_has_floor_peels.bind(split), 0.1)
	var peel: FloorPeelProjectile = split.floor_peels()[0]
	Sfx.history.clear()
	var zombie: Zombie = _tough_zombie(spot)
	assert_true(await _wait_until(zombie.is_stunned, 1.0), "it slipped")
	assert_gt(zombie.stun_left, SPLIT.peel_trail.stun - 0.2, "stunned like Banane's Slippery")
	assert_eq(peel.slipped, 1)
	assert_true(Sfx.history.has(&"slip"), "zwiip")
	assert_true(split.floor_peels().is_empty(), "used up")


func test_ac105_at_most_six_peels_lie_on_the_floor() -> void:
	await _quiet_run()
	var split: BananaSplit = await _evolve(&"banana_split") as BananaSplit
	var start: Vector2 = first_player().global_position + Vector2(-300, 300)
	for i: int in 8:
		split.drop_peel(start + Vector2(i * 60, 0))
		await wait_physics_frames(1)
	var lying: Array[FloorPeelProjectile] = split.floor_peels()
	assert_eq(lying.size(), SPLIT.peel_trail.max_peels, "the oldest made room")
	for peel: FloorPeelProjectile in lying:
		assert_gt(peel.global_position.x, start.x + 60.0, "the first two are gone")
	await wait_physics_frames(roundi((SPLIT.peel_trail.lifetime + 0.2) * FPS))
	assert_true(split.floor_peels().is_empty(), "nobody stepped on them: gone after a while")


func _sewing(storm: SewingStorm) -> bool:
	for needle: StormNeedleProjectile in storm.needles():
		if needle.is_sewing():
			return true
	return false


func _snapped(storm: SewingStorm) -> bool:
	for needle: StormNeedleProjectile in storm.needles():
		if needle.snaps > 0:
			return true
	return false


func test_ac105_sewing_storm_threads_yank_the_zombies_back_in() -> void:
	await _quiet_run()
	var storm: SewingStorm = await _evolve(&"sewing_storm") as SewingStorm
	assert_not_null(storm)
	var hero: Vector2 = first_player().global_position
	var ring: Array[Zombie] = []
	for i: int in 8:
		ring.append(_tough_zombie(hero + Vector2.from_angle(TAU * i / 8.0) * 170.0))
	assert_true(await _wait_until(_sewing.bind(storm), STORM.at_level(1).cooldown + 2.0), "flung")
	await wait_physics_frames(roundi(0.2 * FPS))
	assert_false(storm.threads.segments.is_empty(), "thread trails behind the needles")
	var stitched: int = 0
	for needle: StormNeedleProjectile in storm.needles():
		stitched += needle.stitched.size()
	assert_gt(stitched, 0, "the needles sewed through zombies")
	var hits: Array[Zombie] = []
	run.enemies.zombie_hit.connect(
		func(zombie: Zombie, _amount: float) -> void: hits.append(zombie)
	)
	assert_true(await _wait_until(_snapped.bind(storm), 1.0), "the threads pull tight")
	var yanked: int = 0
	for zombie: Zombie in ring:
		var inward: Vector2 = zombie.global_position.direction_to(first_player().global_position)
		if hits.has(zombie) and zombie.knockback.dot(inward) > 0.0:
			yanked += 1
	assert_gt(yanked, 0, "stitched zombies are hit again and dragged towards the hero")
	await wait_physics_frames(roundi((STORM.stitch_up.snap_seconds + 0.1) * FPS))
	assert_true(storm.threads.segments.is_empty(), "the thread whips back and is gone")


func test_ac105_without_zombies_the_storm_snaps_quietly() -> void:
	await _quiet_run()
	var storm: SewingStorm = await _evolve(&"sewing_storm") as SewingStorm
	assert_true(await _wait_until(_snapped.bind(storm), STORM.at_level(1).cooldown + 3.0))
	assert_eq(storm.needles().size(), STORM.at_level(1).count, "the storm is still whole")


func _floors() -> Array[Color]:
	var colors: Array[Color] = []
	for group: Array in PALETTE.floor_groups():
		for color: Color in group:
			colors.append(color)
			colors.append(color * PALETTE.dusk_tint)
	return colors


## Peels on the floor wear ProjectileLook.SPLIT_PEEL_COLOR (swept by test_clarity_ladder).
func test_spec10_11_the_thread_is_calm_and_quieter_than_the_zombies() -> void:
	var thread: Color = STORM.stitch_up.thread_color
	assert_false(UiColors.is_danger(thread), "no danger colour")
	var ink: float = WorldPalette.brightness(FeltPiece.new().outline_color)
	for floor_color: Color in _floors():
		var floor: float = WorldPalette.brightness(floor_color)
		var gap: float = absf(floor - WorldPalette.brightness(thread))
		assert_lt(gap, absf(floor - ink), floor_color.to_html())
