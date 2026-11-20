class_name BananaSplit
extends PeelBoomerang
## Evolved Peel Boomerang (+ Quick Feet): thrown like the boomerang, but on the way back every
## peel splits into three that all fly home, hitting again (spec 02 §5). Split peels that hit a
## zombie drop a slippery peel there (peel trail, spec 10 §3).


func _peel_kind() -> GDScript:
	return SplitPeelProjectile


## This hero's slippery peels on the floor.
func floor_peels() -> Array[FloorPeelProjectile]:
	var result: Array[FloorPeelProjectile] = []
	var shots: ProjectileManager = projectiles()
	if shots == null:
		return result
	for shot: Projectile in shots.fired_by(self):
		if shot is FloorPeelProjectile and not (shot as FloorPeelProjectile).used:
			result.append(shot as FloorPeelProjectile)
	return result


## Drops a slippery peel at `at`; at the limit the oldest one makes room.
func drop_peel(at: Vector2) -> void:
	var trail: PeelTrail = stats.peel_trail
	var shots: ProjectileManager = projectiles()
	if trail == null or shots == null:
		return
	var lying: Array[FloorPeelProjectile] = floor_peels()
	while lying.size() >= trail.max_peels:
		var oldest: FloorPeelProjectile = lying[0]
		for peel: FloorPeelProjectile in lying:
			if peel.age > oldest.age:
				oldest = peel
		oldest.used = true
		lying.erase(oldest)
	var peel: FloorPeelProjectile = shots.spawn(FloorPeelProjectile) as FloorPeelProjectile
	peel.drop(self, at)
