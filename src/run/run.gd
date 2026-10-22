class_name Run
extends Node2D
## One run: the arena, the players, the zombies, the camera and the HUD. Counts the run time and
## runs the level-up flow.

## The run is over (death, or End run after the goal). Main shows the end screen.
signal finished(result: RunResult)
## The goal time was reached (zombies pop, then the choice appears).
signal goal_reached
## The player chose "Keep going (endless)".
signal endless_started
## The player gave up from the pause menu (the result is still logged, the haul banked).
signal gave_up(result: RunResult)
## The developer menu asks for a new run (0 = new random seed).
signal restart_requested(seed_value: int)
## The music should change to `track` (the boss fight has its own).
signal music_requested(track: StringName)
## Time to save the haul so far (every CHECKPOINT_SECONDS of run time).
signal checkpoint_due

## Weapons and effects find the run through this group.
const GROUP: StringName = &"run"
## How often the run's haul is saved while it goes (spec 03 §9).
const CHECKPOINT_SECONDS: float = 5.0
const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
## How long the chain of pops takes when the goal is reached.
const POP_CHAIN_TIME: float = 1.0
## A short moment to enjoy the empty floor before the choice appears.
const CELEBRATION_TIME: float = 1.2
## A moment to see Banane fall before the end screen.
const DEATH_PAUSE: float = 1.5
## A tiny freeze on big hits, so they feel heavy.
const HIT_STOP_TIME: float = 0.06
## Freezes that muffle the music (a hit-stop is too short to bother).
const MUFFLING: Array[StringName] = [&"pause", &"level_up", &"goal"]

@export var rules: RunRules
@export var upgrade_pool: UpgradePool
## What gift boxes give and how they open.
@export var gift_box_rules: GiftBoxRules
## When zombies drop floor pickups (Big Magnet, ...) and which.
@export var floor_pickup_rules: FloorPickupRules
## What kills, gift boxes and the win add to the haul (spec 03 §3).
@export var material_rules: MaterialRules

## Seconds since the run started.
var elapsed: float = 0.0
## The run's seed: the same seed gives the same zombies and cards. Set before adding the run to
## the tree to replay a run; 0 picks a random one.
var seed_value: int = 0
## Randomness for spawning.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Separate randomness for the cards, so the cards don't depend on how many zombies spawned.
var upgrade_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var over: bool = false
## The goal time has been reached.
var goal_done: bool = false
## Playing on after the goal.
var endless: bool = false
## Endless minutes so far (the horde gets tougher each one).
var endless_minute: int = 0
## The boss is on the field (from the goal time until he is beaten).
var boss_fight: bool = false
## Run time when the goal was reached (the boss was beaten); endless time counts from here.
var goal_time: float = 0.0
## Big-hit freezes so far.
var hit_stops: int = 0
## The gift box moment (built in code, on top of the run).
var gift_screen: GiftBoxScreen = GiftBoxScreen.new()
## Evolutions so far, for the run log: {"weapon", "time", "player"}.
var evolution_log: Array[Dictionary] = []
## Run time when the mini-boss / the boss was first beaten (-1 = not yet).
var mini_boss_defeated_at: float = -1.0
var boss_defeated_at: float = -1.0
## Floor pickups grabbed so far, for the run log: {"name", "time", "player"}.
var floor_pickup_log: Array[Dictionary] = []
## Separate randomness for floor pickups, so they don't change the zombies or the cards.
var pickup_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Decides which kills drop a floor pickup.
var floor_pickup_drops: FloorPickupDrops
## Edge arrows to floor pickups out of sight (on the HUD).
var pickup_arrows: PickupArrows = PickupArrows.new()
## Materials and a freed plushie collected for the town in this run (spec 03 §3).
var haul: RunHaul = RunHaul.new()
## Separate randomness for materials, so they don't change the zombies or the cards.
var material_rng: RandomNumberGenerator = RandomNumberGenerator.new()

