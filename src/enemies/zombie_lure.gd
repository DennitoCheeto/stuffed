class_name ZombieLure
extends RefCounted
## Something in a run that draws nearby zombies away from the heroes (a Snow Day snowman, spec 10
## §3). Zombies within `reach` walk to it and crowd around it at `stand_off`, as if attacking it.
## Bosses ignore lures. The owner keeps `at` up to date and sets `active` false when it is gone;
## the EnemyManager drops inactive lures.

var at: Vector2 = Vector2.ZERO
var reach: float = 200.0
var stand_off: float = 24.0
var active: bool = true


func _init(where: Vector2, pull_reach: float, distance: float) -> void:
	at = where
	reach = pull_reach
	stand_off = distance


func pulls(zombie: Zombie) -> bool:
	return active and zombie.position.distance_squared_to(at) <= reach * reach


## Where `zombie` walks this frame: to the lure, then it stays put next to it.
func walk(zombie: Zombie) -> Vector2:
	if zombie.is_stunned():
		return Vector2.ZERO
	var distance: float = zombie.position.distance_to(at)
	if distance <= stand_off + zombie.radius():
		return Vector2.ZERO
	return zombie.position.direction_to(at) * zombie.current_speed()
