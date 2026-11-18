class_name PawProjectile
extends WhipProjectile
## One swipe of Paw Swat: hurts every zombie in its arc at once (like a whip lash) and shows a
## fat felt paw swipe with claw marks for a blink.


func _part() -> StringName:
	return ProjectileLook.PAW


func _part_radius() -> float:
	return ProjectileLook.PAW_RADIUS
