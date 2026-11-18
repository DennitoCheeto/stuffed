class_name PawSwat
extends ThreadWhip
## Böbö's own weapon (spec 08 §3): a wide paw swipe in the direction he faces (not towards the
## cursor), good damage and a small push. With a count of 2 the second swipe goes behind him.


func _aim() -> Vector2:
	return facing()


func _shot_kind() -> GDScript:
	return PawProjectile
