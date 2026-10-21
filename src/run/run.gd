class_name Run
extends Node2D
## One run: the arena, the players, the zombies, the camera and the HUD. Counts the run time and
## runs the level-up flow.

## Every player is down.
signal all_players_down
## The goal time was reached (zombies pop, then the choice appears).
signal goal_reached
## The player chose "Keep going (endless)".
signal endless_started
## The player chose "End run" after reaching the goal.
signal ended_with_win

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")
## How long the chain of pops takes when the goal is reached.
const POP_CHAIN_TIME: float = 1.0
## A short moment to enjoy the empty floor before the choice appears.
const CELEBRATION_TIME: float = 1.2

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
@onready var spawner: Spawner = $Spawner
@onready var camera: PlayersCamera = $Camera
@onready var hud: Hud = $Hud
@onready var level_up_screen: LevelUpScreen = $LevelUpScreen
@onready var goal_screen: GoalScreen = $GoalScreen


func _ready() -> void:
	if seed_value == 0:
		seed_value = randi_range(1, 2_147_483_647)
	rng.seed = seed_value
	upgrade_rng.seed = seed_value * 31 + 7
	enemies.setup(actors, effects, arena.play_rect(), rules.max_enemies_alive)
	enemies.zombie_killed.connect(_on_zombie_killed)
	spawner.setup(enemies, camera, rng)
	spawner.goal_seconds = rules.goal_seconds
	level_up_screen.picked.connect(_on_upgrade_picked)
	goal_screen.end_chosen.connect(_on_end_chosen)
	goal_screen.endless_chosen.connect(_on_endless_chosen)
	var first: Player = spawn_player(0, arena.center())
	hud.follow_player(first)
	camera.set_bounds(arena.outer_rect())
	camera.snap_to_players()
	Crosshair.use()
	hud.show_time(elapsed, rules.goal_seconds)


func _physics_process(delta: float) -> void:
	if over or _at_goal:
		return
	elapsed += delta
	if not goal_done and elapsed >= rules.goal_seconds:
		elapsed = rules.goal_seconds
		_reach_goal()
	spawner.tick(elapsed, delta)
	hud.show_time(elapsed, rules.goal_seconds)


## Adds a hero for player `index` (0 = player 1) at `at`.
func spawn_player(index: int, at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.player_index = index
	player.position = at
	player.died.connect(_on_player_died)
	actors.add_child(player)
	player.progress.leveled_up.connect(_on_leveled_up.bind(player))
	return player


## Stops everything in the run (zombies, timer, players) until every reason is lifted.
## Screens that must keep working while frozen use process mode "always".
func freeze(reason: StringName) -> void:
	_freeze_reasons[reason] = true
	process_mode = Node.PROCESS_MODE_DISABLED


func unfreeze(reason: StringName) -> void:
	_freeze_reasons.erase(reason)
	if _freeze_reasons.is_empty():
		process_mode = Node.PROCESS_MODE_INHERIT


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
	level_up_screen.open(upgrade_pool.roll(player.upgrade_levels(), upgrade_rng), with_moment)


func _on_upgrade_picked(offer: UpgradeOffer) -> void:
	var player: Player = _level_up_queue.pop_front()
	player.apply_upgrade(offer)
	_show_next_level_up(false)


## Goal reached: spawning stops, the horde pops in a chain, a short celebration, then the run
## pauses and offers End run / Keep going.
func _reach_goal() -> void:
	goal_done = true
	_at_goal = true
	spawner.active = false
	enemies.calm = true
	_drops_enabled = false
	goal_reached.emit()
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


func _on_end_chosen() -> void:
	over = true
	ended_with_win.emit()


func _on_endless_chosen() -> void:
	endless = true
	_at_goal = false
	enemies.calm = false
	spawner.active = true
	unfreeze(&"goal")
	endless_started.emit()


func _on_zombie_killed(zombie: Zombie) -> void:
	if _drops_enabled:
		pickups.drop(zombie.stats.xp_button, zombie.position)


func _on_player_died(_player: Player) -> void:
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			return
	over = true
	spawner.active = false
	all_players_down.emit()
