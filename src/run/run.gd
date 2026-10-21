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
## The player quit from the pause menu (the result is still logged).
signal quit_to_title(result: RunResult)
## The developer menu asks for a new run (0 = new random seed).
signal restart_requested(seed_value: int)

## Weapons and effects find the run through this group.
const GROUP: StringName = &"run"
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
## Big-hit freezes so far.
var hit_stops: int = 0

## False while the goal pops the horde (those zombies drop no XP).
var _drops_enabled: bool = true
## True from the goal until the player has chosen how to go on (the timer waits).
var _at_goal: bool = false
## Players waiting to pick a card (one entry per level gained).
var _level_up_queue: Array[Player] = []
## Why the run is frozen right now (level-up, pause, ...). Empty = running.
var _freeze_reasons: Dictionary[StringName, bool] = {}

@onready var arena: Arena = $Arena
@onready var pickups: PickupManager = $Pickups
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
	enemies.setup(actors, effects, arena.play_rect(), rules.max_enemies_alive)
	projectiles.setup(enemies, arena.play_rect())
	enemies.projectiles = projectiles
	enemies.zombie_killed.connect(_on_zombie_killed)
	enemies.zombie_hit.connect(_on_zombie_hit)
	enemies.zombie_winding_up.connect(func(_zombie: Zombie) -> void: Sfx.play(&"puff"))
	enemies.zombie_spat.connect(func(_zombie: Zombie, _balls: int) -> void: Sfx.play(&"spit"))
	enemies.zombie_burst.connect(_on_zombie_burst)
	pickups.collected.connect(_on_pickup_collected)
	spawner.setup(enemies, camera, rng)
	spawner.goal_seconds = rules.goal_seconds
	level_up_screen.picked.connect(_on_upgrade_picked)
	level_up_screen.reroll_requested.connect(_on_reroll_requested)
	level_up_screen.skip_requested.connect(_on_skip_requested)
	level_up_screen.banish_requested.connect(_on_banish_requested)
	goal_screen.end_chosen.connect(_on_end_chosen)
	goal_screen.endless_chosen.connect(_on_endless_chosen)
	pause_menu.resumed.connect(unfreeze.bind(&"pause"))
	pause_menu.quit_requested.connect(_on_quit_requested)
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
	if not goal_done and elapsed >= rules.goal_seconds:
		elapsed = rules.goal_seconds
		_reach_goal()
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
	if not level_up_screen.is_open():
		_show_next_level_up(true)


func _show_next_level_up(with_moment: bool) -> void:
	if _level_up_queue.is_empty():
		level_up_screen.close()
		unfreeze(&"level_up")
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


## Goal reached: spawning stops, the horde pops in a chain, a short celebration, then the run
## pauses and offers End run / Keep going.
func _reach_goal() -> void:
	goal_done = true
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
	while not _level_up_queue.is_empty():
		await get_tree().process_frame
	_drops_enabled = true
	freeze(&"goal")
	goal_screen.open()


## Seconds played after the goal.
func endless_seconds() -> float:
	return maxf(elapsed - rules.goal_seconds, 0.0) if endless else 0.0


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
	return result


func _show_clock() -> void:
	if endless:
		hud.show_endless_time(endless_seconds())
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
	quit_to_title.emit(make_result("quit"))


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


func _on_zombie_hit(zombie: Zombie, amount: float) -> void:
	damage_numbers.show_damage(amount, zombie.position)
	Sfx.play(&"hit")


## Pickups in a row sound higher and higher ("plip" chain).
func _on_pickup_collected(_player: Player, _value: int, chain: int) -> void:
	Sfx.play(&"pickup", 1.0 + 0.06 * mini(chain - 1, 12))


func _on_player_hurt(_amount: float) -> void:
	Sfx.play(&"hurt")
	camera.shake(0.45)


func _on_zombie_killed(zombie: Zombie) -> void:
	Sfx.play(&"pop")
	if _drops_enabled:
		pickups.drop(zombie.stats.xp_button, zombie.position)


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
