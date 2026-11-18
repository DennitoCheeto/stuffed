class_name SnowballToss
extends ThimbleMortar
## Pip's own weapon (spec 08 §3): lobs a snowball at the nearest group of zombies on screen. It
## bursts in a small area, does a little damage and slows every zombie it hits. More snowballs
## at higher levels go to other groups close by.

## How many of the closest zombies are checked for the biggest group.
const CANDIDATES: int = 8

var _groups: Array[Zombie] = []


func _pick_target(targets: Array[Zombie], index: int) -> Zombie:
	if index == 0:
		_groups = _closest(targets)
		return _biggest_group(_groups)
	return _groups[_rng.randi_range(0, _groups.size() - 1)]


func _shot_kind() -> GDScript:
	return SnowballProjectile


func _closest(targets: Array[Zombie]) -> Array[Zombie]:
	var from: Vector2 = origin()
	var sorted: Array[Zombie] = targets.duplicate()
	sorted.sort_custom(_closer.bind(from))
	return sorted.slice(0, CANDIDATES)


func _closer(a: Zombie, b: Zombie, from: Vector2) -> bool:
	return a.position.distance_squared_to(from) < b.position.distance_squared_to(from)


## The zombie with the most others inside the burst around it (the closest one on a tie).
func _biggest_group(near: Array[Zombie]) -> Zombie:
	var best: Zombie = near[0]
	var best_count: int = -1
	for zombie: Zombie in near:
		var count: int = enemies().query_circle(zombie.position, current().area).size()
		if count > best_count:
			best = zombie
			best_count = count
	return best
