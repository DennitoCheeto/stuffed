extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 01 §10, AC-31 and the feel pass): music, sounds, damage numbers, screen shake,
## hit-stop.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")

var run: Run


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	disarm(first_player())
	return run


func _music_bus_muffled() -> bool:
	return AudioServer.is_bus_effect_enabled(AudioServer.get_bus_index(&"Music"), 0)


func test_ac31_music_plays_on_the_title_screen() -> void:
	assert_true(main.music.playing, "music is playing")
	assert_eq(main.music.track, &"title")
	assert_eq(main.music.bus, &"Music")


func test_ac31_music_plays_during_the_run() -> void:
	await start_run()
	assert_true(main.music.playing)
	assert_eq(main.music.track, &"run")


func test_music_is_muffled_while_paused() -> void:
	await start_run()
	assert_false(_music_bus_muffled())
	sender.action_down("pause")
	await wait_process_frames(2)
	sender.action_up("pause")
	assert_true(_music_bus_muffled(), "muffled in the pause menu")
	assert_true(main.music.playing, "but still playing")
	(main.current_screen as Run).pause_menu.close()
	assert_false(_music_bus_muffled(), "clear again")


func test_many_identical_sounds_are_limited() -> void:
	var started: int = 0
	for i: int in 30:
		if Sfx.play(&"pop"):
			started += 1
	assert_gt(started, 0)
	assert_true(started <= Sfx.max_voices(&"pop"), "at most %d pops at once" % started)


func test_damage_numbers_show_on_hits_and_can_be_turned_off() -> void:
	await _quiet_run()
	var spot: Vector2 = first_player().global_position + Vector2(300, 0)
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
	zombie.max_health = 1000.0
	zombie.health = 1000.0
	GameSettings.damage_numbers = true
	run.enemies.damage(zombie, 7.0)
	assert_eq(run.damage_numbers.count(), 1, "a number for the hit")
	GameSettings.damage_numbers = false
	run.enemies.damage(zombie, 7.0)
	assert_eq(run.damage_numbers.count(), 1, "none while turned off")
	GameSettings.damage_numbers = true
	await wait_seconds(DamageNumbers.LIFETIME + 0.1)
	assert_eq(run.damage_numbers.count(), 0, "numbers fade away")


func test_screen_shakes_when_banane_is_hurt() -> void:
	await _quiet_run()
	assert_eq(run.camera.trauma, 0.0)
	first_player().take_hit(5.0, "Shambler")
	assert_gt(run.camera.trauma, 0.0, "shake")
	await wait_seconds(0.6)
	assert_eq(run.camera.trauma, 0.0, "and it calms down")


func test_hit_stop_when_a_pin_goes_through_three_zombies() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	for i: int in 3:
		var spot: Vector2 = banane.global_position + Vector2(100 + i * 40, 0)
		var zombie: Zombie = run.enemies.spawn(SHAMBLER, spot)
		zombie.move_speed = 0.0
		zombie.max_health = 1000.0
		zombie.health = 1000.0
	var sniper: SewingPinSniper = banane.add_weapon(SNIPER) as SewingPinSniper
	var pin: PinProjectile = PinProjectile.new()
	pin.top_level = true
	sniper.add_child(pin)
	pin.launch(sniper, run.enemies, Vector2.RIGHT)
	await wait_physics_frames(20)
	assert_eq(run.hit_stops, 1, "one heavy hit")
	assert_false(run.is_frozen(), "the hit-stop is over quickly")
