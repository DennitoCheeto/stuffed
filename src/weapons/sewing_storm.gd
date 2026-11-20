class_name SewingStorm
extends Weapon
## Evolved Orbiting Needles (+ Long Thread): a storm of needles that never stops circling the
## player; every cooldown the whole storm is flung outward to `area` and pulled back in
## (spec 02 §5). Reach is the circle's radius, speed how fast a needle moves along it, duration
## how long one fling takes. Flung needles trail thread that yanks the zombies they hit back in
## (stitch-up, spec 10 §3); `threads` draws it.

var threads: StitchThreads


func _ready() -> void:
	threads = StitchThreads.new()
	threads.storm = self
	add_child(threads)


## The first attack raises the storm (and tops it up if a needle is missing); every later one
## flings it outward.
func attack() -> bool:
	var shots: ProjectileManager = projectiles()
	if shots == null:
		return false
	var numbers: WeaponLevel = current()
	# Only storm needles: the old Orbiting Needles' shots can still fly right after the evolution.
	var flock: Array[StormNeedleProjectile] = needles()
	if flock.size() < numbers.count:
		for i: int in range(flock.size(), numbers.count):
			var shot: Projectile = shots.spawn(StormNeedleProjectile)
			var needle: StormNeedleProjectile = shot as StormNeedleProjectile
			needle.launch(self, 0.0)
			flock.append(needle)
		_spread(flock)
		return true
	for needle: StormNeedleProjectile in flock:
		needle.fling()
	return true


## This storm's needles in flight.
func needles() -> Array[StormNeedleProjectile]:
	var result: Array[StormNeedleProjectile] = []
	var shots: ProjectileManager = projectiles()
	if shots == null:
		return result
	for shot: Projectile in shots.fired_by(self):
		if shot is StormNeedleProjectile:
			result.append(shot as StormNeedleProjectile)
	return result


## Spaces the needles evenly around the circle.
func _spread(flock: Array[StormNeedleProjectile]) -> void:
	var start: float = flock[0].angle
	for i: int in flock.size():
		flock[i].angle = start + TAU * i / flock.size()
