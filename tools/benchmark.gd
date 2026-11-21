extends SceneTree
## Frame-rate check for spec 02 §14 on a real PC (not headless): a run with 500 zombies around
## Banane, hundreds of player shots and enemy bullets kept topped up. Prints the average fps and
## draw calls, then quits. Run from the project folder:
##   Godot_v4.7.2-stable_win64.exe --path . -s tools/benchmark.gd
## Add `-- --shot=C:/path/frame.png` to also save one frame as a picture.
## Add `-- --siege` for the night siege (spec 07 §11): every building at its top level firing, all
## plushies helping and `SIEGE_ZOMBIES` zombies around the fort, at dusk in the town.
## Add `-- --hero=pip` to play as that hero (spec 08 §13: compare draw calls with Banane's).
## Add `-- --gear` to wear a Lv 3 Lookout Cap, Picnic Apron and Jingle Bell (spec 09 §12: compare
## with the same run without gear; within ~5% fps, at most +3 draw calls).
## Add `-- --evolutions` to carry all evolved weapons at once (spec 10 §11: at most +15 draw calls
## compared to `main` before M6, no frame over 16 ms). Every mode prints its worst frame time.

const MAIN_SCENE: PackedScene = preload("res://src/main/main.tscn")
const SHAMBLER: EnemyStats = preload("res://data/enemies/shambler.tres")
const SNIPER: WeaponStats = preload("res://data/weapons/sewing_pin_sniper.tres")
const POOL: UpgradePool = preload("res://data/upgrade_pool.tres")
const ZOMBIES: int = 500
const SIEGE_ZOMBIES: int = 300
const SHOTS: int = 600
const BULLETS: int = 400
const WARM_UP: float = 1.5
const SECONDS: float = 6.0
const BENCH_SAVE: String = "user://benchmark_save.json"
const BENCH_SETTINGS: String = "user://benchmark_settings.json"
const LAYOUT: TownLayout = preload("res://data/town/pillow_fort.tres")
const PLUSHIES: Array[String] = ["pip", "bobo", "bambam", "robbar"]
## Head, Body, Charm worn with `--gear`: pieces whose effects keep drawing while the hero stands.
const GEAR: Dictionary[String, String] = {
	"head": "lookout_cap", "body": "picnic_apron", "charm": "jingle_bell"
}

var _run: Run
var _sniper: Weapon
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _siege: bool = false
var _zombies: int = ZOMBIES
## Where the zombies crowd: around Banane in the Bedroom, around the fort in the siege.
var _crowd_center: Vector2 = Vector2.ZERO


func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_start.call_deferred()


func _start() -> void:
	# Never touch the player's own save or settings.
	SaveStore.path = BENCH_SAVE
	SaveStore.delete_all()
	GameSettings.path = BENCH_SETTINGS
	# Main applies the saved screen options on boot: keep V-Sync off for honest fps.
	GameSettings.reset()
	GameSettings.vsync = false
	# First-time hint notes would only add a note to the picture.
	GameSettings.hints = false
	GameSettings.save()
	var main: Main = MAIN_SCENE.instantiate()
	main.quit_enabled = false
	root.add_child(main)
	for i: int in 5:
		await process_frame
	_siege = OS.get_cmdline_user_args().has("--siege")
	var hero: String = _arg("--hero=")
	if not hero.is_empty():
		main.town.plushies[hero] = "in_town"
		main.town.set_hero(0, hero)
	var geared: bool = OS.get_cmdline_user_args().has("--gear")
	var evolved: bool = OS.get_cmdline_user_args().has("--evolutions")
	if geared:
		_dress(main)
	(main.current_screen as TitleScreen).start_button.pressed.emit()
	for i: int in 3:
		await physics_frame
	if _siege:
		_ready_the_town(main)
		main.show_town()
		for i: int in 3:
			await physics_frame
	(main.current_screen as Town).enter_bedroom()
	for i: int in 3:
		await physics_frame
	_run = main.current_screen as Run
	_run.spawner.active = false
	var banane: Player = Players.all(self)[0]
	_crowd_center = banane.global_position
	if _siege:
		var siege: Siege = _run as Siege
		_zombies = SIEGE_ZOMBIES
		_crowd_center = siege.layout.fort_rect.get_center()
		banane.global_position = _crowd_center + Vector2(0.0, siege.layout.fort_rect.size.y)
	banane.invincible = true
	var boomerang: Weapon = banane.weapons()[0]
	_sniper = banane.add_weapon(SNIPER)
	for i: int in 4:
		boomerang.level_up()
		_sniper.level_up()
	if evolved:
		for evolution: EvolutionDef in POOL.evolutions:
			banane.add_weapon(evolution.evolved)
	physics_frame.connect(_top_up)
	if _siege:
		# Only once the crowd is in: a siege with no waves and nobody left is won at once.
		_top_up()
		(_run as Siege).waves.finished = true
	await create_timer(WARM_UP).timeout
	var frames_before: int = Engine.get_frames_drawn()
	var start: int = Time.get_ticks_usec()
	var draw_calls: float = 0.0
	var process_ms: float = 0.0
	var physics_ms: float = 0.0
	var samples: int = 0
	var worst_ms: float = 0.0
	var last: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < SECONDS * 1_000_000.0:
		await process_frame
		var now: int = Time.get_ticks_usec()
		worst_ms = maxf(worst_ms, (now - last) / 1000.0)
		last = now
		draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		process_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		samples += 1
	_save_shot()
	var seconds: float = (Time.get_ticks_usec() - start) / 1_000_000.0
	var fps: float = (Engine.get_frames_drawn() - frames_before) / seconds
	var mode: String = "siege" if _siege else "bedroom"
	mode += (" gear" if geared else "") + (" evolutions" if evolved else "")
	print(
		(
			"BENCHMARK %s zombies=%d shots=%d bullets=%d fps=%.1f draw_calls=%.0f process_ms=%.1f physics_ms=%.1f"
			% [
				mode,
				_run.enemies.alive_count(),
				_run.projectiles.active.size() - _run.projectiles.hostile_count(),
				_run.projectiles.hostile_count(),
				fps,
				draw_calls / maxi(samples, 1),
				process_ms / maxi(samples, 1),
				physics_ms / maxi(samples, 1),
			]
		)
	)
	print("BENCHMARK worst_frame_ms=%.1f" % worst_ms)
	quit()


## Keeps the screen full: zombies around Banane, pins flying out, bullets flying in.
func _top_up() -> void:
	var center: Vector2 = _crowd_center
	while _run.enemies.alive_count() < _zombies:
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


## Siege mode: the saved town has every building at its top level, all plushies at home and the
## horde due, so the fort door starts the siege.
func _ready_the_town(main: Main) -> void:
	for spot: TownSpot in LAYOUT.spots:
		main.town.building_levels[String(spot.id)] = 3
		main.town.revealed.append(String(spot.id))
	for id: String in PLUSHIES:
		main.town.plushies[id] = "in_town"
	main.town.siege_nights = 0


## Gear mode: the Workshop at Lv 3 and player 1 wearing `GEAR`, every piece stitched to Lv 3.
func _dress(main: Main) -> void:
	main.town.building_levels["sewing_workshop"] = 3
	main.town.revealed.append("sewing_workshop")
	for slot: String in GEAR:
		var id: String = GEAR[slot]
		main.town.gear.add_pattern(id)
		main.town.gear.stitches[id] = 3
		main.town.gear.put_on(0, slot, id)


## The value of a `--name=value` argument ("" if not given).
func _arg(prefix: String) -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


func _save_shot() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			root.get_texture().get_image().save_png(arg.trim_prefix("--shot="))
