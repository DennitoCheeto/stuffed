extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §4.1, AC-108): each place plays its own track (title, town, run, boss, siege,
## endless); a change of place crossfades over about a second; the run's layers grow after 2:00
## or with 150 zombies on screen, then after 5:00; the siege gets busier each wave; stingers play
## at the goal, when a hero falls, at an evolution and when a siege is won or lost.

const RULES: MusicRules = preload("res://data/audio/music/music_rules.tres")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
## Rendering every track takes a few seconds after the first boot (on worker threads).
const RENDER_WAIT: float = 30.0

var _overlaps: int = 0
var _most_heard: int = 0
var _lowest_duck: float = 1.0


func _all_ready() -> bool:
	for track: MusicTrack in RULES.tracks + RULES.stingers:
		if not MusicPlayer.is_ready(track.id):
			return false
	return true


func _wait_for_music() -> void:
	await wait_until(_all_ready, RENDER_WAIT)


func _crossfade_done() -> bool:
	return main.music.fading_out.is_empty() and main.music.deck.fade >= 1.0


func _music_level(level: int) -> bool:
	return main.music.intensity == level


func _stinger(id: StringName) -> bool:
	return main.music.stingers_played.has(id)


## A quiet run (no spawns, no shots) with its music ready.
func _quiet_run() -> Run:
	await _wait_for_music()
	var run: Run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	run.rescue_plan = null
	return run


func test_ac108_title_and_town_play_their_tracks_with_a_crossfade() -> void:
	await _wait_for_music()
	var music: MusicPlayer = main.music
	assert_eq(music.track, &"title")
	assert_true(music.deck.is_started(), "the title track plays")
	await wait_until(_crossfade_done, 3.0)
	await go_to_town()
	assert_eq(music.track, &"town", "the town's own track")
	assert_eq(music.deck.track.id, &"town")
	assert_eq(music.fading_out.size(), 1, "the title fades out ...")
	assert_eq(music.fading_out[0].track.id, &"title")
	await wait_seconds(RULES.crossfade_seconds * 0.5)
	assert_between(music.deck.fade, 0.2, 0.8, "... while the town fades in")
	assert_between(music.fading_out[0].fade, 0.2, 0.8, "both play at once mid-way")
	await wait_seconds(RULES.crossfade_seconds * 0.5 + 0.3)
	assert_true(music.fading_out.is_empty(), "the title is gone after about a second")
	assert_eq(music.deck.fade, 1.0, "the town plays fully")


func test_ac108_run_layers_grow_with_time_and_the_crowd() -> void:
	var run: Run = await _quiet_run()
	var music: MusicPlayer = main.music
	assert_eq(music.track, &"run")
	await wait_seconds(1.0)
	assert_eq(music.intensity, 0, "calm at the start")
	var kick: int = 3
	assert_true(music.deck.track.layers[kick].is_drum(), "layer 3 is a drum")
	assert_eq(music.deck.layer_volume(kick), 0.0, "no drums yet")
	# A crowd of 150 zombies on screen brings the drums early.
	var hero: Player = first_player()
	for i: int in RULES.run_drums_crowd:
		var offset: Vector2 = Vector2(260.0 + (i % 15) * 30.0, -270.0 + floori(i / 15.0) * 50.0)
		run.enemies.spawn(SHAMBLER, hero.global_position + offset)
	run.enemies.calm = true
	assert_true(await wait_until(_music_level.bind(1), 2.0), "drums with a big crowd")
	await wait_seconds(RULES.layer_fade_seconds + 0.3)
	assert_almost_eq(music.deck.layer_volume(kick), 1.0, 0.01, "the drums faded in")
	assert_eq(music.deck.layer_volume(music.deck.gains.size() - 1), 0.0, "not everything yet")
	for zombie: Zombie in run.enemies.zombies.duplicate():
		run.enemies.damage(zombie, 99999.0)
	await wait_seconds(1.0)
	assert_eq(music.intensity, 1, "the layers never drop back in a run")
	run.elapsed = RULES.run_full_seconds
	assert_true(await wait_until(_music_level.bind(2), 2.0), "everything after 5:00")


func test_ac108_drums_join_after_two_minutes() -> void:
	var run: Run = await _quiet_run()
	run.elapsed = RULES.run_drums_seconds - 2.0
	await wait_seconds(1.0)
	assert_eq(main.music.intensity, 0, "still calm before 2:00")
	run.elapsed = RULES.run_drums_seconds
	assert_true(await wait_until(_music_level.bind(1), 2.0), "drums at 2:00")


func test_ac108_boss_goal_stinger_and_endless_track() -> void:
	var run: Run = await _quiet_run()
	var king: Zombie = run.spawner.spawn_boss(run.spawner.schedule.boss)
	await wait_physics_frames(2)
	assert_eq(main.music.track, &"boss", "the boss track")
	run.enemies.damage(king, king.max_health * 10.0)
	await wait_for_goal_screen(run)
	assert_true(_stinger(&"goal"), "the goal stinger plays")
	run.goal_screen.endless_button.pressed.emit()
	await wait_physics_frames(2)
	assert_eq(main.music.track, &"endless", "endless has its own track")


func test_ac108_hero_died_and_evolution_stingers() -> void:
	var run: Run = await _quiet_run()
	var hero: Player = first_player()
	await wait_seconds(RULES.check_seconds + 0.2)
	hero.add_weapon(run.upgrade_pool.find(&"peel_boomerang").weapon)
	hero.evolve(run.upgrade_pool.evolution_of(&"peel_boomerang"))
	assert_true(await wait_until(_stinger.bind(&"evolution"), 1.0), "the evolution stinger")
	hero.take_hit(hero.max_health * 10.0, "test")
	assert_true(await wait_until(_stinger.bind(&"hero_died"), 1.0), "a hero falls")


func test_ac108_siege_track_gets_busier_each_wave_and_its_stingers() -> void:
	await _wait_for_music()
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	assert_not_null(siege, "the siege started")
	if siege == null:
		return
	silence_turrets(siege)
	assert_eq(main.music.track, &"siege", "the siege's own track")
	siege.next_wave()
	await wait_seconds(RULES.check_seconds + 0.2)
	var first: int = main.music.intensity
	siege.next_wave()
	await wait_seconds(RULES.check_seconds + 0.2)
	assert_gt(main.music.intensity, first, "busier with the next wave")
	assert_eq(siege.music.level, RULES.siege_level(siege.waves.wave), "follows the wave")
	siege.dev_menu.press(DevMenu.WIN_SIEGE)
	var won: bool = await wait_until(_stinger.bind(&"siege_won"), 15.0)
	assert_true(won, "the siege won stinger")


func test_ac108_a_lost_siege_plays_its_stinger() -> void:
	await _wait_for_music()
	main.town.building_levels = {"toy_box_armory": 1, "lucky_jar": 1}
	main.town.siege_nights = 0
	var town: Town = await go_to_town()
	town.enter_bedroom()
	await wait_physics_frames(2)
	var siege: Siege = main.current_screen as Siege
	assert_not_null(siege)
	if siege == null:
		return
	silence_turrets(siege)
	for i: int in 4:
		siege.dev_menu.press(DevMenu.HURT_FORT)
	assert_true(await wait_until(_stinger.bind(&"siege_lost"), 15.0), "the siege lost stinger")


## #326: one track at a time through the King fight. Outside a crossfade exactly one track is
## heard. Beating the King fades the boss track out (no extra switch back to the run track),
## so the goal stinger plays alone; stingers duck the music; Keep going starts endless.
func test_326_the_king_fight_never_plays_two_tracks_at_once() -> void:
	_overlaps = 0
	_most_heard = 0
	_lowest_duck = 1.0
	var run: Run = await _quiet_run()
	first_player().invincible = true
	await wait_until(_crossfade_done, 3.0)
	var king: Zombie = run.spawner.spawn_boss(run.spawner.schedule.boss)
	await _watch_for(2.0)
	assert_eq(main.music.track, &"boss", "the boss track")
	assert_eq(main.music.audible_decks().size(), 1, "only the boss track after the crossfade")
	run.enemies.damage(king, king.max_health * 10.0)
	await _watch_for(0.5)
	assert_true(_stinger(&"goal"), "the goal stinger plays")
	assert_eq(main.music.track, MusicPlayer.SILENCE, "the boss track fades out")
	assert_lt(_lowest_duck, 1.0, "the stinger ducks the music")
	await _watch_for(RULES.crossfade_seconds)
	assert_eq(main.music.audible_decks().size(), 0, "the goal stinger plays alone")
	await wait_for_goal_screen(run)
	assert_eq(main.music.track, MusicPlayer.SILENCE, "no track comes back on the goal screen")
	run.goal_screen.endless_button.pressed.emit()
	await _watch_for(2.0)
	assert_eq(main.music.track, &"endless", "Keep going crossfades to endless")
	assert_eq(main.music.audible_decks().size(), 1, "only endless after the crossfade")
	assert_eq(_overlaps, 0, "never two tracks outside a crossfade")
	assert_lt(_most_heard, 3, "never more than one crossfade at a time")


## Watches the music every frame for `seconds`: counts moments where the current track plays
## fully while another one can still be heard.
func _watch_for(seconds: float) -> void:
	for i: int in roundi(seconds * FPS):
		var music: MusicPlayer = main.music
		var heard: int = music.audible_decks().size()
		_most_heard = maxi(_most_heard, heard)
		_lowest_duck = minf(_lowest_duck, music.duck)
		if music.deck != null and music.deck.fade >= 1.0 and heard > 1:
			_overlaps += 1
		await wait_physics_frames(1)
