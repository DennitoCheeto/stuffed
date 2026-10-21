class_name ZipperRay
extends Weapon
## Aimed weapon: every few seconds, a short-lived zipper beam from the player towards the
## cursor. It follows the cursor while it lasts and hurts everything along its line (the same
## zombie again after the weapon's hit interval).


## Never fires while the last beam is still out.
func attack() -> bool:
	var shots: ProjectileManager = projectiles()
	if shots == null or enemies() == null or not shots.fired_by(self).is_empty():
		return false
	Sfx.play(&"pin", 0.6)
	var beam: BeamProjectile = shots.spawn(BeamProjectile) as BeamProjectile
	beam.launch(self)
	return true