## False while the goal pops the horde (those zombies drop no XP).
var _drops_enabled: bool = true
## True from the goal until the player has chosen how to go on (the timer waits).
var _at_goal: bool = false
## Players waiting to pick a card (one entry per level gained).
var _level_up_queue: Array[Player] = []
## Opened gift boxes waiting for their moment (their contents are already given).
var _gift_queue: Array[GiftContents] = []
## Why the run is frozen right now (level-up, pause, ...). Empty = running.
var _freeze_reasons: Dictionary[StringName, bool] = {}
## The beaten boss's big gift box, until it is opened.
var _goal_box: GiftBox
## Run time of the next haul checkpoint.
var _next_checkpoint_at: float = CHECKPOINT_SECONDS

@onready var arena: Arena = $Arena
@onready var pickups: PickupManager = $Pickups
@onready var floor_items: Node2D = $FloorItems
@onready var actors: Node2D = $Actors
@onready var effects: Node2D = $Effects
@onready var enemies: EnemyManager = $Enemies
@onready var projectiles: ProjectileManager = $Projectiles
@onready var spawner: Spawner = $Spawner
@onready var camera: PlayersCamera = $Camera
@onready var hud: Hud = $Hud
@onready var level_up_screen: LevelUpScreen = $LevelUpScreen
@onready var goal_screen: GoalScreen = $GoalScreen
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var damage_numbers: DamageNumbers = $DamageNumbers
@onready var dev_menu: DevMenu = $DevMenu


func _ready() -> void:
	add_to_group(GROUP)
	if seed_value == 0:
		seed_value = randi_range(1, 2_147_483_647)
	rng.seed = seed_value
	upgrade_rng.seed = seed_value * 31 + 7
	pickup_rng.seed = seed_value * 17 + 3
	material_rng.seed = seed_value * 13 + 5
	floor_pickup_drops = FloorPickupDrops.new(floor_pickup_rules, pickup_rng)
	var furniture: Obstacles = arena.obstacles()
	enemies.setup(actors, effects, arena.play_rect(), rules.max_enemies_alive, furniture)
	projectiles.setup(enemies, arena.play_rect(), furniture)
	enemies.projectiles = projectiles
	enemies.zombie_killed.connect(_on_zombie_killed)
	enemies.zombie_hit.connect(_on_zombie_hit)
	enemies.zombie_winding_up.connect(func(_zombie: Zombie) -> void: Sfx.play(&"puff"))
	enemies.zombie_spat.connect(func(_zombie: Zombie, _balls: int) -> void: Sfx.play(&"spit"))
	enemies.zombie_burst.connect(_on_zombie_burst)
	enemies.boss_telegraphed.connect(
		func(_boss: Zombie, _pattern: StringName) -> void: Sfx.play(&"puff")
	)
	enemies.boss_attacked.connect(_on_boss_attacked)
	enemies.boss_angry.connect(_on_boss_angry)
	enemies.boss_landed.connect(_on_boss_landed)
	enemies.ice_cracking.connect(func() -> void: Sfx.play(&"ice_crack"))
	spawner.boss_spawned.connect(_on_boss_spawned)
	spawner.elite_spawned.connect(func(_elite: Zombie) -> void: Sfx.play(&"elite"))
	pickups.collected.connect(_on_pickup_collected)
	spawner.setup(enemies, camera, rng)
	spawner.goal_seconds = rules.goal_seconds
	level_up_screen.picked.connect(_on_upgrade_picked)
	level_up_screen.reroll_requested.connect(_on_reroll_requested)
	level_up_screen.skip_requested.connect(_on_skip_requested)
	level_up_screen.banish_requested.connect(_on_banish_requested)
	add_child(gift_screen)
	gift_screen.finished.connect(_on_gift_moment_finished)
	goal_screen.end_chosen.connect(_on_end_chosen)
	goal_screen.endless_chosen.connect(_on_endless_chosen)
	pause_menu.resumed.connect(unfreeze.bind(&"pause"))
	pause_menu.quit_requested.connect(_on_quit_requested)
	pause_menu.upgrade_pool = upgrade_pool
	pickup_arrows.floor_items = floor_items
	hud.add_child(pickup_arrows)
	dev_menu.setup(self)
	dev_menu.restart_requested.connect(restart_requested.emit)
	var first: Player = spawn_player(0, arena.center())
	hud.follow_player(first, upgrade_pool)
	camera.set_bounds(arena.outer_rect())
	camera.snap_to_players()
	Crosshair.use()
	_show_clock()


