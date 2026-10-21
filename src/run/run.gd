class_name Run
extends Node2D
## One run: the arena, the players, the camera and the HUD. Counts the run time.

const PLAYER_SCENE: PackedScene = preload("res://src/player/player.tscn")

@export var rules: RunRules

## Seconds since the run started.
var elapsed: float = 0.0

@onready var arena: Arena = $Arena
@onready var actors: Node2D = $Actors
@onready var camera: PlayersCamera = $Camera
@onready var hud: Hud = $Hud


func _ready() -> void:
	spawn_player(0, arena.center())
	camera.set_bounds(arena.outer_rect())
	camera.snap_to_players()
	hud.show_time(elapsed, rules.goal_seconds)


func _physics_process(delta: float) -> void:
	elapsed += delta
	hud.show_time(elapsed, rules.goal_seconds)


## Adds a hero for player `index` (0 = player 1) at `at`.
func spawn_player(index: int, at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate()
	player.player_index = index
	player.position = at
	actors.add_child(player)
	return player
