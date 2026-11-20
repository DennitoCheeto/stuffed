class_name SnowDay
extends SnowballToss
## Evolved Snowball Toss (+ Thick Felt, Pip, spec 10 §3): bigger icy snowballs; every landing
## builds a snowman that draws nearby zombies, then bursts and freezes them.


func _shot_kind() -> GDScript:
	return SnowDayProjectile


## This hero's standing snowmen.
func snowmen() -> Array[SnowmanProjectile]:
	var result: Array[SnowmanProjectile] = []
	var shots: ProjectileManager = projectiles()
	if shots == null:
		return result
	for shot: Projectile in shots.fired_by(self):
		if shot is SnowmanProjectile and (shot as SnowmanProjectile).is_standing():
			result.append(shot as SnowmanProjectile)
	return result


## Builds a snowman at `at`, unless the most are already standing.
func build_snowman(at: Vector2) -> void:
	var rules: Snowmen = stats.snowmen
	var shots: ProjectileManager = projectiles()
	if rules == null or shots == null or snowmen().size() >= rules.max_snowmen:
		return
	var snowman: SnowmanProjectile = shots.spawn(SnowmanProjectile) as SnowmanProjectile
	snowman.build(self, at)
