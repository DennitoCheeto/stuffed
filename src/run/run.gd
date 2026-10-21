class_name Run
extends Node2D
## One run: the arena, the players, the zombies, the camera and the HUD. Counts the run time.

## Every player is down.
signal all_players_down

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")

@export var rules: RunRules

## Seconds since the run started.
var elapsed: float = 0.0
## The run's seed: the same seed gives the same zombies and cards. Set before adding the run to
## the tree to replay a run; 0 picks a random one.
var seed_value: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var over: bool = false

@onready var arena: Arena = $Arena
@onready var pickups: PickupManager = $Pickups
@onready var actors: Node2D = $Actors
@onready var effects: Node2D = $Effects
@onready var enemies: EnemyManager = $Enemies
@onready var spawner: Spawner = $Spawner
@onready var camera: PlayersCamera = $Camera
@onready var hud: Hud = $Hud


func _ready() -> void:
	if seed_value == 0:
		seed_value = randi_range(1, 2_147_483_647)
	rng.seed = seed_value
	enemies.setup(actors, effects, arena.play_rect(), rules.max_enemies_alive)
	enemies.zombie_killed.connect(_on_zombie_killed)
	spawner.setup(enemies, camera, rng)
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
	return player


func _on_zombie_killed(zombie: Zombie) -> void:
	pickups.drop(zombie.stats.xp_button, zombie.position)


func _on_player_died(_player: Player) -> void:
	for player: Player in Players.all(get_tree()):
		if not player.is_dead():
			return
	over = true
	spawner.active = false
	all_players_down.emit()
