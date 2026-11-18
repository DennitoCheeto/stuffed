class_name SiegeTargets
extends RefCounted
## Where the horde goes in the night siege (spec 07 §4, §5, AC-77). Zombies walk to the pillow
## fort; on the way they turn to what is close. In this order:
## 1. a bait building (Lucky Jar) whose pull reaches them, even with a hero close by,
## 2. the nearest hero within the fort's `hero_reach` (spitters: within spitting distance),
## 3. a standing building, plushie or the fort they already touch (they keep knocking at it),
## 4. the nearest standing building or plushie within its pull,
## 5. the fort.
## Every standing target a zombie touches takes its touch damage. The EnemyManager asks this
## (`goal_for`, `touch`); null = no siege.

var fort: SiegeFort
## Built buildings that fight along (ruins and damaged buildings are never in here).
var buildings: Array[SiegeBuilding] = []
## Helping plushies (spec 07 §4); a knocked-out one is skipped until it stands back up.
var plushies: Array[SiegeTarget] = []


func _init(siege_fort: SiegeFort) -> void:
	fort = siege_fort


## The fort, every building and every plushie.
func all() -> Array[SiegeTarget]:
	var result: Array[SiegeTarget] = [fort]
	result.append_array(buildings)
	result.append_array(plushies)
	return result


## What `zombie` walks to; null = it goes for `hero` (the nearest standing hero, may be null).
func goal_for(zombie: Zombie, hero: Player) -> SiegeTarget:
	var bait: SiegeBuilding = _nearest_bait(zombie)
	if bait != null:
		return bait
	if fort.chases(zombie, hero):
		return null
	var touched: SiegeTarget = _touched(buildings, zombie)
	if touched == null:
		touched = _touched(plushies, zombie)
	if touched != null:
		return touched
	if fort.is_touched_by(zombie):
		return fort
	var close: SiegeTarget = _nearest_close(zombie, buildings, null)
	close = _nearest_close(zombie, plushies, close)
	return close if close != null else fort


## `zombie` knocks at every standing target it touches for `delta` seconds.
func touch(zombie: Zombie, delta: float) -> void:
	fort.touch(zombie, delta)
	for each: SiegeBuilding in buildings:
		each.touch(zombie, delta)
	for each: SiegeTarget in plushies:
		each.touch(zombie, delta)


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


## The first standing target in `list` that `zombie` touches (null = none).
func _touched(list: Array, zombie: Zombie) -> SiegeTarget:
	for each: SiegeTarget in list:
		if not each.is_fallen() and each.is_touched_by(zombie):
			return each
	return null


## The nearest standing bait building whose pull reaches `zombie`.
func _nearest_bait(zombie: Zombie) -> SiegeBuilding:
	var best: SiegeBuilding = null
	var best_distance: float = INF
	for each: SiegeBuilding in buildings:
		if not each.bait or not each.pulls(zombie):
			continue
		var distance: float = each.distance_to(zombie.position)
		if distance < best_distance:
			best = each
			best_distance = distance
	return best


## The nearest standing non-bait target in `list` whose pull reaches `zombie`, or `best` (found
## before) when that is nearer.
func _nearest_close(zombie: Zombie, list: Array, best: SiegeTarget) -> SiegeTarget:
	var best_distance: float = best.distance_to(zombie.position) if best != null else INF
	for each: SiegeTarget in list:
		if (each is SiegeBuilding and (each as SiegeBuilding).bait) or not each.pulls(zombie):
			continue
		var distance: float = each.distance_to(zombie.position)
		if distance < best_distance:
			best = each
			best_distance = distance
	return best
