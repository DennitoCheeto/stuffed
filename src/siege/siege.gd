class_name Siege
extends Run
## The night siege (spec 07 §2, §5, AC-76): the horde attacks the Pillow Fort. It plays like a
## run (same heroes, starting weapon, XP buttons, level-up cards, pause and developer menu), but
## in the town room at dusk: 3 waves come in from all four edges (Big Ted in the last one), a
## short breather between them. Zombies walk to the fort and knock at it, turning to a hero who
## comes close. A fallen hero stands back up at the fort door after a few seconds; the siege is
## lost only when the fort falls, and won once the last wave is popped. XP buttons are worth
## more than in a run (data/siege/siege_xp_rules.tres). No floor pickups, no rescue, no Way
## Home. Every plushie living in town helps (`plushies`, spec 07 §4). Main sets `town_save` and
## `number` before adding it.

## How a siege ended (`RunResult.ending`); giving up from the pause menu stays "quit".
const WON: String = "siege_won"
const LOST: String = "siege_lost"
## How long a wave banner stays.
const WAVE_BANNER_SECONDS: float = 2.6
## Turrets fire from this share of the way up their building (0 = its footprint middle, 1 = top).
const TURRET_HEIGHT: float = 0.5
## More plushies than spots: the next round stands this far beside the first (pixels).
const PLUSHIE_SPACING: float = 46.0
const RESCUE_RULES: RescueRules = preload("res://data/town/rescue_rules.tres")

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
## Building spot id -> its turret (Toy Box Armory, Watchtower; spec 07 §4).
var turrets: Dictionary[StringName, SiegeTurret] = {}
## Building spot id -> its ring on the ground (Snack Bar healing ring, Party Shop confetti trap).
var rings: Dictionary[StringName, SiegeRing] = {}
## Plushie id -> the plushie helping in this siege (every plushie living in town).
var plushies: Dictionary[String, SiegePlushie] = {}
## True once the night is defended.
var won: bool = false
## Wave banners shown so far (wave index), for tests.
var wave_banners: Array[int] = []
## Buildings knocked down in the fight (ids), noted when the siege ends: a lost siege damages
## them (spec 07 §6); a won one stands them back up.
var knocked_ids: PackedStringArray = []

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
	_add_plushies()
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
	_stand_buildings_up()


## Won: buildings knocked down in the fight pop back up with a puff, no damage (spec 07 §6).
func _stand_buildings_up() -> void:
	var looks: Dictionary[StringName, TownBuilding] = town_arena().buildings
	for building: SiegeBuilding in targets.buildings:
		if building.is_fallen():
			building.revive()
			looks[building.id].stand_up()


## A siege's result also tells which siege it was, the waves held and what was knocked down.
## Giving up counts as lost (`won` stays false).
func make_result(ending: String) -> RunResult:
	var result: RunResult = super(ending)
	result.won = ending == WON
	result.siege_number = number
	result.wave_count = waves.count()
	result.waves_held = waves.held(result.won)
	# Giving up mid-fight (no won/lost ending yet): what is down right now counts.
	result.knocked_down = _knocked_now() if _ending.is_empty() else knocked_ids.duplicate()
	return result


func _knocked_now() -> PackedStringArray:
	var ids: PackedStringArray = []
	for id: StringName in targets.knocked_down():
		ids.append(String(id))
	return ids


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
		_add_turret(building, spot, look)
		_add_ring(building, spot)


## A built turret building (Armory, Watchtower) fires on its own from the middle of its look.
func _add_turret(building: SiegeBuilding, spot: TownSpot, look: TownBuilding) -> void:
	var data: BuildingLevel = spot.building.levels[building.level - 1]
	if data.siege_weapon_level <= 0:
		return
	var stats: WeaponStats = spot.building.siege_weapon
	if stats == null:
		stats = _hero_weapon()
	if stats == null:
		return
	var middle: Vector2 = spot.rect.get_center()
	var at: Vector2 = Vector2(middle.x, lerpf(middle.y, look.top_y(), TURRET_HEIGHT))
	var turret: SiegeTurret = SiegeTurret.new()
	turret.setup(building, stats, data.siege_weapon_level, data.siege_range, at)
	town_arena().add_child(turret)
	turrets[spot.id] = turret


