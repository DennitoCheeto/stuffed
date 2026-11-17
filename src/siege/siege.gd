class_name Siege
extends Run
## The night siege (spec 07 §2, §5, AC-76): the horde attacks the Pillow Fort. It plays like a
## run (same heroes, starting weapon, XP buttons, level-up cards, pause and developer menu), but
## in the town room at dusk: 3 waves come in from all four edges (Big Ted in the last one), a
## short breather between them. Zombies walk to the fort and knock at it, turning to a hero who
## comes close. A fallen hero stands back up at the fort door after a few seconds; the siege is
## lost only when the fort falls, and won once the last wave is popped. XP buttons are worth
## more than in a run (data/siege/siege_xp_rules.tres). No floor pickups, no rescue, no Way
## Home. Main sets `town_save` and `number` before adding it.

## How a siege ended (`RunResult.ending`); giving up from the pause menu stays "quit".
const WON: String = "siege_won"
const LOST: String = "siege_lost"
## How long a wave banner stays.
const WAVE_BANNER_SECONDS: float = 2.6

@export var siege_rules: SiegeRules
@export var layout: TownLayout

## The town being attacked (its buildings and levels). Set by Main.
var town_save: TownSave = TownSave.new()
## Which siege this is (1 = the first; later ones are bigger). Set by Main.
var number: int = 1
var waves: SiegeWaves
var fort: SiegeFort
## The fort and the built buildings the horde goes for (AC-77).
var targets: SiegeTargets
var fort_bar: FortHealthBar
## Building spot id -> its small health bar (only built, undamaged buildings).
var building_bars: Dictionary[StringName, BuildingHealthBar] = {}
## True once the night is defended.
var won: bool = false
## Wave banners shown so far (wave index), for tests.
var wave_banners: Array[int] = []

## Fallen heroes (player index) -> seconds until they stand back up.
var _fallen: Dictionary[int, float] = {}
## Fractional zombies owed (rate x time), so low rates still spawn evenly.
var _owed: float = 0.0
## How the siege ended (set when it is over).
var _ending: String = ""


func _ready() -> void:
	town_arena().setup(layout, town_save)
	super()
	var area: Rect2 = town_arena().spawn_area(siege_rules.spawn_margin)
	enemies.play_rect = area
	projectiles.play_rect = area
	spawner.active = false
	floor_pickup_drops.next_drop_at = INF
	enemies.health_scale = siege_rules.health_scale(number)
	waves = SiegeWaves.new(siege_rules)
	var health: float = siege_rules.fort_health_for(town_save.total_levels())
	fort = SiegeFort.new(
		layout.fort_rect, health, siege_rules.hero_reach, siege_rules.fort_touch_rate
	)
	fort.fell.connect(_on_fort_fell)
	targets = SiegeTargets.new(fort)
	_add_buildings()
	enemies.siege = targets
	fort_bar = FortHealthBar.new(fort)
	hud.add_child(fort_bar)
	vignette.visible = false


func _physics_process(delta: float) -> void:
	super(delta)
	if over:
		return
	_stand_up_fallen(delta)
	_spawn_waves(delta)
	if waves.finished and enemies.alive_count() == 0:
		win()


func town_arena() -> SiegeArena:
	return arena as SiegeArena


## Developer menu: the next wave starts now.
func next_wave() -> void:
	var started: int = waves.next_wave()
	if started >= 0:
		_announce_wave(started)


## The night is defended: the horde pops, a banner, then home.
func win() -> void:
	if over:
		return
	won = true
	_end(WON, siege_rules.won_banner, siege_rules.won_subtitle)
	Sfx.play(&"goal")
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			player.celebrate()
	enemies.pop_all_in_chain(fort.rect.get_center(), POP_CHAIN_TIME)


func make_result(ending: String) -> RunResult:
	var result: RunResult = super(ending)
	result.won = ending == WON
	return result


## A siege brings nothing home by the kill: its reward comes at the end (spec 07 §6, M4-07).
func collect(_amounts: Dictionary[String, int], _at: Vector2, _burst: bool = false) -> void:
	pass


## No Way Home in the siege (Big Ted is the night's boss here).
func open_way_home(_near: Vector2) -> WayHomePortal:
	return null


## A fallen hero stands back up at the fort after a few seconds: the siege goes on.
func _on_player_died(player: Player) -> void:
	Sfx.play(&"death")
	_fallen[player.player_index] = siege_rules.stand_up_seconds


