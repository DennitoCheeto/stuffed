class_name Slippery
extends Node
## Banane's passive: every dash drops a banana peel where the dash started.
## Peels go on the run's floor layer (group "floor_items"), under the zombies.

const FLOOR_GROUP: StringName = &"floor_items"

var player: Player
## This player's peels on the floor, oldest first.
var peels: Array[BananaPeel] = []


func setup(owner_player: Player) -> void:
	player = owner_player
	player.dashed.connect(_on_dashed)


func _on_dashed(from_position: Vector2, _direction: Vector2) -> void:
	var floor_layer: Node = get_tree().get_first_node_in_group(FLOOR_GROUP)
	if floor_layer == null:
		return
	peels = peels.filter(func(peel: BananaPeel) -> bool: return is_instance_valid(peel))
	while peels.size() >= player.stats.peel_max:
		var oldest: BananaPeel = peels.pop_front()
		oldest.remove()
	var peel: BananaPeel = BananaPeel.new()
	peel.lifetime = player.stats.peel_lifetime
	peel.stun = player.stats.peel_stun
	peel.radius = player.stats.peel_radius
	peel.position = from_position
	floor_layer.add_child(peel)
	peels.append(peel)
