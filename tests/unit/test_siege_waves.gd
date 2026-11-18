extends GutTest
## Night siege waves and fort (spec 07 §2, §5, AC-76): 3 waves of `wave_seconds` with a breather
## between them, elites and the boss when due, the fort's health from the town's levels, and how
## zombies choose between the fort and a hero.

const RULES: SiegeRules = preload("res://data/siege/siege_rules.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SPITTER: EnemyStats = preload("res://data/enemies/spitter.tres")
const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
const FORT_RECT: Rect2 = Rect2(1000, 600, 400, 300)


func _fort() -> SiegeFort:
	return SiegeFort.new(FORT_RECT, 100.0, 260.0, 0.5)


func _zombie(stats: EnemyStats, at: Vector2) -> Zombie:
	var zombie: Zombie = Zombie.new()
	zombie.position = at
	zombie.setup(stats, 1.0, 1.0, 0.0, null, null)
	autofree(zombie)
	return zombie


## Runs the clock for `seconds` in steps of 0.1 s; returns the waves that started meanwhile.
func _run(waves: SiegeWaves, seconds: float) -> Array[int]:
	var started: Array[int] = []
	for i: int in roundi(seconds * 10.0):
		var wave: int = waves.tick(0.1)
		if wave >= 0:
			started.append(wave)
	return started


func test_the_waves_come_from_data() -> void:
	assert_eq(RULES.wave_list.size(), 3)
	assert_almost_eq(RULES.wave_seconds, 60.0, 0.001)
	var first: SiegeWave = RULES.wave_list[0]
	assert_eq(first.boss, null, "no boss in wave 1")
	assert_eq(first.elites, 0)
	assert_eq(RULES.wave_list[1].elites, 1, "one elite in wave 2")
	assert_not_null(RULES.wave_list[2].boss, "the night's boss in wave 3")
	assert_eq(RULES.wave_list[2].boss.enemy.display_name, "Big Ted")
	assert_almost_eq(RULES.total_seconds(), 3 * 60.0 + 2 * 8.0, 0.001)


func test_ac76_three_waves_with_a_breather_between() -> void:
	var waves: SiegeWaves = SiegeWaves.new(RULES)
	assert_eq(waves.tick(0.1), 0, "wave 1 starts at once")
	assert_true(waves.spawning())
	assert_gt(waves.rate(), 0.0)
	assert_eq(_run(waves, RULES.wave_seconds), [] as Array[int])
	assert_true(waves.resting, "a breather after wave 1")
	assert_eq(waves.rate(), 0.0, "nothing comes in the breather")
	assert_eq(_run(waves, RULES.breather_seconds + 0.2), [1] as Array[int])
	assert_true(waves.spawning())
	_run(waves, RULES.wave_seconds + RULES.breather_seconds + 0.2)
	assert_eq(waves.wave, 2)
	_run(waves, RULES.wave_seconds + 0.2)
	assert_true(waves.finished, "after wave 3 nothing new comes")
	assert_false(waves.spawning())
	assert_eq(waves.tick(1.0), -1)


func test_ac76_the_boss_comes_in_the_last_wave_once() -> void:
	var waves: SiegeWaves = SiegeWaves.new(RULES)
	waves.tick(0.1)
	_run(waves, RULES.wave_seconds)
	assert_null(waves.take_boss(), "no boss in wave 1")
	waves.next_wave()
	waves.next_wave()
	assert_eq(waves.wave, 2)
	assert_null(waves.take_boss(), "not before his time in the wave")
	_run(waves, RULES.wave_list[2].boss_at + 0.2)
	assert_eq(waves.take_boss(), RULES.wave_list[2].boss)
	assert_null(waves.take_boss(), "only once")


func test_elites_are_spread_over_their_wave() -> void:
	var waves: SiegeWaves = SiegeWaves.new(RULES)
	waves.tick(0.1)
	assert_eq(waves.take_elites(), 0, "none in wave 1")
	waves.next_wave()
	var half: float = RULES.wave_list[1].elite_at(0, RULES.wave_seconds)
	_run(waves, half - 1.0)
	assert_eq(waves.take_elites(), 0)
	_run(waves, 1.2)
	assert_eq(waves.take_elites(), 1, "the elite of wave 2, in its middle")
	_run(waves, 10.0)
	assert_eq(waves.take_elites(), 0, "only once")


func test_next_wave_skips_ahead_and_ends_after_the_last() -> void:
	var waves: SiegeWaves = SiegeWaves.new(RULES)
	waves.tick(0.1)
	assert_eq(waves.next_wave(), 1)
	assert_eq(waves.next_wave(), 2)
	assert_eq(waves.next_wave(), -1)
	assert_true(waves.finished)


func test_a_wave_picks_only_its_own_types() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var first: SiegeWave = RULES.wave_list[0]
	for i: int in 50:
		assert_has(first.enemies, first.pick(rng))


func test_the_fort_gets_sturdier_with_every_built_level() -> void:
	assert_almost_eq(RULES.fort_health_for(0), RULES.fort_health, 0.001)
	assert_gt(RULES.fort_health_for(6), RULES.fort_health_for(3))
	assert_almost_eq(
		RULES.fort_health_for(4) - RULES.fort_health_for(3), RULES.fort_health_per_level, 0.001
	)


func test_zombies_walk_to_the_fort_unless_a_hero_is_close() -> void:
	var fort: SiegeFort = _fort()
	var zombie: Zombie = _zombie(SHAMBLER, Vector2(200, 750))
	var walk: Vector2 = fort.walk(zombie)
	assert_gt(walk.x, 0.0, "towards the fort's left wall")
	assert_almost_eq(walk.y, 0.0, 0.01)
	var hero: Player = autofree(PLAYER_SCENE.instantiate())
	hero.global_position = Vector2(300, 750)
	assert_true(fort.chases(zombie, hero), "a hero close by")
	hero.global_position = Vector2(200, 100)
	assert_false(fort.chases(zombie, hero), "a hero far away: the fort")
	assert_false(fort.chases(zombie, null), "no hero standing: the fort")
	var spitter: Zombie = _zombie(SPITTER, Vector2(200, 750))
	hero.global_position = Vector2(200, 750 - SPITTER.attack.keep_distance)
	assert_true(fort.chases(spitter, hero), "a spitter keeps spitting from its distance")


func test_zombies_touching_the_fort_knock_it_down() -> void:
	var fort: SiegeFort = _fort()
	var fell: Array[bool] = []
	fort.fell.connect(func() -> void: fell.append(true))
	var far: Zombie = _zombie(SHAMBLER, Vector2(200, 750))
	fort.touch(far, 1.0)
	assert_almost_eq(fort.health, 100.0, 0.001, "far away: no harm")
	var near: Zombie = _zombie(SHAMBLER, Vector2(FORT_RECT.position.x - _near_radius(), 750))
	fort.touch(near, 1.0)
	assert_almost_eq(fort.health, 100.0 - SHAMBLER.contact_damage * 0.5, 0.001)
	fort.hurt(1000.0)
	assert_true(fort.is_fallen())
	assert_eq(fell.size(), 1)
	fort.hurt(10.0)
	assert_eq(fell.size(), 1, "falls once")


func _near_radius() -> float:
	return SHAMBLER.radius + 2.0


func test_ac80_waves_held_counts_the_waves_that_stopped_coming() -> void:
	var waves: SiegeWaves = SiegeWaves.new(RULES)
	assert_eq(waves.held(false), 0, "before the first wave")
	waves.tick(0.1)
	assert_eq(waves.held(false), 0, "wave 1 still coming")
	_run(waves, RULES.wave_seconds + 0.5)
	assert_true(waves.resting)
	assert_eq(waves.held(false), 1, "wave 1 held, resting")
	waves.next_wave()
	assert_eq(waves.held(false), 1, "wave 2 still coming")
	assert_eq(waves.held(true), 3, "a won siege held them all")
