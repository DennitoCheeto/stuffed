class_name SnowDay
extends SnowballToss
## Evolved Snowball Toss (+ Thick Felt, Pip, spec 10 §3): bigger icy snowballs; every landing
## builds a snowman that draws nearby zombies, then bursts and freezes them.


func _shot_kind() -> GDScript:
	return SnowDayProjectile


## This hero's standing snowmen.
func snowmen() -> Array[SnowmanProjectile]:
	return SnowmanProjectile.standing(self)


## Builds a snowman at `at`, unless the most are already standing.
func build_snowman(at: Vector2) -> void:
	SnowmanProjectile.build_for(self, at)
