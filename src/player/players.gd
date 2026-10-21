class_name Players
extends RefCounted
## Finds the players in the scene tree. Systems use this instead of a single global "the player"
## so that local co-op works later.


static func all(tree: SceneTree) -> Array[Player]:
	var result: Array[Player] = []
	for node: Node in tree.get_nodes_in_group(Player.GROUP):
		var player: Player = node as Player
		if player != null and player.is_inside_tree():
			result.append(player)
	return result


## Average position of all players (what the camera follows). Vector2.ZERO without players.
static func centroid(tree: SceneTree) -> Vector2:
	var players: Array[Player] = all(tree)
	if players.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for player: Player in players:
		sum += player.global_position
	return sum / players.size()
