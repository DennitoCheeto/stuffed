extends SceneTree
## Frame-rate check for spec 02 §14 on a real PC (not headless): a run with 500 zombies around
## Banane, hundreds of player shots and enemy bullets kept topped up. Prints the average fps and
## draw calls, then quits. Run from the project folder:
##   Godot_v4.7.2-stable_win64.exe --path . -s tools/benchmark.gd
## Add `-- --shot=C:/path/frame.png` to also save one frame as a picture.

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")
const ZOMBIES: int = 500
const SHOTS: int = 600
const BULLETS: int = 400
const WARM_UP: float = 1.5
const SECONDS: float = 6.0
const BENCH_SAVE: String = "user://benchmark_save.json"
const BENCH_SETTINGS: String = "user://benchmark_settings.json"

var _run: Run
var _sniper: Weapon
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_start.call_deferred()


func _start() -> void:
	# Never touch the player's own save or settings.
	SaveStore.path = BENCH_SAVE
	GameSettings.path = BENCH_SETTINGS
	var main: Main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	root.add_child(main)
	for i: int in 5:
		await process_frame
	(main.current_screen as TitleScreen).start_button.pressed.emit()
	for i: int in 3:
		await physics_frame
	(main.current_screen as Town).enter_bedroom()
	for i: int in 3:
		await physics_frame
	_run = main.current_screen as Run
	_run.spawner.active = false
	var banane: Player = Players.all(self)[0]
	banane.invincible = true
	var boomerang: Weapon = banane.weapon(&"peel_boomerang")
	_sniper = banane.add_weapon(SNIPER)
	for i: int in 4:
		boomerang.level_up()
		_sniper.level_up()
	physics_frame.connect(_top_up)
	await create_timer(WARM_UP).timeout
	var frames_before: int = Engine.get_frames_drawn()
	var start: int = Time.get_ticks_usec()
	var draw_calls: float = 0.0
	var samples: int = 0
	while Time.get_ticks_usec() - start < SECONDS * 1_000_000.0:
		await process_frame
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		samples += 1
	_save_shot()
	var seconds: float = (Time.get_ticks_usec() - start) / 1_000_000.0
	var fps: float = (Engine.get_frames_drawn() - frames_before) / seconds
	print(
		(
			"BENCHMARK zombies=%d shots=%d bullets=%d fps=%.1f draw_calls=%.0f"
			% [
				_run.enemies.alive_count(),
				_run.projectiles.active.size() - _run.projectiles.hostile_count(),
				_run.projectiles.hostile_count(),
				fps,
				draw_calls / maxi(samples, 1),
			]
		)
	)
	quit()


## Keeps the screen full: zombies around Banane, pins flying out, bullets flying in.
func _top_up() -> void:
	var center: Vector2 = Players.all(self)[0].global_position
	while _run.enemies.alive_count() < ZOMBIES:
		var offset: Vector2 = Vector2.RIGHT.rotated(_rng.randf() * TAU) * _rng.randf_range(150, 700)
		var spot: Vector2 = center + offset
		var zombie: Zombie = _run.enemies.spawn(SHAMBLER, spot)
		zombie.max_health = 1_000_000.0
		zombie.health = zombie.max_health
	var shots: ProjectileManager = _run.projectiles
	while shots.active.size() - shots.hostile_count() < SHOTS:
		var pin: PinProjectile = shots.spawn(PinProjectile) as PinProjectile
		pin.launch(_sniper, Vector2.RIGHT.rotated(_rng.randf() * TAU))
	while shots.hostile_count() < BULLETS:
		var angle: float = _rng.randf() * TAU
		var bullet: EnemyBullet = shots.spawn(EnemyBullet) as EnemyBullet
		var at: Vector2 = center + Vector2.RIGHT.rotated(angle) * 650.0
		bullet.launch(at, Vector2.LEFT.rotated(angle) * 90.0, 1.0, 8.0, 7.0, "Benchmark")


func _save_shot() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			root.get_texture().get_image().save_png(arg.trim_prefix("--shot="))
