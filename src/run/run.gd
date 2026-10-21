class_name Run
extends Node2D
## One run: the arena, the players, the zombies, the camera and the HUD. Counts the run time and
## runs the level-up flow.

## Every player is down.
signal all_players_down

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")

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


func _ready() -> void:
	if seed_value == 0:
		seed_value = randi_range(1, 2_147_483_647)
	rng.seed = seed_value
	upgrade_rng.seed = seed_value * 31 + 7
	enemies.setup(actors, effects, arena.play_rect(), rules.max_enemies_alive)
	enemies.zombie_killed.connect(_on_zombie_killed)
	spawner.setup(enemies, camera, rng)
	level_up_screen.picked.connect(_on_upgrade_picked)
	var first: Player = spawn_player(0, arena.center())
	hud.follow_player(first)
	camera.set_bounds(arena.outer_rect())
	camera.snap_to_players()
	hud.show_time(elapsed, rules.goal_seconds)


func _physics_process(delta: float) -> void:
	if over:
		return
	elapsed += delta
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


func _on_zombie_killed(zombie: Zombie) -> void:
	pickups.drop(zombie.stats.xp_button, zombie.position)


func _on_player_died(_player: Player) -> void:
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			return
	over = true
	spawner.active = false
	all_players_down.emit()
