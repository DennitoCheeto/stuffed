class_name BearSlam
extends PawSwat
## Evolved Paw Swat (+ Extra Stuffing, Böbö, spec 10 §3): a bigger paw swipe, and every few swats
## a ground slam: a ring that knocks the zombies in it down (a short stun) and hurts them all.

## Attacks so far, and slams so far.
var swats: int = 0
var slams: int = 0


func attack() -> bool:
	if not super():
		return false
	swats += 1
	var slam: GroundSlam = stats.ground_slam
	if slam != null and swats % maxi(slam.every, 1) == 0:
		var ring: SlamRingProjectile = projectiles().spawn(SlamRingProjectile) as SlamRingProjectile
		ring.slam(self)
		slams += 1
	return true


func _shot_kind() -> GDScript:
	return BearPawProjectile
