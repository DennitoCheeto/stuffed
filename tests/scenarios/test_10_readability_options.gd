extends "res://tests/scenarios/run_scenario.gd"
## Scenario (spec 10 §5, §8, §9, AC-111): the Readability tab. Screen shake 0% means a still
## camera; Flashes off removes the white hit flashes (zombies, sparkle pops) and softens the
## hero's; Own effects lowers only the players' own shots and effects (zombies and enemy bullets
## never change); Hints on/off + "Show hints again". Everything survives a restart.

const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")

var run: Run
## Calls to `forget_hints` this test received (as a member of the hint keepers group).
var forgotten: int = 0


func after_each() -> void:
	GameSettings.reset()
	super.after_each()


## Called by "Show hints again" (this test joins SettingsPanel.HINT_KEEPERS).
func forget_hints() -> void:
	forgotten += 1


func _quiet_run() -> Run:
	run = await start_run()
	run.spawner.active = false
	return run


func _dummy(at: Vector2) -> Zombie:
	var zombie: Zombie = run.enemies.spawn(SHAMBLER, at)
	zombie.move_speed = 0.0
	zombie.max_health = 100000.0
	zombie.health = 100000.0
	return zombie


## The opacity `item` is really drawn with (its own times every parent's).
func _drawn_alpha(item: CanvasItem) -> float:
	var alpha: float = 1.0
	var at: Node = item
	while at != null:
		var canvas: CanvasItem = at as CanvasItem
		if canvas != null:
			alpha *= canvas.modulate.a
			if canvas.top_level:
				return alpha
		at = at.get_parent()
	return alpha


## The biggest camera offset along one axis over `frames` frames after a full shake (each axis
## is at most the shake strength; the length can be up to √2 times that).
func _shake_seen(frames: int) -> float:
	run.camera.shake(1.0)
	var most: float = 0.0
	for i: int in frames:
		await wait_process_frames(1)
		var offset: Vector2 = run.camera.offset
		most = maxf(most, maxf(absf(offset.x), absf(offset.y)))
	return most


func test_ac111_screen_shake_zero_keeps_the_camera_still() -> void:
	await _quiet_run()
	GameSettings.screen_shake = 1.0
	assert_gt(await _shake_seen(10), 1.0, "full shake moves the camera")
	await wait_seconds(0.6)
	GameSettings.screen_shake = 0.0
	assert_eq(await _shake_seen(10), 0.0, "0% = no camera shake")
	await wait_seconds(0.6)
	GameSettings.screen_shake = 0.4
	var some: float = await _shake_seen(10)
	assert_gt(some, 0.0, "40% still shakes")
	assert_lt(some, PlayersCamera.MAX_SHAKE * 0.41, "but less")


func test_ac111_flashes_off_removes_white_hit_flashes_and_softens_the_hero() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	disarm(banane)
	var zombie: Zombie = _dummy(banane.global_position + Vector2(300, 0))
	await wait_seconds(0.5)
	run.enemies.damage(zombie, 1.0, Vector2.ZERO, null)
	await wait_physics_frames(1)
	assert_true(zombie.puppet.flash.visible, "Flashes on: the zombie flashes white")
	GameSettings.flashes = false
	await wait_seconds(0.3)
	run.enemies.damage(zombie, 1.0, Vector2.ZERO, null)
	await wait_physics_frames(1)
	assert_false(zombie.puppet.flash.visible, "Flashes off: no white flash")
	var puppet: BananePuppet = banane.get_node(^"Puppet") as BananePuppet
	banane.take_hit(1.0, "test")
	var most: float = 0.0
	for i: int in 20:
		await wait_process_frames(1)
		most = maxf(most, puppet.flash())
	assert_gt(most, 0.0, "the hero's hit flash stays")
	assert_almost_eq(most, GameSettings.READABILITY.hero_flash_soft, 0.01, "but softer")


func test_ac111_flashes_off_skips_the_sparkle_pops_of_evolved_shots() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	disarm(banane)
	var zombie: Zombie = _dummy(banane.global_position + Vector2(300, 0))
	var evolved: WeaponStats = load("res://data/weapons/pincushion_volley.tres") as WeaponStats
	assert_not_null(evolved.shot_look, "an evolved weapon has a hit flash")
	# A pin that is not flying (only its hit is used).
	var shot: Projectile = PinProjectile.new()
	shot.manager = run.projectiles
	add_child_autofree(shot)
	shot.look = evolved.shot_look
	var pops: int = _sparkles()
	shot.hurt(zombie, 1.0, Vector2.ZERO)
	assert_eq(_sparkles(), pops + 1, "Flashes on: a sparkle pop")
	GameSettings.flashes = false
	shot.hurt(zombie, 1.0, Vector2.ZERO)
	assert_eq(_sparkles(), pops + 1, "Flashes off: none")