func _stand_up_fallen(delta: float) -> void:
	if _fallen.is_empty():
		return
	for player: Player in Players.all(get_tree()):
		var index: int = player.player_index
		if not _fallen.has(index):
			continue
		_fallen[index] -= delta
		if _fallen[index] <= 0.0:
			_fallen.erase(index)
			var spot: Vector2 = arena.center() + Vector2(PLAYER_SPACING * index, 0.0)
			player.stand_up(spot)
			Sfx.play(&"upgrade")


## Seconds until the fallen hero `index` stands back up (0 = standing).
func stand_up_left(index: int) -> float:
	return _fallen.get(index, 0.0)


func _spawn_waves(delta: float) -> void:
	var started: int = waves.tick(delta)
	if started >= 0:
		_announce_wave(started)
	var wave: SiegeWave = waves.current()
	if wave == null:
		return
	_owed += waves.rate() * siege_rules.zombie_scale(number) * delta
	while _owed >= 1.0:
		_owed -= 1.0
		_spawn_one(wave.pick(rng), null)
	for i: int in waves.take_elites():
		var elite: Zombie = _spawn_one(wave.pick(rng), siege_rules.elite_rules)
		if elite != null:
			spawner.elite_spawned.emit(elite)
	var boss: BossDef = waves.take_boss()
	if boss != null:
		var at: Vector2 = _edge_point(boss.enemy.radius * boss.size)
		spawner.boss_spawned.emit(enemies.spawn_boss(boss, at))


func _spawn_one(stats: EnemyStats, elite: EliteRules) -> Zombie:
	if stats == null:
		return null
	var radius: float = stats.radius * (elite.size if elite != null else 1.0)
	return enemies.spawn(stats, _edge_point(radius), elite)


func _edge_point(radius: float) -> Vector2:
	return town_arena().edge_point(siege_rules.spawn_margin, radius, rng)


func _announce_wave(index: int) -> void:
	wave_banners.append(index)
	var last: bool = index == waves.count() - 1
	var title: String = siege_rules.wave_banner % [index + 1, waves.count()]
	var subtitle: String = siege_rules.last_wave_subtitle if last else siege_rules.wave_subtitle
	hud.show_banner(title, subtitle, WAVE_BANNER_SECONDS)
	Sfx.play(&"elite")


## Every built, undamaged building fights along (spec 07 §4): it gets health and a small bar.
## Ruins and damaged buildings stand still and the horde ignores them.
func _add_buildings() -> void:
	var looks: Dictionary[StringName, TownBuilding] = town_arena().buildings
	for spot: TownSpot in layout.spots:
		var level: int = town_save.building_level(String(spot.id))
		if level <= 0 or town_save.is_damaged(String(spot.id)) or not looks.has(spot.id):
			continue
		var building: SiegeBuilding = SiegeBuilding.new(spot, level, siege_rules)
		targets.buildings.append(building)
		var look: TownBuilding = looks[spot.id]
		var bar: BuildingHealthBar = BuildingHealthBar.new(
			building, Vector2(spot.rect.get_center().x, look.top_y())
		)
		town_arena().add_child(bar)
		building_bars[spot.id] = bar
		building.fell.connect(_on_building_fell.bind(look))


## A building's health is gone: it tips over and stops fighting for the rest of the siege.
func _on_building_fell(look: TownBuilding) -> void:
	look.knock_down(
		siege_rules.knocked_tilt_degrees, siege_rules.knocked_sink, siege_rules.knocked_tint
	)
	Sfx.play(&"stomp")
	camera.shake(0.25)


func _on_fort_fell() -> void:
	if over:
		return
	_end(LOST, siege_rules.lost_banner, siege_rules.lost_subtitle)
	Sfx.play(&"death")
	camera.shake(0.6)


## The siege is over: nothing new comes, the zombies calm down, a banner, then home.
func _end(ending: String, title: String, subtitle: String) -> void:
	over = true
	enemies.calm = true
	projectiles.clear_hostile()
	hud.show_banner(title, subtitle, siege_rules.end_pause_seconds + 1.0)
	# A timer connection (not await) so nothing fires if the siege is closed meanwhile.
	_ending = ending
	get_tree().create_timer(siege_rules.end_pause_seconds).timeout.connect(_finish)


func _finish() -> void:
	finished.emit(make_result(_ending))


func _show_clock() -> void:
	hud.show_time(elapsed, siege_rules.total_seconds())
