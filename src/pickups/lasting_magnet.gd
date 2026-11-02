class_name LastingMagnet
extends Node
## A double Big Magnet (Double Fun trick, spec 06 §3): for a few seconds after the first pull,
## every new XP button on the floor keeps flying to the hero. Lives in the run's effects, so it
## stops while the run is frozen, and frees itself when the time is up.

var pickups: PickupManager
var player: Player
var seconds_left: float = 0.0


func _init(manager: PickupManager, to_player: Player, seconds: float) -> void:
	name = "LastingMagnet"
	pickups = manager
	player = to_player
	seconds_left = seconds


func _physics_process(delta: float) -> void:
	seconds_left -= delta
	if seconds_left <= 0.0 or not is_instance_valid(player) or not is_instance_valid(pickups):
		queue_free()
		return
	if not player.is_dead():
		pickups.attract_all(player)
