class_name SiegeTargets
extends RefCounted
## Where the horde goes in the night siege (spec 07 §4, §5, AC-77). Zombies walk to the pillow
## fort; on the way they turn to what is close. In this order:
## 1. a bait building (Lucky Jar) whose pull reaches them, even with a hero close by,
## 2. the nearest hero within the fort's `hero_reach` (spitters: within spitting distance),
## 3. a standing building or the fort they already touch (they keep knocking at it),
## 4. the nearest standing building within its pull,
## 5. the fort.
## Every standing target a zombie touches takes its touch damage. The EnemyManager asks this
## (`goal_for`, `touch`); null = no siege.

var fort: SiegeFort
## Built buildings that fight along (ruins and damaged buildings are never in here).
var buildings: Array[SiegeBuilding] = []


func _init(siege_fort: SiegeFort) -> void:
	fort = siege_fort


## The fort and every building.
func all() -> Array[SiegeTarget]:
	var result: Array[SiegeTarget] = [fort]
	result.append_array(buildings)
	return result


## What `zombie` walks to; null = it goes for `hero` (the nearest standing hero, may be null).
func goal_for(zombie: Zombie, hero: Player) -> SiegeTarget:
	var bait: SiegeBuilding = _nearest(zombie, true)
	if bait != null:
		return bait
	if fort.chases(zombie, hero):
		return null
	for building: SiegeBuilding in buildings:
		if not building.is_fallen() and building.is_touched_by(zombie):
			return building
	if fort.is_touched_by(zombie):
		return fort
	var close: SiegeBuilding = _nearest(zombie, false)
	return close if close != null else fort


## `zombie` knocks at every standing target it touches for `delta` seconds.
func touch(zombie: Zombie, delta: float) -> void:
	fort.touch(zombie, delta)
	for building: SiegeBuilding in buildings:
		building.touch(zombie, delta)


## The building with this spot id (null = not fighting in this siege).
func building(id: StringName) -> SiegeBuilding:
	for each: SiegeBuilding in buildings:
		if each.id == id:
			return each
	return null


## Ids of the buildings knocked down so far.
func knocked_down() -> Array[StringName]:
	var result: Array[StringName] = []
	for each: SiegeBuilding in buildings:
		if each.is_fallen():
			result.append(each.id)
	return result


## The nearest standing building (only bait, or only non-bait) whose pull reaches `zombie`.
func _nearest(zombie: Zombie, bait: bool) -> SiegeBuilding:
	var best: SiegeBuilding = null
	var best_distance: float = INF
	for each: SiegeBuilding in buildings:
		if each.bait != bait or not each.pulls(zombie):
			continue
		var distance: float = each.distance_to(zombie.position)
		if distance < best_distance:
			best = each
			best_distance = distance
	return best
