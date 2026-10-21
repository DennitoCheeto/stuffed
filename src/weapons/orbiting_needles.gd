class_name OrbitingNeedles
extends Weapon
## Needles circle around the player for a while and hurt every zombie they touch. They come back
## after the cooldown. Reach is the circle's radius, speed how fast a needle moves along it.


## Always fires (it needs no target), but never while the last circle is still out.
func attack() -> bool:
	var shots: ProjectileManager = projectiles()
	if shots == null or not shots.fired_by(self).is_empty():
		return false
	var numbers: WeaponLevel = current()
	Sfx.play(&"pin", 1.4)
	for i: int in numbers.count:
		var needle: NeedleProjectile = shots.spawn(NeedleProjectile) as NeedleProjectile
		needle.launch(self, TAU * i / numbers.count)
	return true
