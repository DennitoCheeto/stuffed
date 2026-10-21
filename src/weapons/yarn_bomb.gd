class_name YarnBomb
extends YarnCannon
## Evolved Yarn Cannon (+ Big Spool): its burst leaves a patch of sticky yarn that slows and
## hurts zombies inside it for a while (spec 02 §5).


func _ball_kind() -> GDScript:
	return BombProjectile
