class_name HitboxOverlay
extends Node2D
## Developer menu: outlines every real hitbox (players and zombies) on top of the game.

const PLAYER_COLOR: Color = Color(0.3, 1.0, 0.4, 0.9)
const ZOMBIE_COLOR: Color = Color(1.0, 0.3, 0.3, 0.9)


func _ready() -> void:
	z_index = 100


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	for player: Player in Players.all(get_tree()):
		draw_arc(player.global_position, player.stats.hitbox_radius, 0.0, TAU, 24, PLAYER_COLOR)
	var group: StringName = EnemyManager.GROUP
	var manager: EnemyManager = get_tree().get_first_node_in_group(group) as EnemyManager
	if manager == null:
		return
	for zombie: Zombie in manager.zombies:
		draw_arc(zombie.position, zombie.radius(), 0.0, TAU, 16, ZOMBIE_COLOR)