func _physics_process(delta: float) -> void:
	if over or _at_goal:
		return
	elapsed += delta
	if elapsed >= _next_checkpoint_at:
		_next_checkpoint_at = elapsed + CHECKPOINT_SECONDS
		checkpoint_due.emit()
	if endless:
		_update_endless_scaling()
	spawner.tick(elapsed, delta)
	_show_clock()


func _exit_tree() -> void:
	# The developer menu may have changed the game speed.
	Engine.time_scale = 1.0


## Esc pauses a running run (the pause menu closes itself with Esc or Resume).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and can_pause():
		get_viewport().set_input_as_handled()
		pause()


func can_pause() -> bool:
	return not over and not _at_goal and not is_frozen()


func pause() -> void:
	freeze(&"pause")
	pause_menu.open()


## Adds a hero for player `index` (0 = player 1) at `at`.
func spawn_player(index: int, at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.player_index = index
	player.position = at
	player.card_controls = CardControls.new(upgrade_pool)
	player.died.connect(_on_player_died)
	player.hurt.connect(_on_player_hurt)
	player.dashed.connect(func(_from: Vector2, _direction: Vector2) -> void: Sfx.play(&"dash"))
	player.celebrated.connect(func() -> void: Sfx.play(&"quack"))
	player.evolved.connect(_on_player_evolved.bind(player))
	actors.add_child(player)
	player.progress.leveled_up.connect(_on_leveled_up.bind(player))
	return player


## Stops everything in the run (zombies, timer, players) until every reason is lifted.
## Screens that must keep working while frozen use process mode "always".
func freeze(reason: StringName) -> void:
	_freeze_reasons[reason] = true
	process_mode = Node.PROCESS_MODE_DISABLED
	MusicPlayer.set_muffled(_is_muffled())


func unfreeze(reason: StringName) -> void:
	_freeze_reasons.erase(reason)
	if _freeze_reasons.is_empty():
		process_mode = Node.PROCESS_MODE_INHERIT
	MusicPlayer.set_muffled(_is_muffled())


## A very short freeze on a big hit (e.g. a pin through 3+ zombies).
func hit_stop(duration: float = HIT_STOP_TIME) -> void:
	hit_stops += 1
	freeze(&"hit_stop")
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(unfreeze.bind(&"hit_stop"))


func _is_muffled() -> bool:
	for reason: StringName in MUFFLING:
		if _freeze_reasons.has(reason):
			return true
	return false


func is_frozen() -> bool:
	return not _freeze_reasons.is_empty()


func _on_leveled_up(_new_level: int, player: Player) -> void:
	_level_up_queue.append(player)
	if not level_up_screen.is_open() and not gift_screen.is_open():
		_show_next_level_up(true)


func _show_next_level_up(with_moment: bool) -> void:
	if _level_up_queue.is_empty():
		level_up_screen.close()
		unfreeze(&"level_up")
		_show_next_gift()
		return
	freeze(&"level_up")
	var player: Player = _level_up_queue[0]
	if with_moment:
		player.celebrate()
	var controls: CardControls = player.card_controls
	level_up_screen.show_controls(controls)
	var offers: Array[UpgradeOffer] = upgrade_pool.roll(
		player.upgrade_levels(), upgrade_rng, controls.banished
	)
	level_up_screen.open(offers, with_moment)


func _on_upgrade_picked(offer: UpgradeOffer) -> void:
	var player: Player = _level_up_queue.pop_front()
	player.apply_upgrade(offer)
	_show_next_level_up(false)


## Reroll: 3 new cards, avoiding the ones on screen while others are left.
func _on_reroll_requested() -> void:
	var player: Player = _level_up_queue[0]
	var controls: CardControls = player.card_controls
	if not controls.use_reroll():
		return
	var offers: Array[UpgradeOffer] = upgrade_pool.roll(
		player.upgrade_levels(), upgrade_rng, controls.banished, _ids_on_screen()
	)
	level_up_screen.show_controls(controls)
	level_up_screen.show_offers(offers)


## Skip: no card, a small heal instead.
func _on_skip_requested() -> void:
	var player: Player = _level_up_queue[0]
	if not player.card_controls.use_skip():
		return
	_level_up_queue.pop_front()
	player.heal(player.max_health * upgrade_pool.skip_heal)
	_show_next_level_up(false)


## Banish: card `index` never comes up again this run; its slot gets a new card that differs
## from the other cards on screen. The snack can't be banished.
func _on_banish_requested(index: int) -> void:
	var player: Player = _level_up_queue[0]
	var controls: CardControls = player.card_controls
	var offers: Array[UpgradeOffer] = level_up_screen.offers.duplicate()
	var banished_card: UpgradeDef = offers[index].upgrade
	if banished_card.kind == UpgradeDef.Kind.SNACK or not controls.banish(banished_card.id):
		return
	var excluded: Array[StringName] = controls.banished.duplicate()
	excluded.append_array(_ids_on_screen())
	offers[index] = upgrade_pool.roll(player.upgrade_levels(), upgrade_rng, excluded, [], 1)[0]
	level_up_screen.show_controls(controls)
	level_up_screen.show_offers(offers)


func _ids_on_screen() -> Array[StringName]:
	var ids: Array[StringName] = []
	for offer: UpgradeOffer in level_up_screen.offers:
		ids.append(offer.upgrade.id)
	return ids


## Goal reached (the boss is beaten): spawning stops, the horde pops in a chain, a short
## celebration, the boss's big gift box opens (by itself if nobody walked onto it), then the run
## pauses and offers End run / Keep going.
func _reach_goal() -> void:
	goal_done = true
	goal_time = elapsed
	boss_fight = false
	music_requested.emit(&"run")
	_at_goal = true
	spawner.active = false
	enemies.calm = true
	_drops_enabled = false
	projectiles.clear_hostile()
	goal_reached.emit()
	Sfx.play(&"goal")
	var players: Array[Player] = Players.all(get_tree())
	for player: Player in players:
		player.celebrate()
	await enemies.pop_all_in_chain(Players.centroid(get_tree()), POP_CHAIN_TIME)
	await get_tree().create_timer(CELEBRATION_TIME).timeout
	if is_instance_valid(_goal_box) and not _goal_box.opened:
		_goal_box.opened = true
		_on_gift_box_touched(_goal_box, _nearest_player(_goal_box.position))
	while not _level_up_queue.is_empty() or not _gift_queue.is_empty() or gift_screen.is_open():
		await get_tree().process_frame
	_drops_enabled = true
	freeze(&"goal")
	goal_screen.open()


## Seconds played after the goal.
func endless_seconds() -> float:
	return maxf(elapsed - goal_time, 0.0) if endless else 0.0


## A summary of the run so far, for the end screen and the run log.
func make_result(ending: String) -> RunResult:
	var result: RunResult = RunResult.new()
	var first: Player = Players.all(get_tree())[0]
	result.won = goal_done
	result.ending = ending
	result.survived_seconds = elapsed
	result.endless_seconds = endless_seconds()
	result.level = first.progress.level
	result.kills = enemies.kills
	result.killed_by = first.last_hit_by if first.is_dead() else ""
	result.upgrades = first.picked_upgrades
	result.seed_value = seed_value
	result.evolutions = evolution_log.duplicate(true)
	result.rerolls_used = first.card_controls.rerolls_used
	result.skips_used = first.card_controls.skips_used
	result.banishes_used = first.card_controls.banishes_used
	result.mini_boss_defeated_at = mini_boss_defeated_at
	result.boss_defeated_at = boss_defeated_at
	result.floor_pickups = floor_pickup_log.duplicate(true)
	result.materials_collected = haul.materials.duplicate()
	return result


func _show_clock() -> void:
	if endless:
		hud.show_endless_time(endless_seconds())
	elif boss_fight:
		hud.show_boss_fight_time(elapsed)
	else:
		hud.show_time(elapsed, rules.goal_seconds)


## Every endless minute makes new zombies tougher and more frequent (numbers in the rules).
func _update_endless_scaling() -> void:
	var minute: int = floori(endless_seconds() / 60.0)
	if minute == endless_minute:
		return
	endless_minute = minute
	enemies.health_scale = rules.endless_health_scale(minute)
	enemies.damage_scale = rules.endless_damage_scale(minute)
	spawner.rate_scale = rules.endless_spawn_scale(minute)


func _on_end_chosen() -> void:
	over = true
	finished.emit(make_result("ended"))


func _on_quit_requested() -> void:
	over = true
	gave_up.emit(make_result("quit"))


func _on_endless_chosen() -> void:
	endless = true
	_at_goal = false
	enemies.calm = false
	spawner.active = true
	unfreeze(&"goal")
	endless_started.emit()


func _on_zombie_burst(_zombie: Zombie, _cloud: EnemyCloud) -> void:
	Sfx.play(&"burst")
	camera.shake(0.2)


## A boss arrives: banner, sound, and its health bar at the top.
func _on_boss_spawned(boss: Zombie) -> void:
	hud.show_boss(boss)
	hud.show_banner(boss.boss.banner, boss.boss.banner_subtitle, boss.boss.banner_seconds)
	Sfx.play(&"boss_banner")
	camera.shake(0.4)
	if is_final_boss(boss):
		boss_fight = true
		music_requested.emit(&"boss")


## True for the area's boss (beating him is the goal), false for the mini-boss.
func is_final_boss(zombie: Zombie) -> bool:
	return zombie.is_boss() and zombie.boss == spawner.schedule.boss


func _on_boss_attacked(_boss: Zombie, pattern: StringName) -> void:
	match pattern:
		BigTedBrain.STOMP:
			Sfx.play(&"stomp")
			camera.shake(0.35)
		SockKingBrain.SPIRAL:
			Sfx.play(&"spit")
		SockKingBrain.SUMMON:
			Sfx.play(&"pop")
		_:
			Sfx.play(&"dash")


func _on_boss_angry(boss: Zombie) -> void:
	var king: SockKingDef = boss.boss as SockKingDef
	if king != null:
		hud.show_banner(king.angry_banner, "", king.banner_seconds * 0.6)
	Sfx.play(&"boss_banner", 1.3)
	camera.shake(0.5)


func _on_boss_landed(_boss: Zombie) -> void:
	Sfx.play(&"stomp")
	camera.shake(0.5)


func _on_zombie_hit(zombie: Zombie, amount: float) -> void:
	damage_numbers.show_damage(amount, zombie.position)
	Sfx.play(&"boss_hit" if zombie.is_boss() else &"hit")


## Pickups in a row sound higher and higher ("plip" chain).
func _on_pickup_collected(_player: Player, _value: int, chain: int) -> void:
	Sfx.play(&"pickup", 1.0 + 0.06 * mini(chain - 1, 12))


func _on_player_hurt(_amount: float) -> void:
	Sfx.play(&"hurt")
	camera.shake(0.45)


func _on_zombie_killed(zombie: Zombie) -> void:
	Sfx.play(&"boss_down" if zombie.is_boss() else &"pop")
	if zombie.is_boss():
		_note_boss_defeat(zombie)
	if _drops_enabled:
		pickups.drop(zombie.xp_button(), zombie.position)
		_collect_kill(zombie)
		var kind: FloorPickupDef = floor_pickup_drops.roll(elapsed, floor_pickups().size())
		if kind != null:
			drop_floor_pickup(kind.id, zombie.position)
		if zombie.is_elite() or zombie.is_boss():
			var box: GiftBox = drop_gift_box(zombie.position, is_final_boss(zombie))
			if box.big:
				_goal_box = box
	if zombie.is_boss():
		camera.shake(0.6)
	if is_final_boss(zombie) and not goal_done:
		collect(material_rules.victory_bonus.roll(material_rng), zombie.position, true)
		_reach_goal()


func _note_boss_defeat(boss: Zombie) -> void:
	if is_final_boss(boss):
		if boss_defeated_at < 0.0:
			boss_defeated_at = elapsed
	elif mini_boss_defeated_at < 0.0:
		mini_boss_defeated_at = elapsed


## Adds `amounts` to the shared haul (any player's kill counts) and shows it on the HUD; with
## `burst`, the pieces fly from world position `at` into the jars.
func collect(amounts: Dictionary[String, int], at: Vector2, burst: bool = false) -> void:
	for material: String in amounts:
		haul.add(material, amounts[material])
	hud.jars.show_haul(haul)
	if burst and not amounts.is_empty():
		hud.jars.burst(amounts, get_viewport().get_canvas_transform() * at)


## A kill's materials go straight into the haul, never onto the floor (spec 03 §3).
func _collect_kill(zombie: Zombie) -> void:
	# The base type's name ("Tank"), not the elite's display name ("Elite Tank").
	var amounts: Dictionary[String, int] = material_rules.for_kill(
		zombie.stats.display_name, zombie.is_elite(), material_rng
	)
	collect(amounts, zombie.position, zombie.is_elite() or zombie.is_boss())


func _on_player_evolved(new_weapon: Weapon, player: Player) -> void:
	var entry: Dictionary = {
		"weapon": new_weapon.stats.display_name, "time": elapsed, "player": player.player_index
	}
	evolution_log.append(entry)


func _on_player_died(_player: Player) -> void:
	Sfx.play(&"death")
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			return
	over = true
	spawner.active = false
	enemies.calm = true
	# A timer connection (not await) so nothing fires if the run is closed meanwhile.
	get_tree().create_timer(DEATH_PAUSE).timeout.connect(_finish_after_death)


func _finish_after_death() -> void:
	finished.emit(make_result("died"))


## Puts a gift box on the floor at `at`; it opens for the first player who touches it.
## The living player closest to `at` (player 1 if everyone is down).
func _nearest_player(at: Vector2) -> Player:
	var players: Array[Player] = Players.all(get_tree())
	var best: Player = players[0]
	var best_distance: float = INF
	for player: Player in players:
		var distance: float = player.global_position.distance_squared_to(at)
		if not player.is_dead() and distance < best_distance:
			best = player
			best_distance = distance
	return best


## A `big` box (the boss's) has more inside.
func drop_gift_box(at: Vector2, big: bool = false) -> GiftBox:
	var box: GiftBox = GiftBox.new()
	box.position = at
	box.setup(gift_box_rules, big)
	box.touched.connect(_on_gift_box_touched)
	floor_items.add_child(box)
	return box


## The box opens for `player`: its contents are given right away, then the moment plays.
func _on_gift_box_touched(box: GiftBox, player: Player) -> void:
	var extra: int = gift_box_rules.big_box_extra_level_ups if box.big else 0
	var gift: GiftContents = gift_box_rules.contents(
		player.upgrade_levels(), upgrade_pool, upgrade_rng, extra
	)
	gift.player = player
	gift.apply_to(player)
	collect(material_rules.for_gift_box(box.big, material_rng), box.position, true)
	box.queue_free()
	_gift_queue.append(gift)
	if not level_up_screen.is_open() and not gift_screen.is_open():
		_show_next_gift()


func _show_next_gift() -> void:
	if _gift_queue.is_empty():
		return
	var gift: GiftContents = _gift_queue.pop_front()
	freeze(&"gift_box")
	gift.player.celebrate()
	gift_screen.open(gift, gift_box_rules)


func _on_gift_moment_finished() -> void:
	unfreeze(&"gift_box")
	if not _level_up_queue.is_empty():
		_show_next_level_up(true)
	else:
		_show_next_gift()


## Floor pickups still lying on the floor.
func floor_pickups() -> Array[FloorPickup]:
	var result: Array[FloorPickup] = []
	for child: Node in floor_items.get_children():
		var pickup: FloorPickup = child as FloorPickup
		if pickup != null and not pickup.taken and not pickup.is_queued_for_deletion():
			result.append(pickup)
	return result


## Puts the floor pickup `id` (e.g. &"magnet") on the floor at `at`; the first player who
## touches it triggers it.
func drop_floor_pickup(id: StringName, at: Vector2) -> FloorPickup:
	var pickup: FloorPickup = FloorPickup.new()
	pickup.position = at
	pickup.setup(floor_pickup_rules.find(id), floor_pickup_rules)
	pickup.touched.connect(_on_floor_pickup_touched)
	floor_items.add_child(pickup)
	return pickup


## A floor pickup works at once (spec 02b §2): banner, sound, log line, then its effect.
func _on_floor_pickup_touched(pickup: FloorPickup, player: Player) -> void:
	var kind: FloorPickupDef = pickup.kind
	pickup.queue_free()
	hud.show_banner(kind.banner, kind.banner_subtitle, floor_pickup_rules.banner_seconds)
	Sfx.play(kind.sound)
	var entry: Dictionary = {
		"name": kind.display_name, "time": elapsed, "player": player.player_index
	}
	floor_pickup_log.append(entry)
	match kind.id:
		&"magnet":
			pickups.attract_all(player)
		&"snow_globe":
			freeze_the_horde()
		&"party_popper":
			party_pop(player)


## Snow Globe (spec 02b §3): the horde freezes, bosses slow down, enemy bullets in the air pop
## into fluff and no new zombies come, all for the freeze time from data.
func freeze_the_horde() -> void:
	var data: FloorPickupRules = floor_pickup_rules
	enemies.freeze(data.freeze_seconds, data.freeze_boss_speed, data.freeze_crack_seconds)
	spawner.pause(data.freeze_seconds)
	var popped: PackedVector2Array = projectiles.pop_enemy_bullets()
	if not popped.is_empty():
		effects.add_child(FluffPoofs.new(popped))


## Party Popper (spec 02b §3): confetti over the whole screen. Normal zombies on screen pop (and
## drop their XP as usual), elites and bosses lose the share of their health set in data,
## zombies off screen are untouched.
func party_pop(player: Player) -> void:
	var data: FloorPickupRules = floor_pickup_rules
	var view: Rect2 = spawner.visible_rect()
	for zombie: Zombie in enemies.zombies.duplicate():
		if zombie.dead or not view.has_point(zombie.position):
			continue
		var hit: float = zombie.health
		if zombie.is_boss():
			hit = zombie.max_health * data.popper_boss_share
		elif zombie.is_elite():
			hit = zombie.max_health * data.popper_elite_share
		enemies.damage(zombie, hit)
	var seconds: float = data.popper_seconds
	var confetti: ConfettiBlast = ConfettiBlast.new(player.global_position, view, seconds, randi())
	effects.add_child(confetti)
	camera.shake(0.3)
