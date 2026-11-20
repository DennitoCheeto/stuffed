extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §7, §8, AC-115): below 25% health the hero's heart patch pulses and a soft
## heartbeat plays; both stop when the hero is healed. In co-op each hero's small bar shows their
## own heart. No red screen edge: nothing on the warning uses a danger colour.

const RULES: LowHealthRules = preload("res://data/ui/low_health.tres")


func _quiet_run() -> Run:
	var run: Run = await start_run()
	run.spawner.active = false
	run.rescue_plan = null
	disarm(first_player())
	return run


func _set_health(hero: Player, share: float) -> void:
	hero.health = hero.max_health * share
	hero.health_changed.emit(hero.health, hero.max_health)


func _overlay_heart(hero: Player) -> bool:
	return hero.get_node(^"Overlay").call(&"shows_low_heart")


func _wait_seconds(run: Run, seconds: float) -> void:
	var until: float = run.elapsed + seconds
	while run.elapsed < until:
		await wait_process_frames(1)


func test_ac115_low_health_pulses_the_heart_and_plays_a_heartbeat() -> void:
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	var warning: LowHealthWarning = LowHealthWarning.of(hero)
	assert_not_null(warning, "every armed hero has a warning")
	Sfx.history.clear()
	await _wait_seconds(run, RULES.beat_seconds * 1.5)
	assert_false(warning.active, "full health: no warning")
	assert_false(run.hud.spare_heart.visible, "no heart patch without Spare Stuffing")
	assert_does_not_have(Sfx.history, RULES.sound)
	_set_health(hero, RULES.threshold * 0.8)
	await _wait_seconds(run, RULES.beat_seconds * 2.5)
	assert_true(warning.active, "below 25%")
	assert_gte(Sfx.history.count(RULES.sound), 2, "the heartbeat keeps playing")
	assert_true(run.hud.spare_heart.visible, "the HUD heart patch shows")
	assert_true(run.hud.spare_heart.shows_low_health())
	assert_true(_overlay_heart(hero), "the small bar's heart too")
	var biggest: float = 1.0
	for frame: int in 60:
		biggest = maxf(biggest, run.hud.spare_heart.pulse_scale())
		await wait_process_frames(1)
	assert_gt(biggest, 1.1, "the heart patch pulses")
	assert_false(UiColors.is_danger(warning.heart_color(SpareHeartPatch.FILL)), "never red")
	hero.heal(hero.max_health)
	await wait_process_frames(2)
	Sfx.history.clear()
	await _wait_seconds(run, RULES.beat_seconds * 2.5)
	assert_false(warning.active, "healed: the warning stops")
	assert_does_not_have(Sfx.history, RULES.sound, "no heartbeat after healing")
	assert_false(run.hud.spare_heart.visible, "the heart patch is gone")
	assert_false(_overlay_heart(hero))


func test_ac115_each_co_op_hero_has_their_own_warning() -> void:
	main.player_count = 2
	var run: Run = await _quiet_run()
	var heroes: Array[Player] = Players.all(get_tree())
	assert_eq(heroes.size(), 2)
	var second: Player = heroes[1]
	disarm(second)
	_set_health(second, RULES.threshold * 0.5)
	await _wait_seconds(run, RULES.beat_seconds)
	assert_true(LowHealthWarning.of(second).active, "player 2 is low")
	assert_true(_overlay_heart(second), "player 2's small bar shows the heart")
	assert_false(LowHealthWarning.of(heroes[0]).active, "player 1 is fine")
	assert_false(_overlay_heart(heroes[0]))
	assert_false(run.hud.spare_heart.visible, "player 1's HUD heart stays away")
