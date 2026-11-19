extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §4.2, AC-109): a crowd of 300 deaths in one frame stays within each sound's
## voice limit (one big "pop", not a crackle), the Master bus has a limiter, frequent sounds vary
## in pitch, and each hero has their own level-up voice.

const ROSTER: HeroRoster = preload("res://data/heroes/hero_roster.tres")


func _quiet_run(hero: StringName = &"banane") -> Run:
	for stats: HeroStats in ROSTER.heroes:
		if stats.plushie != null:
			main.town.plushies[stats.plushie.id] = "in_town"
	main.town.set_hero(0, String(hero))
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	disarm(first_player())
	return run


func _count(sound: StringName) -> int:
	return Sfx.history.count(sound)


func test_ac109_a_crowd_of_300_deaths_stays_within_the_voice_limits() -> void:
	var run: Run = await _quiet_run()
	var stats: EnemyStats = run.spawner.schedule.entries[0].enemy
	var crowd: Array[Zombie] = []
	var middle: Vector2 = first_player().global_position + Vector2(300, 0)
	for i: int in 300:
		var offset: Vector2 = Vector2(i % 20, int(i / 20.0)) * 14.0
		crowd.append(run.enemies.spawn(stats, middle + offset))
	await wait_physics_frames(2)
	Sfx.history.clear()
	var died: int = 0
	for zombie: Zombie in crowd:
		if run.enemies.damage(zombie, 1_000_000.0):
			died += 1
	assert_eq(died, 300, "all 300 died in one frame")
	assert_between(_count(&"pop"), 1, mini(Sfx.RULES.starts_per_frame, 3), "one big pop")
	assert_lte(_count(&"hit"), Sfx.RULES.starts_per_frame, "hits too")
	assert_lte(Sfx.playing_count(&"pop"), Sfx.max_voices(&"pop"), "never past the voice limit")
	for frame: int in 20:
		await wait_process_frames(1)
		assert_lte(Sfx.playing_count(&"pop"), Sfx.max_voices(&"pop"), "frame %d" % frame)


func test_ac109_the_master_bus_has_a_limiter() -> void:
	await _quiet_run()
	var master: int = AudioServer.get_bus_index(&"Master")
	var limiter: AudioEffectHardLimiter = null
	for i: int in AudioServer.get_bus_effect_count(master):
		var effect: AudioEffect = AudioServer.get_bus_effect(master, i)
		if effect is AudioEffectHardLimiter and AudioServer.is_bus_effect_enabled(master, i):
			limiter = effect as AudioEffectHardLimiter
	assert_not_null(limiter, "a limiter on the Master bus")
	if limiter != null:
		assert_lt(limiter.ceiling_db, 0.0, "it stops the output below full scale")


func test_ac109_frequent_sounds_vary_in_pitch() -> void:
	await _quiet_run()
	var pitches: Array[float] = []
	for i: int in 6:
		await wait_process_frames(1)
		Sfx.play(&"hit")
		pitches.append(Sfx.last_pitch)
	pitches.sort()
	assert_gt(pitches[-1] - pitches[0], 0.01, "six hits are not all the same pitch")
	for pitch: float in pitches:
		assert_between(pitch, 1.0 - Sfx.RULES.varied_pitch, 1.0 + Sfx.RULES.varied_pitch)


func test_ac109_each_hero_has_their_own_level_up_voice(
	pair: Array = use_parameters(
		[
			[&"banane", &"quack"],
			[&"pip", &"squeak"],
			[&"bobo", &"grumble"],
			[&"bambam", &"trill"],
			[&"robbar", &"bark"],
		]
	)
) -> void:
	var hero: StringName = pair[0]
	var voice: StringName = pair[1]
	await _quiet_run(hero)
	assert_eq(first_player().stats.id, hero)
	Sfx.history.clear()
	first_player().add_xp(5)
	await wait_process_frames(3)
	assert_true(Sfx.history.has(voice), "%s levels up with a %s" % [hero, voice])