## A built Snack Bar heals heroes in its ring, a built Party Shop pops confetti at zombies in
## its ring (spec 07 §4). Both lie on the floor around the building.
func _add_ring(building: SiegeBuilding, spot: TownSpot) -> void:
	var data: BuildingLevel = spot.building.levels[building.level - 1]
	var middle: Vector2 = spot.rect.get_center()
	var ring: SiegeRing = null
	if data.siege_heal > 0.0:
		var heal: SiegeHealRing = SiegeHealRing.new()
		var color: Color = siege_rules.heal_ring_color
		heal.setup(building, data.siege_heal, data.siege_range, middle, color)
		ring = heal
	elif data.siege_trap_seconds > 0.0:
		var trap: SiegeConfettiTrap = SiegeConfettiTrap.new()
		trap.setup(building, data, middle, siege_rules, self)
		ring = trap
	if ring == null:
		return
	town_arena().add_to_floor(ring)
	rings[spot.id] = ring


## Every plushie living in town stands by the fort and helps (spec 07 §4, AC-79). A built,
## undamaged Plush Hospital stands knocked-out plushies back up.
func _add_plushies() -> void:
	var hospital: SiegeBuilding = null
	var seconds: float = 0.0
	for building: SiegeBuilding in targets.buildings:
		var data: BuildingLevel = layout.spot(building.id).building.levels[building.level - 1]
		if data.siege_revive_seconds > 0.0:
			hospital = building
			seconds = data.siege_revive_seconds
	for id: String in town_save.plushies:
		var who: PlushieDef = RESCUE_RULES.find(id)
		if town_save.plushies[id] != "in_town" or who == null:
			continue
		var helper: SiegePlushie = SiegePlushie.new()
		helper.setup(who, _plushie_spot(plushies.size()), siege_rules)
		helper.set_hospital(hospital, seconds)
		town_arena().add_child(helper)
		targets.plushies.append(helper.target)
		plushies[id] = helper


## Where the plushie number `index` (0 = the first) stands by the fort.
func _plushie_spot(index: int) -> Vector2:
	var spots: PackedVector2Array = layout.siege_plushie_spots
	if spots.is_empty():
		return layout.spawn_position + Vector2(PLUSHIE_SPACING * (index + 1), 0.0)
	var round_index: int = floori(float(index) / spots.size())
	return spots[index % spots.size()] + Vector2(PLUSHIE_SPACING * round_index, 0.0)


## The starting weapon of the first hero (co-op: player 1's), the Armory's turret weapon.
func _hero_weapon() -> WeaponStats:
	var first: Player = null
	for player: Player in Players.all(get_tree()):
		if first == null or player.player_index < first.player_index:
			first = player
	return first.starting_weapon if first != null else null


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
	knocked_ids = _knocked_now()
	over = true
	enemies.calm = true
	for turret: SiegeTurret in turrets.values():
		turret.stop()
	for ring: SiegeRing in rings.values():
		ring.stop()
	for helper: SiegePlushie in plushies.values():
		helper.stop()
	projectiles.clear_hostile()
	hud.show_banner(title, subtitle, siege_rules.end_pause_seconds + 1.0)
	# A timer connection (not await) so nothing fires if the siege is closed meanwhile.
	_ending = ending
	get_tree().create_timer(siege_rules.end_pause_seconds).timeout.connect(_finish)


func _finish() -> void:
	finished.emit(make_result(_ending))


func _show_clock() -> void:
	hud.show_time(elapsed, siege_rules.total_seconds())