func _sparkles() -> int:
	var count: int = 0
	for shot: Projectile in run.projectiles.active:
		if shot is SparkleProjectile:
			count += 1
	return count


func test_ac111_own_effects_only_fade_the_players_own_shots_and_effects() -> void:
	await _quiet_run()
	var banane: Player = first_player()
	var zombie: Zombie = _dummy(banane.global_position + Vector2(250, 0))
	var bullet: EnemyBullet = run.projectiles.spawn(EnemyBullet) as EnemyBullet
	bullet.launch(banane.global_position + Vector2(0, -600), Vector2(0, 1), 7.0, 8.0, 5.0, "Spit")
	GameSettings.own_effects = 0.5
	await wait_physics_frames(roundi(2.0 * FPS))
	var own: Array[Projectile] = []
	for shot: Projectile in run.projectiles.active:
		if not shot.is_hostile():
			own.append(shot)
	assert_gt(own.size(), 0, "Banane's weapon fired")
	for shot: Projectile in own:
		assert_almost_eq(_drawn_alpha(shot), 0.5, 0.01, "own shot at 50%")
	assert_almost_eq(_drawn_alpha(bullet), 1.0, 0.001, "enemy bullet unchanged")
	assert_almost_eq(_drawn_alpha(zombie), 1.0, 0.001, "zombie unchanged")
	assert_almost_eq(_drawn_alpha(zombie.puppet), 1.0, 0.001, "zombie puppet unchanged")
	GameSettings.own_effects = 1.0
	await wait_physics_frames(2)
	for shot: Projectile in run.projectiles.active:
		if not shot.is_hostile():
			assert_almost_eq(_drawn_alpha(shot), 1.0, 0.01, "back to full")


func test_ac111_readability_tab_changes_everything_and_it_survives_a_restart() -> void:
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	var page: SettingsPanel = title.settings
	page.show_tab(SettingsPanel.Tab.READABILITY)
	for control: Control in [
		page.shake_slider, page.own_effects_slider, page.flashes_check, page.hints_check
	]:
		assert_true(control.is_visible_in_tree(), "%s on the Readability tab" % control)
	assert_eq(page.own_effects_slider.min_value, GameSettings.READABILITY.own_effects_min)
	page.shake_slider.value = 0.4
	page.own_effects_slider.value = 0.6
	page.flashes_check.button_pressed = false
	page.hints_check.button_pressed = false
	assert_almost_eq(GameSettings.screen_shake, 0.4, 0.001, "shake at once")
	assert_almost_eq(GameSettings.own_effects, 0.6, 0.001, "own effects at once")
	assert_false(GameSettings.flashes, "flashes at once")
	assert_false(GameSettings.hints, "hints at once")
	page.close()
	GameSettings.reset()
	GameSettings.load_saved()
	assert_almost_eq(GameSettings.screen_shake, 0.4, 0.001, "shake saved")
	assert_almost_eq(GameSettings.own_effects, 0.6, 0.001, "own effects saved")
	assert_false(GameSettings.flashes, "flashes saved")
	assert_false(GameSettings.hints, "hints saved")
	page.open()
	page.show_tab(SettingsPanel.Tab.READABILITY)
	assert_almost_eq(page.shake_slider.value, 0.4, 0.001, "the slider shows it")
	assert_false(page.flashes_check.button_pressed, "the switch shows it")


func test_ac111_show_hints_again_turns_hints_on_and_tells_the_save() -> void:
	add_to_group(SettingsPanel.HINT_KEEPERS)
	forgotten = 0
	GameSettings.hints = false
	var title: TitleScreen = main.current_screen as TitleScreen
	title.open_settings()
	await wait_process_frames(2)
	var page: SettingsPanel = title.settings
	var asked: Array[int] = []
	page.hints_again_requested.connect(func() -> void: asked.append(1))
	page.show_tab(SettingsPanel.Tab.READABILITY)
	assert_false(page.hints_check.button_pressed, "hints off")
	assert_false(page.hints_note.visible, "no note yet")
	page.hints_again_button.pressed.emit()
	assert_true(GameSettings.hints, "hints back on")
	assert_true(page.hints_check.button_pressed, "the switch shows it")
	assert_eq(asked.size(), 1, "the panel asks")
	assert_eq(forgotten, 1, "the hint keepers forget the seen hints")
	assert_true(page.hints_note.visible, "a note says so")
	remove_from_group(SettingsPanel.HINT_KEEPERS)
