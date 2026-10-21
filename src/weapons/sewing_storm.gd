class_name SewingStorm
extends Weapon
## Evolved Orbiting Needles (+ Long Thread): a storm of needles that never stops circling the
## player; every cooldown the whole storm is flung outward to `area` and pulled back in
## (spec 02 §5). Reach is the circle's radius, speed how fast a needle moves along it, duration
## how long one fling takes.


## The first attack raises the storm (and tops it up if a needle is missing); every later one
## flings it outward.
func attack() -> bool:
	var shots: ProjectileManager = projectiles()
	if shots == null:
		return false
	var numbers: WeaponLevel = current()
	var needles: Array[Projectile] = shots.fired_by(self)
	if needles.size() < numbers.count:
		for i: int in range(needles.size(), numbers.count):
			var needle: Projectile = shots.spawn(StormNeedleProjectile)
			(needle as StormNeedleProjectile).launch(self, 0.0)
			needles.append(needle)
		_spread(needles)
		return true
	Sfx.play(&"pin", 1.2)
	for needle: Projectile in needles:
		(needle as StormNeedleProjectile).fling()
	return true


## Spaces the needles evenly around the circle.
func _spread(needles: Array[Projectile]) -> void:
	var start: float = (needles[0] as StormNeedleProjectile).angle
	for i: int in needles.size():
		(needles[i] as StormNeedleProjectile).angle = start + TAU * i / needles.size()
